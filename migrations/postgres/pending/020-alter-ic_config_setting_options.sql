--
--
--
BEGIN;
SET client_min_messages='ERROR';

DROP VIEW IF EXISTS clean.ic_config_setting_options;
DROP VIEW IF EXISTS public.ic_all_codes;

ALTER TABLE ic_config_setting_options ALTER COLUMN setting_code TYPE VARCHAR(255);
ALTER TABLE ic_config_setting_options ALTER COLUMN code TYPE VARCHAR(255);
ALTER TABLE ic_config_setting_options ALTER COLUMN display_label TYPE VARCHAR(255);

SELECT ic_create_clean_view('ic_config_setting_options');
SELECT ic_create_ic_all_codes_view();

COMMIT;
--ROLLBACK;
