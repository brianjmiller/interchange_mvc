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

CREATE SEQUENCE ic_config_setting_options_id_seq;

CREATE TABLE ic_config_setting_options (
    id                      INTEGER DEFAULT nextval('ic_config_setting_options_id_seq'::regclass) NOT NULL PRIMARY KEY,

    date_created            TIMESTAMP NOT NULL DEFAULT timeofday()::TIMESTAMP,
    created_by              VARCHAR(32) NOT NULL,
    last_modified           TIMESTAMP NOT NULL,
    modified_by             VARCHAR(32) NOT NULL,

    setting_code            VARCHAR(255) NOT NULL
                                CONSTRAINT fk_setting_code
                                REFERENCES ic_config_settings(code)
                                ON DELETE RESTRICT
                                ON UPDATE CASCADE,

    -- allow NULLs for options that are available at all levels
    level_code              VARCHAR(30)
                                CONSTRAINT fk_level_code
                                REFERENCES ic_config_levels(code)
                                ON DELETE RESTRICT
                                ON UPDATE CASCADE,
    code                    VARCHAR(255) NOT NULL,
    display_label           VARCHAR(255) NOT NULL,
    is_default              BOOLEAN NOT NULL,
    sort_order              INTEGER,

    UNIQUE(setting_code, level_code, code),
    UNIQUE(display_label)
);

CREATE TRIGGER ic_config_setting_options_last_modified
    BEFORE INSERT OR UPDATE ON ic_config_setting_options
    FOR EACH ROW
    EXECUTE PROCEDURE ic_update_last_modified();

COPY ic_config_setting_options (created_by, modified_by, setting_code, level_code, code, display_label, is_default) FROM STDIN;
schema	schema	ic_date_display_format	global	%Y-%m-%d	2003-03-30	t
schema	schema	ic_date_display_format	global	%L/%e/%Y	3/30/2003	f
schema	schema	ic_date_display_format	global	%A, %B %o %Y	Thursday, March 30th 2003	f
schema	schema	ic_date_display_format	global	%a, %b %e %Y	Thu, Mar 30 2003	f
schema	schema	ic_date_display_format	global	%e %b %Y	30 Mar 2003	f
schema	schema	ic_date_display_format	global	%a, %e-%b-%Y	Thu, 30-Mar-2003	f
schema	schema	ic_time_display_format	global	%T	15:30:00	t
schema	schema	ic_time_display_format	global	%k:%M	15:30	f
schema	schema	ic_time_display_format	global	%l:%M%P	3:30pm	f
schema	schema	ic_date_time_order	global	1	Date then Time	t
schema	schema	ic_date_time_order	global	0	Time then Date	f
\.

--ROLLBACK;
COMMIT;
