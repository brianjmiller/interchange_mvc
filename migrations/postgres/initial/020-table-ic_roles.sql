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

CREATE SEQUENCE ic_roles_id_seq;

CREATE TABLE ic_roles (
    id               integer PRIMARY KEY DEFAULT nextval('ic_roles_id_seq'::regclass) NOT NULL,

    date_created     timestamp without time zone DEFAULT (timeofday())::timestamp without time zone NOT NULL,
    created_by       character varying(32) NOT NULL,
    last_modified    timestamp without time zone NOT NULL,
    modified_by      character varying(32) NOT NULL,

    code             character varying(50) NOT NULL,
    display_label    character varying(100) NOT NULL,
    description text DEFAULT ''::text NOT NULL,

    CONSTRAINT ic_roles_code_valid CHECK ((((code)::text = btrim((code)::text)) AND ((code)::text ~ '[^[:space:]]'::text))),

    UNIQUE(code)
);

CREATE TRIGGER ic_roles_last_modified
    BEFORE INSERT OR UPDATE ON ic_roles
    FOR EACH ROW
    EXECUTE PROCEDURE ic_update_last_modified();

COPY ic_roles (created_by, modified_by, id, code, display_label, description) FROM STDIN;
schema	schema	0	user	User	Group role to which all users are assigned by default
schema	schema	1	ic_site_mgr	IC Site Manager	Group role centered around IC site management interface
schema	schema	2	user_guest	User: guest	
schema	schema	3	user_root	User: root	
schema	schema	4	ic_site_mgr_developer	IC Site Mgr: Developer	
schema	schema	5	ic_site_mgr_user_maintenance	IC Site Mgr: User Maintenance	
\.

SELECT setval('ic_roles_id_seq', max(id)) FROM ic_roles;

--ROLLBACK;
COMMIT;
