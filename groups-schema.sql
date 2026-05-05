CREATE TABLE IF NOT EXISTS groups (id TEXT PRIMARY KEY, name TEXT NOT NULL, description TEXT DEFAULT '', owner_id TEXT NOT NULL, invite_code TEXT UNIQUE NOT NULL, max_members INTEGER DEFAULT 10, is_active INTEGER DEFAULT 1, created_at TEXT, updated_at TEXT);

CREATE TABLE IF NOT EXISTS group_members (id TEXT PRIMARY KEY, group_id TEXT NOT NULL, user_id TEXT NOT NULL, role TEXT DEFAULT 'member', joined_at TEXT, UNIQUE(group_id, user_id));

CREATE TABLE IF NOT EXISTS group_studies (id TEXT PRIMARY KEY, group_id TEXT NOT NULL, study_id TEXT NOT NULL, session_id TEXT, shared_by TEXT NOT NULL, title TEXT DEFAULT '', created_at TEXT);

CREATE TABLE IF NOT EXISTS group_discussions (id TEXT PRIMARY KEY, group_id TEXT NOT NULL, study_id TEXT, user_id TEXT NOT NULL, user_name TEXT DEFAULT '', content TEXT NOT NULL, created_at TEXT);