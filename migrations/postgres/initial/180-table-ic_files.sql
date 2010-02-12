BEGIN;
SET client_min_messages='ERROR';

CREATE SEQUENCE ic_files_id_seq;

CREATE TABLE ic_files (
    id integer DEFAULT nextval('ic_files_id_seq'::regclass) NOT NULL PRIMARY KEY,

    date_created timestamp without time zone DEFAULT (timeofday())::timestamp without time zone NOT NULL,
    created_by character varying(32) NOT NULL,
    last_modified timestamp without time zone NOT NULL,
    modified_by character varying(32) NOT NULL,

    file_resource_id integer,
    object_pk text NOT NULL,

    CONSTRAINT ic_files_id_valid CHECK ((id > 0)),
    UNIQUE (file_resource_id, object_pk)
);

ALTER TABLE ONLY ic_files
    ADD CONSTRAINT fk_file_resource_id 
    FOREIGN KEY (file_resource_id) 
    REFERENCES ic_file_resources(id) 
    ON UPDATE CASCADE 
    ON DELETE CASCADE;

CREATE TRIGGER ic_files_last_modified
    BEFORE INSERT OR UPDATE ON ic_files
    FOR EACH ROW
    EXECUTE PROCEDURE ic_update_last_modified();

--ROLLBACK;
COMMIT;
