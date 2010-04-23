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

CREATE SEQUENCE ic_config_values_id_seq;

CREATE TABLE ic_config_values (
    id                      INTEGER DEFAULT nextval('ic_config_values_id_seq'::regclass) NOT NULL PRIMARY KEY,

    date_created            TIMESTAMP NOT NULL DEFAULT timeofday()::TIMESTAMP,
    created_by              VARCHAR(32) NOT NULL,
    last_modified           TIMESTAMP NOT NULL,
    modified_by             VARCHAR(32) NOT NULL,

    config_id               INTEGER NOT NULL
                                CONSTRAINT fk_config_id
                                REFERENCES ic_config(id)
                                ON DELETE RESTRICT
                                ON UPDATE CASCADE,
    option_id               INTEGER NOT NULL
                                CONSTRAINT fk_option_id
                                REFERENCES ic_config_setting_options(id)
                                ON DELETE RESTRICT
                                ON UPDATE CASCADE
);

CREATE TRIGGER ic_config_values_last_modified
    BEFORE INSERT OR UPDATE ON ic_config_values
    FOR EACH ROW
    EXECUTE PROCEDURE ic_update_last_modified();

INSERT INTO ic_config_values (created_by, modified_by, config_id, option_id) VALUES (
    'schema', 'schema',
    (SELECT id FROM ic_config WHERE setting_code='ic_date_display_format' AND level_code='global'),
    (SELECT id FROM ic_config_setting_options WHERE setting_code='ic_date_display_format' AND level_code='global' AND is_default IS TRUE)
);

INSERT INTO ic_config_values (created_by, modified_by, config_id, option_id) VALUES (
    'schema', 'schema',
    (SELECT id FROM ic_config WHERE setting_code='ic_time_display_format' AND level_code='global'),
    (SELECT id FROM ic_config_setting_options WHERE setting_code='ic_time_display_format' AND level_code='global' AND is_default IS TRUE)
);

INSERT INTO ic_config_values (created_by, modified_by, config_id, option_id) VALUES (
    'schema', 'schema',
    (SELECT id FROM ic_config WHERE setting_code='ic_date_time_order' AND level_code='global'),
    (SELECT id FROM ic_config_setting_options WHERE setting_code='ic_date_time_order' AND level_code='global' AND is_default IS TRUE)
);

--ROLLBACK;
COMMIT;
