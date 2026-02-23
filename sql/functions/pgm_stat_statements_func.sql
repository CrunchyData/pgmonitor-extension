CREATE FUNCTION @extschema@.pgm_stat_statements_func() RETURNS TABLE
(
 "role" name 
 , datname name
 , toplevel boolean
 , queryid bigint
 , query text
 , plans bigint
 , total_plan_time double precision
 , min_plan_time double precision
 , max_plan_time double precision
 , mean_plan_time double precision
 , stddev_plan_time double precision
 , calls bigint
 , total_exec_time double precision
 , min_exec_time double precision
 , max_exec_time double precision
 , mean_exec_time double precision
 , stddev_exec_time double precision
 , rows bigint
 , shared_blks_hit bigint
 , shared_blks_read bigint
 , shared_blks_dirtied bigint
 , shared_blks_written bigint
 , local_blks_hit bigint
 , local_blks_read bigint
 , local_blks_dirtied bigint
 , local_blks_written bigint
 , temp_blks_read bigint
 , temp_blks_written bigint
 , shared_blk_read_time double precision
 , shared_blk_write_time double precision
 , local_blk_read_time double precision
 , local_blk_write_time double precision
 , temp_blk_read_time double precision
 , temp_blk_write_time double precision
 , wal_records bigint
 , wal_fpi bigint
 , wal_bytes numeric
 , wal_buffers_full bigint
 , jit_functions bigint
 , jit_generation_time double precision
 , jit_inlining_count bigint
 , jit_inlining_time double precision
 , jit_optimization_count bigint
 , jit_optimization_time double precision
 , jit_emission_count bigint
 , jit_emission_time double precision
 , jit_deform_count bigint
 , jit_deform_time double precision
 , parallel_workers_to_launch bigint
 , parallel_workers_launched bigint
 , stats_since timestamp with time zone
 , minmax_stats_since timestamp with time zone
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
 */

SELECT nspname INTO v_stat_schema FROM pg_catalog.pg_namespace n, pg_catalog.pg_extension e WHERE e.extname = 'pg_stat_statements'::name AND e.extnamespace = n.oid;
IF v_stat_schema IS NOT NULL THEN
    SELECT current_setting('search_path') INTO v_old_search_path;
    v_new_search_path := format('%s,%s',v_stat_schema, v_old_search_path);
    EXECUTE format('SET LOCAL search_path TO %s', v_new_search_path);
ELSE
    RAISE EXCEPTION 'Unable to find pg_stat_statements extension installed on this database';
END IF;

IF current_setting('server_version_num')::int >= 180000 THEN

    RETURN QUERY SELECT
        pg_get_userbyid(s.userid) AS "role"
        , d.datname
        , s.toplevel
        , s.queryid
        , s.query
        , s.plans
        , s.total_plan_time
        , s.min_plan_time
        , s.max_plan_time
        , s.mean_plan_time
        , s.stddev_plan_time
        , s.calls
        , s.total_exec_time
        , s.min_exec_time
        , s.max_exec_time
        , s.mean_exec_time
        , s.stddev_exec_time
        , s.rows
        , s.shared_blks_hit
        , s.shared_blks_read
        , s.shared_blks_dirtied
        , s.shared_blks_written
        , s.local_blks_hit
        , s.local_blks_read
        , s.local_blks_dirtied
        , s.local_blks_written
        , s.temp_blks_read
        , s.temp_blks_written
        , s.shared_blk_read_time
        , s.shared_blk_write_time
        , s.local_blk_read_time
        , s.local_blk_write_time
        , s.temp_blk_read_time
        , s.temp_blk_write_time
        , s.wal_records
        , s.wal_fpi
        , s.wal_bytes
        , s.wal_buffers_full
        , s.jit_functions
        , s.jit_generation_time
        , s.jit_inlining_count
        , s.jit_inlining_time
        , s.jit_optimization_count
        , s.jit_optimization_time
        , s.jit_emission_count
        , s.jit_emission_time
        , s.jit_deform_count
        , s.jit_deform_time
        , s.parallel_workers_to_launch
        , s.parallel_workers_launched
        , s.stats_since
        , s.minmax_stats_since
    FROM pg_stat_statements s
    JOIN pg_catalog.pg_database d ON d.oid = s.dbid;

ELSIF current_setting('server_version_num')::int < 180000 AND current_setting('server_version_num')::int >= 170000 THEN

    RETURN QUERY SELECT
        pg_get_userbyid(s.userid) AS "role"
        , d.datname
        , s.toplevel
        , s.queryid
        , s.query
        , s.plans
        , s.total_plan_time
        , s.min_plan_time
        , s.max_plan_time
        , s.mean_plan_time
        , s.stddev_plan_time
        , s.calls
        , s.total_exec_time
        , s.min_exec_time
        , s.max_exec_time
        , s.mean_exec_time
        , s.stddev_exec_time
        , s.rows
        , s.shared_blks_hit
        , s.shared_blks_read
        , s.shared_blks_dirtied
        , s.shared_blks_written
        , s.local_blks_hit
        , s.local_blks_read
        , s.local_blks_dirtied
        , s.local_blks_written
        , s.temp_blks_read
        , s.temp_blks_written
        , s.shared_blk_read_time
        , s.shared_blk_write_time
        , s.local_blk_read_time
        , s.local_blk_write_time
        , s.temp_blk_read_time
        , s.temp_blk_write_time
        , s.wal_records
        , s.wal_fpi
        , s.wal_bytes
        , 0::bigint AS wal_buffers_full -- 18+ only
        , s.jit_functions
        , s.jit_generation_time
        , s.jit_inlining_count
        , s.jit_inlining_time
        , s.jit_optimization_count
        , s.jit_optimization_time
        , s.jit_emission_count
        , s.jit_emission_time
        , s.jit_deform_count
        , s.jit_deform_time
        , 0::bigint AS parallel_workers_to_launch -- 18+ only
        , 0::bigint AS parallel_workers_launched  -- 18+ only
        , s.stats_since
        , s.minmax_stats_since
    FROM pg_stat_statements s
    JOIN pg_catalog.pg_database d ON d.oid = s.dbid;

ELSIF current_setting('server_version_num')::int < 170000 AND current_setting('server_version_num')::int >= 150000 THEN

    RETURN QUERY SELECT
        pg_get_userbyid(s.userid) AS "role"
        , d.datname
        , s.toplevel
        , s.queryid
        , s.query
        , s.plans
        , s.total_plan_time
        , s.min_plan_time
        , s.max_plan_time
        , s.mean_plan_time
        , s.stddev_plan_time
        , s.calls
        , s.total_exec_time
        , s.min_exec_time
        , s.max_exec_time
        , s.mean_exec_time
        , s.stddev_exec_time
        , s.rows
        , s.shared_blks_hit
        , s.shared_blks_read
        , s.shared_blks_dirtied
        , s.shared_blks_written
        , s.local_blks_hit
        , s.local_blks_read
        , s.local_blks_dirtied
        , s.local_blks_written
        , s.temp_blks_read
        , s.temp_blks_written
        , s.blk_read_time AS shared_blk_read_time -- 17+ only
        , s.blk_write_time AS shared_blk_write_time -- 17+ only
        , s.blk_read_time AS local_blk_read_time -- 17+ only
        , s.blk_write_time AS local_blk_write_time -- 17+ only
        , s.temp_blk_read_time
        , s.temp_blk_write_time
        , s.wal_records
        , s.wal_fpi
        , s.wal_bytes
        , 0::bigint AS wal_buffers_full -- 18+ only
        , s.jit_functions
        , s.jit_generation_time
        , s.jit_inlining_count
        , s.jit_inlining_time
        , s.jit_optimization_count
        , s.jit_optimization_time
        , s.jit_emission_count
        , s.jit_emission_time
        , 0::bigint AS jit_deform_count -- 17+ only
        , 0::double precision AS jit_deform_time -- 17+ only
        , 0::bigint AS parallel_workers_to_launch -- 18+ only
        , 0::bigint AS parallel_workers_launched  -- 18+ only
        , '1970-01-01 00:00:00'::timestamptz AS stats_since -- 17+ only
        , '1970-01-01 00:00:00'::timestamptz AS minmax_stats_since -- 17+ only
    FROM pg_stat_statements s
    JOIN pg_catalog.pg_database d ON d.oid = s.dbid;

ELSIF current_setting('server_version_num')::int < 150000 AND current_setting('server_version_num')::int >= 140000 THEN

    RETURN QUERY SELECT
        pg_get_userbyid(s.userid) AS "role"
        , d.datname
        , s.toplevel
        , s.queryid
        , s.query
        , s.plans
        , s.total_plan_time
        , s.min_plan_time
        , s.max_plan_time
        , s.mean_plan_time
        , s.stddev_plan_time
        , s.calls
        , s.total_exec_time
        , s.min_exec_time
        , s.max_exec_time
        , s.mean_exec_time
        , s.stddev_exec_time
        , s.rows
        , s.shared_blks_hit
        , s.shared_blks_read
        , s.shared_blks_dirtied
        , s.shared_blks_written
        , s.local_blks_hit
        , s.local_blks_read
        , s.local_blks_dirtied
        , s.local_blks_written
        , s.temp_blks_read
        , s.temp_blks_written
        , s.blk_read_time AS shared_blk_read_time -- 17+ only
        , s.blk_write_time AS shared_blk_write_time -- 17+ only
        , s.blk_read_time AS local_blk_read_time -- 17+ only
        , s.blk_write_time AS local_blk_write_time -- 17+ only
        , 0::double precision AS temp_blk_read_time -- 15+ only
        , 0::double precision AS temp_blk_write_time -- 15+ only
        , s.wal_records
        , s.wal_fpi
        , s.wal_bytes
        , 0::bigint AS wal_buffers_full -- 18+ only
        , 0::bigint AS jit_functions -- 15+ only
        , 0::double precision AS jit_generation_time -- 15+ only
        , 0::bigint AS jit_inlining_count -- 15+ only
        , 0::double precision AS jit_inlining_time -- 15+ only
        , 0::bigint AS jit_optimization_count -- 15+ only
        , 0::double precision AS jit_optimization_time -- 15+ only
        , 0::bigint AS jit_emission_count -- 15+ only
        , 0::double precision AS jit_emission_time -- 15+ only
        , 0::bigint AS jit_deform_count -- 17+ only
        , 0::double precision AS jit_deform_time -- 17+ only
        , 0::bigint AS parallel_workers_to_launch -- 18+ only
        , 0::bigint AS parallel_workers_launched  -- 18+ only
        , '1970-01-01 00:00:00'::timestamptz AS stats_since -- 17+ only
        , '1970-01-01 00:00:00'::timestamptz AS minmax_stats_since -- 17+ only
    FROM pg_stat_statements s
    JOIN pg_catalog.pg_database d ON d.oid = s.dbid;

ELSE

    RAISE EXCEPTION 'PostgreSQL versions older than 14 are not supported with this function/view';

END IF;

END
$function$;

