    --Проверить, был ли запрос по такому репозиторию
    CREATE OR REPLACE PROCEDURE is_was_repository_request
    (
        p_git_id IN NUMBER,
        p_count_of_rows OUT NUMBER
    )
    AS
    BEGIN
        IF p_git_id IS NULL THEN
            RAISE_APPLICATION_ERROR(-20030, 'git_id не может быть NULL');
        END IF;

        SELECT COUNT(*) INTO p_count_of_rows 
        FROM REPOSITORIES 
        WHERE git_id = p_git_id;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            p_count_of_rows := 0;
        WHEN OTHERS THEN
            IF SQLCODE = -20030 THEN
                RAISE;
            ELSE
                RAISE_APPLICATION_ERROR(-20031, 'Ошибка при проверке репозитория: ' || SQLERRM);
            END IF;
    END;

    DROP PROCEDURE is_was_repository_request;

    --Добавить репозиторий в историю
    CREATE OR REPLACE PROCEDURE add_repository_to_history
    (
        p_git_id VARCHAR2,
        p_name VARCHAR2,
        p_owner_git_id NUMBER,
        p_html_url VARCHAR2,
        p_description VARCHAR2,
        p_repo_size NUMBER,
        p_stars NUMBER,
        p_forks NUMBER,
        p_default_branch VARCHAR2,
        p_open_issues NUMBER,
        p_subscribers_count VARCHAR2,
        p_created_at TIMESTAMP,
        p_updated_at TIMESTAMP,
        p_pushed_at TIMESTAMP
    )
    AS
        v_git_id NUMBER;
        v_subscribers_count NUMBER;
        v_owner_git_id NUMBER;
    BEGIN
        IF p_git_id IS NULL THEN
            RAISE_APPLICATION_ERROR(-20032, 'git_id не может быть NULL');
        END IF;

        IF p_name IS NULL THEN
            RAISE_APPLICATION_ERROR(-20033, 'name не может быть NULL');
        END IF;

        IF p_owner_git_id IS NULL THEN
            RAISE_APPLICATION_ERROR(-20034, 'owner_git_id не может быть NULL');
        END IF;

        v_git_id := TO_NUMBER(p_git_id);
        v_subscribers_count := TO_NUMBER(p_subscribers_count);
        v_owner_git_id := TO_NUMBER(p_owner_git_id);

        INSERT INTO REPOSITORIES
        (
            git_id,
            name,
            owner_git_id,
            html_url,
            description,
            repo_size,
            stars,
            forks,
            default_branch,
            open_issues,
            subscribers_count,
            created_at,
            updated_at,
            pushed_at
        )
        VALUES (
            v_git_id,
            p_name,
            v_owner_git_id,
            p_html_url,
            p_description,
            p_repo_size,
            p_stars,
            p_forks,
            p_default_branch,
            p_open_issues,
            v_subscribers_count,
            p_created_at,
            p_updated_at,
            p_pushed_at
        );
    EXCEPTION
        WHEN DUP_VAL_ON_INDEX THEN
            RAISE_APPLICATION_ERROR(-20035, 'Репозиторий с git_id ' || v_git_id || ' уже существует');
        WHEN VALUE_ERROR THEN
            RAISE_APPLICATION_ERROR(-20036, 'Ошибка преобразования типов данных');
        WHEN OTHERS THEN
            IF SQLCODE BETWEEN -20034 AND -20032 THEN
                RAISE;
            ELSE
                RAISE_APPLICATION_ERROR(-20037, 'Ошибка при добавлении репозитория: ' || SQLERRM);
            END IF;
    END;   
    
    DROP PROCEDURE add_repository_to_history;

    --Обновить репозиторий в истории
    CREATE OR REPLACE PROCEDURE update_repository_in_history
    (
        p_git_id VARCHAR2,
        p_name VARCHAR2,
        p_html_url VARCHAR2,
        p_description VARCHAR2,
        p_repo_size NUMBER,
        p_stars NUMBER,
        p_forks NUMBER,
        p_default_branch VARCHAR2,
        p_open_issues NUMBER,
        p_subscribers_count VARCHAR2,
        p_updated_at TIMESTAMP,
        p_pushed_at TIMESTAMP
    )
    AS
        v_git_id NUMBER;
        v_subscribers_count NUMBER;
        v_rows_updated NUMBER;
    BEGIN
        IF p_git_id IS NULL THEN
            RAISE_APPLICATION_ERROR(-20038, 'git_id не может быть NULL');
        END IF;

        v_git_id := TO_NUMBER(p_git_id);
        v_subscribers_count := TO_NUMBER(p_subscribers_count);

        UPDATE REPOSITORIES SET
            NAME = p_name,
            html_url = p_html_url,
            description = p_description,
            repo_size = p_repo_size,
            stars = p_stars,
            forks = p_forks,
            default_branch = p_default_branch,
            open_issues = p_open_issues,
            subscribers_count = v_subscribers_count,
            updated_at = p_updated_at,
            pushed_at = p_pushed_at
        WHERE GIT_ID = v_git_id;

        v_rows_updated := SQL%ROWCOUNT;

        IF v_rows_updated = 0 THEN
            RAISE_APPLICATION_ERROR(-20039, 'Репозиторий с git_id ' || v_git_id || ' не найден');
        END IF;
    EXCEPTION
        WHEN VALUE_ERROR THEN
            RAISE_APPLICATION_ERROR(-20040, 'Ошибка преобразования типов данных');
        WHEN OTHERS THEN
            IF SQLCODE BETWEEN -20039 AND -20038 THEN
                RAISE;
            ELSE
                RAISE_APPLICATION_ERROR(-20041, 'Ошибка при изменении репозитория: ' || SQLERRM);
            END IF;
    END;
    
    DROP PROCEDURE update_repository_in_history;
    
    --Добавить язык для репозитория в историю
    CREATE OR REPLACE PROCEDURE add_repository_language
    (
        p_repository_id NUMBER,
        p_language VARCHAR2,
        p_bytes_count NUMBER
    )
    AS
    BEGIN
        IF p_repository_id IS NULL THEN
            RAISE_APPLICATION_ERROR(-20042, 'repository_id не может быть NULL');
        END IF;

        IF p_language IS NULL THEN
            RAISE_APPLICATION_ERROR(-20043, 'language не может быть NULL');
        END IF;

        INSERT INTO REPOSITORY_LANGUAGES
        (
            repository_id,
            language,
            bytes_count
        )
        VALUES
        (
            p_repository_id,
            p_language,
            p_bytes_count
        );
    EXCEPTION
        WHEN DUP_VAL_ON_INDEX THEN
            RAISE_APPLICATION_ERROR(-20044, 'Язык ' || p_language || ' уже существует для репозитория ' || p_repository_id);
        WHEN OTHERS THEN
            IF SQLCODE BETWEEN -20043 AND -20042 THEN
                RAISE;
            ELSE
                RAISE_APPLICATION_ERROR(-20045, 'Ошибка при добавлении языка: ' || SQLERRM);
            END IF;
    END;

    DROP PROCEDURE add_repository_language;

    CREATE OR REPLACE PROCEDURE clear_repository_languages
    (
        p_repository_id VARCHAR2
    )
    AS
        v_repository_id NUMBER;
    BEGIN
        IF p_repository_id IS NULL THEN
            RAISE_APPLICATION_ERROR(-20046, 'repository_id не может быть NULL');
        END IF;

        v_repository_id := TO_NUMBER(p_repository_id);

        DELETE FROM REPOSITORY_LANGUAGES 
        WHERE REPOSITORY_ID = v_repository_id;
    EXCEPTION
        WHEN VALUE_ERROR THEN
            RAISE_APPLICATION_ERROR(-20047, 'Ошибка преобразования repository_id');
        WHEN OTHERS THEN
            IF SQLCODE BETWEEN -20047 AND -20046 THEN
                RAISE;
            ELSE
                RAISE_APPLICATION_ERROR(-20048, 'Ошибка при удалении языков: ' || SQLERRM);
            END IF;
    END;

    DROP PROCEDURE clear_repository_languages;

    --Добавить тему репозиторию
    CREATE OR REPLACE PROCEDURE add_repository_topic
    (
        p_repository_id NUMBER,
        p_topic VARCHAR2
    )
    AS
    BEGIN
        IF p_repository_id IS NULL THEN
            RAISE_APPLICATION_ERROR(-20049, 'repository_id не может быть NULL');
        END IF;

        IF p_topic IS NULL THEN
            RAISE_APPLICATION_ERROR(-20050, 'topic не может быть NULL');
        END IF;

        INSERT INTO REPOSITORY_TOPICS
        (
            repository_id,
            topic
        )
        VALUES
        (
            p_repository_id,
            p_topic
        );
    EXCEPTION
        WHEN DUP_VAL_ON_INDEX THEN
            RAISE_APPLICATION_ERROR(-20051, 'Тема ' || p_topic || ' уже существует для репозитория ' || p_repository_id);
        WHEN OTHERS THEN
            IF SQLCODE BETWEEN -20050 AND -20049 THEN
                RAISE;
            ELSE
                RAISE_APPLICATION_ERROR(-20052, 'Ошибка при добавлении темы: ' || SQLERRM);
            END IF;
    END;

    --Очистить все темы репозитория
    CREATE OR REPLACE PROCEDURE clear_repository_topics
    (
        p_repository_id NUMBER
    )
    AS
    BEGIN
        IF p_repository_id IS NULL THEN
            RAISE_APPLICATION_ERROR(-20053, 'repository_id не может быть NULL');
        END IF;
    
        DELETE FROM REPOSITORY_TOPICS 
        WHERE REPOSITORY_ID = p_repository_id;
    EXCEPTION
        WHEN OTHERS THEN
            IF SQLCODE = -20053 THEN
                RAISE;
            ELSE
                RAISE_APPLICATION_ERROR(-20054, 'Ошибка при удалении тем: ' || SQLERRM);
            END IF;
    END;

    --Добавить лицензию репозитория
    CREATE OR REPLACE PROCEDURE add_repository_license
    (
        p_repository_id NUMBER,
        p_license_name VARCHAR2,
        p_spdx_id VARCHAR2
    )
    AS
    BEGIN
        IF p_repository_id IS NULL THEN
            RAISE_APPLICATION_ERROR(-20055, 'repository_id не может быть NULL');
        END IF;
    
        INSERT INTO REPOSITORY_LICENSES
        (
            repository_id,
            license_name,
            spdx_id
        )
        VALUES
        (
            p_repository_id,
            p_license_name,
            p_spdx_id
        );
    EXCEPTION
        WHEN DUP_VAL_ON_INDEX THEN
            RAISE_APPLICATION_ERROR(-20056, 'Лицензия уже существует для репозитория ' || p_repository_id);
        WHEN OTHERS THEN
            IF SQLCODE = -20055 THEN
                RAISE;
            ELSE
                RAISE_APPLICATION_ERROR(-20057, 'Ошибка при добавлении лицензии: ' || SQLERRM);
            END IF;
    END;

    DROP PROCEDURE add_repository_license;

    --Обновить лицензию репозиторию
    CREATE OR REPLACE PROCEDURE add_or_update_repository_license
    (
        repository_id NUMBER,
        license_name VARCHAR2,
        spdx_id VARCHAR2
    )
    AS
    BEGIN
        IF repository_id IS NULL THEN
            RAISE_APPLICATION_ERROR(-20058, 'repository_id не может быть NULL');
        END IF;

        MERGE INTO REPOSITORY_LICENSES c
        USING (
            SELECT
                repository_id AS repository_id,
                license_name AS license_name,
                spdx_id AS spdx_id
            FROM DUAL
        ) src
        ON (c.repository_id = src.repository_id)
        WHEN MATCHED THEN
            UPDATE SET
                c.license_name = src.license_name,
                c.spdx_id = src.spdx_id
        WHEN NOT MATCHED THEN
            INSERT (repository_id, license_name, spdx_id)
            VALUES (src.repository_id, src.license_name, src.spdx_id);
    EXCEPTION
        WHEN OTHERS THEN
            IF SQLCODE = -20058 THEN
                RAISE;
            ELSE
                RAISE_APPLICATION_ERROR(-20059, 'Ошибка при добавлении/обновлении лицензии репозитория: ' || SQLERRM);
            END IF;
    END;

    DROP PROCEDURE add_or_update_repository_license;

    --Удалить лицензию репозиторию
    CREATE OR REPLACE PROCEDURE delete_repository_license
    (
        p_repository_id NUMBER
    )
    AS
    BEGIN
        IF p_repository_id IS NULL THEN
            RAISE_APPLICATION_ERROR(-20060, 'repository_id не может быть NULL');
        END IF;

        DELETE FROM REPOSITORY_LICENSES 
        WHERE repository_id = p_repository_id;
    EXCEPTION
        WHEN OTHERS THEN
            IF SQLCODE = -20060 THEN
                RAISE;
            ELSE
                RAISE_APPLICATION_ERROR(-20061, 'Ошибка при удалении лицензии репозитория: ' || SQLERRM);
            END IF;
    END;

    --Добавить коммит в историю
    CREATE OR REPLACE PROCEDURE add_commit
    (
        p_repository_id IN NUMBER,
        p_sha IN VARCHAR2,
        p_author_login IN VARCHAR2,
        p_author_avatar_url IN VARCHAR2,
        p_commit_date IN TIMESTAMP,
        p_url IN VARCHAR2
    )
    AS
    BEGIN
        IF p_repository_id IS NULL THEN
            RAISE_APPLICATION_ERROR(-20062, 'repository_id не может быть NULL');
        END IF;

        IF p_sha IS NULL THEN
            RAISE_APPLICATION_ERROR(-20063, 'sha не может быть NULL');
        END IF;

        INSERT INTO COMMITS (repository_id, sha, author_login, author_avatar_url, commit_date, url)
        VALUES (p_repository_id, p_sha, p_author_login, p_author_avatar_url, p_commit_date, p_url);
    EXCEPTION
        WHEN DUP_VAL_ON_INDEX THEN
            NULL;
        WHEN OTHERS THEN
            IF SQLCODE BETWEEN -20063 AND -20062 THEN
                RAISE;
            ELSE
                RAISE_APPLICATION_ERROR(-20064, 'Ошибка при добавлении коммита: ' || SQLERRM);
            END IF;
    END;

    --Получить репозиторий по id
    CREATE OR REPLACE PROCEDURE get_repository_by_id
    (
        p_repository_id IN VARCHAR,
        user_cursor OUT SYS_REFCURSOR
    )
    AS
        v_repository_id NUMBER;
    BEGIN
        IF p_repository_id IS NULL THEN
            RAISE_APPLICATION_ERROR(-20065, 'repository_id не может быть NULL');
        END IF;
    
        v_repository_id := TO_NUMBER(p_repository_id);
    
        OPEN user_cursor FOR
        SELECT 
            r.*, 
            p.login AS owner_login,
            p.avatar_url AS owner_avatar_url,
            h.REQUEST_TIME
        FROM REPOSITORIES r
        INNER JOIN PROFILES p ON r.owner_git_id = p.git_id
        LEFT JOIN REQUEST_HISTORY h ON r.git_id = h.repository_id
        WHERE r.GIT_ID = v_repository_id
        AND (h.REQUEST_TIME IS NULL OR NOT EXISTS (
            SELECT 1 
            FROM REQUEST_HISTORY h2
            WHERE h2.REPOSITORY_ID = h.REPOSITORY_ID
            AND h2.REQUEST_TIME > h.REQUEST_TIME
        ));
    EXCEPTION
        WHEN VALUE_ERROR THEN
            IF user_cursor%ISOPEN THEN
                CLOSE user_cursor;
            END IF;
            RAISE_APPLICATION_ERROR(-20066, 'Ошибка преобразования repository_id');
        WHEN OTHERS THEN
            IF user_cursor%ISOPEN THEN
                CLOSE user_cursor;
            END IF;
            IF SQLCODE BETWEEN -20066 AND -20065 THEN
                RAISE;
            ELSE
                RAISE_APPLICATION_ERROR(-20067, 'Ошибка при получении репозитория по ID: ' || SQLERRM);
            END IF;
    END;

    --Получить языки репозитория
    CREATE OR REPLACE PROCEDURE get_repository_languages
    (
        p_repository_id IN VARCHAR2,
        user_cursor OUT SYS_REFCURSOR
    )
    AS
        v_repository_id NUMBER;
    BEGIN
        IF p_repository_id IS NULL THEN
            RAISE_APPLICATION_ERROR(-20068, 'repository_id не может быть NULL');
        END IF;

        v_repository_id := TO_NUMBER(p_repository_id);

        OPEN user_cursor FOR
        SELECT language, bytes_count 
        FROM REPOSITORY_LANGUAGES 
        WHERE repository_id = v_repository_id;
    EXCEPTION
        WHEN VALUE_ERROR THEN
            IF user_cursor%ISOPEN THEN
                CLOSE user_cursor;
            END IF;
            RAISE_APPLICATION_ERROR(-20069, 'Ошибка преобразования repository_id');
        WHEN OTHERS THEN
            IF user_cursor%ISOPEN THEN
                CLOSE user_cursor;
            END IF;
            IF SQLCODE BETWEEN -20069 AND -20068 THEN
                RAISE;
            ELSE
                RAISE_APPLICATION_ERROR(-20070, 'Ошибка при получении языков репозитория: ' || SQLERRM);
            END IF;
    END;

    --Получить темы репозитория
    CREATE OR REPLACE PROCEDURE get_repository_topics
    (
        p_repository_id IN VARCHAR,
        user_cursor OUT SYS_REFCURSOR
    )
    AS
        v_repository_id NUMBER;
    BEGIN
        IF p_repository_id IS NULL THEN
            RAISE_APPLICATION_ERROR(-20071, 'repository_id не может быть NULL');
        END IF;
    
        v_repository_id := TO_NUMBER(p_repository_id);
    
        OPEN user_cursor FOR
        SELECT topic 
        FROM REPOSITORY_TOPICS 
        WHERE repository_id = v_repository_id;
    EXCEPTION
        WHEN VALUE_ERROR THEN
            IF user_cursor%ISOPEN THEN
                CLOSE user_cursor;
            END IF;
            RAISE_APPLICATION_ERROR(-20072, 'Ошибка преобразования repository_id');
        WHEN OTHERS THEN
            IF user_cursor%ISOPEN THEN
                CLOSE user_cursor;
            END IF;
            IF SQLCODE BETWEEN -20072 AND -20071 THEN
                RAISE;
            ELSE
                RAISE_APPLICATION_ERROR(-20073, 'Ошибка при получении тем репозитория: ' || SQLERRM);
            END IF;
    END;

    --Получить лицензию репозитория
    CREATE OR REPLACE PROCEDURE get_repository_license
    (
        p_repository_id IN VARCHAR,
        user_cursor OUT SYS_REFCURSOR
    )
    AS
        v_repository_id NUMBER;
    BEGIN
        IF p_repository_id IS NULL THEN
            RAISE_APPLICATION_ERROR(-20074, 'repository_id не может быть NULL');
        END IF;

        v_repository_id := TO_NUMBER(p_repository_id);

        OPEN user_cursor FOR
        SELECT license_name, spdx_id 
        FROM REPOSITORY_LICENSES 
        WHERE repository_id = v_repository_id;
    EXCEPTION
        WHEN VALUE_ERROR THEN
            IF user_cursor%ISOPEN THEN
                CLOSE user_cursor;
            END IF;
            RAISE_APPLICATION_ERROR(-20075, 'Ошибка преобразования repository_id');
        WHEN OTHERS THEN
            IF user_cursor%ISOPEN THEN
                CLOSE user_cursor;
            END IF;
            IF SQLCODE BETWEEN -20075 AND -20074 THEN
                RAISE;
            ELSE
                RAISE_APPLICATION_ERROR(-20076, 'Ошибка при получении лицензии репозитория: ' || SQLERRM);
            END IF;
    END;
    
    --Получить коммиты репозитория
    CREATE OR REPLACE PROCEDURE get_repository_commits
    (
        p_repository_id IN VARCHAR,
        user_cursor OUT SYS_REFCURSOR
    )
    AS
        v_repository_id NUMBER;
    BEGIN
        IF p_repository_id IS NULL THEN
            RAISE_APPLICATION_ERROR(-20077, 'repository_id не может быть NULL');
        END IF;
    
        v_repository_id := TO_NUMBER(p_repository_id);
    
        OPEN user_cursor FOR
        SELECT sha, author_login, author_avatar_url, commit_date, url 
        FROM COMMITS 
        WHERE repository_id = v_repository_id;
    EXCEPTION
        WHEN VALUE_ERROR THEN
            IF user_cursor%ISOPEN THEN
                CLOSE user_cursor;
            END IF;
            RAISE_APPLICATION_ERROR(-20078, 'Ошибка преобразования repository_id');
        WHEN OTHERS THEN
            IF user_cursor%ISOPEN THEN
                CLOSE user_cursor;
            END IF;
            IF SQLCODE BETWEEN -20078 AND -20077 THEN
                RAISE;
            ELSE
                RAISE_APPLICATION_ERROR(-20079, 'Ошибка при получении коммитов репозитория: ' || SQLERRM);
            END IF;
    END;

    --Проверить, есть ли информация по репозиторию в базе данных
    CREATE OR REPLACE PROCEDURE is_repository_info_exist
    (
        p_owner_login IN VARCHAR2,
        p_repository_name IN VARCHAR2,
        rows_count OUT NUMBER
    )
    AS
    BEGIN
        IF p_owner_login IS NULL THEN
            RAISE_APPLICATION_ERROR(-20080, 'owner_login не может быть NULL');
        END IF;

        IF p_repository_name IS NULL THEN
            RAISE_APPLICATION_ERROR(-20081, 'repository_name не может быть NULL');
        END IF;

        SELECT COUNT(*) 
        INTO rows_count 
        FROM REPOSITORIES r
        INNER JOIN PROFILES p ON r.owner_git_id = p.git_id
        WHERE UPPER(p.login) = UPPER(p_owner_login) 
        AND UPPER(r.name) = UPPER(p_repository_name);
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            rows_count := 0;
        WHEN OTHERS THEN
            IF SQLCODE BETWEEN -20081 AND -20080 THEN
                RAISE;
            ELSE
                RAISE_APPLICATION_ERROR(-20082, 'Ошибка при проверке репозитория: ' || SQLERRM);
            END IF;
    END;

    CREATE OR REPLACE PROCEDURE get_repository_by_owner_and_name
    (
        p_owner_login IN VARCHAR2,
        p_repo_name IN VARCHAR2,
        user_cursor OUT SYS_REFCURSOR
    )
    AS
    BEGIN
        IF p_owner_login IS NULL THEN
            RAISE_APPLICATION_ERROR(-20083, 'owner_login не может быть NULL');
        END IF;

        IF p_repo_name IS NULL THEN
            RAISE_APPLICATION_ERROR(-20084, 'repo_name не может быть NULL');
        END IF;

        OPEN user_cursor FOR
        SELECT 
            r.*,
            p.login AS owner_login,
            p.avatar_url AS owner_avatar_url,
            h.REQUEST_TIME
        FROM REPOSITORIES r
        INNER JOIN PROFILES p ON r.owner_git_id = p.git_id
        LEFT JOIN REQUEST_HISTORY h ON r.git_id = h.repository_id
        WHERE UPPER(p.login) = UPPER(p_owner_login)
        AND UPPER(r.name) = UPPER(p_repo_name)
        AND (h.REQUEST_TIME IS NULL OR NOT EXISTS (
            SELECT 1 
            FROM REQUEST_HISTORY h2
            WHERE h2.REPOSITORY_ID = h.REPOSITORY_ID
            AND h2.REQUEST_TIME > h.REQUEST_TIME
        ));
    EXCEPTION
        WHEN OTHERS THEN
            IF user_cursor%ISOPEN THEN
                CLOSE user_cursor;
            END IF;
            IF SQLCODE BETWEEN -20084 AND -20083 THEN
                RAISE;
            ELSE
                RAISE_APPLICATION_ERROR(-20085, 'Ошибка при получении репозитория: ' || SQLERRM);
            END IF;
    END;

    VAR c REFCURSOR
    EXEC get_repository_languages(1061065861, :c)
    PRINT c;