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

INSERT INTO @extschema@.metric_matviews (
    view_name
    , run_interval
    , scope )
VALUES (
   'pgm_stat_user_tables_matview'
    , '5 minutes'::interval
    , 'database')
ON CONFLICT DO NOTHING;


