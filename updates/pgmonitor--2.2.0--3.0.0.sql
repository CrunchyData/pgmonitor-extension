/**** FUNCTION CHANGES ****/

ALTER FUNCTION @extschema@.ccp_database_size_view_choice() RENAME TO pgm_database_size_view_choice;
ALTER FUNCTION @extschema@.ccp_replication_slots_func() RENAME TO pgm_replication_slots_func;
ALTER FUNCTION @extschema@.ccp_stat_checkpointer_func() RENAME TO pgm_stat_checkpointer_func;
ALTER FUNCTION @extschema@.ccp_stat_io_bgwriter_func() RENAME TO pgm_stat_io_bgwriter_func;
ALTER FUNCTION @extschema@.ccp_stat_user_tables_func() RENAME TO pgm_stat_user_tables_func;
ALTER FUNCTION @extschema@.ccp_stat_user_tables_view_choice() RENAME TO pgm_stat_user_tables_view_choice;
ALTER FUNCTION @extschema@.ccp_table_size_view_choice() RENAME TO pgm_table_size_view_choice;

CREATE OR REPLACE FUNCTION @extschema@.pgm_database_size_view_choice() RETURNS TABLE
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


CREATE OR REPLACE FUNCTION @extschema@.pgm_stat_user_tables_view_choice() RETURNS TABLE
(
    dbname name
    , schemaname name
    , relname name
    , seq_scan bigint
    , seq_tup_read bigint
    , idx_scan bigint
    , idx_tup_fetch bigint
    , n_tup_ins bigint
    , n_tup_upd bigint
    , n_tup_del bigint
    , n_tup_hot_upd bigint
    , n_tup_newpage_upd bigint
    , n_live_tup bigint
    , n_dead_tup bigint
    , vacuum_count bigint
    , autovacuum_count bigint
    , analyze_count bigint
    , autoanalyze_count bigint
)
    LANGUAGE plpgsql
AS $function$
DECLARE

v_matview   boolean;

BEGIN

SELECT matview_source 
INTO v_matview
FROM @extschema@.metric_views
WHERE view_name = 'pgm_stat_user_tables';

IF v_matview THEN

    RETURN QUERY SELECT
        s.dbname
        , s.schemaname
        , s.relname
        , s.seq_scan
        , s.seq_tup_read
        , s.idx_scan
        , s.idx_tup_fetch
        , s.n_tup_ins
        , s.n_tup_upd
        , s.n_tup_del
        , s.n_tup_hot_upd
        , s.n_tup_newpage_upd
        , s.n_live_tup
        , s.n_dead_tup
        , s.vacuum_count
        , s.autovacuum_count
        , s.analyze_count
        , s.autoanalyze_count
    FROM @extschema@.pgm_stat_user_tables_matview s;

ELSE

    RETURN QUERY SELECT
        current_database() as dbname
        , s.schemaname
        , s.relname
        , s.seq_scan
        , s.seq_tup_read
        , s.idx_scan
        , s.idx_tup_fetch
        , s.n_tup_ins
        , s.n_tup_upd
        , s.n_tup_del
        , s.n_tup_hot_upd
        , s.n_tup_newpage_upd
        , s.n_live_tup
        , s.n_dead_tup
        , s.vacuum_count
        , s.autovacuum_count
        , s.analyze_count
        , s.autoanalyze_count
    FROM @extschema@.pgm_stat_user_tables_func() s;

END IF; 

END
$function$;


CREATE OR REPLACE FUNCTION @extschema@.pgm_table_size_view_choice() RETURNS TABLE
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


CREATE OR REPLACE FUNCTION @extschema@.pg_stat_statements_reset_info()
  RETURNS bigint
  LANGUAGE plpgsql
  SECURITY DEFINER
  SET search_path TO pg_catalog, pg_temp
AS $function$
DECLARE

  v_reset_timestamp      timestamptz;
  v_reset_interval       interval;
  v_sql                  text;
  v_stat_schema          name;

BEGIN
-- ******** NOTE ********
-- This function must be owned by a superuser to work

-- Function to reset pg_stat_statements periodically
-- The run_interval stored in metric_tables for "pgm_pg_stat_statements_reset" is
--   what is used to determine how often this function resets the stats

  SELECT n.nspname INTO v_stat_schema
  FROM pg_catalog.pg_extension e
  JOIN pg_catalog.pg_namespace n ON e.extnamespace = n.oid
  WHERE e.extname = 'pg_stat_statements';

  IF v_stat_schema IS NULL THEN
    RAISE EXCEPTION 'Unable to find pg_stat_statements extension installed on this database';
  END IF;

  SELECT run_interval INTO v_reset_interval
  FROM @extschema@.metric_tables
  WHERE table_schema = '@extschema@'
  AND table_name = 'pgm_pg_stat_statements_reset';

  SELECT COALESCE(pg_catalog.max(reset_time), '1970-01-01'::timestamptz) INTO v_reset_timestamp FROM @extschema@.pg_stat_statements_reset_info;

  IF ((CURRENT_TIMESTAMP - v_reset_timestamp) > v_reset_interval) THEN
      -- Ensure table is empty
      DELETE FROM @extschema@.pg_stat_statements_reset_info;
      v_sql := format('SELECT %I.pg_stat_statements_reset()', v_stat_schema);
      EXECUTE v_sql;
      INSERT INTO @extschema@.pg_stat_statements_reset_info(reset_time) values (CURRENT_TIMESTAMP);
  END IF;

  RETURN (SELECT pg_catalog.extract(epoch from reset_time) FROM @extschema@.pg_stat_statements_reset_info);

END
$function$;


-- TODO RENAME FILE
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

/**** END FUNCTION CHANGES ****/

/**** MATVIEW CHANGES ****/

ALTER MATERIALIZED VIEW @extschema@.ccp_database_size_matview RENAME TO pgm_database_size_matview;
ALTER INDEX @extschema@.ccp_database_size_matview_idx RENAME TO pgm_database_size_matview_idx;
UPDATE @extschema@.metric_matviews SET view_name = 'pgm_database_size_matview' WHERE view_name = 'ccp_database_size_matview';

ALTER MATERIALIZED VIEW @extschema@.ccp_pg_hba_checksum RENAME TO pgm_pg_hba_checksum;
ALTER INDEX @extschema@.ccp_pg_hba_checksum_idx RENAME TO pgm_pg_hba_checksum_idx;
UPDATE @extschema@.metric_matviews SET view_name = 'pgm_pg_hba_checksum' WHERE view_name = 'ccp_pg_hba_checksum';

ALTER MATERIALIZED VIEW @extschema@.ccp_sequence_exhaustion RENAME TO pgm_sequence_exhaustion;
ALTER INDEX @extschema@.ccp_sequence_exhaustion_idx RENAME TO pgm_sequence_exhaustion_idx;
UPDATE @extschema@.metric_matviews SET view_name = 'pgm_sequence_exhaustion' WHERE view_name = 'ccp_sequence_exhaustion';

DROP MATERIALIZED VIEW @extschema@.ccp_stat_user_tables_matview;
CREATE MATERIALIZED VIEW @extschema@.pgm_stat_user_tables_matview AS
    SELECT current_database() as dbname
    , schemaname
    , relname
    , seq_scan
    , seq_tup_read
    , idx_scan
    , idx_tup_fetch
    , n_tup_ins
    , n_tup_upd
    , n_tup_del
    , n_tup_hot_upd
    , n_tup_newpage_upd
    , n_live_tup
    , n_dead_tup
    , vacuum_count
    , autovacuum_count
    , analyze_count
    , autoanalyze_count
    FROM @extschema@.pgm_stat_user_tables_func();
CREATE UNIQUE INDEX pgm_user_tables_matview_idx ON @extschema@.pgm_stat_user_tables_matview (dbname, schemaname, relname);
UPDATE @extschema@.metric_matviews SET view_name = 'pgm_stat_user_tables_matview' WHERE view_name = 'ccp_stat_user_tables_matview';

ALTER MATERIALIZED VIEW @extschema@.ccp_table_size_matview RENAME TO pgm_table_size_matview;
ALTER INDEX @extschema@.ccp_table_size_matview_idx RENAME TO pgm_table_size_matview_idx;
UPDATE @extschema@.metric_matviews SET view_name = 'pgm_table_size_matview' WHERE view_name = 'ccp_table_size_matview';

/**** END MATVIEW CHANGES ****/

/**** VIEW CHANGES ****/

-- pgBackRest views
-- All backrest data is pulled from a refreshed table so no need for individual view entries in config table

ALTER VIEW @extschema@.ccp_backrest_last_diff_backup RENAME TO pgm_backrest_last_diff_backup;
ALTER VIEW @extschema@.ccp_backrest_last_full_backup RENAME TO pgm_backrest_last_full_backup;
ALTER VIEW @extschema@.ccp_backrest_last_incr_backup RENAME TO pgm_backrest_last_incr_backup;
ALTER VIEW @extschema@.ccp_backrest_last_info RENAME TO pgm_backrest_last_info;
ALTER VIEW @extschema@.ccp_backrest_oldest_full_backup RENAME TO pgm_backrest_oldest_full_backup;

ALTER VIEW @extschema@.ccp_archive_command_status RENAME TO pgm_archive_command_status;
UPDATE @extschema@.metric_views SET view_name = 'pgm_archive_command_status' WHERE view_name = 'ccp_archive_command_status';

ALTER VIEW @extschema@.ccp_connection_stats RENAME TO pgm_connection_stats;
UPDATE @extschema@.metric_views SET view_name = 'pgm_connection_stats' WHERE view_name = 'ccp_connection_stats';

ALTER VIEW @extschema@.ccp_data_checksum_failure RENAME TO pgm_data_checksum_failure;
UPDATE @extschema@.metric_views SET view_name = 'pgm_data_checksum_failure' WHERE view_name = 'ccp_data_checksum_failure';

ALTER VIEW @extschema@.ccp_database_size RENAME TO pgm_database_size;
CREATE OR REPLACE VIEW @extschema@.pgm_database_size AS
    SELECT dbname
    , bytes
    FROM @extschema@.pgm_database_size_view_choice();
UPDATE @extschema@.metric_views SET view_name = 'pgm_database_size' WHERE view_name = 'ccp_database_size';

ALTER VIEW @extschema@.ccp_locks RENAME TO pgm_locks;
UPDATE @extschema@.metric_views SET view_name = 'pgm_locks' WHERE view_name = 'ccp_locks';

ALTER VIEW @extschema@.ccp_pg_is_in_recovery RENAME TO pgm_pg_is_in_recovery;
UPDATE @extschema@.metric_views SET view_name = 'pgm_pg_is_in_recovery' WHERE view_name = 'ccp_pg_is_in_recovery';

ALTER VIEW @extschema@.ccp_pg_stat_statements_reset RENAME TO pgm_pg_stat_statements_reset;
UPDATE @extschema@.metric_tables SET table_name = 'pgm_pg_stat_statements_reset' WHERE table_name = 'ccp_pg_stat_statements_reset';

ALTER VIEW @extschema@.ccp_postgresql_version RENAME TO pgm_postgresql_version;
UPDATE @extschema@.metric_views SET view_name = 'pgm_postgresql_version' WHERE view_name = 'ccp_postgresql_version';

ALTER VIEW @extschema@.ccp_postmaster_runtime RENAME TO pgm_postmaster_runtime;
UPDATE @extschema@.metric_views SET view_name = 'pgm_postmaster_runtime' WHERE view_name = 'ccp_postmaster_runtime';

ALTER VIEW @extschema@.ccp_postmaster_uptime RENAME TO pgm_postmaster_uptime;
UPDATE @extschema@.metric_views SET view_name = 'pgm_postmaster_uptime' WHERE view_name = 'ccp_postmaster_uptime';

ALTER VIEW @extschema@.ccp_replication_lag RENAME TO pgm_replication_lag;
UPDATE @extschema@.metric_views SET view_name = 'pgm_replication_lag' WHERE view_name = 'ccp_replication_lag';

ALTER VIEW @extschema@.ccp_replication_lag_size RENAME TO pgm_replication_lag_size;
UPDATE @extschema@.metric_views SET view_name = 'pgm_replication_lag_size' WHERE view_name = 'ccp_replication_lag_size';

ALTER VIEW @extschema@.ccp_replication_slots RENAME TO pgm_replication_slots;
CREATE OR REPLACE VIEW @extschema@.pgm_replication_slots AS
    SELECT slot_name
        , active
        , retained_bytes
        , database
        , slot_type
        , conflicting
        , failover
        , synced
    FROM @extschema@.pgm_replication_slots_func();
UPDATE @extschema@.metric_views SET view_name = 'pgm_replication_slots' WHERE view_name = 'ccp_replication_slots';

ALTER VIEW @extschema@.ccp_settings_pending_restart RENAME TO pgm_settings_pending_restart;
UPDATE @extschema@.metric_views SET view_name = 'pgm_settings_pending_restart' WHERE view_name = 'ccp_settings_pending_restart';

ALTER VIEW @extschema@.ccp_stat_bgwriter RENAME TO pgm_stat_bgwriter;
UPDATE @extschema@.metric_views SET view_name = 'pgm_stat_bgwriter' WHERE view_name = 'ccp_stat_bgwriter';

ALTER VIEW @extschema@.ccp_stat_checkpointer RENAME TO pgm_stat_checkpointer;
CREATE OR REPLACE VIEW @extschema@.pgm_stat_checkpointer AS
    SELECT
        num_timed
        , num_requested
        , write_time
        , sync_time
        , buffers_written
    FROM @extschema@.pgm_stat_checkpointer_func();
UPDATE @extschema@.metric_views SET view_name = 'pgm_stat_checkpointer' WHERE view_name = 'ccp_stat_checkpointer';

ALTER VIEW @extschema@.ccp_stat_database RENAME TO pgm_stat_database;
UPDATE @extschema@.metric_views SET view_name = 'pgm_stat_database' WHERE view_name = 'ccp_stat_database';

ALTER VIEW @extschema@.ccp_stat_io_bgwriter RENAME TO pgm_stat_io_bgwriter;
CREATE VIEW @extschema@.pgm_stat_io_bgwriter AS
    SELECT
        writes
        , fsyncs
    FROM @extschema@.pgm_stat_io_bgwriter_func();
UPDATE @extschema@.metric_views SET view_name = 'pgm_stat_io_bgwriter' WHERE view_name = 'ccp_stat_io_bgwriter';

ALTER VIEW @extschema@.ccp_stat_user_tables RENAME TO pgm_stat_user_tables;
CREATE OR REPLACE VIEW @extschema@.pgm_stat_user_tables AS
    SELECT dbname
    , schemaname
    , relname
    , seq_scan
    , seq_tup_read
    , idx_scan
    , idx_tup_fetch
    , n_tup_ins
    , n_tup_upd
    , n_tup_del
    , n_tup_hot_upd
    , n_tup_newpage_upd
    , n_live_tup
    , n_dead_tup
    , vacuum_count
    , autovacuum_count
    , analyze_count
    , autoanalyze_count
    FROM @extschema@.pgm_stat_user_tables_view_choice();
UPDATE @extschema@.metric_views SET view_name = 'pgm_stat_user_tables' WHERE view_name = 'ccp_stat_user_tables';

ALTER VIEW @extschema@.ccp_table_size RENAME TO pgm_table_size;
CREATE OR REPLACE VIEW @extschema@.pgm_table_size AS
    SELECT dbname
    , schemaname
    , relname
    , bytes
    FROM @extschema@.pgm_table_size_view_choice();
UPDATE @extschema@.metric_views SET view_name = 'pgm_table_size' WHERE view_name = 'ccp_table_size';

ALTER VIEW @extschema@.ccp_transaction_wraparound RENAME TO pgm_transaction_wraparound;
UPDATE @extschema@.metric_views SET view_name = 'pgm_transaction_wraparound' WHERE view_name = 'ccp_transaction_wraparound';

ALTER VIEW @extschema@.ccp_wal_activity RENAME TO pgm_wal_activity;
UPDATE @extschema@.metric_views SET view_name = 'pgm_wal_activity' WHERE view_name = 'ccp_wal_activity';

CREATE VIEW @extschema@.pgm_stat_statements AS
    SELECT
        "role"
        , datname
        , toplevel
        , queryid
        , query
        , plans
        , total_plan_time
        , min_plan_time
        , max_plan_time
        , mean_plan_time
        , stddev_plan_time
        , calls
        , total_exec_time
        , min_exec_time
        , max_exec_time
        , mean_exec_time
        , stddev_exec_time
        , rows
        , shared_blks_hit
        , shared_blks_read
        , shared_blks_dirtied
        , shared_blks_written
        , local_blks_hit
        , local_blks_read
        , local_blks_dirtied
        , local_blks_written
        , temp_blks_read
        , temp_blks_written
        , shared_blk_read_time
        , shared_blk_write_time
        , local_blk_read_time
        , local_blk_write_time
        , temp_blk_read_time
        , temp_blk_write_time
        , wal_records
        , wal_fpi
        , wal_bytes
        , wal_buffers_full
        , jit_functions
        , jit_generation_time
        , jit_inlining_count
        , jit_inlining_time
        , jit_optimization_count
        , jit_optimization_time
        , jit_emission_count
        , jit_emission_time
        , jit_deform_count
        , jit_deform_time
        , parallel_workers_to_launch
        , parallel_workers_launched
        , stats_since
        , minmax_stats_since
    FROM @extschema@.pgm_stat_statements_func();
INSERT INTO @extschema@.metric_views (
    view_name
    , matview_source
    , scope )
VALUES (
   'pgm_stat_statements'
    , false
    , 'global')
ON CONFLICT DO NOTHING;

/**** END VIEW CHANGES ****/

/**** LEGACY VIEWS ****/

CREATE VIEW @extschema@.ccp_backrest_last_diff_backup AS SELECT * FROM @extschema@.pgm_backrest_last_diff_backup;
CREATE VIEW @extschema@.ccp_backrest_last_full_backup AS SELECT * FROM @extschema@.pgm_backrest_last_full_backup;
CREATE VIEW @extschema@.ccp_backrest_last_incr_backup AS SELECT * FROM @extschema@.pgm_backrest_last_incr_backup;
CREATE VIEW @extschema@.ccp_backrest_last_info AS SELECT * FROM @extschema@.pgm_backrest_last_info;
CREATE VIEW @extschema@.ccp_backrest_oldest_full_backup AS SELECT * FROM @extschema@.pgm_backrest_oldest_full_backup; 
CREATE VIEW @extschema@.ccp_archive_command_status AS SELECT * FROM @extschema@.pgm_archive_command_status;
CREATE VIEW @extschema@.ccp_connection_stats AS SELECT * FROM @extschema@.pgm_connection_stats;
CREATE VIEW @extschema@.ccp_data_checksum_failure AS SELECT * FROM @extschema@.pgm_data_checksum_failure; 
CREATE VIEW @extschema@.ccp_database_size AS SELECT * FROM @extschema@.pgm_database_size;
CREATE VIEW @extschema@.ccp_locks AS SELECT * FROM @extschema@.pgm_locks;
CREATE VIEW @extschema@.ccp_pg_is_in_recovery AS SELECT * FROM @extschema@.pgm_pg_is_in_recovery;
CREATE VIEW @extschema@.ccp_pg_stat_statements_reset AS SELECT * FROM @extschema@.pgm_pg_stat_statements_reset;
CREATE VIEW @extschema@.ccp_postgresql_version AS SELECT * FROM @extschema@.pgm_postgresql_version;
CREATE VIEW @extschema@.ccp_postmaster_runtime AS SELECT * FROM @extschema@.pgm_postmaster_runtime;
CREATE VIEW @extschema@.ccp_postmaster_uptime AS SELECT * FROM @extschema@.pgm_postmaster_uptime;
CREATE VIEW @extschema@.ccp_replication_lag AS SELECT * FROM @extschema@.pgm_replication_lag;
CREATE VIEW @extschema@.ccp_replication_lag_size AS SELECT * FROM @extschema@.pgm_replication_lag_size;
CREATE VIEW @extschema@.ccp_replication_slots AS SELECT * FROM @extschema@.pgm_replication_slots;
CREATE VIEW @extschema@.ccp_settings_pending_restart AS SELECT * FROM @extschema@.pgm_settings_pending_restart; 
CREATE VIEW @extschema@.ccp_stat_bgwriter AS SELECT * FROM @extschema@.pgm_stat_bgwriter;
CREATE VIEW @extschema@.ccp_stat_checkpointer AS SELECT * FROM @extschema@.pgm_stat_checkpointer;
CREATE VIEW @extschema@.ccp_stat_database AS SELECT * FROM @extschema@.pgm_stat_database;
CREATE VIEW @extschema@.ccp_stat_io_bgwriter AS SELECT * FROM @extschema@.pgm_stat_io_bgwriter;
CREATE VIEW @extschema@.ccp_stat_user_tables AS SELECT * FROM @extschema@.pgm_stat_user_tables;
CREATE VIEW @extschema@.ccp_table_size AS SELECT * FROM @extschema@.pgm_table_size;
CREATE VIEW @extschema@.ccp_transaction_wraparound AS SELECT * FROM @extschema@.pgm_transaction_wraparound;
CREATE VIEW @extschema@.ccp_wal_activity AS SELECT * FROM @extschema@.pgm_wal_activity;


COMMENT ON VIEW @extschema@.ccp_backrest_last_diff_backup IS 'This object exists for backward compatibility with applications that are expecting object names from version 2.x and older. Please update your applications to use the new object names introduced in 3.0.0';
COMMENT ON VIEW @extschema@.ccp_backrest_last_full_backup IS 'This object exists for backward compatibility with applications that are expecting object names from version 2.x and older. Please update your applications to use the new object names introduced in 3.0.0';
COMMENT ON VIEW @extschema@.ccp_backrest_last_incr_backup IS 'This object exists for backward compatibility with applications that are expecting object names from version 2.x and older. Please update your applications to use the new object names introduced in 3.0.0';
COMMENT ON VIEW @extschema@.ccp_backrest_last_info IS 'This object exists for backward compatibility with applications that are expecting object names from version 2.x and older. Please update your applications to use the new object names introduced in 3.0.0';
COMMENT ON VIEW @extschema@.ccp_backrest_oldest_full_backup IS 'This object exists for backward compatibility with applications that are expecting object names from version 2.x and older. Please update your applications to use the new object names introduced in 3.0.0';
COMMENT ON VIEW @extschema@.ccp_archive_command_status IS 'This object exists for backward compatibility with applications that are expecting object names from version 2.x and older. Please update your applications to use the new object names introduced in 3.0.0';
COMMENT ON VIEW @extschema@.ccp_connection_stats IS 'This object exists for backward compatibility with applications that are expecting object names from version 2.x and older. Please update your applications to use the new object names introduced in 3.0.0';
COMMENT ON VIEW @extschema@.ccp_data_checksum_failure IS 'This object exists for backward compatibility with applications that are expecting object names from version 2.x and older. Please update your applications to use the new object names introduced in 3.0.0';
COMMENT ON VIEW @extschema@.ccp_database_size IS 'This object exists for backward compatibility with applications that are expecting object names from version 2.x and older. Please update your applications to use the new object names introduced in 3.0.0';
COMMENT ON VIEW @extschema@.ccp_locks IS 'This object exists for backward compatibility with applications that are expecting object names from version 2.x and older. Please update your applications to use the new object names introduced in 3.0.0';
COMMENT ON VIEW @extschema@.ccp_pg_is_in_recovery IS 'This object exists for backward compatibility with applications that are expecting object names from version 2.x and older. Please update your applications to use the new object names introduced in 3.0.0';
COMMENT ON VIEW @extschema@.ccp_pg_stat_statements_reset IS 'This object exists for backward compatibility with applications that are expecting object names from version 2.x and older. Please update your applications to use the new object names introduced in 3.0.0';
COMMENT ON VIEW @extschema@.ccp_postgresql_version IS 'This object exists for backward compatibility with applications that are expecting object names from version 2.x and older. Please update your applications to use the new object names introduced in 3.0.0';
COMMENT ON VIEW @extschema@.ccp_postmaster_runtime IS 'This object exists for backward compatibility with applications that are expecting object names from version 2.x and older. Please update your applications to use the new object names introduced in 3.0.0';
COMMENT ON VIEW @extschema@.ccp_postmaster_uptime IS 'This object exists for backward compatibility with applications that are expecting object names from version 2.x and older. Please update your applications to use the new object names introduced in 3.0.0';
COMMENT ON VIEW @extschema@.ccp_replication_lag IS 'This object exists for backward compatibility with applications that are expecting object names from version 2.x and older. Please update your applications to use the new object names introduced in 3.0.0';
COMMENT ON VIEW @extschema@.ccp_replication_lag_size IS 'This object exists for backward compatibility with applications that are expecting object names from version 2.x and older. Please update your applications to use the new object names introduced in 3.0.0';
COMMENT ON VIEW @extschema@.ccp_replication_slots IS 'This object exists for backward compatibility with applications that are expecting object names from version 2.x and older. Please update your applications to use the new object names introduced in 3.0.0';
COMMENT ON VIEW @extschema@.ccp_settings_pending_restart IS 'This object exists for backward compatibility with applications that are expecting object names from version 2.x and older. Please update your applications to use the new object names introduced in 3.0.0';
COMMENT ON VIEW @extschema@.ccp_stat_bgwriter IS 'This object exists for backward compatibility with applications that are expecting object names from version 2.x and older. Please update your applications to use the new object names introduced in 3.0.0';
COMMENT ON VIEW @extschema@.ccp_stat_checkpointer IS 'This object exists for backward compatibility with applications that are expecting object names from version 2.x and older. Please update your applications to use the new object names introduced in 3.0.0';
COMMENT ON VIEW @extschema@.ccp_stat_database IS 'This object exists for backward compatibility with applications that are expecting object names from version 2.x and older. Please update your applications to use the new object names introduced in 3.0.0';
COMMENT ON VIEW @extschema@.ccp_stat_io_bgwriter IS 'This object exists for backward compatibility with applications that are expecting object names from version 2.x and older. Please update your applications to use the new object names introduced in 3.0.0';
COMMENT ON VIEW @extschema@.ccp_stat_user_tables IS 'This object exists for backward compatibility with applications that are expecting object names from version 2.x and older. Please update your applications to use the new object names introduced in 3.0.0';
COMMENT ON VIEW @extschema@.ccp_table_size IS 'This object exists for backward compatibility with applications that are expecting object names from version 2.x and older. Please update your applications to use the new object names introduced in 3.0.0';
COMMENT ON VIEW @extschema@.ccp_transaction_wraparound IS 'This object exists for backward compatibility with applications that are expecting object names from version 2.x and older. Please update your applications to use the new object names introduced in 3.0.0';
COMMENT ON VIEW @extschema@.ccp_wal_activity IS 'This object exists for backward compatibility with applications that are expecting object names from version 2.x and older. Please update your applications to use the new object names introduced in 3.0.0';

/**** END LEGACY VIEWS ****/
