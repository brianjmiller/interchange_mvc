BEGIN;
SET client_min_messages='ERROR';

CREATE FUNCTION plpgsql_call_handler() RETURNS language_handler
    AS '$libdir/plpgsql', 'plpgsql_call_handler'
        LANGUAGE c
;

--ROLLBACK;
COMMIT;
