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

CREATE SEQUENCE ic_files_id_seq;

CREATE TABLE ic_files (
    id integer DEFAULT nextval('ic_files_id_seq'::regclass) NOT NULL PRIMARY KEY,

    date_created timestamp without time zone DEFAULT (timeofday())::timestamp without time zone NOT NULL,
    created_by character varying(32) NOT NULL,
    last_modified timestamp without time zone NOT NULL,
    modified_by character varying(32) NOT NULL,

    file_resource_id integer,
    object_pk text NOT NULL,

    CONSTRAINT ic_files_id_valid CHECK ((id > 0)),
    UNIQUE (file_resource_id, object_pk)
);

ALTER TABLE ONLY ic_files
    ADD CONSTRAINT fk_file_resource_id 
    FOREIGN KEY (file_resource_id) 
    REFERENCES ic_file_resources(id) 
    ON UPDATE CASCADE 
    ON DELETE CASCADE;

CREATE TRIGGER ic_files_last_modified
    BEFORE INSERT OR UPDATE ON ic_files
    FOR EACH ROW
    EXECUTE PROCEDURE ic_update_last_modified();

--ROLLBACK;
COMMIT;
