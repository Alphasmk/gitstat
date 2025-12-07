    --Добавление пользователя
    CREATE OR REPLACE PROCEDURE add_user(
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
    EXCEPTION
        WHEN DUP_VAL_ON_INDEX THEN
            RAISE_APPLICATION_ERROR(-20020, 'Пользователь с таким email или username уже существует');
        WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR(-20022, 'Ошибка при добавлении пользователя: ' || SQLERRM);
    END;

    --Получить пользователя по email или логину
    CREATE OR REPLACE PROCEDURE get_user_by_email_or_login
    (
        user_input IN VARCHAR2,
        user_cursor OUT SYS_REFCURSOR
    )
    AS
    BEGIN
        OPEN user_cursor FOR
        SELECT * FROM USERS WHERE email = user_input OR username = user_input;
    EXCEPTION
        WHEN OTHERS THEN
            IF user_cursor%ISOPEN THEN
                CLOSE user_cursor;
            END IF;
            RAISE_APPLICATION_ERROR(-20023, 'Ошибка при получении пользователя: ' || SQLERRM);
    END;

    DROP PROCEDURE get_user_by_email_or_login;

    --Получить пользователя по id
    CREATE OR REPLACE PROCEDURE get_user_by_id
    (
        user_id IN VARCHAR2,
        user_cursor OUT SYS_REFCURSOR
    )
    AS
        v_user_id NUMBER;
    BEGIN
        v_user_id := TO_NUMBER(user_id);
        OPEN user_cursor FOR
        SELECT * FROM USERS WHERE USERS.ID = user_id;
    EXCEPTION
        WHEN INVALID_NUMBER THEN
            IF user_cursor%ISOPEN THEN
                CLOSE user_cursor;
            END IF;
            RAISE_APPLICATION_ERROR(-20024, 'Некорректный ID пользователя: ' || user_id);
        WHEN VALUE_ERROR THEN
            IF user_cursor%ISOPEN THEN
                CLOSE user_cursor;
            END IF;
            RAISE_APPLICATION_ERROR(-20025, 'Ошибка преобразования ID: ' || user_id);
        WHEN OTHERS THEN
            IF user_cursor%ISOPEN THEN
                CLOSE user_cursor;
            END IF;
            RAISE_APPLICATION_ERROR(-20026, 'Ошибка при получении пользователя: ' || SQLERRM);
    END;

    DROP PROCEDURE get_user_by_id;

    --Получить количество пользователей
    CREATE OR REPLACE PROCEDURE get_total_users_count
    (
        p_count OUT NUMBER
    )
    AS
    BEGIN
        SELECT COUNT(*) INTO p_count FROM USERS;
    EXCEPTION
        WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR(-20002, 'Ошибка при подсчете пользователей: ' || SQLERRM);
    END;

    --Получить историю запросов пользователя по id
    CREATE OR REPLACE PROCEDURE get_user_history
    (
        p_user_id IN VARCHAR2,
        user_cursor OUT SYS_REFCURSOR
    )
    AS
        v_user_id NUMBER;
    BEGIN
        v_user_id := TO_NUMBER(p_user_id);
        OPEN user_cursor FOR
        SELECT 
            a.id,
            a.repository_id AS obj_id,
            b.name AS obj_name,
            a.request_time,
            a.request_type
        FROM SYSTEM.REQUEST_HISTORY a
        INNER JOIN SYSTEM.REPOSITORIES b ON b.GIT_ID = a.REPOSITORY_ID
        WHERE a.USER_ID = v_user_id AND a.REQUEST_TYPE = 'REPOSITORY'
        
        UNION ALL
        
        SELECT 
            a.id,
            a.profile_id AS obj_id,
            b.login AS obj_name,
            a.request_time,
            a.request_type
        FROM SYSTEM.REQUEST_HISTORY a
        INNER JOIN SYSTEM.PROFILES b ON b.GIT_ID = a.PROFILE_ID
        WHERE a.USER_ID = v_user_id AND a.REQUEST_TYPE = 'PROFILE'
        
        ORDER BY request_time DESC;
    END;

    CREATE OR REPLACE PROCEDURE get_user_history_secure
    (
        p_user_id IN VARCHAR2,
        user_cursor OUT SYS_REFCURSOR
    )
    AUTHID CURRENT_USER
    AS
        v_user_id NUMBER;
    BEGIN
        v_user_id := TO_NUMBER(p_user_id);

        OPEN user_cursor FOR
        SELECT id, obj_id, obj_name, request_time, request_type
        FROM SYSTEM.v_user_history
        WHERE user_id = v_user_id
        ORDER BY request_time DESC;
    END;

    --Получить всех зарегистрированных пользователей
    CREATE OR REPLACE PROCEDURE get_all_users
    (
        user_cursor OUT SYS_REFCURSOR
    )
    AS
    BEGIN 
        OPEN user_cursor FOR
        SELECT id, username, email, role, is_blocked, created_at FROM USERS
        ORDER BY created_at DESC;
    END;

    --Заблокировать пользователя
    CREATE OR REPLACE PROCEDURE change_user_block_state
    (
        p_user_id VARCHAR2
    )
    AS
        v_user_id NUMBER;
    BEGIN
        v_user_id := TO_NUMBER(p_user_id);

        UPDATE USERS
        SET is_blocked = CASE 
            WHEN is_blocked = 'Y' THEN 'N'
            ELSE 'Y'
        END
        WHERE id = v_user_id
        AND role = 'user';

        IF SQL%ROWCOUNT = 0 THEN
            RAISE_APPLICATION_ERROR(-20002, 'Пользователь не найден или имеет защищенную роль');
        END IF;
    END;

    --Удалить пользователя
    CREATE OR REPLACE PROCEDURE delete_user
    (
        p_user_id VARCHAR2
    )
    AS
        v_user_id NUMBER;
    BEGIN
        v_user_id := TO_NUMBER(p_user_id);

        DELETE FROM USERS
        WHERE id = v_user_id
        AND role = 'user';

        IF SQL%ROWCOUNT = 0 THEN
            RAISE_APPLICATION_ERROR(-20003, 'Пользователь не найден или имеет защищенную роль');
        END IF;

        COMMIT;
    END;

    --Сменить роль пользователя
    CREATE OR REPLACE PROCEDURE change_user_role
    (
        p_user_id VARCHAR2,
        p_new_role VARCHAR2
    )
    AS
        v_user_id NUMBER;
    BEGIN
        v_user_id := TO_NUMBER(p_user_id);

        IF p_new_role NOT IN ('user', 'moderator', 'admin') THEN
            RAISE_APPLICATION_ERROR(-20004, 'Недопустимое значение роли');
        END IF;

        UPDATE USERS
        SET role = p_new_role
        WHERE id = v_user_id;

        IF SQL%ROWCOUNT = 0 THEN
            RAISE_APPLICATION_ERROR(-20005, 'Пользователь не найден');
        END IF;

        COMMIT;
    EXCEPTION
        WHEN INVALID_NUMBER THEN
            RAISE_APPLICATION_ERROR(-20006, 'Некорректный ID пользователя');
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(-20007, 'Ошибка при изменении роли: ' || SQLERRM);
    END;

    --Сменить пароль пользователю
    CREATE OR REPLACE PROCEDURE change_user_password 
    (
        p_user_id VARCHAR2,
        p_new_pass VARCHAR2
    )
    AS
        v_user_id NUMBER;
    BEGIN
        v_user_id := TO_NUMBER(p_user_id);

        IF TRIM(p_new_pass) IS NULL THEN
            RAISE_APPLICATION_ERROR(-20004, 'Недопустимое значение пароля');
        END IF;

        UPDATE USERS
        SET password_hash = p_new_pass
        WHERE id = v_user_id;

        IF SQL%ROWCOUNT = 0 THEN
            RAISE_APPLICATION_ERROR(-20005, 'Пользователь не найден');
        END IF;

    EXCEPTION
        WHEN INVALID_NUMBER THEN
            RAISE_APPLICATION_ERROR(-20006, 'Некорректный ID пользователя');
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(-20007, 'Ошибка при изменении пароля: ' || SQLERRM);
    END;

    CREATE OR REPLACE PROCEDURE get_user_history_secure (
        p_user_id IN VARCHAR2, 
        user_cursor OUT SYS_REFCURSOR
    ) AS
    BEGIN
        DBMS_APPLICATION_INFO.SET_CLIENT_INFO('MASK_REQUIRED');
        SYSTEM.get_user_history(p_user_id, user_cursor);
    END;