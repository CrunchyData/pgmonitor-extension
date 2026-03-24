/*
 * Can't just do a raw check for the hash value since Prometheus only records numeric values for alerts
 * If checksum function returns 0, then NO settings have changed
 * If checksum function returns 1, then something has changed since last known valid state
 * For replicas, logging past settings is not possible to compare what may have changed
 * For replicas, by default, it is expected that its settings will match the primary
 * For replicas, if the pg_settings or pg_hba.conf are necessarily different from the primary, a known good hash of that replica's
    settings can be sent as an argument to the relevant checksum function. Views are provided to easily obtain the hash values used by this monitoring tool.
 * If any known hash parameters are passed to the checksum functions, note that it will override any past hash values stored in the log table when doing comparisons and completely re-evaluate the entire state. This is true even if done on a primary where the current state will then also be logged for comparison if it differs from the given hash.
 */

/**** These hash views are required to exist before the associated functions can be created  ****/
CREATE VIEW @extschema@.pg_hba_hash AS
    -- Order by line number so it's caught if no content is changed but the order of entries is changed
    WITH hba_ordered_list AS (
        SELECT COALESCE(type, '<<NULL>>') AS type
            , array_to_string(COALESCE(database, ARRAY['<<NULL>>']), ',') AS database
            , array_to_string(COALESCE(user_name, ARRAY['<<NULL>>']), ',') AS user_name
            , COALESCE(address, '<<NULL>>') AS address
            , COALESCE(netmask, '<<NULL>>') AS netmask
            , COALESCE(auth_method, '<<NULL>>') AS auth_method
            , array_to_string(COALESCE(options, ARRAY['<<NULL>>']), ',') AS options
        FROM pg_catalog.pg_hba_file_rules
        ORDER BY line_number)
    SELECT md5(string_agg(type||database||user_name||address||netmask||auth_method||options, ',')) AS md5_hash
        , string_agg(type||database||user_name||address||netmask||auth_method||options, ',') AS hba_string
    FROM hba_ordered_list;


CREATE FUNCTION @extschema@.pg_hba_checksum(p_known_hba_hash text DEFAULT NULL)
    RETURNS smallint
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO pg_catalog, pg_temp
AS $function$
DECLARE

v_hba_hash              text;
v_hba_hash_old          text;
v_hba_match             smallint := 0;
v_hba_string            text;
v_hba_string_old        text;
v_is_in_recovery        boolean;
v_valid                 smallint;

BEGIN

SELECT pg_is_in_recovery() INTO v_is_in_recovery;

IF current_setting('server_version_num')::int >= 100000 THEN

    SELECT md5_hash
        , hba_string
    INTO v_hba_hash
        , v_hba_string
    FROM @extschema@.pg_hba_hash;

ELSE
    RAISE EXCEPTION 'pg_hba change monitoring unsupported in versions older than PostgreSQL 10';
END IF;

SELECT  hba_hash_generated, valid
INTO v_hba_hash_old, v_valid
FROM @extschema@.pg_hba_checksum
ORDER BY created_at DESC LIMIT 1;

IF p_known_hba_hash IS NOT NULL THEN
    v_hba_hash_old := p_known_hba_hash;
    -- Do not base validity on the stored value if manual hash is given.
    v_valid := 0;
END IF;

IF (v_hba_hash_old IS NOT NULL) THEN

    IF (v_hba_hash != v_hba_hash_old) THEN

        v_valid := 1;

        IF v_is_in_recovery = false THEN
            INSERT INTO @extschema@.pg_hba_checksum (
                    hba_hash_generated
                    , hba_hash_known_provided
                    , hba_string
                    , valid)
            VALUES (
                    v_hba_hash
                    , p_known_hba_hash
                    , v_hba_string
                    , v_valid);
        END IF;
    END IF;

ELSE

    v_valid := 0;
    IF v_is_in_recovery = false THEN
        INSERT INTO @extschema@.pg_hba_checksum (
                hba_hash_generated
                , hba_hash_known_provided
                , hba_string
                , valid)
        VALUES (v_hba_hash
                , p_known_hba_hash
                , v_hba_string
                , v_valid);
    END IF;

END IF;

RETURN v_valid;

END
$function$;

REVOKE ALL ON FUNCTION @extschema@.pg_hba_checksum(text) FROM PUBLIC;

