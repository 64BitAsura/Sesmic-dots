-- Sample queries for seismic events database

-- 1. Get all recent events (last 24 hours)
SELECT 
    event_id,
    magnitude,
    magnitude_type,
    depth,
    latitude,
    longitude,
    time,
    flynn_region,
    auth
FROM seismic_events
WHERE time >= NOW() - INTERVAL '24 hours'
ORDER BY time DESC;

-- 2. Get significant events (magnitude >= 5.0)
SELECT * FROM recent_significant_events;

-- 3. Count events by region
SELECT 
    flynn_region,
    COUNT(*) as event_count,
    AVG(magnitude) as avg_magnitude,
    MAX(magnitude) as max_magnitude
FROM seismic_events
WHERE flynn_region IS NOT NULL
GROUP BY flynn_region
ORDER BY event_count DESC
LIMIT 20;

-- 4. Events by magnitude range
SELECT 
    CASE
        WHEN magnitude < 3.0 THEN 'Minor (< 3.0)'
        WHEN magnitude >= 3.0 AND magnitude < 5.0 THEN 'Light (3.0-4.9)'
        WHEN magnitude >= 5.0 AND magnitude < 6.0 THEN 'Moderate (5.0-5.9)'
        WHEN magnitude >= 6.0 AND magnitude < 7.0 THEN 'Strong (6.0-6.9)'
        WHEN magnitude >= 7.0 AND magnitude < 8.0 THEN 'Major (7.0-7.9)'
        ELSE 'Great (>= 8.0)'
    END as magnitude_category,
    COUNT(*) as count
FROM seismic_events
WHERE magnitude IS NOT NULL
GROUP BY magnitude_category
ORDER BY MIN(magnitude);

-- 5. Recent events in a specific region
SELECT 
    event_id,
    magnitude,
    depth,
    time,
    flynn_region
FROM seismic_events
WHERE flynn_region ILIKE '%mediterranean%'
ORDER BY time DESC
LIMIT 20;

-- 6. Deep earthquakes (depth > 100km)
SELECT 
    event_id,
    magnitude,
    depth,
    latitude,
    longitude,
    flynn_region,
    time
FROM seismic_events
WHERE depth > 100
ORDER BY depth DESC;

-- 7. Events within a geographic bounding box
-- Example: Mediterranean region
SELECT 
    event_id,
    magnitude,
    latitude,
    longitude,
    flynn_region,
    time
FROM seismic_events
WHERE latitude BETWEEN 30 AND 45
  AND longitude BETWEEN -10 AND 40
ORDER BY time DESC;

-- 8. Get event statistics by day
SELECT 
    DATE(time) as event_date,
    COUNT(*) as event_count,
    AVG(magnitude) as avg_magnitude,
    MAX(magnitude) as max_magnitude,
    MIN(magnitude) as min_magnitude
FROM seismic_events
WHERE time >= NOW() - INTERVAL '30 days'
GROUP BY DATE(time)
ORDER BY event_date DESC;

-- 9. Search raw JSON data for specific properties
SELECT 
    event_id,
    magnitude,
    time,
    raw_data->'properties'->>'auth' as authority
FROM seismic_events
WHERE raw_data @> '{"properties": {"auth": "EMSC"}}'
ORDER BY time DESC
LIMIT 10;

-- 10. Get most active regions in the last week
SELECT 
    flynn_region,
    COUNT(*) as event_count,
    AVG(magnitude) as avg_magnitude,
    MAX(magnitude) as max_magnitude,
    MIN(time) as first_event,
    MAX(time) as last_event
FROM seismic_events
WHERE time >= NOW() - INTERVAL '7 days'
  AND flynn_region IS NOT NULL
GROUP BY flynn_region
ORDER BY event_count DESC
LIMIT 10;
