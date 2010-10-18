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

CREATE SEQUENCE ic_manage_menu_items_id_seq;

CREATE TABLE ic_manage_menu_items (
    id                              integer DEFAULT nextval('ic_manage_menu_items_id_seq'::regclass) NOT NULL PRIMARY KEY,

    date_created                    timestamp without time zone DEFAULT (timeofday())::timestamp without time zone NOT NULL,
    created_by                      character varying(32) NOT NULL,
    last_modified                   timestamp without time zone NOT NULL,
    modified_by                     character varying(32) NOT NULL,

    parent_id                       integer,
    branch_order                    integer,
    lookup_value                    character varying(70) NOT NULL,
    manage_class_action_id          integer
                                        CONSTRAINT fk_manage_class_action_id
                                        REFERENCES ic_manage_class_actions(id)
                                        ON DELETE RESTRICT
                                        ON UPDATE CASCADE,
    manage_class_action_addtl_args  character varying(255),

    CONSTRAINT manage_menu_items_id_valid CHECK ((id > 0)),
    CONSTRAINT manage_menu_items_lookup_value_valid CHECK (((length((lookup_value)::text) > 0) AND ((lookup_value)::text = btrim((lookup_value)::text))))
);

CREATE TRIGGER ic_manage_menu_items_last_modified
    BEFORE INSERT OR UPDATE ON ic_manage_menu_items
    FOR EACH ROW
    EXECUTE PROCEDURE ic_update_last_modified();

CREATE UNIQUE INDEX ic_manage_menu_items_parent_id_lookup_value_unique 
    ON ic_manage_menu_items 
    USING btree (parent_id, regexp_replace(lower((lookup_value)::text), 'W+'::text, ''::text));

COPY ic_manage_menu_items (id, created_by, modified_by, parent_id, branch_order, lookup_value) FROM stdin;
1	schema	schema	\N	\N	**Artificial Top Node**
\.

SELECT pg_catalog.setval('ic_manage_menu_items_id_seq', (SELECT MAX(id) FROM ic_manage_menu_items), true);

--ROLLBACK;
COMMIT;
