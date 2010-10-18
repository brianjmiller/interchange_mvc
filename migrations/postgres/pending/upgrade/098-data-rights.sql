BEGIN;
SET client_min_messages='ERROR';

UPDATE
    ic_right_types
SET
    display_label = 'Execute: Site Management Action',
    description   = 'Determines right to execute site management action',
    modified_by   = 'schema'
WHERE
    code             = 'execute'
    AND
    target_kind_code = 'site_mgmt_func'
;

UPDATE
    ic_right_type_target_kinds
SET
    code          = 'site_mgmt_action',
    display_label = 'Site Mgmt Action',
    model_class   = 'IC::M::ManageClass::Action',
    relation_name = 'ic_manage_class_actions',
    modified_by   = 'schema'
WHERE
    code = 'site_mgmt_func'
;

--ROLLBACK;
COMMIT;
