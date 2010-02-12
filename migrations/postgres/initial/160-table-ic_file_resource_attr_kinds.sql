BEGIN;
SET client_min_messages='ERROR';

CREATE TABLE ic_file_resource_attr_kinds (
    code character varying(30) NOT NULL PRIMARY KEY,

    date_created timestamp without time zone DEFAULT (timeofday())::timestamp without time zone NOT NULL,
    created_by character varying(32) NOT NULL,
    last_modified timestamp without time zone NOT NULL,
    modified_by character varying(32) NOT NULL,

    display_label character varying(100) NOT NULL,
    description text NOT NULL,
    
    CONSTRAINT code_valid CHECK (((length((code)::text) > 0) AND ((code)::text = btrim((code)::text))))
);

CREATE TRIGGER ic_file_resource_attr_kinds_last_modified
    BEFORE INSERT OR UPDATE ON ic_file_resource_attr_kinds
    FOR EACH ROW
    EXECUTE PROCEDURE ic_update_last_modified();


COPY ic_file_resource_attr_kinds (code, date_created, created_by, last_modified, modified_by, display_label, description) FROM stdin;
numeric	2009-03-06 16:47:47.728471	schema	2009-03-06 16:47:47.363356	schema	Numeric	Numeric value
\.

--ROLLBACK;
COMMIT;
