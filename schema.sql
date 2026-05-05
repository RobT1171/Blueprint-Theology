CREATE TABLE IF NOT EXISTS user_profiles (
  id TEXT PRIMARY KEY,
  name TEXT DEFAULT '',
  email TEXT DEFAULT '',
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
CREATE TABLE IF NOT EXISTS studies (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL,
  mode TEXT NOT NULL DEFAULT 'passage',
  input_reference TEXT DEFAULT '',
  input_text TEXT DEFAULT '',
  translation_preference TEXT DEFAULT 'ESV',
  depth_mode TEXT DEFAULT 'standard',
  created_at TEXT DEFAULT (datetime('now'))
);
CREATE INDEX IF NOT EXISTS idx_studies_user ON studies(user_id);
CREATE TABLE IF NOT EXISTS study_sessions (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL,
  study_id TEXT NOT NULL,
  generated_content TEXT DEFAULT '',
  completion_status TEXT DEFAULT 'not_started',
  completion_score INTEGER DEFAULT 0,
  head_complete INTEGER DEFAULT 0,
  heart_complete INTEGER DEFAULT 0,
  hand_complete INTEGER DEFAULT 0,
  questions_answered INTEGER DEFAULT 0,
  completed_at TEXT,
  created_at TEXT DEFAULT (datetime('now'))
);
CREATE INDEX IF NOT EXISTS idx_sessions_user ON study_sessions(user_id);
CREATE TABLE IF NOT EXISTS notes (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL,
  study_id TEXT DEFAULT '',
  content TEXT DEFAULT '',
  study_reference TEXT DEFAULT '',
  created_at TEXT DEFAULT (datetime('now'))
);
CREATE INDEX IF NOT EXISTS idx_notes_user ON notes(user_id);
CREATE TABLE IF NOT EXISTS tasks (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL,
  study_id TEXT DEFAULT '',
  timeframe TEXT DEFAULT '24hr',
  task_text TEXT DEFAULT '',
  is_completed INTEGER DEFAULT 0,
  completed_at TEXT,
  study_reference TEXT DEFAULT '',
  created_at TEXT DEFAULT (datetime('now'))
);
CREATE INDEX IF NOT EXISTS idx_tasks_user ON tasks(user_id);
CREATE TABLE IF NOT EXISTS study_activity (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id TEXT NOT NULL,
  activity_date TEXT NOT NULL,
  study_id TEXT,
  session_id TEXT,
  activity_type TEXT DEFAULT 'study_completed',
  created_at TEXT DEFAULT (datetime('now')),
  UNIQUE(user_id, activity_date, activity_type)
);
CREATE INDEX IF NOT EXISTS idx_activity_user ON study_activity(user_id);
CREATE TABLE IF NOT EXISTS formation_arc_exposures (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id TEXT NOT NULL,
  arc_key TEXT NOT NULL,
  study_id TEXT,
  session_id TEXT,
  created_at TEXT DEFAULT (datetime('now'))
);
CREATE INDEX IF NOT EXISTS idx_arcs_user ON formation_arc_exposures(user_id);
CREATE TABLE IF NOT EXISTS xp_events (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id TEXT NOT NULL,
  amount INTEGER NOT NULL,
  action TEXT DEFAULT '',
  study_id TEXT,
  created_at TEXT DEFAULT (datetime('now'))
);
CREATE INDEX IF NOT EXISTS idx_xp_user ON xp_events(user_id);
CREATE TABLE IF NOT EXISTS study_paths (
  id TEXT PRIMARY KEY,
  creator_id TEXT NOT NULL,
  group_id TEXT,
  title TEXT DEFAULT '',
  description TEXT DEFAULT '',
  duration_days INTEGER DEFAULT 7,
  theme TEXT DEFAULT '',
  path_data TEXT DEFAULT '[]',
  status TEXT DEFAULT 'draft',
  created_at TEXT DEFAULT (datetime('now'))
);
CREATE INDEX IF NOT EXISTS idx_paths_creator ON study_paths(creator_id);
