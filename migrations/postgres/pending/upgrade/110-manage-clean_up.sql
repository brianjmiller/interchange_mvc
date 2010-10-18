BEGIN;
SET client_min_messages='ERROR';

DROP VIEW IF EXISTS ic_all_codes;
DROP VIEW IF EXISTS clean.ic_manage_functions;
DROP TABLE IF EXISTS ic_manage_functions;
DROP VIEW IF EXISTS clean.ic_manage_function_sections;
DROP TABLE IF EXISTS ic_manage_function_sections;

--ROLLBACK;
COMMIT;
