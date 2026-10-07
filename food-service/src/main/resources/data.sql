-- Dummy data for food-service (mysql: Fooddb, configured in the config repo).
-- Runs on every startup after Hibernate has created/updated the tables
-- (spring.jpa.defer-datasource-initialization=true); INSERT IGNORE keeps it idempotent.
-- restaurant_id values match the restaurants seeded by restaurant-service's data.sql.

INSERT IGNORE INTO food_service_category (id, name, description) VALUES
    ('c0000000-0001-4000-8000-000000000001', 'Main Course', 'Curries, biryanis and other filling dishes'),
    ('c0000000-0002-4000-8000-000000000002', 'Starters', 'Small plates to begin your meal'),
    ('c0000000-0003-4000-8000-000000000003', 'Pizza', 'Wood-fired pizzas'),
    ('c0000000-0004-4000-8000-000000000004', 'Desserts', 'Something sweet to finish');

INSERT IGNORE INTO food_service_food_item
    (id, title, description, quantity, out_of_stock, food_type, food_category_id, restaurant_id) VALUES
    ('f0000000-0001-4000-8000-000000000001', 'Paneer Butter Masala', 'Cottage cheese in a rich tomato-butter gravy',
     50, false, 'VEG', 'c0000000-0001-4000-8000-000000000001', 'a1b2c3d4-0001-4000-8000-000000000001'),
    ('f0000000-0002-4000-8000-000000000002', 'Chicken Biryani', 'Hyderabadi dum biryani with raita',
     40, false, 'NONVEG', 'c0000000-0001-4000-8000-000000000001', 'a1b2c3d4-0001-4000-8000-000000000001'),
    ('f0000000-0003-4000-8000-000000000003', 'Gulab Jamun', 'Two pieces, served warm',
     100, false, 'VEG', 'c0000000-0004-4000-8000-000000000004', 'a1b2c3d4-0001-4000-8000-000000000001'),
    ('f0000000-0004-4000-8000-000000000004', 'Veg Manchurian', 'Vegetable balls in a spicy soy-garlic sauce',
     60, false, 'VEG', 'c0000000-0002-4000-8000-000000000002', 'a1b2c3d4-0002-4000-8000-000000000002'),
    ('f0000000-0005-4000-8000-000000000005', 'Chicken Momos', 'Steamed dumplings with red chutney',
     0, true, 'NONVEG', 'c0000000-0002-4000-8000-000000000002', 'a1b2c3d4-0002-4000-8000-000000000002'),
    ('f0000000-0006-4000-8000-000000000006', 'Margherita Pizza', 'Tomato, mozzarella and fresh basil',
     30, false, 'VEG', 'c0000000-0003-4000-8000-000000000003', 'a1b2c3d4-0003-4000-8000-000000000003'),
    ('f0000000-0007-4000-8000-000000000007', 'Pepperoni Pizza', 'Loaded with chicken pepperoni',
     25, false, 'NONVEG', 'c0000000-0003-4000-8000-000000000003', 'a1b2c3d4-0003-4000-8000-000000000003');
