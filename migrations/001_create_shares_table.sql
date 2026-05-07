CREATE TABLE IF NOT EXISTS shares (
  id TEXT PRIMARY KEY,
  share_type TEXT NOT NULL,
  sender_user_id TEXT NOT NULL,
  recipient_email TEXT NOT NULL,
  payload TEXT NOT NULL,
  subject TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'queued',
  resend_message_id TEXT,
  optional_message TEXT,
  created_at INTEGER NOT NULL,
  sent_at INTEGER,
  FOREIGN KEY (sender_user_id) REFERENCES user_profiles(id)
);

CREATE INDEX IF NOT EXISTS idx_shares_sender_created ON shares(sender_user_id, created_at);
