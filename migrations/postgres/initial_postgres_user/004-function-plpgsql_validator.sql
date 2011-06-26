BEGIN;
SET client_min_messages='ERROR';

CREATE FUNCTION plpgsql_validator(oid) RETURNS void
    AS '$libdir/plpgsql', 'plpgsql_validator'
        LANGUAGE c
;

--ROLLBACK;
COMMIT;
