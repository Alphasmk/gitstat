    --Добавить запрос в общую историю
    CREATE OR REPLACE PROCEDURE add_request_to_general_history
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
    EXCEPTION
        WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR(-20019, 'Ошибка при добавлении запроса в историю: ' || SQLERRM);
    END;

    DROP PROCEDURE add_request_to_general_history;

    SELECT * FROM REQUEST_HISTORY ORDER BY REQUEST_TIME;