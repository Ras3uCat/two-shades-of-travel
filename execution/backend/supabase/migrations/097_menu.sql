-- 097_menu.sql
-- Menu / Price List module — standalone table, not linked to booking services.

CREATE TABLE menu_items (
  id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  category     text NOT NULL DEFAULT 'General',
  name         text NOT NULL,
  description  text,
  price        integer,           -- cents (null = "Price on request"). $15.00 stored as 1500.
  image_url    text,
  is_available boolean NOT NULL DEFAULT true,
  sort_order   integer NOT NULL DEFAULT 0,
  created_at   timestamptz DEFAULT now()
);

ALTER TABLE menu_items ENABLE ROW LEVEL SECURITY;

CREATE POLICY "public read" ON menu_items FOR SELECT USING (true);

CREATE POLICY "admin write" ON menu_items FOR ALL USING (
  EXISTS (
    SELECT 1 FROM profiles WHERE user_id = auth.uid() AND role IN ('master', 'staff')
  )
);
