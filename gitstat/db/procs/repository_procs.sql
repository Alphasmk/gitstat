    --Проверить, был ли запрос по такому репозиторию
    CREATE PROCEDURE is_was_repository_request
    (
        p_git_id IN NUMBER,
        count_of_rows OUT NUMBER
    )
    AS
    BEGIN
        SELECT COUNT(*) INTO count_of_rows FROM REPOSITORIES WHERE REPOSITORIES.git_id = p_git_id;
    END;

    DROP PROCEDURE is_was_repository_request;

    --Добавить репозиторий в историю
    CREATE PROCEDURE add_repository_to_history
    (
        git_id NUMBER,
        name VARCHAR2,
        owner_login VARCHAR2,
        owner_avatar_url VARCHAR2,
        html_url VARCHAR2,
        description VARCHAR2,
        repo_size NUMBER,
        stars NUMBER,
        watchers NUMBER,
        default_branch VARCHAR2,
        open_issues NUMBER,
        subscribers_count NUMBER,
        created_at TIMESTAMP,
        updated_at TIMESTAMP,
        pushed_at TIMESTAMP
    )
    AS
    BEGIN
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
            watchers,
            default_branch,
            open_issues,
            subscribers_count,
            created_at,
            updated_at,
            pushed_at
        )
        VALUES (
            git_id,
            name,
            owner_login,
            owner_avatar_url,
            html_url,
            description,
            repo_size,
            stars,
            watchers,
            default_branch,
            open_issues,
            subscribers_count,
            created_at,
            updated_at,
            pushed_at
        );
        COMMIT;
    END;   
    
    DROP PROCEDURE add_repository_to_history;

    --Добавить язык для репозитория в историю
    CREATE PROCEDURE add_repository_language
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
    END;

    DROP PROCEDURE add_repository_language;

    --Обновить язык репозитория в истории
    CREATE PROCEDURE update_repository_language
    (
        repository_id NUMBER,
        language VARCHAR2,
        bytes_count NUMBER
    )
    AS
    BEGIN
        UPDATE REPOSITORY_LANGUAGES SET REPOSITORY_LANGUAGES.BYTES_COUNT = bytes_count
        WHERE REPOSITORY_LANGUAGES.repository_id = repository_id AND REPOSITORY_LANGUAGES.language = language;
    END;

    DROP PROCEDURE update_repository_languages;

    --Добавить тему репозиторию
    CREATE PROCEDURE add_repository_topic
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
    END;

    --Очистить все темы репозитория
    CREATE PROCEDURE clear_repository_topics
    (
        repository_id NUMBER
    )
    AS
    BEGIN
        DELETE FROM REPOSITORY_TOPICS WHERE REPOSITORY_TOPICS.REPOSITORY_ID = repository_id;
    END;

    --Добавить лицензию репозитория
    CREATE PROCEDURE add_repository_license
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
    END;

    DROP PROCEDURE add_repository_license;