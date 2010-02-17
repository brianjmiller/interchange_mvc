BEGIN;
set client_min_messages='ERROR';

CREATE TABLE ic_hash_kinds (
    code            VARCHAR(30) PRIMARY KEY
                        CONSTRAINT ic_hash_kinds_code_valid
                        CHECK (length(code) > 0 AND code = trim(code)),

    date_created    TIMESTAMP NOT NULL DEFAULT timeofday()::TIMESTAMP,
    created_by      VARCHAR(32) NOT NULL,
    last_modified   TIMESTAMP NOT NULL,
    modified_by     VARCHAR(32) NOT NULL,

    display_label   VARCHAR(100) NOT NULL,

    UNIQUE(display_label)
);

CREATE TRIGGER ic_hash_kinds_last_modified
    BEFORE INSERT OR UPDATE ON ic_hash_kinds
    FOR EACH ROW
    EXECUTE PROCEDURE ic_update_last_modified()
;

COPY ic_hash_kinds (created_by, modified_by, code, display_label) FROM STDIN;
schema	schema	pass_through	Pass Through (No hashing)
schema	schema	md5	MD5
schema	schema	sha1	SHA-1
\.

--ROLLBACK;
COMMIT;
