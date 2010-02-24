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

CREATE FUNCTION ic_right_types_code_lowercase() RETURNS trigger
    AS $$
BEGIN
    NEW.code := LOWER(NEW.code);
    RETURN NEW;
END;
$$
    LANGUAGE plpgsql;

CREATE SEQUENCE ic_right_types_id_seq;

CREATE TABLE ic_right_types (
    id integer DEFAULT nextval('ic_right_types_id_seq'::regclass) NOT NULL PRIMARY KEY,

    date_created timestamp without time zone DEFAULT (timeofday())::timestamp without time zone NOT NULL,
    created_by character varying(32) NOT NULL,
    last_modified timestamp without time zone NOT NULL,
    modified_by character varying(32) NOT NULL,

    code character varying(50) NOT NULL,
    display_label character varying(100) NOT NULL,
    description text DEFAULT ''::text NOT NULL,
    target_kind_code character varying(30),

    CONSTRAINT ic_right_types_code_valid CHECK ((((code)::text ~ '[^[:space:]]'::text) AND ((code)::text = btrim((code)::text)))),

    UNIQUE(code, target_kind_code)
);

ALTER TABLE ONLY ic_right_types
    ADD CONSTRAINT fk_target_kind_code FOREIGN KEY (target_kind_code) REFERENCES ic_right_type_target_kinds(code) ON UPDATE CASCADE ON DELETE RESTRICT;

CREATE TRIGGER ic_right_types_code_enforce_lowercase
    BEFORE INSERT OR UPDATE ON ic_right_types
    FOR EACH ROW
    EXECUTE PROCEDURE ic_right_types_code_lowercase();

CREATE TRIGGER ic_right_types_last_modified
    BEFORE INSERT OR UPDATE ON ic_right_types
    FOR EACH ROW
    EXECUTE PROCEDURE ic_update_last_modified();

COPY ic_right_types (created_by, modified_by, id, code, display_label, description) FROM STDIN;
schema	schema	1	superuser	Unrestricted Access	Special right type that grants unrestricted access
schema	schema	2	access_site_mgmt	Access: Site Management	Determines access to the site management facility
\.

COPY ic_right_types (created_by, modified_by, id, code, display_label, target_kind_code, description) FROM STDIN;
schema	schema	3	execute	Execute: Site Management Function	site_mgmt_func	Determines right to execute site mgmt function
schema	schema	4	switch_user	Switch to Different User	user	Determines right to become a different user (bypassing login form)
\.

SELECT setval('ic_right_types_id_seq', max(id)) FROM ic_right_types;

--ROLLBACK;
COMMIT;
