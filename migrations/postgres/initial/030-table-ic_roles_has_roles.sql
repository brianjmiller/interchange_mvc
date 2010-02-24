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
schema	schema	4	1
schema	schema	5	1
\.

--ROLLBACK;
COMMIT;
