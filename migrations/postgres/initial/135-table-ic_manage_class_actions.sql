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
SET client_min_messages='ERROR';

CREATE SEQUENCE ic_manage_class_actions_id_seq;

CREATE TABLE ic_manage_class_actions (
    id                      INTEGER DEFAULT nextval('ic_manage_class_actions_id_seq'::regclass) NOT NULL PRIMARY KEY,

    date_created            TIMESTAMP NOT NULL DEFAULT timeofday()::TIMESTAMP,
    created_by              VARCHAR(32) NOT NULL,
    last_modified           TIMESTAMP NOT NULL,
    modified_by             VARCHAR(32) NOT NULL,

    class_code              VARCHAR(100) NOT NULL
                                CONSTRAINT fk_class_code
                                REFERENCES ic_manage_classes(code)
                                ON DELETE RESTRICT
                                ON UPDATE CASCADE,

    code                    VARCHAR(100) NOT NULL,
    display_label           VARCHAR(255) NOT NULL,
    is_primary              BOOLEAN NOT NULL,

    UNIQUE(class_code, code),
    UNIQUE(display_label)
);

CREATE TRIGGER ic_manage_class_actions_last_modified
    BEFORE INSERT OR UPDATE ON ic_manage_class_actions
    FOR EACH ROW
    EXECUTE PROCEDURE ic_update_last_modified();

COPY ic_manage_class_actions (class_code, code, display_label, is_primary, date_created, created_by, last_modified, modified_by) FROM stdin;
TimeZones	Add	Add Time Zone	t	2009-04-17 07:33:12.814683	schema	2009-04-17 07:33:12.814683	schema
TimeZones	List	List Time Zones	t	2009-04-17 07:33:12.814683	schema	2009-04-17 07:33:12.814683	schema
TimeZones	DetailView	Time Zone Detail View	f	2009-04-17 07:33:12.814683	schema	2009-04-17 07:33:12.814683	schema
TimeZones	Drop	Drop Time Zone	f	2009-04-17 07:33:12.814683	schema	2009-04-17 07:33:12.814683	schema
TimeZones	Properties	Edit Time Zone Properties	f	2009-04-17 07:33:12.814683	schema	2009-04-17 07:33:12.814683	schema
Users	Add	Add User	t	2009-04-17 07:33:12.814683	schema	2009-04-17 07:33:12.814683	schema
Users	List	List Users	t	2009-04-17 07:33:12.814683	schema	2009-04-17 07:33:12.814683	schema
Users	DetailView	User Detail View	f	2009-04-17 07:33:12.814683	schema	2009-04-17 07:33:12.814683	schema
Users	Drop	Drop User	f	2009-04-17 07:33:12.814683	schema	2009-04-17 07:33:12.814683	schema
Users	Properties	Edit User Properties	f	2009-04-17 07:33:12.814683	schema	2009-04-17 07:33:12.814683	schema
Roles	Add	Add Role	t	2009-04-17 07:33:12.814683	schema	2009-04-17 07:33:12.814683	schema
Roles	List	List Roles	t	2009-04-17 07:33:12.814683	schema	2009-04-17 07:33:12.814683	schema
Roles	DetailView	Role Detail View	f	2009-04-17 07:33:12.814683	schema	2009-04-17 07:33:12.814683	schema
Roles	Drop	Drop Role	f	2009-04-17 07:33:12.814683	schema	2009-04-17 07:33:12.814683	schema
Roles	Properties	Edit Role Properties	f	2009-04-17 07:33:12.814683	schema	2009-04-17 07:33:12.814683	schema
RightTypes	Add	Add Right Type	t	2009-04-17 07:33:12.814683	schema	2009-04-17 07:33:12.814683	schema
RightTypes	List	List Right Types	t	2009-04-17 07:33:12.814683	schema	2009-04-17 07:33:12.814683	schema
RightTypes	DetailView	Right Type Detail View	f	2009-04-17 07:33:12.814683	schema	2009-04-17 07:33:12.814683	schema
RightTypes	Drop	Drop Right Type	f	2009-04-17 07:33:12.814683	schema	2009-04-17 07:33:12.814683	schema
RightTypes	Properties	Edit Right Type Properties	f	2009-04-17 07:33:12.814683	schema	2009-04-17 07:33:12.814683	schema
Rights	Add	Add Right	t	2009-04-17 07:33:12.814683	schema	2009-04-17 07:33:12.814683	schema
Rights	DetailView	Right Detail View	f	2009-04-17 07:33:12.814683	schema	2009-04-17 07:33:12.814683	schema
Rights	Drop	Drop Right	f	2009-04-17 07:33:12.814683	schema	2009-04-17 07:33:12.814683	schema
Rights	Properties	Edit Right Properties	f	2009-04-17 07:33:12.814683	schema	2009-04-17 07:33:12.814683	schema
Files__Properties	Properties	Edit File Properties Properties	f	2010-11-17 10:55:43.00000	schema	2010-11-17 10:55:43.00000	schema
Files__Properties	Drop	Drop File Property	f	2010-11-17 10:55:43.00000	schema	2010-11-17 10:55:43.00000	schema
Files__Properties	Add	Add File Property	f	2010-11-17 10:55:43.00000	schema	2010-11-17 10:55:43.00000	schema
\.

--ROLLBACK;
COMMIT;
