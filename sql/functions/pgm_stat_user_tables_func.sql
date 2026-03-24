CREATE FUNCTION @extschema@.pgm_stat_user_tables_func() RETURNS TABLE
(
    schemaname name
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
BEGIN

IF current_setting('server_version_num')::int >= 160000 THEN
    RETURN QUERY SELECT
        p.schemaname
        , p.relname
        , p.seq_scan
        , p.seq_tup_read
        , p.idx_scan
        , p.idx_tup_fetch
        , p.n_tup_ins
        , p.n_tup_upd
        , p.n_tup_del
        , p.n_tup_hot_upd
        , p.n_tup_newpage_upd
        , p.n_live_tup
        , p.n_dead_tup
        , p.vacuum_count
        , p.autovacuum_count
        , p.analyze_count
        , p.autoanalyze_count
      FROM pg_catalog.pg_stat_user_tables p;
ELSE
    RETURN QUERY SELECT
        p.schemaname
        , p.relname
        , p.seq_scan
        , p.seq_tup_read
        , p.idx_scan
        , p.idx_tup_fetch
        , p.n_tup_ins
        , p.n_tup_upd
        , p.n_tup_del
        , p.n_tup_hot_upd
        , 0::bigint AS n_tup_newpage_upd
        , p.n_live_tup
        , p.n_dead_tup
        , p.vacuum_count
        , p.autovacuum_count
        , p.analyze_count
        , p.autoanalyze_count
      FROM pg_catalog.pg_stat_user_tables p;
END IF;

END
$function$;
