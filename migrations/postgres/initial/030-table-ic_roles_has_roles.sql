BEGIN;
set client_min_messages='ERROR';

CREATE TABLE ic_roles_has_roles (
    role_id integer NOT NULL,
    has_role_id integer NOT NULL,

    date_created timestamp without time zone DEFAULT (timeofday())::timestamp without time zone NOT NULL,
    created_by character varying(32) NOT NULL,
    last_modified timestamp without time zone NOT NULL,
    modified_by character varying(32) NOT NULL,

    CONSTRAINT ic_roles_has_role_nonredundancy CHECK ((role_id <> has_role_id))
);

ALTER TABLE ONLY ic_roles_has_roles
    ADD CONSTRAINT ic_roles_has_roles_pkey PRIMARY KEY (role_id, has_role_id);

ALTER TABLE ONLY ic_roles_has_roles
    ADD CONSTRAINT fk_role_id FOREIGN KEY (role_id) REFERENCES ic_roles(id) ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY ic_roles_has_roles
    ADD CONSTRAINT fk_has_role_id FOREIGN KEY (has_role_id) REFERENCES ic_roles(id) ON UPDATE CASCADE ON DELETE CASCADE;

CREATE TRIGGER ic_roles_has_roles_last_modified
    BEFORE INSERT OR UPDATE ON ic_roles_has_roles
    FOR EACH ROW
    EXECUTE PROCEDURE ic_update_last_modified();

COPY ic_roles_has_roles (created_by, modified_by, role_id, has_role_id) FROM STDIN;
schema	schema	2	0
schema	schema	3	0
\.

--ROLLBACK;
COMMIT;
