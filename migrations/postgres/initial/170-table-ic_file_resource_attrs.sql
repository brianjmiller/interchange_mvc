BEGIN;
SET client_min_messages='ERROR';

CREATE SEQUENCE ic_file_resource_attrs_id_seq;

CREATE TABLE ic_file_resource_attrs (
    id integer DEFAULT nextval('ic_file_resource_attrs_id_seq'::regclass) NOT NULL PRIMARY KEY,

    date_created timestamp without time zone DEFAULT (timeofday())::timestamp without time zone NOT NULL,
    created_by character varying(32) NOT NULL,
    last_modified timestamp without time zone NOT NULL,
    modified_by character varying(32) NOT NULL,

    file_resource_id integer NOT NULL,
    code character varying(100) NOT NULL,
    kind_code character varying(30) NOT NULL,
    display_label character varying(100) NOT NULL,
    description text NOT NULL,

    CONSTRAINT ic_file_resource_attrs_id_valid CHECK ((id > 0)),
    UNIQUE (file_resource_id, code)
);

ALTER TABLE ONLY ic_file_resource_attrs
    ADD CONSTRAINT fk_kind_code 
    FOREIGN KEY (kind_code) 
    REFERENCES ic_file_resource_attr_kinds(code) 
    ON UPDATE CASCADE 
    ON DELETE RESTRICT;

CREATE TRIGGER ic_file_resource_attrs_last_modified
    BEFORE INSERT OR UPDATE ON ic_file_resource_attrs
    FOR EACH ROW
    EXECUTE PROCEDURE ic_update_last_modified();

--ROLLBACK;
COMMIT;
