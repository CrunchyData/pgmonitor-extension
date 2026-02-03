CREATE MATERIALIZED VIEW @extschema@.pgm_sequence_exhaustion AS
    SELECT count FROM @extschema@.sequence_exhaustion(75);
CREATE UNIQUE INDEX pgm_sequence_exhaustion_idx ON @extschema@.pgm_sequence_exhaustion (count);

INSERT INTO @extschema@.metric_matviews (
    view_name
    , run_interval
    , scope )
VALUES (
   'pgm_sequence_exhaustion'
    , '5 minutes'::interval
    , 'database')
ON CONFLICT DO NOTHING;


