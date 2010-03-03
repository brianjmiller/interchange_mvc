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

CREATE TABLE ic_user_versions (
    id                          INTEGER PRIMARY KEY,

    date_created                TIMESTAMP NOT NULL DEFAULT timeofday()::TIMESTAMP,
    created_by                  VARCHAR(32) NOT NULL,
    last_modified               TIMESTAMP NOT NULL,
    modified_by                 VARCHAR(32) NOT NULL,

    display_label               VARCHAR(50) NOT NULL,

    UNIQUE (display_label)
);

CREATE TRIGGER ic_users_last_modified
    BEFORE INSERT OR UPDATE ON ic_user_versions
    FOR EACH ROW
    EXECUTE PROCEDURE ic_update_last_modified()
;

INSERT INTO ic_user_versions (id, created_by, modified_by, display_label) VALUES (1, 'schema', 'schema', '1 - Initial');

--ROLLBACK;
COMMIT;
