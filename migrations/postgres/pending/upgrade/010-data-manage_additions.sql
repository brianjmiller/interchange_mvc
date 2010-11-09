BEGIN;
SET client_min_messages='ERROR';

INSERT INTO ic_manage_classes (created_by, modified_by, code) VALUES ('schema','schema','Files__Properties');

COPY ic_manage_class_actions (created_by, modified_by, class_code, code, display_label, is_primary) FROM stdin;
schema	schema	Files__Properties	Properties	Edit File Properties Properties	f
schema	schema	Files__Properties	Drop	Drop File Property	f
schema	schema	Files__Properties	Add	Add File Property	f
\.

COPY ic_rights (created_by, modified_by, role_id, right_type_id, is_granted) FROM stdin;
schema	schema	1	3	t
\.

INSERT INTO ic_right_targets (created_by, modified_by, right_id, ref_obj_pk) (
    SELECT
        'schema',
        'schema',
        (SELECT id FROM ic_rights WHERE role_id=1 AND right_type_id=3),
        id
    FROM
        ic_manage_class_actions
    WHERE
        class_code='Files__Properties'
);

--ROLLBACK;
COMMIT;
