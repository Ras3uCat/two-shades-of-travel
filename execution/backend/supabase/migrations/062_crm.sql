-- 062_crm.sql
-- Client summary function for the admin CRM tab.
-- Aggregates booking history per unique client email.
-- Timestamped: 2026-03-07

-- Returns one row per unique client with booking count, last visit, total spent.
-- SECURITY DEFINER + runtime auth check restricts to master role only.
CREATE OR REPLACE FUNCTION get_client_summary()
RETURNS TABLE (
  client_name   text,
  client_email  text,
  booking_count bigint,
  last_visit    timestamptz,
  total_spent   numeric
)
LANGUAGE plpgsql STABLE SECURITY DEFINER
AS $$
BEGIN
  IF (SELECT role FROM profiles WHERE id = auth.uid()) <> 'master' THEN
    RAISE EXCEPTION 'Access denied';
  END IF;

  RETURN QUERY
  SELECT
    b.client_name,
    b.client_email,
    COUNT(*)::bigint       AS booking_count,
    MAX(b.start_time)      AS last_visit,
    SUM(b.total_price)     AS total_spent
  FROM bookings b
  WHERE b.status <> 'cancelled'
  GROUP BY b.client_email, b.client_name
  ORDER BY MAX(b.start_time) DESC NULLS LAST;
END;
$$;
