CREATE FUNCTION @extschema@.pgm_stat_io_bgwriter_func() RETURNS TABLE
(
    writes bigint
    , fsyncs bigint
)
    LANGUAGE plpgsql
AS $function$
DECLARE
BEGIN

IF current_setting('server_version_num')::int >= 170000 THEN

    RETURN QUERY
    SELECT
        s.writes
        , s.fsyncs
    FROM pg_catalog.pg_stat_io s
    WHERE backend_type = 'background writer';

ELSE
    RETURN QUERY
    SELECT
        s.buffers_backend AS writes
        , s.buffers_backend_fsync AS fsyncs
    FROM pg_catalog.pg_stat_bgwriter s;

END IF;

END
$function$;
