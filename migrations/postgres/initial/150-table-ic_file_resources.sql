BEGIN;
SET client_min_messages='ERROR';

CREATE SEQUENCE ic_file_resources_id_seq;

CREATE TABLE ic_file_resources (
    id integer DEFAULT nextval('ic_file_resources_id_seq'::regclass) NOT NULL PRIMARY KEY,

    date_created timestamp without time zone DEFAULT (timeofday())::timestamp without time zone NOT NULL,
    created_by character varying(32) NOT NULL,
    last_modified timestamp without time zone NOT NULL,
    modified_by character varying(32) NOT NULL,

    parent_id integer,
    branch_order integer,
    lookup_value character varying(70) NOT NULL,
    generate_from_parent boolean NOT NULL,

    CONSTRAINT file_resources_id_valid CHECK ((id > 0)),
    CONSTRAINT file_resources_lookup_value_valid CHECK (((length((lookup_value)::text) > 0) AND ((lookup_value)::text = btrim((lookup_value)::text))))
);

CREATE TRIGGER ic_file_resources_last_modified
    BEFORE INSERT OR UPDATE ON ic_file_resources
    FOR EACH ROW
    EXECUTE PROCEDURE ic_update_last_modified();

CREATE UNIQUE INDEX ic_file_resources_parent_id_lookup_value_unique 
    ON ic_file_resources 
    USING btree (parent_id, regexp_replace(lower((lookup_value)::text), 'W+'::text, ''::text));

COPY ic_file_resources (id, date_created, created_by, last_modified, modified_by, parent_id, branch_order, lookup_value, generate_from_parent) FROM stdin;
1	2009-02-03 16:28:25.606947	schema	2009-02-03 16:28:25.598311	schema	\N	\N	**Artificial Top Node**	f
\.

SELECT pg_catalog.setval('ic_file_resources_id_seq', (SELECT MAX(id) FROM ic_file_resources), true);

--ROLLBACK;
COMMIT;
