BEGIN;

CREATE FUNCTION ic_update_last_modified() RETURNS "trigger"
    AS '
BEGIN
    NEW.last_modified = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
'
LANGUAGE plpgsql;

--ROLLBACK;
COMMIT;
