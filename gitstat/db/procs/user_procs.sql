    --Добавление пользователя
    CREATE OR REPLACE PROCEDURE add_user
    (
    username VARCHAR2,
    email VARCHAR2,
    password_hash VARCHAR2,
    role VARCHAR2,
    is_blocked char
    )
    AS
    BEGIN
        IF username IS NULL THEN
            RAISE_APPLICATION_ERROR(-20094, 'username не может быть NULL');
        END IF;

        IF email IS NULL THEN
            RAISE_APPLICATION_ERROR(-20095, 'email не может быть NULL');
        END IF;

        IF password_hash IS NULL THEN
            RAISE_APPLICATION_ERROR(-20096, 'password_hash не может быть NULL');
        END IF;

        IF role IS NULL THEN
            RAISE_APPLICATION_ERROR(-20097, 'role не может быть NULL');
        END IF;

        IF role NOT IN ('user', 'admin', 'moderator') THEN
            RAISE_APPLICATION_ERROR(-20098, 'Недопустимое значение роли');
        END IF;

        IF is_blocked NOT IN ('Y', 'N') THEN
            RAISE_APPLICATION_ERROR(-20099, 'is_blocked должен быть Y или N');
        END IF;

        INSERT INTO USERS(username, email, password_hash, role, is_blocked)
        VALUES (username, email, password_hash, role, is_blocked);
    EXCEPTION
        WHEN DUP_VAL_ON_INDEX THEN
            RAISE_APPLICATION_ERROR(-20100, 'Пользователь с таким email или username уже существует');
        WHEN OTHERS THEN
            IF SQLCODE BETWEEN -20099 AND -20094 THEN
                RAISE;
            ELSE
                RAISE_APPLICATION_ERROR(-20101, 'Ошибка при добавлении пользователя: ' || SQLERRM);
            END IF;
    END;

    --Получить пользователя по email или логину
    CREATE OR REPLACE PROCEDURE get_user_by_email_or_login
    (
        user_input IN VARCHAR2,
        user_cursor OUT SYS_REFCURSOR
    )
    AS
    BEGIN
        IF user_input IS NULL THEN
            RAISE_APPLICATION_ERROR(-20102, 'user_input не может быть NULL');
        END IF;

        OPEN user_cursor FOR
        SELECT * FROM USERS WHERE email = user_input OR username = user_input;
    EXCEPTION
        WHEN OTHERS THEN
            IF user_cursor%ISOPEN THEN
                CLOSE user_cursor;
            END IF;
            IF SQLCODE = -20102 THEN
                RAISE;
            ELSE
                RAISE_APPLICATION_ERROR(-20103, 'Ошибка при получении пользователя: ' || SQLERRM);
            END IF;
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
        IF user_id IS NULL THEN
            RAISE_APPLICATION_ERROR(-20104, 'user_id не может быть NULL');
        END IF;
    
        v_user_id := TO_NUMBER(user_id);
    
        OPEN user_cursor FOR
        SELECT * FROM USERS WHERE ID = v_user_id;
    EXCEPTION
        WHEN INVALID_NUMBER THEN
            IF user_cursor%ISOPEN THEN
                CLOSE user_cursor;
            END IF;
            RAISE_APPLICATION_ERROR(-20105, 'Некорректный ID пользователя: ' || user_id);
        WHEN VALUE_ERROR THEN
            IF user_cursor%ISOPEN THEN
                CLOSE user_cursor;
            END IF;
            RAISE_APPLICATION_ERROR(-20106, 'Ошибка преобразования ID: ' || user_id);
        WHEN OTHERS THEN
            IF user_cursor%ISOPEN THEN
                CLOSE user_cursor;
            END IF;
            IF SQLCODE BETWEEN -20106 AND -20104 THEN
                RAISE;
            ELSE
                RAISE_APPLICATION_ERROR(-20107, 'Ошибка при получении пользователя: ' || SQLERRM);
            END IF;
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
        WHEN NO_DATA_FOUND THEN
            p_count := 0;
        WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR(-20108, 'Ошибка при подсчете пользователей: ' || SQLERRM);
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
        IF p_user_id IS NULL THEN
            RAISE_APPLICATION_ERROR(-20109, 'user_id не может быть NULL');
        END IF;
    
        v_user_id := TO_NUMBER(p_user_id);
    
        OPEN user_cursor FOR
        SELECT 
            a.id,
            a.repository_id AS obj_id,
            b.name AS obj_name,
            a.request_time,
            a.request_type
        FROM REQUEST_HISTORY a
        INNER JOIN REPOSITORIES b ON b.GIT_ID = a.REPOSITORY_ID
        WHERE a.USER_ID = v_user_id AND a.REQUEST_TYPE = 'REPOSITORY'
        
        UNION ALL
        
        SELECT 
            a.id,
            a.profile_id AS obj_id,
            b.login AS obj_name,
            a.request_time,
            a.request_type
        FROM REQUEST_HISTORY a
        INNER JOIN PROFILES b ON b.GIT_ID = a.PROFILE_ID
        WHERE a.USER_ID = v_user_id AND a.REQUEST_TYPE = 'PROFILE'
        
        ORDER BY request_time DESC;
    EXCEPTION
        WHEN VALUE_ERROR THEN
            IF user_cursor%ISOPEN THEN
                CLOSE user_cursor;
            END IF;
            RAISE_APPLICATION_ERROR(-20110, 'Ошибка преобразования user_id');
        WHEN OTHERS THEN
            IF user_cursor%ISOPEN THEN
                CLOSE user_cursor;
            END IF;
            IF SQLCODE BETWEEN -20110 AND -20109 THEN
                RAISE;
            ELSE
                RAISE_APPLICATION_ERROR(-20111, 'Ошибка при получении истории пользователя: ' || SQLERRM);
            END IF;
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
        IF p_user_id IS NULL THEN
            RAISE_APPLICATION_ERROR(-20112, 'user_id не может быть NULL');
        END IF;

        v_user_id := TO_NUMBER(p_user_id);

        OPEN user_cursor FOR
        SELECT id, obj_id, obj_name, request_time, request_type
        FROM SYSTEM.v_user_history
        WHERE user_id = v_user_id
        ORDER BY request_time DESC;
    EXCEPTION
        WHEN VALUE_ERROR THEN
            IF user_cursor%ISOPEN THEN
                CLOSE user_cursor;
            END IF;
            RAISE_APPLICATION_ERROR(-20113, 'Ошибка преобразования user_id');
        WHEN OTHERS THEN
            IF user_cursor%ISOPEN THEN
                CLOSE user_cursor;
            END IF;
            IF SQLCODE BETWEEN -20113 AND -20112 THEN
                RAISE;
            ELSE
                RAISE_APPLICATION_ERROR(-20114, 'Ошибка при получении защищенной истории: ' || SQLERRM);
            END IF;
    END;

    --Получить всех зарегистрированных пользователей
    CREATE OR REPLACE PROCEDURE get_all_users
    (
        user_cursor OUT SYS_REFCURSOR
    )
    AS
    BEGIN 
        OPEN user_cursor FOR
        SELECT id, username, email, role, is_blocked, created_at 
        FROM USERS
        ORDER BY created_at DESC;
    EXCEPTION
        WHEN OTHERS THEN
            IF user_cursor%ISOPEN THEN
                CLOSE user_cursor;
            END IF;
            RAISE_APPLICATION_ERROR(-20115, 'Ошибка при получении списка пользователей: ' || SQLERRM);
    END;

    --Заблокировать/разблокировать пользователя
    CREATE OR REPLACE PROCEDURE change_user_block_state
    (
        p_user_id VARCHAR2
    )
    AS
        v_user_id NUMBER;
    BEGIN
        IF p_user_id IS NULL THEN
            RAISE_APPLICATION_ERROR(-20116, 'user_id не может быть NULL');
        END IF;

        v_user_id := TO_NUMBER(p_user_id);

        UPDATE USERS
        SET is_blocked = CASE 
            WHEN is_blocked = 'Y' THEN 'N'
            ELSE 'Y'
        END
        WHERE id = v_user_id
        AND role = 'user';

        IF SQL%ROWCOUNT = 0 THEN
            RAISE_APPLICATION_ERROR(-20117, 'Пользователь не найден или имеет защищенную роль');
        END IF;

        COMMIT;
    EXCEPTION
        WHEN VALUE_ERROR THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(-20118, 'Ошибка преобразования user_id');
        WHEN OTHERS THEN
            ROLLBACK;
            IF SQLCODE BETWEEN -20118 AND -20116 THEN
                RAISE;
            ELSE
                RAISE_APPLICATION_ERROR(-20119, 'Ошибка при изменении статуса блокировки: ' || SQLERRM);
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
        IF p_user_id IS NULL THEN
            RAISE_APPLICATION_ERROR(-20120, 'user_id не может быть NULL');
        END IF;

        v_user_id := TO_NUMBER(p_user_id);

        DELETE FROM USERS
        WHERE id = v_user_id
        AND role = 'user';

        IF SQL%ROWCOUNT = 0 THEN
            RAISE_APPLICATION_ERROR(-20121, 'Пользователь не найден или имеет защищенную роль');
        END IF;

        COMMIT;
    EXCEPTION
        WHEN VALUE_ERROR THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(-20122, 'Ошибка преобразования user_id');
        WHEN OTHERS THEN
            ROLLBACK;
            IF SQLCODE BETWEEN -20122 AND -20120 THEN
                RAISE;
            ELSE
                RAISE_APPLICATION_ERROR(-20123, 'Ошибка при удалении пользователя: ' || SQLERRM);
            END IF;
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
        IF p_user_id IS NULL THEN
            RAISE_APPLICATION_ERROR(-20124, 'user_id не может быть NULL');
        END IF;

        IF p_new_role IS NULL THEN
            RAISE_APPLICATION_ERROR(-20125, 'new_role не может быть NULL');
        END IF;

        v_user_id := TO_NUMBER(p_user_id);

        IF p_new_role NOT IN ('user', 'moderator', 'admin') THEN
            RAISE_APPLICATION_ERROR(-20126, 'Недопустимое значение роли');
        END IF;

        UPDATE USERS
        SET role = p_new_role
        WHERE id = v_user_id;

        IF SQL%ROWCOUNT = 0 THEN
            RAISE_APPLICATION_ERROR(-20127, 'Пользователь не найден');
        END IF;

        COMMIT;
    EXCEPTION
        WHEN INVALID_NUMBER THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(-20128, 'Некорректный ID пользователя');
        WHEN VALUE_ERROR THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(-20129, 'Ошибка преобразования user_id');
        WHEN OTHERS THEN
            ROLLBACK;
            IF SQLCODE BETWEEN -20129 AND -20124 THEN
                RAISE;
            ELSE
                RAISE_APPLICATION_ERROR(-20130, 'Ошибка при изменении роли: ' || SQLERRM);
            END IF;
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
        IF p_user_id IS NULL THEN
            RAISE_APPLICATION_ERROR(-20131, 'user_id не может быть NULL');
        END IF;

        IF p_new_pass IS NULL THEN
            RAISE_APPLICATION_ERROR(-20132, 'new_pass не может быть NULL');
        END IF;

        v_user_id := TO_NUMBER(p_user_id);

        IF TRIM(p_new_pass) IS NULL THEN
            RAISE_APPLICATION_ERROR(-20133, 'Недопустимое значение пароля');
        END IF;

        UPDATE USERS
        SET password_hash = p_new_pass
        WHERE id = v_user_id;

        IF SQL%ROWCOUNT = 0 THEN
            RAISE_APPLICATION_ERROR(-20134, 'Пользователь не найден');
        END IF;

        COMMIT;
    EXCEPTION
        WHEN INVALID_NUMBER THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(-20135, 'Некорректный ID пользователя');
        WHEN VALUE_ERROR THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(-20136, 'Ошибка преобразования user_id');
        WHEN OTHERS THEN
            ROLLBACK;
            IF SQLCODE BETWEEN -20136 AND -20131 THEN
                RAISE;
            ELSE
                RAISE_APPLICATION_ERROR(-20137, 'Ошибка при изменении пароля: ' || SQLERRM);
            END IF;
    END;

    VAR curs REFCURSOR
    EXEC change_user_password('658886', '$argon2id$v=19$m=65536,t=3,p=4$yxVll7lzqUCakfTFN9IN4w$/WSQwd/35Er1znZ/IKxM2dpfQNm0qTDGUEUjNH4Sizg')
    PRINT curs;