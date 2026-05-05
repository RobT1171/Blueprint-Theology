CREATE TABLE IF NOT EXISTS magic_link_tokens (
  token TEXT PRIMARY KEY,
  email TEXT NOT NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  expires_at DATETIME NOT NULL,
  used_at DATETIME NULL
);

CREATE INDEX IF NOT EXISTS idx_magic_link_email_created
  ON magic_link_tokens(email, created_at);
