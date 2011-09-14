BEGIN;
SET client_min_messages='ERROR';

ALTER TABLE ic_manage_class_actions DROP CONSTRAINT ic_manage_class_actions_display_label_key;
ALTER TABLE ic_manage_class_actions ADD CONSTRAINT ic_manage_class_actions_display_label_key UNIQUE(class_code, display_label);

UPDATE ic_manage_class_actions SET display_label='Details' WHERE code = 'DetailView';
UPDATE ic_manage_class_actions SET display_label='Add' WHERE code = 'Add';
UPDATE ic_manage_class_actions SET display_label='Drop' WHERE code = 'Drop';
UPDATE ic_manage_class_actions SET display_label='Properties' WHERE code = 'Properties';
UPDATE ic_manage_class_actions SET display_label='List' WHERE code = 'List';

--ROLLBACK;
COMMIT;
