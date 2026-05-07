CREATE TABLE ghl_webhook_log (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL,
  email TEXT NOT NULL,
  status TEXT NOT NULL,
  http_status INTEGER,
  error_message TEXT,
  attempted_at TEXT NOT NULL DEFAULT (datetime('now')),
  retry_count INTEGER NOT NULL DEFAULT 0
);

CREATE INDEX idx_ghl_log_status ON ghl_webhook_log(status, attempted_at);
CREATE INDEX idx_ghl_log_email ON ghl_webhook_log(email);
