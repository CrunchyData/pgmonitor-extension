-- Enabling this metric view will reset the pg_stat_statements statistics based on
--   the run_interval set in metric_matviews
CREATE VIEW @extschema@.pgm_pg_stat_statements_reset AS
    SELECT reset_time AS time FROM @extschema@.pg_stat_statements_reset_info;

-- Inserted into metric_tables to be able to use the interval refresh option to reset pg_stat_statements
INSERT INTO @extschema@.metric_tables (
    table_name
    , refresh_statement
    , run_interval
    , active )
VALUES (
    'pgm_pg_stat_statements_reset'
    , 'SELECT pgmonitor_ext.pg_stat_statements_reset_info()'
    , '1440 seconds'::interval
    , false )
ON CONFLICT DO NOTHING;
