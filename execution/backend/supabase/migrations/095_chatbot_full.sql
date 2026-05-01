-- 095_chatbot_full.sql
-- Adds custom system prompt + welcome message for AI Chatbot Full tier.

ALTER TABLE business_config ADD COLUMN chatbot_system_prompt   text;
ALTER TABLE business_config ADD COLUMN chatbot_welcome_message text
  DEFAULT 'Hi! How can I help you today?';
