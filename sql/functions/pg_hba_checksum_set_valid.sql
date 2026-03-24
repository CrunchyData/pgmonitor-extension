CREATE FUNCTION @extschema@.pg_hba_checksum_set_valid() RETURNS smallint
    LANGUAGE sql
AS $function$
/*
 * This function provides quick, clear interface for resetting the checksum monitor to treat the currently detected configuration as valid after alerting on a change. Note that configuration history will be cleared.
 */
TRUNCATE @extschema@.pg_hba_checksum;

SELECT @extschema@.pg_hba_checksum();

$function$;


REVOKE ALL ON FUNCTION @extschema@.pg_hba_checksum_set_valid() FROM PUBLIC;
