BEGIN;
SET client_min_messages='ERROR';

CREATE SEQUENCE ic_file_properties_id_seq;

CREATE TABLE ic_file_properties (
    id integer DEFAULT nextval('ic_file_properties_id_seq'::regclass) NOT NULL PRIMARY KEY,

    date_created timestamp without time zone DEFAULT (timeofday())::timestamp without time zone NOT NULL,
    created_by character varying(32) NOT NULL,
    last_modified timestamp without time zone NOT NULL,
    modified_by character varying(32) NOT NULL,

    file_id integer,
    file_resource_attr_id integer,
    value text NOT NULL,

    CONSTRAINT ic_file_properties_id_valid CHECK ((id > 0))
);

ALTER TABLE ONLY ic_file_properties
    ADD CONSTRAINT fk_file_resource_attr_id 
    FOREIGN KEY (file_resource_attr_id) 
    REFERENCES ic_file_resource_attrs(id) 
    ON UPDATE CASCADE 
    ON DELETE CASCADE;

ALTER TABLE ONLY ic_file_properties
    ADD CONSTRAINT fk_file_id 
    FOREIGN KEY (file_id) 
    REFERENCES ic_files(id) 
    ON UPDATE CASCADE 
    ON DELETE CASCADE;

CREATE TRIGGER ic_file_properties_last_modified
    BEFORE INSERT OR UPDATE ON ic_file_properties
    FOR EACH ROW
    EXECUTE PROCEDURE ic_update_last_modified();

--ROLLBACK;
COMMIT;
