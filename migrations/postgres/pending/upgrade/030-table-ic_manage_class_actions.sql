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

--ROLLBACK;
COMMIT;
