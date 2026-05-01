-- 093_sms_reminder_sent.sql
-- Separates SMS reminder tracking from email reminder tracking (SMS_ENABLED feature).
-- Previously send-sms-reminders shared reminder_sent with send-reminders (email), causing a
-- race condition where whichever cron ran first would consume all bookings, blocking the other.

ALTER TABLE bookings ADD COLUMN sms_reminder_sent boolean NOT NULL DEFAULT false;
