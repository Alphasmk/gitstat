-- Схема для авторизации
CREATE USER auth_schema IDENTIFIED BY 1111;
GRANT CREATE SESSION TO auth_schema;
GRANT EXECUTE ON SYSTEM.add_user to auth_schema;
GRANT EXECUTE ON SYSTEM.get_user_by_email_or_login to auth_schema;
GRANT EXECUTE ON SYSTEM.get_user_by_id to auth_schema;
GRANT EXECUTE ON SYSTEM.get_total_users_count TO auth_schema;

-- Схема пользователя
CREATE USER user_schema IDENTIFIED BY 2222;
GRANT CREATE SESSION TO user_schema;
GRANT EXECUTE ON SYSTEM.get_user_by_id to user_schema;
GRANT EXECUTE ON SYSTEM.get_profile_by_name TO user_schema;
GRANT EXECUTE ON SYSTEM.get_profile_repositories TO user_schema;
GRANT EXECUTE ON SYSTEM.add_profile_to_history TO user_schema;
GRANT EXECUTE ON SYSTEM.update_profile_history TO user_schema;
GRANT EXECUTE ON SYSTEM.is_was_profile_request TO user_schema;
GRANT EXECUTE ON SYSTEM.get_repository_by_id TO user_schema;
GRANT EXECUTE ON SYSTEM.get_repository_by_owner_and_name TO user_schema;
GRANT EXECUTE ON SYSTEM.add_repository_to_history TO user_schema;
GRANT EXECUTE ON SYSTEM.update_repository_in_history TO user_schema;
GRANT EXECUTE ON SYSTEM.is_repository_info_exist TO user_schema;
GRANT EXECUTE ON SYSTEM.add_repository_language TO user_schema;
GRANT EXECUTE ON SYSTEM.clear_repository_languages TO user_schema;
GRANT EXECUTE ON SYSTEM.add_repository_topic TO user_schema;
GRANT EXECUTE ON SYSTEM.clear_repository_topics TO user_schema;
GRANT EXECUTE ON SYSTEM.add_or_update_repository_license TO user_schema;
GRANT EXECUTE ON SYSTEM.delete_repository_license TO user_schema;
GRANT EXECUTE ON SYSTEM.add_commit TO user_schema;
GRANT EXECUTE ON SYSTEM.get_repository_languages TO user_schema;
GRANT EXECUTE ON SYSTEM.get_repository_topics TO user_schema;
GRANT EXECUTE ON SYSTEM.get_repository_license TO user_schema;
GRANT EXECUTE ON SYSTEM.get_repository_commits TO user_schema;
GRANT EXECUTE ON SYSTEM.add_request_to_general_history TO user_schema;

-- Схема администратора
CREATE USER admin_schema IDENTIFIED BY 3333;
GRANT CREATE SESSION TO admin_schema;
GRANT EXECUTE ON SYSTEM.admin_get_all_users TO admin_schema;
GRANT EXECUTE ON SYSTEM.admin_get_request_history TO admin_schema;
GRANT EXECUTE ON SYSTEM.admin_change_role TO admin_schema;

-- Схема модератора
CREATE USER moderator_schema IDENTIFIED BY 4444;
GRANT CREATE SESSION TO moderator_schema;

-- PL/SQL скрипт для копирования ролей
BEGIN
    FOR rec IN (
        SELECT table_name 
        FROM DBA_TAB_PRIVS 
        WHERE grantee = 'AUTH_SCHEMA' 
        AND privilege = 'EXECUTE' 
        AND owner = 'SYSTEM'
    ) LOOP
        EXECUTE IMMEDIATE 'GRANT EXECUTE ON SYSTEM.' || rec.table_name || ' TO user_schema';
        EXECUTE IMMEDIATE 'GRANT EXECUTE ON SYSTEM.' || rec.table_name || ' TO admin_schema';
        EXECUTE IMMEDIATE 'GRANT EXECUTE ON SYSTEM.' || rec.table_name || ' TO moderator_schema';
    END LOOP;
END;