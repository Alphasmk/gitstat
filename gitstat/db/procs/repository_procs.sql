    --Проверить, был ли запрос по такому репозиторию
    CREATE OR REPLACE PROCEDURE is_was_repository_request
    (
        p_git_id IN NUMBER,
        count_of_rows OUT NUMBER
    )
    AS
    BEGIN
        SELECT COUNT(*) INTO count_of_rows FROM REPOSITORIES WHERE REPOSITORIES.git_id = p_git_id;
    EXCEPTION
        WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR(-20001, 'Ошибка при проверке репозитория: ' || SQLERRM);
    END;

    DROP PROCEDURE is_was_repository_request;

    --Добавить репозиторий в историю
    CREATE OR REPLACE PROCEDURE add_repository_to_history
    (
        git_id VARCHAR2,
        name VARCHAR2,
        owner_login VARCHAR2,
        owner_avatar_url VARCHAR2,
        html_url VARCHAR2,
        description VARCHAR2,
        repo_size NUMBER,
        stars NUMBER,
        forks NUMBER,
        default_branch VARCHAR2,
        open_issues NUMBER,
        subscribers_count VARCHAR2,
        created_at TIMESTAMP,
        updated_at TIMESTAMP,
        pushed_at TIMESTAMP
    )
    AS
        v_git_id NUMBER;
        v_subscribers_count NUMBER;
    BEGIN
        v_git_id := TO_NUMBER(git_id);
        v_subscribers_count := TO_NUMBER(subscribers_count);
        INSERT
        INTO REPOSITORIES
        (
            git_id,
            name,
            owner_login,
            owner_avatar_url,
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
            name,
            owner_login,
            owner_avatar_url,
            html_url,
            description,
            repo_size,
            stars,
            forks,
            default_branch,
            open_issues,
            v_subscribers_count,
            created_at,
            updated_at,
            pushed_at
        );
    EXCEPTION
        WHEN DUP_VAL_ON_INDEX THEN
            RAISE_APPLICATION_ERROR(-20002, 'Репозиторий с git_id ' || git_id || ' уже существует');
        WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR(-20003, 'Ошибка при добавлении репозитория: ' || SQLERRM);
    END;   
    
    DROP PROCEDURE add_repository_to_history;

    --Обновить репозиторий в истории
    CREATE OR REPLACE PROCEDURE update_repository_in_history
    (
        git_id VARCHAR2,
        name VARCHAR2,
        owner_login VARCHAR2,
        owner_avatar_url VARCHAR2,
        html_url VARCHAR2,
        description VARCHAR2,
        repo_size NUMBER,
        stars NUMBER,
        forks NUMBER,
        default_branch VARCHAR2,
        open_issues NUMBER,
        subscribers_count VARCHAR2,
        updated_at TIMESTAMP,
        pushed_at TIMESTAMP
    )
    AS
        v_git_id NUMBER;
        v_subscribers_count NUMBER;
    BEGIN
        v_git_id := TO_NUMBER(git_id);
        v_subscribers_count := TO_NUMBER(subscribers_count);
        UPDATE REPOSITORIES SET
        REPOSITORIES.NAME = name,
        REPOSITORIES.owner_login = owner_login,
        REPOSITORIES.owner_avatar_url = owner_avatar_url,
        REPOSITORIES.html_url = html_url,
        REPOSITORIES.description = description,
        REPOSITORIES.repo_size = repo_size,
        REPOSITORIES.stars = stars,
        REPOSITORIES.forks = forks,
        REPOSITORIES.default_branch = default_branch,
        REPOSITORIES.open_issues = open_issues,
        REPOSITORIES.subscribers_count = v_subscribers_count,
        REPOSITORIES.updated_at = updated_at,
        REPOSITORIES.pushed_at = pushed_at
        WHERE REPOSITORIES.GIT_ID = v_git_id;
    EXCEPTION
        WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR(-20003, 'Ошибка при изменении репозитория: ' || SQLERRM);
    END;   
    
    DROP PROCEDURE update_repository_in_history;
    
    --Добавить язык для репозитория в историю
    CREATE OR REPLACE PROCEDURE add_repository_language
    (
        repository_id NUMBER,
        language VARCHAR2,
        bytes_count NUMBER
    )
    AS
    BEGIN
        INSERT INTO REPOSITORY_LANGUAGES
        (
            repository_id,
            language,
            bytes_count
        )
        VALUES
        (
            repository_id,
            language,
            bytes_count
        );
    EXCEPTION
        WHEN DUP_VAL_ON_INDEX THEN
            RAISE_APPLICATION_ERROR(-20004, 'Язык ' || language || ' уже существует для репозитория ' || repository_id);
        WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR(-20005, 'Ошибка при добавлении языка: ' || SQLERRM);
    END;

    DROP PROCEDURE add_repository_language;

    CREATE OR REPLACE PROCEDURE clear_repository_languages
    (
        repository_id VARCHAR2
    )
    AS
        v_repository_id NUMBER;
    BEGIN
        v_repository_id := TO_NUMBER(repository_id);
        DELETE FROM REPOSITORY_LANGUAGES WHERE REPOSITORY_LANGUAGES.REPOSITORY_ID = v_repository_id;
    EXCEPTION
        WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR(-20009, 'Ошибка при удалении языков: ' || SQLERRM);
    END;

    DROP PROCEDURE clear_repository_languages;

    --Добавить тему репозиторию
    CREATE OR REPLACE PROCEDURE add_repository_topic
    (
        repository_id NUMBER,
        topic VARCHAR2
    )
    AS
    BEGIN
        INSERT INTO REPOSITORY_TOPICS
        (
            repository_id,
            topic
        )
        VALUES
        (
            repository_id,
            topic
        );
    EXCEPTION
        WHEN DUP_VAL_ON_INDEX THEN
            RAISE_APPLICATION_ERROR(-20007, 'Тема ' || topic || ' уже существует для репозитория ' || repository_id);
        WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR(-20008, 'Ошибка при добавлении темы: ' || SQLERRM);
    END;

    --Очистить все темы репозитория
    CREATE OR REPLACE PROCEDURE clear_repository_topics
    (
        repository_id NUMBER
    )
    AS
    BEGIN
        DELETE FROM REPOSITORY_TOPICS WHERE REPOSITORY_TOPICS.REPOSITORY_ID = repository_id;
    EXCEPTION
        WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR(-20009, 'Ошибка при удалении тем: ' || SQLERRM);
    END;

    --Добавить лицензию репозитория
    CREATE OR REPLACE PROCEDURE add_repository_license
    (
        repository_id NUMBER,
        license_name VARCHAR2,
        spdx_id VARCHAR2
    )
    AS
    BEGIN
        INSERT INTO REPOSITORY_LICENSES
        (
            repository_id,
            license_name,
            spdx_id
        )
        VALUES
        (
            repository_id,
            license_name,
            spdx_id
        );
    EXCEPTION
        WHEN DUP_VAL_ON_INDEX THEN
            RAISE_APPLICATION_ERROR(-20010, 'Лицензия уже существует для репозитория ' || repository_id);
        WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR(-20011, 'Ошибка при добавлении лицензии: ' || SQLERRM);
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
            RAISE_APPLICATION_ERROR(-20001, 'Ошибка при добавлении/обновлении лицензии репозитория: ' || SQLERRM);
    END;

    DROP PROCEDURE add_or_update_repository_license;

    --Удалить лицензию репозиторию
    CREATE OR REPLACE PROCEDURE delete_repository_license
    (
        repository_id NUMBER
    )
    AS
    BEGIN
        DELETE FROM REPOSITORY_LICENSES WHERE REPOSITORY_LICENSES.repository_id = repository_id;
    EXCEPTION
       WHEN OTHERS THEN
           RAISE_APPLICATION_ERROR(-20001, 'Ошибка при удалении лицензии репозитория: ' || SQLERRM);
    END;

    --Добавить коммит в историю
    CREATE OR REPLACE PROCEDURE add_commit (
    p_repository_id IN NUMBER,
    p_sha IN VARCHAR2,
    p_author_login IN VARCHAR2,
    p_author_avatar_url IN VARCHAR2,
    p_message IN VARCHAR2,
    p_commit_date IN TIMESTAMP,
    p_url IN VARCHAR2
    )
    AS
    BEGIN
        MERGE INTO COMMITS c
        USING (
            SELECT 
                p_repository_id AS repository_id,
                p_sha AS sha,
                p_author_login AS author_login,
                p_author_avatar_url AS author_avatar_url,
                p_message AS message,
                p_commit_date AS commit_date,
                p_url AS url
            FROM DUAL
        ) src
        ON (c.sha = src.sha)
        WHEN NOT MATCHED THEN
            INSERT (repository_id, sha, author_login, author_avatar_url, message, commit_date, url)
            VALUES (src.repository_id, src.sha, src.author_login, src.author_avatar_url, src.message, src.commit_date, src.url);
    END;

    --Получить репозиторий по id
    CREATE OR REPLACE PROCEDURE get_repository_by_id
    (
        repository_id IN VARCHAR,
        user_cursor OUT SYS_REFCURSOR
    )
    AS
        v_repository_id NUMBER;
    BEGIN
        v_repository_id := TO_NUMBER(repository_id);
        OPEN user_cursor FOR
        SELECT a.*, b.REQUEST_TIME
        FROM REPOSITORIES a 
        LEFT JOIN REQUEST_HISTORY b
        ON a.GIT_ID = b.REPOSITORY_ID
        WHERE a.GIT_ID = v_repository_id
        AND (b.REQUEST_TIME IS NULL OR NOT EXISTS (
            SELECT 1 
            FROM REQUEST_HISTORY b2
            WHERE b2.REPOSITORY_ID = b.REPOSITORY_ID
            AND b2.REQUEST_TIME > b.REQUEST_TIME
        ));
    END;

    --Получить языки репозитория
    CREATE OR REPLACE PROCEDURE get_repository_languages
    (
        repository_id IN VARCHAR2,
        user_cursor OUT SYS_REFCURSOR
    )
    AS
        v_repository_id NUMBER;
    BEGIN
        v_repository_id := TO_NUMBER(repository_id);
        OPEN user_cursor FOR
        SELECT language, bytes_count FROM REPOSITORY_LANGUAGES WHERE REPOSITORY_LANGUAGES.repository_id = v_repository_id;
    END;

    --Получить темы репозитория
    CREATE OR REPLACE PROCEDURE get_repository_topics
    (
        repository_id IN VARCHAR,
        user_cursor OUT SYS_REFCURSOR
    )
    AS
        v_repository_id NUMBER;
    BEGIN
        v_repository_id := TO_NUMBER(repository_id);
        OPEN user_cursor FOR
        SELECT topic FROM REPOSITORY_TOPICS WHERE REPOSITORY_TOPICS.repository_id = v_repository_id;
    END;

    --Получить лицензию репозитория
    CREATE OR REPLACE PROCEDURE get_repository_license
    (
        repository_id IN VARCHAR,
        user_cursor OUT SYS_REFCURSOR
    )
    AS
        v_repository_id NUMBER;
    BEGIN
        v_repository_id := TO_NUMBER(repository_id);
        OPEN user_cursor FOR
        SELECT license_name, spdx_id FROM REPOSITORY_LICENSES WHERE REPOSITORY_LICENSES.repository_id = v_repository_id;
    END;
    
    --Получить коммиты репозитория
    CREATE OR REPLACE PROCEDURE get_repository_commits
    (
        repository_id IN VARCHAR,
        user_cursor OUT SYS_REFCURSOR
    )
    AS
        v_repository_id NUMBER;
    BEGIN
        v_repository_id := TO_NUMBER(repository_id);
        OPEN user_cursor FOR
        SELECT sha, author_login, author_avatar_url, commit_date, url FROM COMMITS WHERE COMMITS.repository_id = v_repository_id;
    END;

    --Проверить, есть ли информация по репозиторию в базе данных
    CREATE OR REPLACE PROCEDURE is_repository_info_exist
    (
        repository_id IN VARCHAR,
        rows_count OUT NUMBER
    )
    AS
    BEGIN
        SELECT count(*) INTO rows_count FROM REPOSITORIES WHERE REPOSITORIES.GIT_ID = v_repository_id;
    END;

    SELECT sha, author_login, author_avatar_url, commit_date, url FROM COMMITS WHERE COMMITS.repository_id = 1061065861;


    VAR c REFCURSOR
    EXEC get_repository_languages(1061065861, :c)
    PRINT c;