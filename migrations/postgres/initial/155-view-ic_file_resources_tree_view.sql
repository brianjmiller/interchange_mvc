BEGIN;
SET client_min_messages='ERROR';

CREATE VIEW file_resources_tree_view AS
    SELECT 
        tree.id, 
        tree.parent_id, 
        (tree."level" - 1) AS "level", 
        tree.branch, 
        tree.pos 
    FROM 
        connectby(
            'file_resources'::text,
            'id'::text,
            'parent_id'::text,
            'branch_order,
            lookup_value'::text,
            (1)::text,
             0,
             '~'::text
         ) tree(id integer, parent_id integer, "level" integer, branch text, pos integer)
     ORDER BY tree.pos
;

--ROLLBACK;
COMMIT;
