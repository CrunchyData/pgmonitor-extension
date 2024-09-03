
DROP MATERIALIZED VIEW @extschema@.ccp_stat_bgwriter;
DELETE FROM @extschema@.metric_views WHERE view_name = 'ccp_stat_bgwriter');

CREATE FUNCTION @extschema@.ccp_stat_checkpointer() RETURNS TABLE
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


CREATE FUNCTION @extschema@.ccp_stat_io_bgwriter() RETURNS TABLE
(
    writes bigint
    , fsyncs bigint
)
    LANGUAGE plpgsql
AS $function$
DECLARE
BEGIN

IF current_setting('server_version_num')::int >= 170000 THEN

    RETURN QUERY
    SELECT
        s.writes
        , s.fsyncs
    FROM pg_catalog.pg_stat_io s
    WHERE backend_type = 'background writer';

ELSE
    RETURN QUERY
    SELECT
        s.buffers_backend AS writes
        , s.buffers_backend_fsync AS fsyncs
    FROM pg_catalog.pg_stat_bgwriter s;

END IF;

END
$function$;


CREATE VIEW @extschema@.ccp_stat_bgwriter AS
    SELECT
        buffers_clean
        , maxwritten_clean
        , buffers_alloc
    FROM pg_catalog.pg_stat_bgwriter;
INSERT INTO @extschema@.metric_views (
    view_name
    , materialized_view
    , scope )
VALUES (
   'ccp_stat_bgwriter'
    , false
    , 'global');


CREATE VIEW @extschema@.ccp_stat_checkpointer AS
    SELECT
        num_timed
        , num_requested
        , write_time
        , sync_time
        , buffers_written
    FROM @extschema@.ccp_stat_checkpointer();
INSERT INTO @extschema@.metric_views (
    view_name
    , materialized_view
    , scope )
VALUES (
   'ccp_stat_checkpointer'
    , false
    , 'global');

CREATE VIEW @extschema@.ccp_stat_io_bgwriter AS
    SELECT
        writes
        , fsyncs
    FROM @extschema@.ccp_stat_io_bgwriter();
INSERT INTO @extschema@.metric_views (
    view_name
    , materialized_view
    , scope )
VALUES (
   'ccp_stat_io_bgwriter'
    , false
    , 'global');
