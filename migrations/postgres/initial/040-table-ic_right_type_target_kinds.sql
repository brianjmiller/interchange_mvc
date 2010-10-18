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

CREATE TABLE ic_right_type_target_kinds (
    code character varying(30) NOT NULL PRIMARY KEY,

    date_created timestamp without time zone DEFAULT (timeofday())::timestamp without time zone NOT NULL,
    created_by character varying(32) NOT NULL,
    last_modified timestamp without time zone NOT NULL,
    modified_by character varying(32) NOT NULL,

    display_label character varying(100) NOT NULL,
    model_class character varying(100) NOT NULL,
    relation_name character varying(100) NOT NULL,

    CONSTRAINT ic_right_type_target_kinds_code_valid CHECK (((length((code)::text) > 0) AND ((code)::text = btrim((code)::text)))),
    CONSTRAINT ic_right_type_target_kinds_display_label_valid CHECK (((length((display_label)::text) > 0) AND ((display_label)::text = btrim((display_label)::text)))),
    CONSTRAINT ic_right_type_target_kinds_model_class_valid CHECK (((length((model_class)::text) > 0) AND ((model_class)::text = btrim((model_class)::text)))),

    -- TODO: improve this to run a check for relation existence
    CONSTRAINT ic_right_type_target_kinds_relation_name_valid CHECK (((length((relation_name)::text) > 0) AND ((relation_name)::text = btrim((relation_name)::text)))),

    UNIQUE(display_label),
    UNIQUE(model_class),
    UNIQUE(relation_name)
);

CREATE TRIGGER ic_right_type_target_kinds_last_modified
    BEFORE INSERT OR UPDATE ON ic_right_type_target_kinds
    FOR EACH ROW
    EXECUTE PROCEDURE ic_update_last_modified();

COPY ic_right_type_target_kinds (created_by, modified_by, code, display_label, model_class, relation_name) FROM STDIN;
schema	schema	user	User	IC::M::User	users
schema	schema	role	Role	IC::M::Role	roles
schema	schema	site_mgmt_action	Site Mgmt Action	IC::M::ManageClass::Action	ic_manage_class_actions
\.

--ROLLBACK;
COMMIT;
