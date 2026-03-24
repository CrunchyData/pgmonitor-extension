CREATE VIEW @extschema@.pgm_database_size AS
    SELECT dbname
    , bytes
    FROM @extschema@.pgm_database_size_view_choice();

INSERT INTO @extschema@.metric_views (
    view_name
    , matview_source)
VALUES (
    'pgm_database_size'
    , true)
ON CONFLICT DO NOTHING;
