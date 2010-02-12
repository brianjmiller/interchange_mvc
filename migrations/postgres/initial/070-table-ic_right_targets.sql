BEGIN;
set client_min_messages='ERROR';

CREATE SEQUENCE ic_right_targets_id_seq;

CREATE TABLE ic_right_targets (
    id integer DEFAULT nextval('ic_right_targets_id_seq'::regclass) NOT NULL,

    date_created timestamp without time zone DEFAULT (timeofday())::timestamp without time zone NOT NULL,
    created_by character varying(32) NOT NULL,
    last_modified timestamp without time zone NOT NULL,
    modified_by character varying(32) NOT NULL,

    right_id integer NOT NULL,

    ref_obj_pk text NOT NULL
);

ALTER TABLE ONLY ic_right_targets
    ADD CONSTRAINT fk_right_id FOREIGN KEY (right_id) REFERENCES ic_rights(id) ON UPDATE CASCADE ON DELETE CASCADE;

CREATE TRIGGER ic_right_targets_last_modified
    BEFORE INSERT OR UPDATE ON ic_right_targets
    FOR EACH ROW
    EXECUTE PROCEDURE ic_update_last_modified();

--ROLLBACK;
COMMIT;
