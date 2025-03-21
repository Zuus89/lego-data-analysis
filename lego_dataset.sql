-- List all tables in the database
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public';

--This query finds foreign key relationships in the database
SELECT 
    conrelid::regclass AS table_name, 
    a.attname AS column_name, 
    confrelid::regclass AS referenced_table, 
    af.attname AS referenced_column
FROM pg_constraint c
JOIN pg_attribute a ON a.attnum = ANY(c.conkey) AND a.attrelid = c.conrelid
JOIN pg_attribute af ON af.attnum = ANY(c.confkey) AND af.attrelid = c.confrelid
WHERE c.contype = 'f';

-- Count the number of rows in each table
SELECT 'sets' AS table_name, COUNT(*) AS row_count FROM sets
UNION ALL
SELECT 'themes', COUNT(*) FROM themes
UNION ALL
SELECT 'parts', COUNT(*) FROM parts
UNION ALL
SELECT 'part_categories', COUNT(*) FROM part_categories
UNION ALL
SELECT 'colors', COUNT(*) FROM colors
UNION ALL
SELECT 'inventories', COUNT(*) FROM inventories
UNION ALL
SELECT 'inventory_parts', COUNT(*) FROM inventory_parts
UNION ALL
SELECT 'inventory_sets', COUNT(*) FROM inventory_sets;

-- Count missing values in key columns of all tables
SELECT 'sets' AS table_name, 
       COUNT(*) AS total_rows,
       COUNT(set_num) AS filled_col_1,
       COUNT(name) AS filled_col_2,
       COUNT(theme_id) AS filled_col_3,
       COUNT(year) AS filled_col_4,
       COUNT(num_parts) AS filled_col_5
FROM sets

UNION ALL

SELECT 'themes', 
       COUNT(*),
       COUNT(id),
       COUNT(name),
       NULL,
       NULL,
       NULL
FROM themes

UNION ALL

SELECT 'parts', 
       COUNT(*),
       COUNT(part_num),
       COUNT(name),
       COUNT(part_cat_id),
       NULL,
       NULL
FROM parts

UNION ALL

SELECT 'part_categories', 
       COUNT(*),
       COUNT(id),
       COUNT(name),
       NULL,
       NULL,
       NULL
FROM part_categories

UNION ALL

SELECT 'colors', 
       COUNT(*),
       COUNT(id),
       COUNT(name),
       NULL,
       NULL,
       NULL
FROM colors

UNION ALL

SELECT 'inventories', 
       COUNT(*),
       COUNT(id),
       COUNT(set_num),
       NULL,
       NULL,
       NULL
FROM inventories

UNION ALL

SELECT 'inventory_parts', 
       COUNT(*),
       COUNT(inventory_id),
       COUNT(part_num),
       COUNT(color_id),
       COUNT(quantity),
       NULL
FROM inventory_parts

UNION ALL

SELECT 'inventory_sets', 
       COUNT(*),
       COUNT(inventory_id),
       COUNT(set_num),
       NULL,
       NULL,
       NULL
FROM inventory_sets;

-- Check for duplicate primary keys in major tables
SELECT 'sets' AS table_name, set_num::TEXT AS duplicate_value, COUNT(*) AS count
FROM sets 
GROUP BY set_num 
HAVING COUNT(*) > 1

UNION ALL

SELECT 'themes', id::TEXT, COUNT(*) 
FROM themes 
GROUP BY id 
HAVING COUNT(*) > 1

UNION ALL

SELECT 'parts', part_num::TEXT, COUNT(*) 
FROM parts 
GROUP BY part_num 
HAVING COUNT(*) > 1

UNION ALL

SELECT 'inventories', id::TEXT, COUNT(*) 
FROM inventories 
GROUP BY id 
HAVING COUNT(*) > 1;

-- Find the most popular LEGO themes by number of sets
SELECT t.name AS theme_name, COUNT(s.set_num) AS total_sets
FROM sets s
JOIN themes t ON s.theme_id = t.id
GROUP BY t.name
ORDER BY total_sets DESC
LIMIT 10;

-- Find the LEGO sets with the highest number of parts
SELECT set_num, name, num_parts, year
FROM sets
ORDER BY num_parts DESC
LIMIT 10;

-- Count the number of LEGO sets released per year
SELECT year, COUNT(*) AS total_sets
FROM sets
GROUP BY year
ORDER BY year;

-- Find the top 10 themes with the highest average number of parts per set
SELECT t.name AS theme_name, 
       ROUND(AVG(s.num_parts), 2) AS avg_num_parts,
       COUNT(s.set_num) AS total_sets
FROM sets s
JOIN themes t ON s.theme_id = t.id
GROUP BY t.name
HAVING COUNT(s.set_num) > 5  -- Ensure themes have more than 5 sets for accuracy
ORDER BY avg_num_parts DESC
LIMIT 10;

-- Calculate the average number of parts per set by year
SELECT year, 
       ROUND(AVG(num_parts), 2) AS avg_num_parts
FROM sets
WHERE year >= 1950  -- Focus on modern LEGO sets
GROUP BY year
ORDER BY year;

-- Find the most common LEGO colors based on part count
SELECT c.name AS color_name, 
       COUNT(ip.part_num) AS total_parts
FROM inventory_parts ip
JOIN colors c ON ip.color_id = c.id
GROUP BY c.name
ORDER BY total_parts DESC
LIMIT 10;

-- Find the top 10 most used LEGO parts
SELECT p.part_num, p.name AS part_name, COUNT(ip.inventory_id) AS usage_count
FROM inventory_parts ip
JOIN parts p ON ip.part_num = p.part_num
GROUP BY p.part_num, p.name
ORDER BY usage_count DESC
LIMIT 10;

-- Find the top LEGO themes by number of sets released per year
WITH theme_trends AS (
    SELECT t.name AS theme_name, 
           s.year, 
           COUNT(s.set_num) AS total_sets,
           RANK() OVER (PARTITION BY s.year ORDER BY COUNT(s.set_num) DESC) AS rank
    FROM sets s
    JOIN themes t ON s.theme_id = t.id
    GROUP BY t.name, s.year
)
SELECT * 
FROM theme_trends
WHERE rank <= 5  -- Show only the top 5 themes per year
ORDER BY year DESC, rank;

-- Calculate moving average for number of sets released per year
WITH yearly_counts AS (
    SELECT year, COUNT(*) AS total_sets
    FROM sets
    WHERE year >= 1950  -- Focus on modern LEGO sets
    GROUP BY year
)
SELECT year, 
       total_sets,
       ROUND(AVG(total_sets) OVER (ORDER BY year ROWS BETWEEN 4 PRECEDING AND CURRENT ROW), 2) AS moving_avg_5yr
FROM yearly_counts;

-- Count the number of unique parts used by each LEGO theme
WITH theme_part_count AS (
    SELECT t.name AS theme_name, 
           COUNT(DISTINCT ip.part_num) AS unique_parts
    FROM inventory_parts ip
    JOIN inventories i ON ip.inventory_id = i.id
    JOIN sets s ON i.set_num = s.set_num
    JOIN themes t ON s.theme_id = t.id
    GROUP BY t.name
)
SELECT * 
FROM theme_part_count
ORDER BY unique_parts DESC
LIMIT 10;

--Identify themes that have the most unique new sets introduced each year (compared to previous years).
WITH theme_yearly_sets AS (
    -- Count the number of sets released per theme per year
    SELECT s.theme_id, t.name AS theme_name, s.year, COUNT(s.set_num) AS total_sets
    FROM sets s
    JOIN themes t ON s.theme_id = t.id
    GROUP BY s.theme_id, t.name, s.year
),
theme_growth AS (
    -- Calculate year-over-year growth using a window function
    SELECT theme_name, year, total_sets,
           LAG(total_sets) OVER (PARTITION BY theme_name ORDER BY year) AS prev_year_sets,
           total_sets - COALESCE(LAG(total_sets) OVER (PARTITION BY theme_name ORDER BY year), 0) AS growth
    FROM theme_yearly_sets
)
SELECT theme_name, year, total_sets, prev_year_sets, growth
FROM theme_growth
WHERE growth > 0  -- Only show years where the theme actually grew
ORDER BY growth DESC, year DESC
LIMIT 10;

--Predict future LEGO set releases using exponential weighted moving averages (EWMA).
WITH yearly_data AS (
    -- Get the number of sets released per year
    SELECT year, COUNT(*) AS total_sets
    FROM sets
    WHERE year >= 1950
    GROUP BY year
)
SELECT year, total_sets,
       ROUND(AVG(total_sets) OVER (ORDER BY year ROWS BETWEEN 9 PRECEDING AND CURRENT ROW), 2) AS moving_avg_10yr,
       ROUND(0.7 * total_sets + 0.3 * COALESCE(LAG(total_sets) OVER (ORDER BY year), total_sets), 2) AS ewma
FROM yearly_data;