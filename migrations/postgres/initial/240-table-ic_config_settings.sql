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

CREATE TABLE ic_config_settings (
    code                        VARCHAR(255) PRIMARY KEY
                                    CONSTRAINT ic_config_settings_code_valid
                                    CHECK (length(code) > 0 AND code = trim(code)),

    date_created                TIMESTAMP NOT NULL DEFAULT timeofday()::TIMESTAMP,
    created_by                  VARCHAR(32) NOT NULL,
    last_modified               TIMESTAMP NOT NULL,
    modified_by                 VARCHAR(32) NOT NULL,

    display_label               VARCHAR(255) NOT NULL
                                    CONSTRAINT ic_config_settings_display_label_valid
                                    CHECK (length(display_label) > 0 AND display_label = trim(display_label)),
    should_cascade              BOOLEAN NOT NULL,
    should_combine              BOOLEAN NOT NULL,
    is_web_editable             BOOLEAN NOT NULL,

    interface_input_kind_code   VARCHAR(30) NOT NULL
                                    CONSTRAINT fk_interface_kind_code
                                    REFERENCES ic_config_interface_input_kinds(code)
                                    ON DELETE RESTRICT
                                    ON UPDATE CASCADE,

    -- allow NULLs for non-web editable settings
    interface_node_id           INTEGER
                                    CONSTRAINT fk_interface_node_id
                                    REFERENCES ic_config_interface_structure(id)
                                    ON DELETE RESTRICT
                                    ON UPDATE CASCADE,

    UNIQUE (display_label)
);

CREATE TRIGGER ic_config_settings_last_modified
    BEFORE INSERT OR UPDATE ON ic_config_settings
    FOR EACH ROW
    EXECUTE PROCEDURE ic_update_last_modified()
;

COPY ic_config_settings (created_by, modified_by, code, display_label, should_cascade, should_combine, is_web_editable, interface_input_kind_code, interface_node_id) FROM STDIN;
schema	schema	ic_mailing_default_email	Default E-mail Address on Mailings	0	0	1	text_entry	2
schema	schema	ic_mailing_default_name	Default Name on Mailings	0	0	1	text_entry	2
schema	schema	ic_mailing_default_subject_prefix	Default Subject Prefix on Mailings	0	0	1	text_entry	2
schema	schema	ic_date_display_format	Format for Display of Date	1	0	1	select_single	1
schema	schema	ic_time_display_format	Format for Display of Times	1	0	1	select_single	1
schema	schema	ic_date_time_order	Date + Time Order	1	0	1	radio	1
\.

--ROLLBACK;
COMMIT;
