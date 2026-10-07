-- Dummy data for restaurant-service (postgres: restaurantdb).
-- Runs on every startup after Hibernate has created/updated the tables
-- (spring.jpa.defer-datasource-initialization=true), so every statement is idempotent.
-- The whole file is sent as one script (see spring.sql.init.separator) because
-- the DO block below contains semicolons.

-- Older versions of Restaurant used @Lob, which created about_restaurant as an
-- oid large-object column. Convert it to TEXT, keeping existing values.
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.columns
               WHERE table_name = 'restaurant'
                 AND column_name = 'about_restaurant'
                 AND data_type = 'oid') THEN
        ALTER TABLE restaurant
            ALTER COLUMN about_restaurant TYPE TEXT
            USING CASE WHEN about_restaurant IS NULL THEN NULL
                       ELSE convert_from(lo_get(about_restaurant), 'UTF8') END;
    END IF;
END $$;

INSERT INTO restaurant (id, name, address, phone, open, open_time, close_time, about_restaurant)
VALUES
    ('a1b2c3d4-0001-4000-8000-000000000001', 'Spice Garden', '12 MG Road, Bengaluru', '9876543210', true,
     '09:00:00', '23:00:00', 'Authentic North Indian curries, tandoor and biryanis.'),
    ('a1b2c3d4-0002-4000-8000-000000000002', 'Dragon Wok', '45 Park Street, Kolkata', '9876543211', true,
     '11:00:00', '23:30:00', 'Indo-Chinese favourites: noodles, manchurian and momos.'),
    ('a1b2c3d4-0003-4000-8000-000000000003', 'Pizza Piazza', '7 Linking Road, Mumbai', '9876543212', false,
     '12:00:00', '00:00:00', 'Wood-fired pizzas and fresh pasta.')
ON CONFLICT (id) DO NOTHING;

INSERT INTO restaurant_pictures (restaurant_id, pictures)
SELECT v.restaurant_id, v.pictures
FROM (VALUES
    ('a1b2c3d4-0001-4000-8000-000000000001', 'https://picsum.photos/seed/spice-garden-1/600/400'),
    ('a1b2c3d4-0001-4000-8000-000000000001', 'https://picsum.photos/seed/spice-garden-2/600/400'),
    ('a1b2c3d4-0002-4000-8000-000000000002', 'https://picsum.photos/seed/dragon-wok-1/600/400'),
    ('a1b2c3d4-0003-4000-8000-000000000003', 'https://picsum.photos/seed/pizza-piazza-1/600/400')
) AS v(restaurant_id, pictures)
WHERE NOT EXISTS (SELECT 1 FROM restaurant_pictures p
                  WHERE p.restaurant_id = v.restaurant_id AND p.pictures = v.pictures);
