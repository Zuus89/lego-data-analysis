--query that returns the users table with the specified format, including identifying and cleaning all invalid values.
SELECT 
	user_id, 
	COALESCE(age, (SELECT AVG(age) FROM users WHERE age IS NOT NULL)) AS age, 
	COALESCE(registration_date, '2024-01-01 00:00:00.000') AS registration_date, 
	COALESCE(email, 'Unknown') AS email, 
	COALESCE(NULLIF(TRIM(LOWER(workout_frequency)), ''), 'flexible') AS workout_frequency
FROM users;

--query so that the events table has a game_id for all events including those before 2021.
WITH running_game AS (
    -- Obtener el game_id de los juegos tipo 'running'
    SELECT game_id
    FROM games
    WHERE game_type = 'running'
)

SELECT 
    event_id,
    COALESCE(game_id, (SELECT game_id FROM running_game)) AS game_id,  -- Si game_id es NULL, reemplazar con running_game
    device_id,
    user_id,
    event_time
FROM events;

--SQL query to provide the user_id and event_time for users who have participated in events related to biking games.
SELECT 
    e.user_id, 
    e.event_time
FROM events e
JOIN games g 
    ON e.game_id = g.game_id
WHERE g.game_type = 'biking';

--query that returns the count of unique users for each game type game_type and game_id
SELECT 
    g.game_type, 
    e.game_id, 
    COUNT(DISTINCT e.user_id) AS user_count
FROM events e
JOIN games g 
    ON e.game_id = g.game_id
WHERE g.game_type IS NOT NULL
GROUP BY g.game_type, e.game_id
ORDER BY g.game_type, e.game_id;