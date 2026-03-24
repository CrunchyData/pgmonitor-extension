CREATE FUNCTION @extschema@.pg_stat_statements_reset_info()
  RETURNS bigint
  LANGUAGE plpgsql
  SECURITY DEFINER
  SET search_path TO pg_catalog, pg_temp
AS $function$
DECLARE

  v_reset_timestamp      timestamptz;
  v_reset_interval       interval;
  v_sql                  text;
  v_stat_schema          name;

BEGIN
-- ******** NOTE ********
-- This function must be owned by a superuser to work

-- Function to reset pg_stat_statements periodically
-- The run_interval stored in metric_tables for "pgm_pg_stat_statements_reset" is
--   what is used to determine how often this function resets the stats

  SELECT n.nspname INTO v_stat_schema
  FROM pg_catalog.pg_extension e
  JOIN pg_catalog.pg_namespace n ON e.extnamespace = n.oid
  WHERE e.extname = 'pg_stat_statements';

  IF v_stat_schema IS NULL THEN
    RAISE EXCEPTION 'Unable to find pg_stat_statements extension installed on this database';
  END IF;

  SELECT run_interval INTO v_reset_interval
  FROM @extschema@.metric_tables
  WHERE table_schema = '@extschema@'
  AND table_name = 'pgm_pg_stat_statements_reset';

  SELECT COALESCE(pg_catalog.max(reset_time), '1970-01-01'::timestamptz) INTO v_reset_timestamp FROM @extschema@.pg_stat_statements_reset_info;

  IF ((CURRENT_TIMESTAMP - v_reset_timestamp) > v_reset_interval) THEN
      -- Ensure table is empty
      DELETE FROM @extschema@.pg_stat_statements_reset_info;
      v_sql := pg_catalog.format('SELECT %I.pg_stat_statements_reset()', v_stat_schema);
      EXECUTE v_sql;
      INSERT INTO @extschema@.pg_stat_statements_reset_info(reset_time) values (CURRENT_TIMESTAMP);
  END IF;

  RETURN (SELECT pg_catalog.extract(epoch from reset_time) FROM @extschema@.pg_stat_statements_reset_info);

END
$function$;

REVOKE ALL ON FUNCTION @extschema@.pg_stat_statements_reset_info() FROM PUBLIC;
