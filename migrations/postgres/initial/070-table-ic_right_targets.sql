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

COPY ic_right_targets (created_by, modified_by, right_id, ref_obj_pk) FROM STDIN;
schema	schema	3	ManageFunctions__Sections_sectionAdd
schema	schema	3	ManageFunctions__Sections_sectionProperties
schema	schema	3	ManageFunctions__Sections_sectionDrop
schema	schema	3	ManageFunctions__Sections_sectionList
schema	schema	3	ManageFunctions_functionAdd
schema	schema	3	ManageFunctions_functionProperties
schema	schema	3	ManageFunctions_functionDrop
schema	schema	3	ManageFunctions_functionList
schema	schema	3	ManageFunctions_functionDetailView
schema	schema	3	TimeZones_zoneAdd
schema	schema	3	TimeZones_zoneProperties
schema	schema	3	TimeZones_zoneDrop
schema	schema	3	TimeZones_zoneList
schema	schema	3	TimeZones_zoneDetailView
schema	schema	3	RightTypes_typeAdd
schema	schema	3	RightTypes_typeProperties
schema	schema	3	RightTypes_typeDrop
schema	schema	3	RightTypes_typeList
schema	schema	3	RightTypes_typeDetailView
schema	schema	4	Roles_roleAdd
schema	schema	4	Roles_roleProperties
schema	schema	4	Roles_roleDrop
schema	schema	4	Roles_roleList
schema	schema	4	Roles_roleDetailView
schema	schema	4	Users_userAdd
schema	schema	4	Users_userProperties
schema	schema	4	Users_userDrop
schema	schema	4	Users_userDetailView
schema	schema	4	Users_userList
schema	schema	4	Rights_rightAdd
schema	schema	4	Rights_rightProperties
schema	schema	4	Rights_rightDrop
schema	schema	4	Rights_rightDetailView
\.

--ROLLBACK;
COMMIT;
