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
