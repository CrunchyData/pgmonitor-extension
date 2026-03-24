-- pgBackRest views
-- All backrest data is pulled from a refreshed table so no need for individual view entries in config table

CREATE VIEW @extschema@.pgm_backrest_last_diff_backup AS
    WITH all_backups AS (
      SELECT config_file
       , jsonb_array_elements(data) AS stanza_data
    FROM @extschema@.pgbackrest_info
    )
    , per_stanza AS (
      SELECT config_file
       , stanza_data->>'name' AS stanza
       , jsonb_array_elements(stanza_data->'backup') AS backup_data
      FROM all_backups
    )
    SELECT config_file
    , stanza
    , backup_data->'database'->>'repo-key' AS repo
    , extract(epoch from (CURRENT_TIMESTAMP - max(to_timestamp((backup_data->'timestamp'->>'stop')::bigint)))) AS time_since_completion_seconds
    FROM per_stanza
    WHERE backup_data->>'type' IN ('full', 'diff')
    GROUP BY config_file, stanza, backup_data->'database'->>'repo-key';


CREATE VIEW @extschema@.pgm_backrest_last_full_backup AS
    WITH all_backups AS (
      SELECT config_file
       , jsonb_array_elements(data) AS stanza_data
      FROM @extschema@.pgbackrest_info
    )
    , per_stanza AS (
      SELECT config_file
       , stanza_data->>'name' AS stanza
       , jsonb_array_elements(stanza_data->'backup') AS backup_data
      FROM all_backups
    )
    SELECT config_file
    , stanza
    , backup_data->'database'->>'repo-key' AS repo
    , extract(epoch from (CURRENT_TIMESTAMP - max(to_timestamp((backup_data->'timestamp'->>'stop')::bigint)))) AS time_since_completion_seconds
    FROM per_stanza
    WHERE backup_data->>'type' IN ('full')
    GROUP BY config_file, stanza, backup_data->'database'->>'repo-key';


CREATE VIEW @extschema@.pgm_backrest_last_incr_backup AS
    WITH all_backups AS (
      SELECT config_file
       , jsonb_array_elements(data) AS stanza_data
      FROM @extschema@.pgbackrest_info
    )
    , per_stanza AS (
      SELECT config_file
       , stanza_data->>'name' AS stanza
       , jsonb_array_elements(stanza_data->'backup') AS backup_data
      FROM all_backups
    )
    SELECT config_file
    , stanza
    , backup_data->'database'->>'repo-key' AS repo
    , extract(epoch from (CURRENT_TIMESTAMP - max(to_timestamp((backup_data->'timestamp'->>'stop')::bigint)))) AS time_since_completion_seconds
    FROM per_stanza
    WHERE backup_data->>'type' IN ('full', 'diff', 'incr')
    GROUP BY config_file, stanza, backup_data->'database'->>'repo-key';


CREATE VIEW @extschema@.pgm_backrest_last_info AS
    WITH all_backups AS (
      SELECT config_file
       , jsonb_array_elements(data) AS stanza_data
      FROM @extschema@.pgbackrest_info
    )
    , per_stanza AS (
      SELECT config_file
       , stanza_data->>'name' AS stanza
       , jsonb_array_elements(stanza_data->'backup') AS backup_data
      FROM all_backups
    )
    SELECT a.config_file
    , a.stanza
    , split_part(a.backup_data->'backrest'->>'version', '.', 1) || lpad(split_part(a.backup_data->'backrest'->>'version', '.', 2), 2, '0') || lpad(coalesce(nullif(split_part(a.backup_data->'backrest'->>'version', '.', 3), ''), '00'), 2, '0') AS backrest_repo_version
    , a.backup_data->'database'->>'repo-key' AS repo
    , a.backup_data->>'type' AS backup_type
    , a.backup_data->'info'->'repository'->>'delta' AS repo_backup_size_bytes
    , (a.backup_data->'timestamp'->>'stop')::bigint - (a.backup_data->'timestamp'->>'start')::bigint AS backup_runtime_seconds
    , CASE
       WHEN a.backup_data->>'error' = 'true' THEN 1
       ELSE 0
     END AS backup_error
    FROM per_stanza a
    JOIN (
          SELECT config_file
              , stanza
              , backup_data->'database'->>'repo-key' AS repo
              , backup_data->>'type' AS backup_type
              , max(backup_data->'timestamp'->>'start') AS max_backup_start
              , max(backup_data->'timestamp'->>'stop') AS max_backup_stop
          FROM per_stanza
          GROUP BY 1,2,3,4) b
    ON a.config_file = b.config_file
    AND a.stanza = b.stanza
    AND a.backup_data->>'type' = b.backup_type
    AND a.backup_data->'timestamp'->>'start' = b.max_backup_start
    AND a.backup_data->'timestamp'->>'stop' = b.max_backup_stop;


CREATE VIEW @extschema@.pgm_backrest_oldest_full_backup AS
    WITH all_backups AS (
      SELECT config_file
       , jsonb_array_elements(data) AS stanza_data
      FROM @extschema@.pgbackrest_info
    )
    , per_stanza AS (
      SELECT config_file
       , stanza_data->>'name' AS stanza
       , jsonb_array_elements(stanza_data->'backup') AS backup_data
      FROM all_backups
    )
    SELECT config_file
    , stanza
    , backup_data->'database'->>'repo-key' AS repo
    , min((backup_data->'timestamp'->>'stop')::bigint) time_seconds
    FROM per_stanza
    WHERE backup_data->>'type' IN ('full')
    GROUP BY config_file, stanza, backup_data->'database'->>'repo-key';
