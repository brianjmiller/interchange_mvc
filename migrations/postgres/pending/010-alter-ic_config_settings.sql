--
--
--
BEGIN;
SET client_min_messages='ERROR';

DROP VIEW IF EXISTS clean.ic_config_settings;
DROP VIEW IF EXISTS public.ic_all_codes;

ALTER TABLE ic_config_settings ALTER COLUMN code TYPE VARCHAR(255);
ALTER TABLE ic_config_settings ALTER COLUMN display_label TYPE VARCHAR(255);

SELECT ic_create_clean_view('ic_config_settings');
SELECT ic_create_ic_all_codes_view();

COMMIT;
--ROLLBACK;
