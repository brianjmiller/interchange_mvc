BEGIN;
SET client_min_messages='ERROR';

CREATE SCHEMA clean;

ALTER SCHEMA clean OWNER TO com_residualselfimage;

--ROLLBACK;
COMMIT;
