BEGIN
  DBMS_REDACT.ADD_POLICY(
    object_schema   => 'SYSTEM',
    object_name     => 'V_USER_HISTORY',
    column_name     => 'OBJ_ID',
    policy_name     => 'redact_view_for_moderator',
    function_type   => DBMS_REDACT.PARTIAL,
    function_parameters => '0,5,15',
    expression      => 'SYS_CONTEXT(''USERENV'',''SESSION_USER'') = ''MODERATOR_SCHEMA'''
  );
END;

SELECT * FROM SYSTEM.V_USER_HISTORY;

BEGIN
  DBMS_REDACT.ALTER_POLICY(
    object_schema   => 'SYSTEM',
    object_name     => 'V_USER_HISTORY',
    policy_name     => 'redact_view_for_moderator',
    action          => DBMS_REDACT.ADD_COLUMN,
    column_name     => 'OBJ_NAME',
    function_type   => DBMS_REDACT.REGEXP,
    regexp_pattern  => '(.{3})(.*)',
    regexp_replace_string => '\1****',
    regexp_position => 1,
    regexp_occurrence => 0
  );
END;