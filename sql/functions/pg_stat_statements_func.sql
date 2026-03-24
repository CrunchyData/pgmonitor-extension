CREATE FUNCTION @extschema@.pg_stat_statements_func() RETURNS TABLE
(
    "role" name
    , dbname name
    , queryid bigint
    , query text
    , calls bigint
    , total_exec_time double precision
    , max_exec_time double precision
    , mean_exec_time double precision
    , rows bigint
    , wal_records bigint
    , wal_fpi bigint
    , wal_bytes numeric
)
    LANGUAGE plpgsql
    SET search_path = @extschema@, pg_catalog, pg_temp
AS $function$
DECLARE

v_new_search_path               text;
v_old_search_path               text;
v_stat_schema                   text;

BEGIN
/*
 * Function interface to the pg_stat_statements contrib view to allow multi-version PG support
 *  Only columns that are used by pgMonitor metrics are returned
 */

SELECT current_setting('search_path') INTO v_old_search_path;
IF length(v_old_search_path) > 0 THEN
   v_new_search_path := '@extschema@,pg_temp,'||v_old_search_path;
ELSE
    v_new_search_path := '@extschema@,pg_temp';
END IF;
SELECT nspname INTO v_stat_schema FROM pg_catalog.pg_namespace n, pg_catalog.pg_extension e WHERE e.extname = 'pg_stat_statements'::name AND e.extnamespace = n.oid;
IF v_stat_schema IS NOT NULL THEN
    v_new_search_path := format('%s,%s',v_stat_schema, v_new_search_path);
    EXECUTE format('SELECT set_config(%L, %L, %L)', 'search_path', v_new_search_path, 'false');
ELSE
    RAISE EXCEPTION 'Unable to find pg_stat_statements extension installed on this database';
END IF;

IF current_setting('server_version_num')::int >= 130000 THEN
    RETURN QUERY SELECT
        pg_get_userbyid(s.userid) AS role
        , d.datname AS dbname
        , s.queryid
        , btrim(replace(left(s.query, 40), '\n', '')) AS query
        , s.calls
        , s.total_exec_time
        , s.max_exec_time
        , s.mean_exec_time
        , s.rows
        , s.wal_records
        , s.wal_fpi
        , s.wal_bytes
      FROM pg_stat_statements s
      JOIN pg_catalog.pg_database d ON d.oid = s.dbid;
ELSE
    RETURN QUERY SELECT
        pg_get_userbyid(s.userid) AS role
        , d.datname AS dbname
        , s.queryid
        , btrim(replace(left(s.query, 40), '\n', '')) AS query
        , s.calls
        , s.total_time AS total_exec_time
        , s.max_time AS max_exec_time
        , s.mean_time AS mean_exec_time
        , s.rows
        , 0::bigint AS wal_records
        , 0::bigint AS wal_fpi
        , 0::numeric AS wal_bytes
      FROM pg_stat_statements s
      JOIN pg_catalog.pg_database d ON d.oid = s.dbid;
END IF;

IF v_stat_schema IS NOT NULL THEN
    EXECUTE format('SELECT set_config(%L, %L, %L)', 'search_path', v_old_search_path, 'false');
END IF;

END
$function$;


