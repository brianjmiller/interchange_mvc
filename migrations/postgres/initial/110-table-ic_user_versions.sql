BEGIN;
set client_min_messages='ERROR';

CREATE TABLE ic_user_versions (
    id                          INTEGER PRIMARY KEY,

    date_created                TIMESTAMP NOT NULL DEFAULT timeofday()::TIMESTAMP,
    created_by                  VARCHAR(32) NOT NULL,
    last_modified               TIMESTAMP NOT NULL,
    modified_by                 VARCHAR(32) NOT NULL,

    display_label               VARCHAR(50) NOT NULL,

    UNIQUE (display_label)
);

CREATE TRIGGER ic_users_last_modified
    BEFORE INSERT OR UPDATE ON ic_user_versions
    FOR EACH ROW
    EXECUTE PROCEDURE update_last_modified()
;

INSERT INTO ic_user_versions (id, created_by, modified_by, display_label) VALUES (1, 'schema', 'schema', '1 - Initial');

--ROLLBACK;
COMMIT;
