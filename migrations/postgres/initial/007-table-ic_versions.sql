BEGIN;
set client_min_messages='ERROR';

CREATE TABLE ic_versions (
    id integer PRIMARY KEY NOT NULL,

    date_created timestamp without time zone DEFAULT (timeofday())::timestamp without time zone NOT NULL,
    created_by character varying(32) NOT NULL,
    last_modified timestamp without time zone NOT NULL,
    modified_by character varying(32) NOT NULL
);

CREATE TRIGGER ic_versions_last_modified
    BEFORE INSERT OR UPDATE ON ic_versions
    FOR EACH ROW
    EXECUTE PROCEDURE ic_update_last_modified();

COPY ic_versions (created_by, modified_by, id) FROM STDIN;
schema	schema	1
\.

--ROLLBACK;
COMMIT;
