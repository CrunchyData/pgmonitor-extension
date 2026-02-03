CREATE FUNCTION @extschema@.pgm_database_size_view_choice() RETURNS TABLE
(
    dbname name
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
WHERE view_name = 'pgm_database_size';

IF v_matview THEN

    RETURN QUERY SELECT m.dbname
    , m.bytes
    FROM @extschema@.pgm_database_size_matview m;

ELSE

    RETURN QUERY SELECT datname as dbname
    , pg_catalog.pg_database_size(datname) as bytes
    FROM pg_catalog.pg_database
    WHERE datistemplate = false;

END IF;

END
$function$;


