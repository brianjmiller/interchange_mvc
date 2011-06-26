BEGIN;
SET client_min_messages='ERROR';

CREATE TRUSTED PROCEDURAL LANGUAGE plpgsql HANDLER plpgsql_call_handler VALIDATOR plpgsql_validator;

--ROLLBACK;
COMMIT;
