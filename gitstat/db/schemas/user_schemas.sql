-- 1 Создание схем
CREATE USER auth_schema IDENTIFIED BY 1111;
GRANT CREATE SESSION TO auth_schema;

CREATE USER user_schema IDENTIFIED BY 2222;
GRANT CREATE SESSION TO user_schema;

CREATE USER admin_schema IDENTIFIED BY 3333;
GRANT CREATE SESSION TO admin_schema;

CREATE USER moderator_schema IDENTIFIED BY 4444;
GRANT CREATE SESSION TO moderator_schema;

-- 2 Роль авторизации
CREATE ROLE auth_role;
GRANT EXECUTE ON SYSTEM.add_user TO auth_role;
GRANT EXECUTE ON SYSTEM.get_user_by_email_or_login TO auth_role;
GRANT EXECUTE ON SYSTEM.get_user_by_id TO auth_role;
GRANT EXECUTE ON SYSTEM.get_total_users_count TO auth_role;

GRANT auth_role TO auth_schema;

-- 3. Роль пользователя
CREATE ROLE user_role;
GRANT EXECUTE ON SYSTEM.get_user_by_id TO user_role;
GRANT EXECUTE ON SYSTEM.get_profile_by_name TO user_role;
GRANT EXECUTE ON SYSTEM.get_profile_repositories TO user_role;
GRANT EXECUTE ON SYSTEM.add_profile_to_history TO user_role;
GRANT EXECUTE ON SYSTEM.update_profile_history TO user_role;
GRANT EXECUTE ON SYSTEM.is_was_profile_request TO user_role;
GRANT EXECUTE ON SYSTEM.is_was_profile_request_by_login TO user_role;
GRANT EXECUTE ON SYSTEM.get_repository_by_id TO user_role;
GRANT EXECUTE ON SYSTEM.get_repository_by_owner_and_name TO user_role;
GRANT EXECUTE ON SYSTEM.add_repository_to_history TO user_role;
GRANT EXECUTE ON SYSTEM.update_repository_in_history TO user_role;
GRANT EXECUTE ON SYSTEM.is_repository_info_exist TO user_role;
GRANT EXECUTE ON SYSTEM.add_repository_language TO user_role;
GRANT EXECUTE ON SYSTEM.clear_repository_languages TO user_role;
GRANT EXECUTE ON SYSTEM.add_repository_topic TO user_role;
GRANT EXECUTE ON SYSTEM.clear_repository_topics TO user_role;
GRANT EXECUTE ON SYSTEM.add_or_update_repository_license TO user_role;
GRANT EXECUTE ON SYSTEM.delete_repository_license TO user_role;
GRANT EXECUTE ON SYSTEM.add_commit TO user_role;
GRANT EXECUTE ON SYSTEM.get_repository_languages TO user_role;
GRANT EXECUTE ON SYSTEM.get_repository_topics TO user_role;
GRANT EXECUTE ON SYSTEM.get_repository_license TO user_role;
GRANT EXECUTE ON SYSTEM.get_repository_commits TO user_role;
GRANT EXECUTE ON SYSTEM.add_request_to_general_history TO user_role;
GRANT EXECUTE ON SYSTEM.get_user_history TO user_role;

GRANT user_role TO user_schema;

-- 4 Роль модератора
CREATE ROLE moderator_role;
GRANT EXECUTE ON SYSTEM.change_user_block_state TO moderator_role;
GRANT EXECUTE ON SYSTEM.get_all_users TO moderator_role;
GRANT EXECUTE ON SYSTEM.change_user_password TO moderator_role;
GRANT EXECUTE ON SYSTEM.get_user_history_secure TO moderator_role;
GRANT SELECT ON SYSTEM.v_user_history TO moderator_role;

GRANT user_role TO moderator_schema;
GRANT moderator_role TO moderator_schema;


-- 5 Роль администратора
CREATE ROLE admin_role;
GRANT EXECUTE ON SYSTEM.change_user_role TO admin_role;
GRANT EXECUTE ON SYSTEM.delete_user TO admin_role;
GRANT user_role TO admin_schema;
GRANT moderator_role TO admin_schema;
GRANT admin_role TO admin_schema;

DROP USER auth_schema CASCADE;
DROP USER user_schema CASCADE;
DROP USER moderator_schema CASCADE;
DROP USER admin_schema CASCADE;
DROP ROLE auth_role;
DROP ROLE user_role;
DROP ROLE moderator_role;
DROP ROLE admin_role;
BEGIN
  -- REQUEST_HISTORY
  FOR p IN (
    SELECT policy_name
    FROM   redaction_policies
    WHERE  object_owner = 'SYSTEM'
    AND    object_name  = 'REQUEST_HISTORY'
  ) LOOP
    DBMS_REDACT.DROP_POLICY(
      object_schema => 'SYSTEM',
      object_name   => 'REQUEST_HISTORY',
      policy_name   => p.policy_name
    );
  END LOOP;

  -- REPOSITORIES
  FOR p IN (
    SELECT policy_name
    FROM   redaction_policies
    WHERE  object_owner = 'SYSTEM'
    AND    object_name  = 'REPOSITORIES'
  ) LOOP
    DBMS_REDACT.DROP_POLICY(
      object_schema => 'SYSTEM',
      object_name   => 'REPOSITORIES',
      policy_name   => p.policy_name
    );
  END LOOP;

  -- PROFILES
  FOR p IN (
    SELECT policy_name
    FROM   redaction_policies
    WHERE  object_owner = 'SYSTEM'
    AND    object_name  = 'PROFILES'
  ) LOOP
    DBMS_REDACT.DROP_POLICY(
      object_schema => 'SYSTEM',
      object_name   => 'PROFILES',
      policy_name   => p.policy_name
    );
  END LOOP;

  FOR p IN (
    SELECT policy_name
    FROM   redaction_policies
    WHERE  object_owner = 'SYSTEM'
    AND    object_name  = 'V_USER_HISTORY'
  ) LOOP
    DBMS_REDACT.DROP_POLICY(
      object_schema => 'SYSTEM',
      object_name   => 'V_USER_HISTORY',
      policy_name   => p.policy_name
    );
  END LOOP;
END;


VAR rc REFCURSOR;
EXEC SYSTEM.get_user_history_secure('3', :rc);
PRINT rc;