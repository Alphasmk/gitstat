    --Добавление пользователя
    CREATE PROCEDURE add_user(
        username VARCHAR2,
        email VARCHAR2,
        password_hash VARCHAR2,
        role VARCHAR2,
        is_blocked char
    )
    AS
    BEGIN
        INSERT
        INTO USERS(username, email, password_hash, role, is_blocked)
        VALUES (username, email, password_hash, role, is_blocked);
    END;

    --Получить пользователя по email или логину
    CREATE PROCEDURE get_user_by_email_or_login
    (
        user_input IN VARCHAR,
        user_cursor OUT SYS_REFCURSOR
    )
    AS
    BEGIN
        OPEN user_cursor FOR
        SELECT * FROM USERS WHERE USERS.EMAIL = user_input OR USERS.USERNAME = user_input;
    END;

    DROP PROCEDURE get_user_by_email_or_login;

    --Получить пользователя по id
    CREATE PROCEDURE get_user_by_id
    (
        user_id IN VARCHAR2,
        user_cursor OUT SYS_REFCURSOR
    )
    AS
        v_user_id NUMBER;
    BEGIN
        v_user_id := TO_NUMBER(user_id_str);
        OPEN user_cursor FOR
        SELECT * FROM USERS WHERE USERS.ID = user_id;
    END;

    DROP PROCEDURE get_user_by_id;

    --Получить профиль по имени
    CREATE PROCEDURE get_user_profile_by_name
    (
        user_name IN VARCHAR2,
        user_cursor OUT SYS_REFCURSOR
    )
    AS
    BEGIN
        OPEN user_cursor FOR
        SELECT a.*, b.REQUEST_TIME
        FROM PROFILES a
        LEFT JOIN REQUEST_HISTORY b 
        ON a.GIT_ID = b.PROFILE_ID
        WHERE UPPER(a.LOGIN) LIKE UPPER(user_name)
        AND (b.REQUEST_TIME IS NULL OR NOT EXISTS (
            SELECT 1 
            FROM REQUEST_HISTORY b2 
            WHERE b2.PROFILE_ID = b.PROFILE_ID 
            AND b2.REQUEST_TIME > b.REQUEST_TIME
        ));
    END;

    DROP PROCEDURE get_user_profile_by_name;

    --Добавить профиль пользователя для истории
    CREATE PROCEDURE add_profile_to_history
    (
        git_id NUMBER,
        login VARCHAR2,
        avatar_url VARCHAR2,
        html_url VARCHAR2,
        type VARCHAR2,
        name VARCHAR2,
        company VARCHAR2,
        location VARCHAR,
        email VARCHAR2,
        blog VARCHAR2,
        bio VARCHAR2,
        twitter_username VARCHAR2,
        followers_count NUMBER,
        following_count NUMBER,
        public_repos NUMBER,
        created_at TIMESTAMP,
        updated_at TIMESTAMP
    )
    AS
    BEGIN
        INSERT
        INTO PROFILES
        (
            git_id,
            login,
            avatar_url,
            html_url,
            type,
            name,
            company,
            location,
            email,
            blog,
            bio,
            twitter_username,
            followers_count,
            following_count,
            public_repos,
            created_at,
            updated_at
        )
        VALUES (
            git_id,
            login,
            avatar_url,
            html_url,
            type,
            name,
            company,
            location,
            email,
            blog,
            bio,
            twitter_username,
            followers_count,
            following_count,
            public_repos,
            created_at,
            updated_at
        );
        COMMIT;
    END;

    DROP PROCEDURE add_profile_to_history;

    --Проверить, был ли запрос по такому пользователю
    CREATE PROCEDURE is_was_profile_request
    (
        p_git_id IN NUMBER,
        count_of_rows OUT NUMBER
    )
    AS
    BEGIN
        SELECT COUNT(*) INTO count_of_rows FROM PROFILES WHERE PROFILES.git_id = p_git_id;
    END;

    DROP PROCEDURE is_was_profile_request;

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

    --Обновить данные профиля в истории
    CREATE PROCEDURE update_profile_history
    (
        p_git_id NUMBER,
        p_login VARCHAR2,
        p_avatar_url VARCHAR2,
        p_html_url VARCHAR2,
        p_type VARCHAR2,
        p_name VARCHAR2,
        p_company VARCHAR2,
        p_location VARCHAR,
        p_email VARCHAR2,
        p_blog VARCHAR2,
        p_bio VARCHAR2,
        p_twitter_username VARCHAR2,
        p_followers_count NUMBER,
        p_following_count NUMBER,
        p_public_repos NUMBER,
        p_updated_at TIMESTAMP
    )
    AS
    BEGIN
        UPDATE PROFILES SET PROFILES.login = p_login,
        PROFILES.avatar_url = p_avatar_url,
        PROFILES.html_url = p_html_url,
        PROFILES.type = p_type,
        PROFILES.name = p_name,
        PROFILES.company = p_company,
        PROFILES.location = p_location,
        PROFILES.email = p_email,
        PROFILES.blog = p_blog,
        PROFILES.bio = p_bio,
        PROFILES.twitter_username = p_twitter_username,
        PROFILES.followers_count = p_followers_count,
        PROFILES.following_count = p_following_count,
        PROFILES.public_repos = p_public_repos,
        PROFILES.updated_at = p_updated_at
        WHERE PROFILES.git_id = p_git_id;
    END;

    DROP PROCEDURE update_profile_history;

    --Добавить запрос в общую историю
    CREATE PROCEDURE add_request_to_general_history
    (
        p_user_id NUMBER,
        p_repository_id NUMBER,
        p_profile_id NUMBER,
        p_request_type VARCHAR2
    )
    AS
    BEGIN
        INSERT
        INTO REQUEST_HISTORY(user_id, repository_id, profile_id, request_type)
        VALUES (p_user_id, p_repository_id, p_profile_id, p_request_type);
    END;

    DROP PROCEDURE add_request_to_general_history;