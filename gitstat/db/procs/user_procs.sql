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
        user_input IN VARCHAR,
        user_cursor OUT SYS_REFCURSOR
    )
    AS
    BEGIN
        OPEN user_cursor FOR
        SELECT * FROM USERS WHERE LOWER(USERS.EMAIL) = LOWER(user_input) OR LOWER(USERS.USERNAME) = LOWER(user_input);
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