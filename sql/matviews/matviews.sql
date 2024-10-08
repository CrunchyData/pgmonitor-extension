-- TODO Create sub-extension to add support for nodemx queries (require pgmonitor extension)

CREATE MATERIALIZED VIEW @extschema@.ccp_stat_user_tables AS
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
    FROM  @extschema@.ccp_stat_user_tables_func();
CREATE UNIQUE INDEX ccp_user_tables_db_schema_relname_idx ON @extschema@.ccp_stat_user_tables (dbname, schemaname, relname);
INSERT INTO @extschema@.metric_views (
    view_name
    , run_interval
    , scope )
VALUES (
   'ccp_stat_user_tables'
    , '5 minutes'::interval
    , 'database');


CREATE MATERIALIZED VIEW @extschema@.ccp_table_size AS
    SELECT current_database() as dbname
    , n.nspname as schemaname
    , c.relname
    , pg_total_relation_size(c.oid) as size_bytes
    FROM pg_catalog.pg_class c
    JOIN pg_catalog.pg_namespace n ON c.relnamespace = n.oid
    WHERE NOT pg_is_other_temp_schema(n.oid)
    AND relkind IN ('r', 'm', 'f');
CREATE UNIQUE INDEX ccp_table_size_idx ON @extschema@.ccp_table_size (dbname, schemaname, relname);
INSERT INTO @extschema@.metric_views (
    view_name
    , run_interval
    , scope )
VALUES (
   'ccp_table_size'
    , '5 minutes'::interval
    , 'database');


CREATE MATERIALIZED VIEW @extschema@.ccp_database_size AS
    SELECT datname as dbname
    , pg_database_size(datname) as bytes
    FROM pg_catalog.pg_database
    WHERE datistemplate = false;
CREATE UNIQUE INDEX ccp_database_size_idx ON @extschema@.ccp_database_size (dbname);
INSERT INTO @extschema@.metric_views (
    view_name
    , run_interval
    , scope )
VALUES (
   'ccp_database_size'
    , '5 minutes'::interval
    , 'global');


CREATE MATERIALIZED VIEW @extschema@.ccp_stat_database AS
    SELECT s.datname AS dbname
    , s.xact_commit
    , s.xact_rollback
    , s.blks_read
    , s.blks_hit
    , s.tup_returned
    , s.tup_fetched
    , s.tup_inserted
    , s.tup_updated
    , s.tup_deleted
    , s.conflicts
    , s.temp_files
    , s.temp_bytes
    , s.deadlocks
    FROM pg_catalog.pg_stat_database s
    JOIN pg_catalog.pg_database d ON d.datname = s.datname
    WHERE d.datistemplate = false;
CREATE UNIQUE INDEX ccp_stat_database_idx ON @extschema@.ccp_stat_database (dbname);
INSERT INTO @extschema@.metric_views (
    view_name
    , run_interval
    , scope )
VALUES (
   'ccp_stat_database'
    , '5 minutes'::interval
    , 'global');


CREATE MATERIALIZED VIEW @extschema@.ccp_sequence_exhaustion AS
    SELECT count FROM @extschema@.sequence_exhaustion(75);
CREATE UNIQUE INDEX ccp_sequence_exhaustion_idx ON @extschema@.ccp_sequence_exhaustion (count);
INSERT INTO @extschema@.metric_views (
    view_name
    , run_interval
    , scope )
VALUES (
   'ccp_sequence_exhaustion'
    , '5 minutes'::interval
    , 'database');


CREATE MATERIALIZED VIEW @extschema@.ccp_pg_settings_checksum AS
    SELECT @extschema@.pg_settings_checksum() AS status;
CREATE UNIQUE INDEX ccp_pg_settings_checksum_idx ON @extschema@.ccp_pg_settings_checksum (status);
INSERT INTO @extschema@.metric_views (
    view_name
    , run_interval
    , scope )
VALUES (
   'ccp_pg_settings_checksum'
    , '5 minutes'::interval
    , 'global');


CREATE MATERIALIZED VIEW @extschema@.ccp_pg_hba_checksum AS
    SELECT @extschema@.pg_hba_checksum() AS status;
CREATE UNIQUE INDEX ccp_pg_hba_checksum_idx ON @extschema@.ccp_pg_hba_checksum (status);
INSERT INTO @extschema@.metric_views (
    view_name
    , run_interval
    , scope )
VALUES (
   'ccp_pg_hba_checksum'
    , '5 minutes'::interval
    , 'global');
