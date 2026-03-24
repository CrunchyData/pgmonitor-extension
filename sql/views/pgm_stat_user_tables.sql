CREATE VIEW @extschema@.pgm_stat_user_tables AS
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

INSERT INTO @extschema@.metric_views (
    view_name
)
VALUES (
    'pgm_stat_user_tables'
)
ON CONFLICT DO NOTHING;


