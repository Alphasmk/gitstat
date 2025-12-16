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
        IF p_user_id IS NULL THEN
            RAISE_APPLICATION_ERROR(-20086, 'user_id не может быть NULL');
        END IF;

        IF p_request_type IS NULL THEN
            RAISE_APPLICATION_ERROR(-20087, 'request_type не может быть NULL');
        END IF;

        IF p_request_type NOT IN ('REPOSITORY', 'PROFILE') THEN
            RAISE_APPLICATION_ERROR(-20088, 'request_type должен быть REPOSITORY или PROFILE');
        END IF;

        IF (p_repository_id IS NULL AND p_profile_id IS NULL) THEN
            RAISE_APPLICATION_ERROR(-20089, 'Должен быть указан repository_id или profile_id');
        END IF;

        IF (p_repository_id IS NOT NULL AND p_profile_id IS NOT NULL) THEN
            RAISE_APPLICATION_ERROR(-20090, 'Нельзя указывать одновременно repository_id и profile_id');
        END IF;

        IF p_request_type = 'REPOSITORY' AND p_repository_id IS NULL THEN
            RAISE_APPLICATION_ERROR(-20091, 'Для типа REPOSITORY необходимо указать repository_id');
        END IF;

        IF p_request_type = 'PROFILE' AND p_profile_id IS NULL THEN
            RAISE_APPLICATION_ERROR(-20092, 'Для типа PROFILE необходимо указать profile_id');
        END IF;

        INSERT INTO REQUEST_HISTORY(user_id, repository_id, profile_id, request_type)
        VALUES (p_user_id, p_repository_id, p_profile_id, p_request_type);
    EXCEPTION
        WHEN OTHERS THEN
            IF SQLCODE BETWEEN -20092 AND -20086 THEN
                RAISE;
            ELSE
                RAISE_APPLICATION_ERROR(-20093, 'Ошибка при добавлении запроса в историю: ' || SQLERRM);
            END IF;
    END;

    DROP PROCEDURE add_request_to_general_history;