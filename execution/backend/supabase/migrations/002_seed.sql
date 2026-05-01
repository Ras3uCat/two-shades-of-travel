-- 002_seed.sql
-- Business configuration seed data.
-- CLIENT_NAME and CLIENT_TIMEZONE tokens are replaced by setup.sh before this file is pushed.
-- Safe to re-run: inserts only if no rows exist.

DO $$
BEGIN
  -- business_config: single row, seeded once
  IF NOT EXISTS (SELECT 1 FROM business_config LIMIT 1) THEN
    INSERT INTO business_config (client_name, timezone, booking_advance_days, slot_duration_minutes, currency)
    VALUES ('CLIENT_NAME', 'CLIENT_TIMEZONE', 7, 20, 'usd');
  END IF;

  -- business_hours: 7 rows (Sun–Sat), default Mon–Sat 09:00–18:00, Sunday closed
  -- Adjust via Admin panel or Supabase dashboard after delivery.
  IF NOT EXISTS (SELECT 1 FROM business_hours LIMIT 1) THEN
    INSERT INTO business_hours (day_of_week, open_time, close_time, is_closed) VALUES
      (0, '09:00', '18:00', true),   -- Sunday:    closed
      (1, '09:00', '18:00', false),  -- Monday:    09:00–18:00
      (2, '09:00', '18:00', false),  -- Tuesday:   09:00–18:00
      (3, '09:00', '18:00', false),  -- Wednesday: 09:00–18:00
      (4, '09:00', '18:00', false),  -- Thursday:  09:00–18:00
      (5, '09:00', '18:00', false),  -- Friday:    09:00–18:00
      (6, '10:00', '16:00', false);  -- Saturday:  10:00–16:00
  END IF;
END $$;
