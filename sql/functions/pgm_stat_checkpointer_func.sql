CREATE FUNCTION @extschema@.pgm_stat_checkpointer_func() RETURNS TABLE
(
    num_timed bigint
    , num_requested bigint
    , write_time double precision
    , sync_time double precision
    , buffers_written bigint
)
    LANGUAGE plpgsql
AS $function$
DECLARE
BEGIN

IF current_setting('server_version_num')::int >= 170000 THEN

    RETURN QUERY
    SELECT
        c.num_timed
        , c.num_requested
        , c.write_time
        , c.sync_time
        , c.buffers_written
    FROM pg_catalog.pg_stat_checkpointer c;

ELSE
    RETURN QUERY
    SELECT
        c.checkpoints_timed AS num_timed
        , c.checkpoints_req AS num_requested
        , c.checkpoint_write_time AS write_time
        , c.checkpoint_sync_time AS sync_time
        , c.buffers_checkpoint AS buffers_written
    FROM pg_catalog.pg_stat_bgwriter c;

END IF;

END
$function$;
