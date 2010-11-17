--
-- Copyright (C) 2008-2010 End Point Corporation, http://www.endpoint.com/
--
-- This program is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 2 of the License, or
-- (at your option) any later version.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program. If not, see: http://www.gnu.org/licenses/ 
--
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
schema	schema	2	1	2	t
schema	schema	3	4	3	t
schema	schema	4	5	3	t
schema	schema	5	1	3	t
\.

SELECT setval('ic_rights_id_seq', max(id)) FROM ic_rights;

--ROLLBACK;
COMMIT;
