BEGIN;
set client_min_messages='ERROR';

CREATE TABLE ic_user_statuses (
    code            VARCHAR(30) PRIMARY KEY
                        CONSTRAINT ic_user_statuses_code_valid
                        CHECK (length(code) > 0 AND code = trim(code)),

    date_created    TIMESTAMP NOT NULL DEFAULT timeofday()::TIMESTAMP,
    created_by      VARCHAR(32) NOT NULL,
    last_modified   TIMESTAMP NOT NULL,
    modified_by     VARCHAR(32) NOT NULL,

    display_label   VARCHAR(50) NOT NULL,

    UNIQUE (display_label)
);

CREATE TRIGGER ic_users_last_modified
    BEFORE INSERT OR UPDATE ON ic_user_statuses
    FOR EACH ROW
    EXECUTE PROCEDURE update_last_modified()
;

INSERT INTO ic_user_statuses (code, created_by, modified_by, display_label) VALUES ('disabled', 'schema', 'schema', 'Disabled');
INSERT INTO ic_user_statuses (code, created_by, modified_by, display_label) VALUES ('enabled', 'schema', 'schema', 'Enabled');

--ROLLBACK;
COMMIT;
