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
END;

DROP PROCEDURE add_profile_to_history;