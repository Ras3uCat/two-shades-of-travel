-- 084_analytics.sql
-- Admin analytics summary function.
-- Returns revenue by period, booking volume, top services, and busiest days.
-- p_period: 'week' (last 12 weeks) | 'month' (last 6 months)
-- Master-only via JWT role check.

CREATE OR REPLACE FUNCTION get_revenue_summary(
  p_period TEXT DEFAULT 'week'
)
RETURNS JSON
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
AS $$
DECLARE
  v_lookback  INTERVAL;
  v_label_fmt TEXT;
BEGIN
  -- Guard: master only
  IF (current_setting('request.jwt.claims', true)::json ->> 'user_role') <> 'master' THEN
    RAISE EXCEPTION 'Access denied';
  END IF;

  IF p_period = 'month' THEN
    v_lookback  := INTERVAL '6 months';
    v_label_fmt := 'Mon YYYY';
  ELSE
    v_lookback  := INTERVAL '12 weeks';
    v_label_fmt := 'Mon DD';
  END IF;

  RETURN json_build_object(

    -- ── 30-day KPIs ────────────────────────────────────────────────────────
    'kpis', (
      SELECT json_build_object(
        'revenue_30d',       COALESCE(SUM(total_price), 0)::FLOAT,
        'bookings_30d',      COUNT(*)::INT,
        'avg_booking_value', COALESCE(AVG(total_price), 0)::FLOAT
      )
      FROM bookings
      WHERE status IN ('confirmed', 'completed')
        AND start_time >= NOW() - INTERVAL '30 days'
    ),

    -- ── Revenue / volume by period ─────────────────────────────────────────
    'revenue_by_period', (
      SELECT COALESCE(json_agg(r ORDER BY r.period_date), '[]'::json)
      FROM (
        SELECT
          to_char(date_trunc(p_period, start_time), v_label_fmt) AS label,
          date_trunc(p_period, start_time)                        AS period_date,
          COALESCE(SUM(total_price), 0)::FLOAT                    AS revenue,
          COUNT(*)::INT                                            AS count
        FROM bookings
        WHERE status IN ('confirmed', 'completed')
          AND start_time >= NOW() - v_lookback
        GROUP BY date_trunc(p_period, start_time)
      ) r
    ),

    -- ── Top services by booking count (90-day window) ──────────────────────
    'top_services', (
      SELECT COALESCE(json_agg(s), '[]'::json)
      FROM (
        SELECT
          svc                                  AS name,
          COUNT(*)::INT                        AS count,
          COALESCE(SUM(total_price), 0)::FLOAT AS revenue
        FROM bookings, unnest(service_names) AS svc
        WHERE status IN ('confirmed', 'completed')
          AND start_time >= NOW() - INTERVAL '90 days'
        GROUP BY svc
        ORDER BY count DESC
        LIMIT 6
      ) s
    ),

    -- ── Busiest days of week (90-day window) ───────────────────────────────
    'busiest_days', (
      SELECT COALESCE(json_agg(d ORDER BY d.day_num), '[]'::json)
      FROM (
        SELECT
          to_char(start_time, 'Dy')         AS day,
          EXTRACT(DOW FROM start_time)::INT  AS day_num,
          COUNT(*)::INT                      AS count
        FROM bookings
        WHERE status IN ('confirmed', 'completed')
          AND start_time >= NOW() - INTERVAL '90 days'
        GROUP BY to_char(start_time, 'Dy'), EXTRACT(DOW FROM start_time)::INT
      ) d
    )

  );
END;
$$;

REVOKE ALL ON FUNCTION get_revenue_summary(TEXT) FROM PUBLIC;
GRANT  EXECUTE ON FUNCTION get_revenue_summary(TEXT) TO authenticated;
