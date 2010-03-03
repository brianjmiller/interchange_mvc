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

CREATE TABLE ic_manage_functions (
    code character varying(70) NOT NULL PRIMARY KEY,

    date_created timestamp without time zone DEFAULT (timeofday())::timestamp without time zone NOT NULL,
    created_by character varying(32) NOT NULL,
    last_modified timestamp without time zone NOT NULL,
    modified_by character varying(32) NOT NULL,

    section_code character varying(30) NOT NULL,
    developer_only boolean DEFAULT false NOT NULL,
    in_menu boolean DEFAULT false NOT NULL,
    sort_order smallint DEFAULT 0 NOT NULL,
    display_label character varying(100) NOT NULL,
    extra_params text DEFAULT ''::text NOT NULL,
    help_copy text DEFAULT ''::text NOT NULL,

    CONSTRAINT ic_manage_functions_code_valid CHECK (((length((code)::text) > 0) AND ((code)::text = btrim((code)::text)))),
    CONSTRAINT ic_manage_functions_display_label_valid CHECK (((length((display_label)::text) > 0) AND ((display_label)::text = btrim((display_label)::text))))
);

ALTER TABLE ONLY ic_manage_functions
    ADD CONSTRAINT fk_ic_manage_functions_section_code FOREIGN KEY (section_code) REFERENCES ic_manage_function_sections(code) ON UPDATE CASCADE ON DELETE RESTRICT;

CREATE TRIGGER ic_manage_functions_last_modified
    BEFORE INSERT OR UPDATE ON ic_manage_functions
    FOR EACH ROW
    EXECUTE PROCEDURE ic_update_last_modified();

COPY ic_manage_functions (code, date_created, created_by, last_modified, modified_by, section_code, developer_only, in_menu, sort_order, display_label, extra_params, help_copy) FROM stdin;
ManageFunctions__Sections_sectionAdd	2009-01-12 14:02:24.395965	1	2009-01-12 14:02:24.061873	1	_development	t	f	1	Add Manage Function Section		
ManageFunctions__Sections_sectionProperties	2009-01-12 14:02:24.397783	1	2009-01-12 14:02:24.061873	1	_development	t	f	2	Edit Manage Function Section Properties		
ManageFunctions__Sections_sectionDrop	2009-01-12 14:02:24.397922	1	2009-01-12 14:02:24.061873	1	_development	t	f	3	Drop Manage Function Section		
ManageFunctions__Sections_sectionList	2009-01-12 14:02:24.397995	1	2009-01-12 14:02:24.061873	1	_development	t	t	4	List Manage Function Sections		
ManageFunctions_functionAdd	2009-01-12 14:02:24.398066	1	2009-01-12 14:02:24.061873	1	_development	t	f	5	Add Manage Function		
ManageFunctions_functionProperties	2009-01-12 14:02:24.398242	1	2009-01-12 14:02:24.061873	1	_development	t	f	6	Edit Manage Function Properties		
ManageFunctions_functionDrop	2009-01-12 14:02:24.398314	1	2009-01-12 14:02:24.061873	1	_development	t	f	7	Drop Manage Function		
ManageFunctions_functionList	2009-01-12 14:02:24.398385	1	2009-01-12 14:02:24.061873	1	_development	t	t	8	List Manage Functions		
ManageFunctions_functionDetailView	2009-01-12 14:02:24.398464	1	2009-01-12 14:02:24.061873	1	_development	t	f	9	Manage Function Detail View		
TimeZones_zoneAdd	2009-04-17 07:33:12.814683	schema	2009-04-17 07:33:12.81281	schema	general_maint	t	f	10	Add Time Zone		
TimeZones_zoneProperties	2009-04-17 07:33:12.81707	schema	2009-04-17 07:33:12.81281	schema	general_maint	t	f	11	Edit Time Zone Properties		
TimeZones_zoneDrop	2009-04-17 07:33:12.817119	schema	2009-04-17 07:33:12.81281	schema	general_maint	t	f	12	Drop Time Zone		
TimeZones_zoneList	2009-04-17 07:33:12.817157	schema	2009-04-17 07:33:12.81281	schema	general_maint	f	t	13	List Time Zones		
TimeZones_zoneDetailView	2009-04-17 07:33:12.817193	schema	2009-04-17 07:33:12.81281	schema	general_maint	f	f	14	Time Zone Detail View		
Roles_roleAdd	2009-04-17 07:33:12.81723	schema	2009-04-17 07:33:12.81281	schema	access	f	f	10	Add Role		
Roles_roleProperties	2009-04-17 07:33:12.817264	schema	2009-04-17 07:33:12.81281	schema	access	f	f	11	Edit Role Properties		
Roles_roleDrop	2009-04-17 07:33:12.817298	schema	2009-04-17 07:33:12.81281	schema	access	f	f	12	Drop Role		
Roles_roleList	2009-04-17 07:33:12.817394	schema	2009-04-17 07:33:12.81281	schema	access	f	t	13	List Roles		
Roles_roleDetailView	2009-04-17 07:33:12.817432	schema	2009-04-17 07:33:12.81281	schema	access	f	f	14	Role Detail View		
Users_userAdd	2009-04-17 07:33:12.817467	schema	2009-04-17 07:33:12.81281	schema	access	f	f	20	Add User		
Users_userProperties	2009-04-17 07:33:12.817502	schema	2009-04-17 07:33:12.81281	schema	access	f	f	21	Edit User Properties		
Users_userDrop	2009-04-17 07:33:12.817536	schema	2009-04-17 07:33:12.81281	schema	access	f	f	22	Drop User		
Users_userDetailView	2009-04-17 07:33:12.817571	schema	2009-04-17 07:33:12.81281	schema	access	f	f	23	User Detail View		
Users_userList	2009-04-17 07:33:12.817571	schema	2009-04-17 07:33:12.81281	schema	access	f	t	24	List Users		
Rights_rightAdd	2009-04-17 07:33:12.817607	schema	2009-04-17 07:33:12.81281	schema	access	f	f	30	Add Right		
Rights_rightProperties	2009-04-17 07:33:12.817641	schema	2009-04-17 07:33:12.81281	schema	access	f	f	31	Edit Right Properties		
Rights_rightDrop	2009-04-17 07:33:12.817675	schema	2009-04-17 07:33:12.81281	schema	access	f	f	32	Drop Right		
Rights_rightDetailView	2009-04-17 07:33:12.817711	schema	2009-04-17 07:33:12.81281	schema	access	f	f	33	Right Detail View		
RightTypes_typeAdd	2009-04-17 07:33:12.817746	schema	2009-04-17 07:33:12.81281	schema	access	t	f	40	Add Right Type		
RightTypes_typeProperties	2009-04-17 07:33:12.817781	schema	2009-04-17 07:33:12.81281	schema	access	t	f	41	Edit Right Type Properties		
RightTypes_typeDrop	2009-04-17 07:33:12.817816	schema	2009-04-17 07:33:12.81281	schema	access	t	f	42	Drop Right Type		
RightTypes_typeList	2009-04-17 07:33:12.817852	schema	2009-04-17 07:33:12.81281	schema	access	f	t	43	List Right Types		
RightTypes_typeDetailView	2009-04-17 07:33:12.817888	schema	2009-04-17 07:33:12.81281	schema	access	f	f	44	Right Type Detail View		
\.

--ROLLBACK;
COMMIT;
