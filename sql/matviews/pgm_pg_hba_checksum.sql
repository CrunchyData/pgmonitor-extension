CREATE MATERIALIZED VIEW @extschema@.pgm_pg_hba_checksum AS
    SELECT @extschema@.pg_hba_checksum() AS status;
CREATE UNIQUE INDEX pgm_pg_hba_checksum_idx ON @extschema@.pgm_pg_hba_checksum (status);

INSERT INTO @extschema@.metric_matviews (
    view_name
    , run_interval
    , scope )
VALUES (
   'pgm_pg_hba_checksum'
    , '5 minutes'::interval
    , 'global')
ON CONFLICT DO NOTHING;


