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

CREATE OR REPLACE FUNCTION ic_create_clean_view(table_name TEXT)
RETURNS text
LANGUAGE 'plpgsql'
AS $$
DECLARE
    column_list TEXT;
    column RECORD;
    row RECORD;
BEGIN
    column_list := '';
    FOR column IN EXECUTE 'SELECT column_name FROM information_schema.columns WHERE table_schema = ''public'' AND table_name = ' ||
        quote_literal(table_name) || ' AND column_name NOT IN (''date_created'',''created_by'',''last_modified'',''modified_by'')'
    LOOP
        IF (LENGTH(column_list) > 0)
        THEN
            column_list := column_list || ',';
        END IF;
        column_list := column_list || quote_ident(column.column_name);
    END LOOP;

    EXECUTE 'DROP VIEW IF EXISTS clean.' || quote_ident(table_name);
    EXECUTE 'CREATE VIEW clean.' || quote_ident(table_name) || ' AS SELECT ' ||
        column_list || ' FROM public.' || quote_ident(table_name);

    RETURN quote_ident(table_name);
END;
$$;

--ROLLBACK;
COMMIT;
