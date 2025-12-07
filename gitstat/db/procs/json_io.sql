CREATE OR REPLACE PACKAGE json_io AS
   FUNCTION export_users_to_json RETURN CLOB;
   PROCEDURE import_users_from_json(p_json_data IN CLOB);
   PROCEDURE export_users_to_file(p_file_name VARCHAR2);
   PROCEDURE import_users_from_file(p_file_name VARCHAR2);
END json_io;

CREATE OR REPLACE PACKAGE BODY json_io AS
   
   PROCEDURE export_users_to_file(p_file_name VARCHAR2) IS
      v_file UTL_FILE.FILE_TYPE;
      v_buffer VARCHAR2(32767);
      v_batch_size CONSTANT INTEGER := 1000;
      v_total_count INTEGER;
      v_offset INTEGER := 0;
      v_first_batch BOOLEAN := TRUE;
   BEGIN
      SELECT COUNT(*) INTO v_total_count FROM USERS;
      
      v_file := UTL_FILE.FOPEN('EXPORT_DIR', p_file_name, 'W', 32767);
      
      UTL_FILE.PUT_LINE(v_file, '[');
      
      WHILE v_offset < v_total_count LOOP
         FOR rec IN (
            SELECT 
               JSON_OBJECT(
                  'id' VALUE id,
                  'username' VALUE username,
                  'email' VALUE email,
                  'password_hash' VALUE password_hash,
                  'role' VALUE role,
                  'is_blocked' VALUE is_blocked,
                  'created_at' VALUE TO_CHAR(created_at, 'YYYY-MM-DD"T"HH24:MI:SS')
               ) AS json_row,
               ROW_NUMBER() OVER (ORDER BY id) AS rn
            FROM USERS
            ORDER BY id
            OFFSET v_offset ROWS FETCH NEXT v_batch_size ROWS ONLY
         ) LOOP
            IF v_first_batch AND rec.rn = 1 THEN
               v_first_batch := FALSE;
            ELSE
               UTL_FILE.PUT(v_file, ',');
            END IF;
            
            UTL_FILE.PUT_LINE(v_file, rec.json_row);
         END LOOP;
         
         v_offset := v_offset + v_batch_size;
         DBMS_OUTPUT.PUT_LINE('Экспортировано: ' || v_offset || '/' || v_total_count);
      END LOOP;
      
      UTL_FILE.PUT_LINE(v_file, ']');
      UTL_FILE.FCLOSE(v_file);
      
      DBMS_OUTPUT.PUT_LINE('Экспорт завершен: ' || p_file_name);
   EXCEPTION
      WHEN OTHERS THEN
         IF UTL_FILE.IS_OPEN(v_file) THEN
            UTL_FILE.FCLOSE(v_file);
         END IF;
         RAISE_APPLICATION_ERROR(-20002, 'Ошибка экспорта: ' || SQLERRM);
   END export_users_to_file;

   FUNCTION export_users_to_json RETURN CLOB IS
      json_clob CLOB;
   BEGIN
      SELECT JSON_ARRAYAGG(
         JSON_OBJECT(
            'id' VALUE id,
            'username' VALUE username,
            'email' VALUE email,
            'password_hash' VALUE password_hash,
            'role' VALUE role,
            'is_blocked' VALUE is_blocked,
            'created_at' VALUE TO_CHAR(created_at, 'YYYY-MM-DD"T"HH24:MI:SS')
         )
         ORDER BY id
      )
      INTO json_clob
      FROM USERS
      WHERE ROWNUM <= 1000;

      RETURN json_clob;
   END export_users_to_json;

   PROCEDURE import_users_from_json(p_json_data IN CLOB) IS
   BEGIN
      MERGE INTO USERS u
      USING (
         SELECT 
            jsontable.username,
            jsontable.email,
            jsontable.password_hash,
            jsontable.role,
            jsontable.is_blocked,
            TO_TIMESTAMP(jsontable.created_at, 'YYYY-MM-DD"T"HH24:MI:SS') AS created_at
         FROM JSON_TABLE(p_json_data, '$[*]'
            COLUMNS (
               username VARCHAR2(200) PATH '$.username',
               email VARCHAR2(400) PATH '$.email',
               password_hash VARCHAR2(255) PATH '$.password_hash',
               role VARCHAR2(150) PATH '$.role',
               is_blocked CHAR(1) PATH '$.is_blocked',
               created_at VARCHAR2(50) PATH '$.created_at'
            )
         ) jsontable
      ) src
      ON (u.email = src.email OR u.username = src.username)
      WHEN MATCHED THEN
         UPDATE SET
            u.password_hash = src.password_hash,
            u.role = src.role,
            u.is_blocked = src.is_blocked
      WHEN NOT MATCHED THEN
         INSERT (username, email, password_hash, role, is_blocked, created_at)
         VALUES (src.username, src.email, src.password_hash, src.role, src.is_blocked, src.created_at);

      COMMIT;
      DBMS_OUTPUT.PUT_LINE('Импорт завершен. Обработано записей: ' || SQL%ROWCOUNT);
   EXCEPTION
      WHEN OTHERS THEN
         ROLLBACK;
         RAISE_APPLICATION_ERROR(-20001, 'Ошибка импорта: ' || SQLERRM);
   END import_users_from_json;

   PROCEDURE import_users_from_file(p_file_name VARCHAR2) IS
      v_file UTL_FILE.FILE_TYPE;
      v_buffer VARCHAR2(32767);
      v_json_data CLOB;
   BEGIN
      DBMS_LOB.CREATETEMPORARY(v_json_data, TRUE);
      v_file := UTL_FILE.FOPEN('EXPORT_DIR', p_file_name, 'R', 32767);
      
      LOOP
         BEGIN
            UTL_FILE.GET_LINE(v_file, v_buffer);
            DBMS_LOB.WRITEAPPEND(v_json_data, LENGTH(v_buffer), v_buffer);
         EXCEPTION
            WHEN NO_DATA_FOUND THEN
               EXIT;
         END;
      END LOOP;
      
      UTL_FILE.FCLOSE(v_file);
      import_users_from_json(v_json_data);
      DBMS_LOB.FREETEMPORARY(v_json_data);
      
      DBMS_OUTPUT.PUT_LINE('Импорт из файла завершен: ' || p_file_name);
   EXCEPTION
      WHEN OTHERS THEN
         IF UTL_FILE.IS_OPEN(v_file) THEN
            UTL_FILE.FCLOSE(v_file);
         END IF;
         IF DBMS_LOB.ISTEMPORARY(v_json_data) = 1 THEN
            DBMS_LOB.FREETEMPORARY(v_json_data);
         END IF;
         RAISE_APPLICATION_ERROR(-20003, 'Ошибка импорта из файла: ' || SQLERRM);
   END import_users_from_file;

END json_io;


CREATE OR REPLACE DIRECTORY export_dir AS '/tmp';
GRANT READ, WRITE ON DIRECTORY export_dir TO SYSTEM;