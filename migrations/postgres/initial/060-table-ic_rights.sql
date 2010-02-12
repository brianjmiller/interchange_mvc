BEGIN;
set client_min_messages='ERROR';

CREATE SEQUENCE ic_rights_id_seq;

CREATE TABLE ic_rights (
    id integer PRIMARY KEY DEFAULT nextval('ic_rights_id_seq'::regclass) NOT NULL,

    date_created timestamp without time zone DEFAULT (timeofday())::timestamp without time zone NOT NULL,
    created_by character varying(32) NOT NULL,
    last_modified timestamp without time zone NOT NULL,
    modified_by character varying(32) NOT NULL,

    role_id integer NOT NULL,
    right_type_id integer NOT NULL,
    is_granted boolean NOT NULL,

    CONSTRAINT ic_rights_id_valid CHECK ((id > 0)),
    
    UNIQUE(role_id, right_type_id, is_granted)
);

ALTER TABLE ONLY ic_rights
    ADD CONSTRAINT fk_right_type_id FOREIGN KEY (right_type_id) REFERENCES ic_right_types(id) ON UPDATE CASCADE ON DELETE RESTRICT;

ALTER TABLE ONLY ic_rights
    ADD CONSTRAINT fk_role_id FOREIGN KEY (role_id) REFERENCES ic_roles(id) ON UPDATE CASCADE ON DELETE CASCADE;

CREATE TRIGGER ic_rights_last_modified
    BEFORE INSERT OR UPDATE ON ic_rights
    FOR EACH ROW
    EXECUTE PROCEDURE ic_update_last_modified();

COPY ic_rights (created_by, modified_by, id, role_id, right_type_id, is_granted) FROM STDIN;
schema	schema	1	3	1	t
\.

SELECT setval('ic_rights_id_seq', max(id)) FROM ic_rights;

--ROLLBACK;
COMMIT;
