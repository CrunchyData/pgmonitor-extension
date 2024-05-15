-- TODO preserve privileges

CREATE FUNCTION @extschema@.ccp_stat_user_tables_func() RETURNS TABLE
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
        , 0 AS n_tup_newpage_upd
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


DROP MATERIALIZED VIEW @extschema@.ccp_stat_user_tables;

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
