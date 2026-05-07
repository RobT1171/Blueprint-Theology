ALTER TABLE user_profiles ADD COLUMN twitter_handle TEXT;
ALTER TABLE user_profiles ADD COLUMN instagram_handle TEXT;
ALTER TABLE user_profiles ADD COLUMN linkedin_handle TEXT;
ALTER TABLE user_profiles ADD COLUMN facebook_handle TEXT;
ALTER TABLE user_profiles ADD COLUMN theme_preference TEXT DEFAULT 'system';
ALTER TABLE user_profiles ADD COLUMN default_translation TEXT DEFAULT 'ESV';
ALTER TABLE user_profiles ADD COLUMN default_depth TEXT DEFAULT 'standard';
