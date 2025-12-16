    --Получить профиль по имени
    CREATE OR REPLACE PROCEDURE get_profile_by_name
    (
        user_name IN VARCHAR2,
        user_cursor OUT SYS_REFCURSOR
    )
    AS
    BEGIN
        IF user_name IS NULL THEN
            RAISE_APPLICATION_ERROR(-20011, 'Имя пользователя не может быть NULL');
        END IF;
    
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
    EXCEPTION
        WHEN OTHERS THEN
            IF user_cursor%ISOPEN THEN
                CLOSE user_cursor;
            END IF;
            IF SQLCODE = -20011 THEN
                RAISE;
            ELSE
                RAISE_APPLICATION_ERROR(-20012, 'Ошибка при получении профиля: ' || SQLERRM);
            END IF;
    END;

    DROP PROCEDURE get_user_profile_by_name;

    --Добавить профиль пользователя для истории
    CREATE OR REPLACE PROCEDURE add_profile_to_history
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
        IF git_id IS NULL THEN
            RAISE_APPLICATION_ERROR(-20010, 'git_id не может быть NULL');
        END IF;

        IF login IS NULL THEN
            RAISE_APPLICATION_ERROR(-20011, 'login не может быть NULL');
        END IF;

        INSERT INTO PROFILES
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
    EXCEPTION
        WHEN DUP_VAL_ON_INDEX THEN
            RAISE_APPLICATION_ERROR(-20013, 'Профиль с git_id ' || git_id || ' уже существует');
        WHEN VALUE_ERROR THEN
            RAISE_APPLICATION_ERROR(-20014, 'Ошибка типа данных при добавлении профиля');
        WHEN OTHERS THEN
            IF SQLCODE BETWEEN -20011 AND -20010 THEN
                RAISE;
            ELSE
                RAISE_APPLICATION_ERROR(-20015, 'Ошибка при добавлении профиля: ' || SQLERRM);
            END IF;
    END;

    DROP PROCEDURE add_profile_to_history;

    --Проверить, был ли запрос по такому профилю
    CREATE OR REPLACE PROCEDURE is_was_profile_request
    (
        p_git_id IN NUMBER,
        count_of_rows OUT NUMBER
    )
    AS
    BEGIN
        IF p_git_id IS NULL THEN
            RAISE_APPLICATION_ERROR(-20016, 'git_id не может быть NULL');
        END IF;
    
        SELECT COUNT(*) INTO count_of_rows 
        FROM PROFILES 
        WHERE git_id = p_git_id;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            count_of_rows := 0;
        WHEN OTHERS THEN
            IF SQLCODE = -20016 THEN
                RAISE;
            ELSE
                RAISE_APPLICATION_ERROR(-20017, 'Ошибка при проверке профиля: ' || SQLERRM);
            END IF;
    END;

    DROP PROCEDURE is_was_profile_request;

    CREATE OR REPLACE PROCEDURE is_was_profile_request_by_login
    (
        user_name IN VARCHAR2,
        count_of_rows OUT NUMBER
    )
    AS
    BEGIN
        IF user_name IS NULL THEN
            RAISE_APPLICATION_ERROR(-20018, 'Имя пользователя не может быть NULL');
        END IF;

        SELECT COUNT(*) INTO count_of_rows 
        FROM PROFILES 
        WHERE UPPER(LOGIN) = UPPER(user_name);
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            count_of_rows := 0;
        WHEN OTHERS THEN
            IF SQLCODE = -20018 THEN
                RAISE;
            ELSE
                RAISE_APPLICATION_ERROR(-20019, 'Ошибка при проверке профиля: ' || SQLERRM);
            END IF;
    END;

    -- Обновить данные профиля в истории
    CREATE OR REPLACE PROCEDURE update_profile_history
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
        v_rows_updated NUMBER;
    BEGIN
        IF p_git_id IS NULL THEN
            RAISE_APPLICATION_ERROR(-20020, 'git_id не может быть NULL');
        END IF;

        UPDATE PROFILES 
        SET login = p_login,
            avatar_url = p_avatar_url,
            html_url = p_html_url,
            type = p_type,
            name = p_name,
            company = p_company,
            location = p_location,
            email = p_email,
            blog = p_blog,
            bio = p_bio,
            twitter_username = p_twitter_username,
            followers_count = p_followers_count,
            following_count = p_following_count,
            public_repos = p_public_repos,
            updated_at = p_updated_at
        WHERE git_id = p_git_id;

        v_rows_updated := SQL%ROWCOUNT;

        IF v_rows_updated = 0 THEN
            RAISE_APPLICATION_ERROR(-20021, 'Профиль с git_id ' || p_git_id || ' не найден для обновления');
        END IF;
    EXCEPTION
        WHEN VALUE_ERROR THEN
            RAISE_APPLICATION_ERROR(-20022, 'Ошибка типа данных при обновлении профиля');
        WHEN OTHERS THEN
            IF SQLCODE BETWEEN -20021 AND -20020 THEN
                RAISE;
            ELSE
                RAISE_APPLICATION_ERROR(-20023, 'Ошибка при обновлении профиля: ' || SQLERRM);
            END IF;
    END;

    --Получить все репозитории пользователя
    CREATE OR REPLACE PROCEDURE get_profile_repositories
    (
        p_owner_login IN VARCHAR2,
        user_cursor OUT SYS_REFCURSOR
    )
    AS
    BEGIN
        IF p_owner_login IS NULL THEN
            RAISE_APPLICATION_ERROR(-20024, 'Логин владельца не может быть NULL');
        END IF;
    
        OPEN user_cursor FOR
        SELECT 
            r.name, 
            p.login AS owner_login,
            p.avatar_url AS owner_avatar_url,
            r.html_url, 
            r.description, 
            r.git_id,
            r.pushed_at
        FROM REPOSITORIES r
        INNER JOIN PROFILES p ON r.owner_git_id = p.git_id
        WHERE UPPER(p.login) = UPPER(p_owner_login)
        ORDER BY r.pushed_at DESC NULLS LAST;
    EXCEPTION
        WHEN OTHERS THEN
            IF user_cursor%ISOPEN THEN
                CLOSE user_cursor;
            END IF;
            IF SQLCODE = -20024 THEN
                RAISE;
            ELSE
                RAISE_APPLICATION_ERROR(-20025, 'Ошибка при получении репозиториев профиля: ' || SQLERRM);
            END IF;
    END;