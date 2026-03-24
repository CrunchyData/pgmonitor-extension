CREATE FUNCTION @extschema@.pgm_stat_user_tables_view_choice() RETURNS TABLE
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
    SET search_path = @extschema@, pg_catalog, pg_temp
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


