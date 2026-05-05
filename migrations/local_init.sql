-- Local dev bootstrap: minimal schema for magic link smoke tests.
-- Mirrors the live prod schema for the tables our auth flow reads/writes.
-- This file is for `wrangler d1 execute --local` only — production already has these.

CREATE TABLE IF NOT EXISTS user_profiles (
  id TEXT PRIMARY KEY,
  name TEXT DEFAULT '',
  email TEXT DEFAULT '',
  password_hash TEXT DEFAULT '',
  subscription_plan TEXT DEFAULT 'free',
  total_xp INTEGER DEFAULT 0,
  level INTEGER DEFAULT 1,
  streak_count INTEGER DEFAULT 0,
  longest_streak INTEGER DEFAULT 0,
  studies_completed INTEGER DEFAULT 0,
  tasks_completed INTEGER DEFAULT 0,
  engagement_score INTEGER DEFAULT 0,
  created_at TEXT DEFAULT (datetime('now')),
  updated_at TEXT DEFAULT (datetime('now'))
);

CREATE TABLE IF NOT EXISTS auth_sessions (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL,
  token TEXT NOT NULL UNIQUE,
  expires_at TEXT,
  created_at TEXT DEFAULT (datetime('now'))
);
CREATE INDEX IF NOT EXISTS idx_auth_sessions_token ON auth_sessions(token);

CREATE TABLE IF NOT EXISTS magic_link_tokens (
  token TEXT PRIMARY KEY,
  email TEXT NOT NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  expires_at DATETIME NOT NULL,
  used_at DATETIME NULL
);
CREATE INDEX IF NOT EXISTS idx_magic_link_email_created
  ON magic_link_tokens(email, created_at);
