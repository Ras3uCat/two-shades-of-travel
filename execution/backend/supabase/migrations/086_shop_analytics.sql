-- 086_shop_analytics.sql
-- Extends get_revenue_summary() (084_analytics.sql) to include shop order data.
-- Only deployed when the 'shop' module is enabled (deliver.sh handles this).
-- Replaces the function in place — safe to re-run (CREATE OR REPLACE).

CREATE OR REPLACE FUNCTION get_revenue_summary(
  p_period TEXT DEFAULT 'week'  -- 'week' (12 weeks) | 'month' (6 months)
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

    -- ── Booking KPIs ──────────────────────────────────────────────────────────
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

    -- ── Booking revenue by period ──────────────────────────────────────────────
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

    -- ── Top services ──────────────────────────────────────────────────────────
    'top_services', (
      SELECT COALESCE(json_agg(s), '[]'::json)
      FROM (
        SELECT svc AS name, COUNT(*)::INT AS count, COALESCE(SUM(total_price), 0)::FLOAT AS revenue
        FROM bookings, unnest(service_names) AS svc
        WHERE status IN ('confirmed', 'completed')
          AND start_time >= NOW() - INTERVAL '90 days'
        GROUP BY svc ORDER BY count DESC LIMIT 6
      ) s
    ),

    -- ── Busiest days ──────────────────────────────────────────────────────────
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
    ),

    -- ── Shop KPIs ─────────────────────────────────────────────────────────────
    'shop_kpis', (
      SELECT json_build_object(
        'revenue_30d',     COALESCE(SUM(total_cents), 0)::FLOAT / 100,
        'orders_30d',      COUNT(*)::INT,
        'avg_order_value', COALESCE(AVG(total_cents), 0)::FLOAT / 100
      )
      FROM shop_orders
      WHERE status IN ('paid', 'processing', 'shipped', 'delivered')
        AND created_at >= NOW() - INTERVAL '30 days'
    ),

    -- ── Shop revenue by period ────────────────────────────────────────────────
    'shop_revenue_by_period', (
      SELECT COALESCE(json_agg(r ORDER BY r.period_date), '[]'::json)
      FROM (
        SELECT
          to_char(date_trunc(p_period, created_at), v_label_fmt) AS label,
          date_trunc(p_period, created_at)                        AS period_date,
          COALESCE(SUM(total_cents), 0)::FLOAT / 100              AS revenue,
          COUNT(*)::INT                                            AS count
        FROM shop_orders
        WHERE status IN ('paid', 'processing', 'shipped', 'delivered')
          AND created_at >= NOW() - v_lookback
        GROUP BY date_trunc(p_period, created_at)
      ) r
    ),

    -- ── Top products (90-day window) ──────────────────────────────────────────
    'top_products', (
      SELECT COALESCE(json_agg(p), '[]'::json)
      FROM (
        SELECT
          soi.product_name                                              AS name,
          SUM(soi.quantity)::INT                                        AS count,
          COALESCE(SUM(soi.price_cents * soi.quantity), 0)::FLOAT / 100 AS revenue
        FROM shop_order_items soi
        JOIN shop_orders so ON so.id = soi.order_id
        WHERE so.status IN ('paid', 'processing', 'shipped', 'delivered')
          AND so.created_at >= NOW() - INTERVAL '90 days'
        GROUP BY soi.product_name
        ORDER BY count DESC
        LIMIT 6
      ) p
    )

  );
END;
$$;

REVOKE ALL ON FUNCTION get_revenue_summary(TEXT) FROM PUBLIC;
GRANT  EXECUTE ON FUNCTION get_revenue_summary(TEXT) TO authenticated;
