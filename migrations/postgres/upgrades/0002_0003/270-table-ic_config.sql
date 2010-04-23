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

CREATE SEQUENCE ic_config_id_seq;

CREATE TABLE ic_config (
    id                      INTEGER DEFAULT nextval('ic_config_id_seq'::regclass) NOT NULL PRIMARY KEY,

    date_created            TIMESTAMP NOT NULL DEFAULT timeofday()::TIMESTAMP,
    created_by              VARCHAR(32) NOT NULL,
    last_modified           TIMESTAMP NOT NULL,
    modified_by             VARCHAR(32) NOT NULL,

    setting_code            VARCHAR(50) NOT NULL,
    level_code              VARCHAR(30) NOT NULL,

    -- allow NULLs for global settings which won't have a reference object
    -- reference objects can be looked up based on the kind of level
    ref_obj_pk              text,

    UNIQUE(setting_code, level_code, ref_obj_pk)
);

ALTER TABLE ONLY ic_config  
    ADD CONSTRAINT fk_setting_code_level_code 
    FOREIGN KEY (setting_code, level_code) 
    REFERENCES ic_config_setting_level_map(setting_code, level_code)
    ON UPDATE CASCADE
    ON DELETE RESTRICT
;

CREATE TRIGGER ic_config_last_modified
    BEFORE INSERT OR UPDATE ON ic_config
    FOR EACH ROW
    EXECUTE PROCEDURE ic_update_last_modified();

COPY ic_config (created_by, modified_by, setting_code, level_code) FROM STDIN;
schema	schema	ic_date_display_format	global
schema	schema	ic_time_display_format	global
schema	schema	ic_date_time_order	global
\.

--ROLLBACK;
COMMIT;
