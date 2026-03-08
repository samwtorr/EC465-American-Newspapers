"""
Shared database utilities for the railroad-ties pipeline.

Database path: owner_bio_scraping/railroad_pipeline.db
All tables are created by init_db(); every subsequent step just calls get_connection().
"""

import sqlite3
import json
from datetime import datetime
from pathlib import Path

DB_PATH = Path(__file__).parent / "railroad_pipeline.db"


# ---------------------------------------------------------------------------
# Connection
# ---------------------------------------------------------------------------

def get_connection(db_path=None):
    """Return a sqlite3 connection with row_factory set to Row."""
    path = db_path or DB_PATH
    conn = sqlite3.connect(str(path))
    conn.row_factory = sqlite3.Row
    conn.execute("PRAGMA journal_mode=WAL")
    conn.execute("PRAGMA foreign_keys=ON")
    return conn


# ---------------------------------------------------------------------------
# Schema
# ---------------------------------------------------------------------------

SCHEMA = """
-- Core persons table: one row per researchable individual
CREATE TABLE IF NOT EXISTS persons (
    research_id   INTEGER PRIMARY KEY AUTOINCREMENT,
    person_id     INTEGER,          -- FK to names_qualified_papers (may repeat when nqp has multi-person rows)
    canonical_name TEXT NOT NULL,
    name_variants  TEXT,            -- JSON array of known alternate spellings
    known_states   TEXT,            -- JSON array of state abbreviations/names
    known_newspapers TEXT,          -- JSON array of newspaper names
    first_active_year INTEGER,
    last_active_year  INTEGER,
    is_ambiguous   INTEGER DEFAULT 0,  -- 1 = common name, needs extra disambiguation care
    notes          TEXT
);

-- Every book / article / API hit found per person
CREATE TABLE IF NOT EXISTS sources_discovered (
    id             INTEGER PRIMARY KEY AUTOINCREMENT,
    research_id    INTEGER NOT NULL REFERENCES persons(research_id),
    source_type    TEXT NOT NULL,   -- 'google_books' | 'hathitrust' | 'dpla' | 'internet_archive' | 'chronicling_america' | 'manual'
    title          TEXT,
    url            TEXT,
    item_id        TEXT,            -- e.g. Internet Archive identifier or HathiTrust volume ID
    snippet        TEXT,
    relevance_note TEXT,
    discovery_step TEXT,            -- '2a_google_books' | '2b_hathitrust' | '2c_dpla' | '3a_ia' | '3b_ca' | '2.5_manual'
    discovered_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(research_id, source_type, item_id)  -- prevent duplicate discoveries
);

-- Full text passages keyed to person + source
CREATE TABLE IF NOT EXISTS texts_downloaded (
    id              INTEGER PRIMARY KEY AUTOINCREMENT,
    research_id     INTEGER NOT NULL REFERENCES persons(research_id),
    source_id       INTEGER REFERENCES sources_discovered(id),
    source_type     TEXT,
    source_url      TEXT,
    source_title    TEXT,
    passage_text    TEXT NOT NULL,
    context_text    TEXT,           -- wider window of surrounding text
    is_keyword_filtered INTEGER DEFAULT 0,  -- 1 = matched a financial/obituary keyword
    keyword_match   TEXT,           -- which keyword(s) triggered this
    page_num        TEXT,           -- page number or section within source
    downloaded_at   TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Structured metadata gathered per person from external sources
CREATE TABLE IF NOT EXISTS enrichment (
    id           INTEGER PRIMARY KEY AUTOINCREMENT,
    research_id  INTEGER NOT NULL REFERENCES persons(research_id),
    source       TEXT NOT NULL,     -- 'wikidata' | 'familysearch' | 'manual'
    birth_year   INTEGER,
    death_year   INTEGER,
    birth_place  TEXT,
    death_place  TEXT,
    occupations  TEXT,              -- JSON array
    external_ids TEXT,              -- JSON dict e.g. {"viaf": "...", "lccn": "..."}
    wikidata_qid TEXT,
    raw_data     TEXT,              -- full JSON response from API
    enriched_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Structured financial ties extracted in Step 5
CREATE TABLE IF NOT EXISTS extraction_results (
    id               INTEGER PRIMARY KEY AUTOINCREMENT,
    research_id      INTEGER NOT NULL REFERENCES persons(research_id),
    text_id          INTEGER REFERENCES texts_downloaded(id),
    railroad_company TEXT,
    connection_type  TEXT,  -- 'stockholder' | 'director' | 'officer' | 'legal_counsel' | 'debtor' | 'land_grant' | 'other'
    other_financial_ties TEXT,
    source_passage   TEXT,
    source_ref       TEXT,  -- title + page for citation
    confidence       TEXT,  -- 'confirmed' | 'uncertain' | 'garbled_ocr'
    extraction_model TEXT,
    extracted_at     TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Field-level extractions for manual coding (Step 5)
CREATE TABLE IF NOT EXISTS field_extractions (
    id               INTEGER PRIMARY KEY AUTOINCREMENT,
    research_id      INTEGER NOT NULL REFERENCES persons(research_id),
    field_name       TEXT NOT NULL,       -- e.g. 'political_affiliation', 'railroad_stockholder'
    extracted_text   TEXT NOT NULL,       -- verbatim quote from source
    source_ref       TEXT,               -- source title/page for traceability
    confidence       TEXT DEFAULT 'confirmed',  -- 'confirmed' | 'uncertain' | 'inferred'
    identity_confidence TEXT DEFAULT 'high',    -- 'high' | 'medium' — is this passage about the right person?
    extraction_model TEXT,
    extracted_at     TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    coded_value      TEXT,               -- user-assigned value (filled in step 5b)
    coded_at         TIMESTAMP
);

-- Per-person, per-step progress tracking (for resumable pipeline)
CREATE TABLE IF NOT EXISTS pipeline_progress (
    research_id  INTEGER NOT NULL REFERENCES persons(research_id),
    step         TEXT NOT NULL,     -- e.g. '1_wikidata' | '2a_google_books' | '3b_ca'
    status       TEXT NOT NULL DEFAULT 'pending',  -- 'pending' | 'running' | 'done' | 'failed' | 'skipped'
    last_run     TIMESTAMP,
    error_msg    TEXT,
    result_count INTEGER,           -- how many rows were inserted in the relevant table
    PRIMARY KEY (research_id, step)
);

-- Global key-value config store
CREATE TABLE IF NOT EXISTS pipeline_config (
    key   TEXT PRIMARY KEY,
    value TEXT,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
"""


def init_db(db_path=None):
    """Create all tables if they don't exist. Safe to call multiple times."""
    conn = get_connection(db_path)
    conn.executescript(SCHEMA)
    conn.commit()
    print(f"Database initialised at {db_path or DB_PATH}")
    return conn


# ---------------------------------------------------------------------------
# Progress tracking
# ---------------------------------------------------------------------------

def get_progress(conn, research_id, step):
    row = conn.execute(
        "SELECT status FROM pipeline_progress WHERE research_id=? AND step=?",
        (research_id, step)
    ).fetchone()
    return row["status"] if row else "pending"


def set_progress(conn, research_id, step, status, error_msg=None, result_count=None):
    conn.execute(
        """INSERT INTO pipeline_progress (research_id, step, status, last_run, error_msg, result_count)
           VALUES (?, ?, ?, ?, ?, ?)
           ON CONFLICT(research_id, step) DO UPDATE SET
               status=excluded.status,
               last_run=excluded.last_run,
               error_msg=excluded.error_msg,
               result_count=excluded.result_count""",
        (research_id, step, status, datetime.utcnow().isoformat(), error_msg, result_count)
    )
    conn.commit()


def pending_persons(conn, step):
    """Return list of research_id values that haven't completed the given step yet."""
    done = {
        r["research_id"]
        for r in conn.execute(
            "SELECT research_id FROM pipeline_progress WHERE step=? AND status='done'",
            (step,)
        ).fetchall()
    }
    all_ids = {r["research_id"] for r in conn.execute("SELECT research_id FROM persons").fetchall()}
    return sorted(all_ids - done)


# ---------------------------------------------------------------------------
# Persons helpers
# ---------------------------------------------------------------------------

def get_all_persons(conn):
    return conn.execute("SELECT * FROM persons ORDER BY research_id").fetchall()


def get_person(conn, research_id):
    return conn.execute("SELECT * FROM persons WHERE research_id=?", (research_id,)).fetchone()


def name_variants_for(conn, research_id):
    row = conn.execute("SELECT name_variants FROM persons WHERE research_id=?", (research_id,)).fetchone()
    if row and row["name_variants"]:
        return json.loads(row["name_variants"])
    return []


# ---------------------------------------------------------------------------
# Source / text logging helpers
# ---------------------------------------------------------------------------

def log_source(conn, research_id, source_type, title=None, url=None, item_id=None,
               snippet=None, relevance_note=None, discovery_step=None):
    """Insert or ignore a discovered source. Returns the row id."""
    try:
        cur = conn.execute(
            """INSERT OR IGNORE INTO sources_discovered
               (research_id, source_type, title, url, item_id, snippet, relevance_note, discovery_step)
               VALUES (?, ?, ?, ?, ?, ?, ?, ?)""",
            (research_id, source_type, title, url, item_id, snippet, relevance_note, discovery_step)
        )
        conn.commit()
        if cur.rowcount == 1:
            return cur.lastrowid
        # Row already existed (INSERT OR IGNORE skipped) — fetch its id.
        # N.B. We must not use cur.lastrowid here: after a skipped INSERT,
        # it returns a stale connection-wide value that may belong to a
        # different table (e.g. texts_downloaded), causing FK violations.
        row = conn.execute(
            "SELECT id FROM sources_discovered WHERE research_id=? AND source_type=? AND item_id=?",
            (research_id, source_type, item_id)
        ).fetchone()
        return row["id"] if row else None
    except Exception as e:
        print(f"  log_source error: {e}")
        return None


def store_text(conn, research_id, passage_text, source_id=None, source_type=None,
               source_url=None, source_title=None, context_text=None,
               is_keyword_filtered=0, keyword_match=None, page_num=None):
    """Store a downloaded text passage. Returns row id."""
    cur = conn.execute(
        """INSERT INTO texts_downloaded
           (research_id, source_id, source_type, source_url, source_title,
            passage_text, context_text, is_keyword_filtered, keyword_match, page_num)
           VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)""",
        (research_id, source_id, source_type, source_url, source_title,
         passage_text, context_text, is_keyword_filtered, keyword_match, page_num)
    )
    conn.commit()
    return cur.lastrowid


def store_enrichment(conn, research_id, source, birth_year=None, death_year=None,
                     birth_place=None, death_place=None, occupations=None,
                     external_ids=None, wikidata_qid=None, raw_data=None):
    conn.execute(
        """INSERT INTO enrichment
           (research_id, source, birth_year, death_year, birth_place, death_place,
            occupations, external_ids, wikidata_qid, raw_data)
           VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)""",
        (research_id, source,
         birth_year, death_year, birth_place, death_place,
         json.dumps(occupations) if occupations else None,
         json.dumps(external_ids) if external_ids else None,
         wikidata_qid,
         json.dumps(raw_data) if raw_data and not isinstance(raw_data, str) else raw_data)
    )
    conn.commit()


def store_extraction(conn, research_id, text_id=None, railroad_company=None,
                     connection_type=None, other_financial_ties=None,
                     source_passage=None, source_ref=None,
                     confidence="confirmed", extraction_model=None):
    conn.execute(
        """INSERT INTO extraction_results
           (research_id, text_id, railroad_company, connection_type, other_financial_ties,
            source_passage, source_ref, confidence, extraction_model)
           VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)""",
        (research_id, text_id, railroad_company, connection_type, other_financial_ties,
         source_passage, source_ref, confidence, extraction_model)
    )
    conn.commit()


def store_field_extraction(conn, research_id, field_name, extracted_text,
                           source_ref=None, confidence="confirmed",
                           identity_confidence="high", extraction_model=None):
    conn.execute(
        """INSERT INTO field_extractions
           (research_id, field_name, extracted_text, source_ref,
            confidence, identity_confidence, extraction_model)
           VALUES (?, ?, ?, ?, ?, ?, ?)""",
        (research_id, field_name, extracted_text, source_ref,
         confidence, identity_confidence, extraction_model)
    )
    conn.commit()


def save_coded_value(conn, extraction_id, coded_value):
    conn.execute(
        """UPDATE field_extractions SET coded_value=?, coded_at=? WHERE id=?""",
        (coded_value, datetime.utcnow().isoformat(), extraction_id)
    )
    conn.commit()


def save_manual_coded_value(conn, research_id, field_name, coded_value):
    """Insert or update a manually coded value (no LLM-extracted text).
    Creates a placeholder extraction row if none exists for this field."""
    now = datetime.utcnow().isoformat()
    existing = conn.execute(
        "SELECT id FROM field_extractions WHERE research_id=? AND field_name=? AND extracted_text='[manual]'",
        (research_id, field_name)
    ).fetchone()
    if existing:
        conn.execute(
            "UPDATE field_extractions SET coded_value=?, coded_at=? WHERE id=?",
            (coded_value, now, existing["id"])
        )
    else:
        conn.execute(
            """INSERT INTO field_extractions
               (research_id, field_name, extracted_text, confidence, identity_confidence, coded_value, coded_at)
               VALUES (?, ?, '[manual]', 'manual', 'high', ?, ?)""",
            (research_id, field_name, coded_value, now)
        )
    conn.commit()


# ---------------------------------------------------------------------------
# Summary helpers (for notebook dashboards)
# ---------------------------------------------------------------------------

def pipeline_summary(conn):
    """Print a quick summary of pipeline progress across all steps."""
    steps = [r["step"] for r in conn.execute(
        "SELECT DISTINCT step FROM pipeline_progress ORDER BY step"
    ).fetchall()]
    print(f"{'Step':<30} {'done':>6} {'failed':>7} {'pending':>8}")
    print("-" * 55)
    total = conn.execute("SELECT COUNT(*) as n FROM persons").fetchone()["n"]
    for step in steps:
        counts = {
            r["status"]: r["n"]
            for r in conn.execute(
                "SELECT status, COUNT(*) as n FROM pipeline_progress WHERE step=? GROUP BY status",
                (step,)
            ).fetchall()
        }
        done    = counts.get("done", 0)
        failed  = counts.get("failed", 0)
        pending = total - done - failed - counts.get("running", 0) - counts.get("skipped", 0)
        print(f"  {step:<28} {done:>6} {failed:>7} {pending:>8}")
    print()
    print(f"Total persons: {total}")
    print(f"Sources discovered: {conn.execute('SELECT COUNT(*) as n FROM sources_discovered').fetchone()['n']}")
    print(f"Text passages:      {conn.execute('SELECT COUNT(*) as n FROM texts_downloaded').fetchone()['n']}")
    print(f"Extractions:        {conn.execute('SELECT COUNT(*) as n FROM extraction_results').fetchone()['n']}")
