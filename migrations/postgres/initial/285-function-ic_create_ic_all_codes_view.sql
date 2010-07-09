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

CREATE FUNCTION ic_create_ic_all_codes_view()
RETURNS VOID
LANGUAGE 'plpgsql'
AS $$
DECLARE
    stmt TEXT;
    tbl RECORD;
BEGIN
    stmt := '';
    FOR tbl IN EXECUTE $SQL$
SELECT DISTINCT table_name
FROM information_schema.columns a
JOIN information_schema.columns b
USING (table_name)
JOIN information_schema.tables t
USING (table_name)
WHERE a.column_name = 'code'
AND   b.column_name = 'display_label'
AND   t.table_type  = 'BASE TABLE'
$SQL$
    LOOP
        IF (LENGTH(stmt) > 0)
        THEN
            stmt := stmt || ' UNION ';
        END IF;
        stmt := stmt || 'SELECT code, display_label, ' ||
            quote_literal(tbl.table_name) ||
            ' AS table_name FROM ' ||
            quote_ident(tbl.table_name);
    END LOOP;

    EXECUTE 'DROP VIEW IF EXISTS ic_all_codes';
    EXECUTE 'CREATE VIEW ic_all_codes AS ' || stmt;
    RETURN;
END;
$$
;

--ROLLBACK;
COMMIT;
