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