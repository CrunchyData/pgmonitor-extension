CREATE FUNCTION @extschema@.pgm_table_size_view_choice() RETURNS TABLE
(
    dbname name
    , schemaname name
    , relname name
    , bytes bigint
)
    LANGUAGE plpgsql
AS $function$
DECLARE

v_matview   boolean;

BEGIN

SELECT matview_source 
INTO v_matview
FROM @extschema@.metric_views
WHERE view_name = 'pgm_table_size';

IF v_matview THEN

    RETURN QUERY SELECT m.dbname
    , m.schemaname
    , m.relname
    , m.bytes
    FROM @extschema@.pgm_table_size_matview m;

ELSE

    RETURN QUERY SELECT current_database() as dbname
    , n.nspname as schemaname
    , c.relname
    , pg_catalog.pg_total_relation_size(c.oid) as bytes
    FROM pg_catalog.pg_class c
    JOIN pg_catalog.pg_namespace n ON c.relnamespace = n.oid
    WHERE NOT pg_is_other_temp_schema(n.oid)
    AND relkind IN ('r', 'm', 'f');

END IF;

END
$function$;


