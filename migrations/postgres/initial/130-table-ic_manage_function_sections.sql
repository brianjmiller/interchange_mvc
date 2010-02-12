BEGIN;
set client_min_messages='ERROR';

CREATE TABLE ic_manage_function_sections (
    code character varying(30) NOT NULL PRIMARY KEY,

    date_created timestamp without time zone DEFAULT (timeofday())::timestamp without time zone NOT NULL,
    created_by character varying(32) NOT NULL,
    last_modified timestamp without time zone NOT NULL,
    modified_by character varying(32) NOT NULL,

    status integer NOT NULL,
    display_label character varying(20) DEFAULT ''::character varying NOT NULL,

    CONSTRAINT ic_manage_function_sections_code_valid CHECK (((length((code)::text) > 0) AND ((code)::text = btrim((code)::text)))),
    CONSTRAINT ic_manage_function_sections_display_label_valid CHECK (((length((display_label)::text) > 0) AND ((display_label)::text = btrim((display_label)::text))))
);

CREATE TRIGGER ic_manage_function_sections_last_modified
    BEFORE INSERT OR UPDATE ON ic_manage_function_sections
    FOR EACH ROW
    EXECUTE PROCEDURE ic_update_last_modified();

COPY ic_manage_function_sections (code, date_created, created_by, last_modified, modified_by, status, display_label) FROM stdin;
_development	2009-01-12 14:02:23.89016	1	2009-01-12 14:02:23.571935	1	1	_Development
general_maint	2009-01-12 14:02:23.892017	1	2009-01-12 14:02:23.571935	1	1	General Maintenance
access	2009-04-17 07:33:08.62354	schema	2009-04-17 07:33:08.62158	schema	1	Access Controls
\.

--ROLLBACK;
COMMIT;
