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

CREATE TABLE ic_config_setting_level_map (
    setting_code            VARCHAR(50) NOT NULL
                                CONSTRAINT fk_setting_code
                                REFERENCES ic_config_settings(code)
                                ON DELETE RESTRICT
                                ON UPDATE CASCADE,

    level_code              VARCHAR(30) NOT NULL
                                CONSTRAINT fk_level_code
                                REFERENCES ic_config_levels(code)
                                ON DELETE RESTRICT
                                ON UPDATE CASCADE,

    date_created            TIMESTAMP NOT NULL DEFAULT timeofday()::TIMESTAMP,
    created_by              VARCHAR(32) NOT NULL,
    last_modified           TIMESTAMP NOT NULL,
    modified_by             VARCHAR(32) NOT NULL,

    PRIMARY KEY (setting_code, level_code)
);

CREATE TRIGGER ic_config_setting_level_map_last_modified
    BEFORE INSERT OR UPDATE ON ic_config_setting_level_map
    FOR EACH ROW
    EXECUTE PROCEDURE ic_update_last_modified()
;

COPY ic_config_setting_level_map (created_by, modified_by, setting_code, level_code) FROM STDIN;
schema	schema	ic_mailing_default_email	global
schema	schema	ic_mailing_default_name	global
schema	schema	ic_mailing_default_subject_prefix	global
schema	schema	ic_date_display_format	global
schema	schema	ic_date_display_format	user
schema	schema	ic_time_display_format	global
schema	schema	ic_time_display_format	user
schema	schema	ic_date_time_order	global
schema	schema	ic_date_time_order	user
\.

--ROLLBACK;
COMMIT;
