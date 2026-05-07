CREATE TABLE unsubscribes (
  email TEXT PRIMARY KEY,
  unsubscribed_at TEXT NOT NULL DEFAULT (datetime('now')),
  source TEXT,
  user_agent TEXT,
  share_id TEXT
);

CREATE INDEX idx_unsubscribes_email ON unsubscribes(email);
