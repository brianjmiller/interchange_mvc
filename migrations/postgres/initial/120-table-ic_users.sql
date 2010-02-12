BEGIN;
set client_min_messages='ERROR';

CREATE SEQUENCE ic_users_id_seq;

CREATE TABLE ic_users (
    id                          INTEGER PRIMARY KEY DEFAULT nextval('ic_users_id_seq')
                                    CONSTRAINT ic_users_id_valid CHECK (id > -1),

    date_created                TIMESTAMP NOT NULL DEFAULT timeofday()::TIMESTAMP,
    created_by                  VARCHAR(32) NOT NULL,
    last_modified               TIMESTAMP NOT NULL,
    modified_by                 VARCHAR(32) NOT NULL,

    role_id                     INTEGER NOT NULL
                                    CONSTRAINT fk_role_id
                                    REFERENCES ic_roles(id)
                                    ON DELETE RESTRICT 
                                    ON UPDATE CASCADE,
    version_id                  INTEGER NOT NULL
                                    CONSTRAINT fk_version_id
                                    REFERENCES ic_user_versions(id)
                                    ON DELETE RESTRICT 
                                    ON UPDATE CASCADE,
    status_code                 VARCHAR(30) NOT NULL
                                    CONSTRAINT fk_status_code
                                    REFERENCES ic_user_statuses(code)
                                    ON DELETE RESTRICT
                                    ON UPDATE CASCADE,
    username                    VARCHAR(30) NOT NULL
                                    CHECK (username ~ '^[a-z]{2,}$'),
    email                       VARCHAR(100) NOT NULL,
    password                    VARCHAR(40) NOT NULL,
    password_hash_kind_code     VARCHAR(30) NOT NULL
                                    CONSTRAINT fk_password_hash_kind_code
                                    REFERENCES ic_hash_kinds(code)
                                    ON DELETE RESTRICT
                                    ON UPDATE CASCADE,
    password_expires_on         DATE,
    password_force_reset        BOOLEAN NOT NULL DEFAULT FALSE,
    password_failure_attempts   SMALLINT NOT NULL DEFAULT 0,
    time_zone_code              VARCHAR(50) NOT NULL
                                    CONSTRAINT fk_time_zone_code
                                    REFERENCES ic_time_zones(code)
                                    ON DELETE RESTRICT
                                    ON UPDATE CASCADE,

    UNIQUE (username)
);

CREATE TRIGGER ic_users_last_modified
    BEFORE INSERT OR UPDATE ON ic_users
    FOR EACH ROW
    EXECUTE PROCEDURE update_last_modified()
;

COPY ic_users (created_by, modified_by, id, username, role_id, version_id, status_code, time_zone_code, email, password_hash_kind_code, password) FROM STDIN;
schema	schema	0	guest	2	1	disabled	US/Eastern	nouser@domain.com	sha1	NOPASS-GUEST
schema	schema	1	root	3	1	enabled	US/Eastern	root@domain.com	sha1	57d1355bc06c95c737aa5c5653fb48056e189f44
\.

SELECT setval('ic_users_id_seq', max(id)) FROM ic_users;

--ROLLBACK;
COMMIT;
