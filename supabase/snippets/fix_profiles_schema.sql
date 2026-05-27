-- Add missing columns to profiles table for subscriptions and usage limits
ALTER TABLE profiles 
ADD COLUMN IF NOT EXISTS role TEXT DEFAULT 'free',
ADD COLUMN IF NOT EXISTS purchase_token TEXT,
ADD COLUMN IF NOT EXISTS pro_expires_at TIMESTAMPTZ,
ADD COLUMN IF NOT EXISTS daily_messages_count INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS last_message_at TIMESTAMPTZ,
ADD COLUMN IF NOT EXISTS ai_credits INTEGER DEFAULT 20,
ADD COLUMN IF NOT EXISTS monthly_messages_count INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS last_monthly_refill TIMESTAMPTZ,
ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT now();

-- Ensure existing free users have 20 credits if they are new (optional logic, but good for testing)
-- UPDATE profiles SET ai_credits = 20 WHERE role = 'free' AND ai_credits IS NULL;

-- Comments for documentation
COMMENT ON COLUMN profiles.role IS 'User subscription role (free, pro)';
COMMENT ON COLUMN profiles.purchase_token IS 'Last validated Google Play purchase token';
COMMENT ON COLUMN profiles.pro_expires_at IS 'Timestamp when pro access expires';
COMMENT ON COLUMN profiles.daily_messages_count IS 'Count of messages sent in the current day';
COMMENT ON COLUMN profiles.last_message_at IS 'Timestamp of the last message sent';
COMMENT ON COLUMN profiles.ai_credits IS 'Initial gift credits or purchased one-time credits';
COMMENT ON COLUMN profiles.monthly_messages_count IS 'Count of messages sent in the current month (Pro users)';
COMMENT ON COLUMN profiles.last_monthly_refill IS 'Timestamp of the last monthly limit reset';
COMMENT ON COLUMN profiles.updated_at IS 'Standard last updated timestamp';
