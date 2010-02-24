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

CREATE TABLE ic_time_zones (
    code            VARCHAR(50) PRIMARY KEY
                        CONSTRAINT ic_time_zones_code_valid
                        CHECK (length(code) > 0 AND code = trim(code)),

    date_created    TIMESTAMP NOT NULL DEFAULT timeofday()::TIMESTAMP,
    created_by      VARCHAR(32) NOT NULL,
    last_modified   TIMESTAMP NOT NULL,
    modified_by     VARCHAR(32) NOT NULL,

    utc_offset      NUMERIC
                        CONSTRAINT ic_time_zones_utc_offset_valid
                        CHECK (utc_offset BETWEEN -24 AND 24),
    is_visible      BOOLEAN NOT NULL
);

CREATE TRIGGER ic_time_zones_last_modified
    BEFORE INSERT OR UPDATE ON ic_time_zones
    FOR EACH ROW
    EXECUTE PROCEDURE ic_update_last_modified()
;

COPY ic_time_zones (created_by, modified_by, code, utc_offset, is_visible) FROM STDIN;
schema	schema	US/Pacific	-8	t
schema	schema	US/Mountain	-7	t
schema	schema	US/Central	-6	t
schema	schema	US/Eastern	-5	t
schema	schema	Europe/Stockholm	1	t
schema	schema	America/Puerto_Rico	-5	t
\.

--ROLLBACK;
COMMIT;
