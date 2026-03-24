CREATE VIEW @extschema@.pgm_table_size AS
    SELECT dbname
    , schemaname
    , relname
    , bytes
    FROM @extschema@.pgm_table_size_view_choice();

INSERT INTO @extschema@.metric_views (
    view_name
    , matview_source)
VALUES (
    'pgm_table_size'
    , true)
ON CONFLICT DO NOTHING;

