CREATE OR REPLACE PACKAGE json_io AS
   FUNCTION export_users_to_json RETURN CLOB;
   PROCEDURE import_users_from_json(p_json_data IN CLOB);
   PROCEDURE export_users_to_file(p_file_name VARCHAR2);
   PROCEDURE import_users_from_file(p_file_name VARCHAR2);
END json_io;
/

CREATE OR REPLACE PACKAGE BODY json_io AS
   PROCEDURE export_users_to_file(p_file_name VARCHAR2) IS
      v_file UTL_FILE.FILE_TYPE;
      v_total_count INTEGER;
      v_offset INTEGER := 0;
      v_first_record BOOLEAN := TRUE;
      v_json_row CLOB;
      v_json_length INTEGER;
      v_newline RAW(2);
      v_comma RAW(2);
      v_bracket_open RAW(2);
      v_bracket_close RAW(2);
      
      CURSOR c_users IS
         SELECT id,
                JSON_OBJECT(
                   'id' VALUE id,
                   'username' VALUE username,
                   'email' VALUE email,
                   'password_hash' VALUE password_hash,
                   'role' VALUE role,
                   'is_blocked' VALUE is_blocked,
                   'created_at' VALUE TO_CHAR(created_at, 'YYYY-MM-DD"T"HH24:MI:SS')
                   RETURNING CLOB
                ) AS json_row
         FROM USERS
         ORDER BY id;
      v_user_id INTEGER;
   BEGIN
      SELECT COUNT(*) INTO v_total_count FROM USERS;
      DBMS_OUTPUT.PUT_LINE('Всего строк в таблице: ' || v_total_count);
      
      v_newline := UTL_RAW.CAST_TO_RAW(CHR(10));
      v_comma := UTL_RAW.CAST_TO_RAW(',');
      v_bracket_open := UTL_RAW.CAST_TO_RAW('[');
      v_bracket_close := UTL_RAW.CAST_TO_RAW(']');
      
      v_file := UTL_FILE.FOPEN('EXPORT_DIR', p_file_name, 'wb', 32767);
      
      UTL_FILE.PUT_RAW(v_file, v_bracket_open);
      UTL_FILE.PUT_RAW(v_file, v_newline);
      
      OPEN c_users;
      LOOP
         BEGIN
            FETCH c_users INTO v_user_id, v_json_row;
            EXIT WHEN c_users%NOTFOUND;
            
            v_json_length := DBMS_LOB.GETLENGTH(v_json_row);
            
            IF NOT v_first_record THEN
               UTL_FILE.PUT_RAW(v_file, v_comma);
               UTL_FILE.PUT_RAW(v_file, v_newline);
            END IF;
            v_first_record := FALSE;
            
            IF v_json_length <= 32000 THEN
               UTL_FILE.PUT_RAW(v_file, UTL_RAW.CAST_TO_RAW('  ' || v_json_row));
            ELSE
               DECLARE
                  v_chunk_size CONSTANT INTEGER := 30000;
                  v_pos INTEGER := 1;
               BEGIN
                  UTL_FILE.PUT_RAW(v_file, UTL_RAW.CAST_TO_RAW('  '));
                  WHILE v_pos <= v_json_length LOOP
                     UTL_FILE.PUT_RAW(v_file, 
                        UTL_RAW.CAST_TO_RAW(DBMS_LOB.SUBSTR(v_json_row, v_chunk_size, v_pos)));
                     v_pos := v_pos + v_chunk_size;
                  END LOOP;
               END;
            END IF;
            
            v_offset := v_offset + 1;
            
            IF MOD(v_offset, 1000) = 0 THEN
               UTL_FILE.FFLUSH(v_file);
               DBMS_OUTPUT.PUT_LINE('Экспортировано: ' || v_offset || '/' || v_total_count);
            END IF;
         EXCEPTION
            WHEN OTHERS THEN
               DBMS_OUTPUT.PUT_LINE('ОШИБКА на строке ID=' || v_user_id || ': ' || SQLERRM);
         END;
      END LOOP;
      CLOSE c_users;
      
      UTL_FILE.PUT_RAW(v_file, v_newline);
      UTL_FILE.PUT_RAW(v_file, v_bracket_close);
      UTL_FILE.FCLOSE(v_file);
      
      DBMS_OUTPUT.PUT_LINE('Экспорт завершен: ' || p_file_name || ', записано строк: ' || v_offset);
      
      IF v_offset < v_total_count THEN
         DBMS_OUTPUT.PUT_LINE('ВНИМАНИЕ: экспортировано меньше строк!');
      END IF;
   EXCEPTION
      WHEN OTHERS THEN
         DBMS_OUTPUT.PUT_LINE('КРИТИЧЕСКАЯ ОШИБКА: ' || SQLERRM);
         IF c_users%ISOPEN THEN
            CLOSE c_users;
         END IF;
         IF UTL_FILE.IS_OPEN(v_file) THEN
            UTL_FILE.FCLOSE(v_file);
         END IF;
         RAISE;
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
      TYPE t_user_rec IS RECORD (
         username VARCHAR2(200),
         email VARCHAR2(400),
         password_hash VARCHAR2(255),
         role VARCHAR2(150),
         is_blocked CHAR(1),
         created_at TIMESTAMP
      );
      TYPE t_users_tab IS TABLE OF t_user_rec;
      v_users t_users_tab;
      
      v_batch_size CONSTANT INTEGER := 1000;
      v_processed INTEGER := 0;
      v_errors INTEGER := 0;
      
      CURSOR c_json IS
         SELECT 
            username,
            email,
            password_hash,
            role,
            is_blocked,
            TO_TIMESTAMP(created_at, 'YYYY-MM-DD"T"HH24:MI:SS') AS created_at
         FROM JSON_TABLE(p_json_data, '$[*]'
            COLUMNS (
               username VARCHAR2(200) PATH '$.username',
               email VARCHAR2(400) PATH '$.email',
               password_hash VARCHAR2(255) PATH '$.password_hash',
               role VARCHAR2(150) PATH '$.role',
               is_blocked CHAR(1) PATH '$.is_blocked',
               created_at VARCHAR2(50) PATH '$.created_at'
            )
         );
   BEGIN
      DBMS_OUTPUT.PUT_LINE('Начало импорта...');
      
      OPEN c_json;
      LOOP
         FETCH c_json BULK COLLECT INTO v_users LIMIT v_batch_size;
         EXIT WHEN v_users.COUNT = 0;
         
         BEGIN
            FORALL i IN 1..v_users.COUNT SAVE EXCEPTIONS
               MERGE INTO USERS u
               USING (SELECT 
                         v_users(i).username AS username,
                         v_users(i).email AS email,
                         v_users(i).password_hash AS password_hash,
                         v_users(i).role AS role,
                         v_users(i).is_blocked AS is_blocked,
                         v_users(i).created_at AS created_at
                      FROM dual) src
               ON (u.email = src.email)
               WHEN MATCHED THEN
                  UPDATE SET
                     u.username = src.username,
                     u.password_hash = src.password_hash,
                     u.role = src.role,
                     u.is_blocked = src.is_blocked
               WHEN NOT MATCHED THEN
                  INSERT (username, email, password_hash, role, is_blocked, created_at)
                  VALUES (src.username, src.email, src.password_hash, 
                          src.role, src.is_blocked, src.created_at);
         EXCEPTION
            WHEN OTHERS THEN
               IF SQLCODE = -24381 THEN
                  v_errors := v_errors + SQL%BULK_EXCEPTIONS.COUNT;
                  FOR i IN 1..SQL%BULK_EXCEPTIONS.COUNT LOOP
                     DBMS_OUTPUT.PUT_LINE('Ошибка в строке ' || SQL%BULK_EXCEPTIONS(i).ERROR_INDEX || 
                                          ': ' || SQLERRM(-SQL%BULK_EXCEPTIONS(i).ERROR_CODE));
                  END LOOP;
               ELSE
                  RAISE;
               END IF;
         END;
         
         v_processed := v_processed + v_users.COUNT;
         COMMIT;
         
         IF MOD(v_processed, 5000) = 0 THEN
            DBMS_OUTPUT.PUT_LINE('Импортировано: ' || v_processed || ' (ошибок: ' || v_errors || ')');
         END IF;
      END LOOP;
      CLOSE c_json;
      
      DBMS_OUTPUT.PUT_LINE('Импорт завершен. Обработано записей: ' || v_processed || 
                          ' (ошибок: ' || v_errors || ')');
   EXCEPTION
      WHEN OTHERS THEN
         IF c_json%ISOPEN THEN
            CLOSE c_json;
         END IF;
         ROLLBACK;
         RAISE_APPLICATION_ERROR(-20001, 'Ошибка импорта: ' || SQLERRM);
   END import_users_from_json;

   PROCEDURE import_users_from_file(p_file_name VARCHAR2) IS
      v_bfile BFILE;
      v_json_data CLOB;
      v_warning INTEGER;
      v_dest_offset INTEGER := 1;
      v_src_offset INTEGER := 1;
      v_lang_ctx INTEGER := DBMS_LOB.DEFAULT_LANG_CTX;
      v_file_size INTEGER;
   BEGIN
      DBMS_OUTPUT.PUT_LINE('Начало чтения файла: ' || p_file_name);
      
      v_bfile := BFILENAME('EXPORT_DIR', p_file_name);
      
      IF DBMS_LOB.FILEEXISTS(v_bfile) = 0 THEN
         RAISE_APPLICATION_ERROR(-20404, 'Файл не найден: ' || p_file_name);
      END IF;
      
      DBMS_LOB.OPEN(v_bfile, DBMS_LOB.LOB_READONLY);
      v_file_size := DBMS_LOB.GETLENGTH(v_bfile);
      DBMS_OUTPUT.PUT_LINE('Размер файла: ' || v_file_size || ' байт');
      
      DBMS_LOB.CREATETEMPORARY(v_json_data, TRUE);
      
      DBMS_LOB.LOADCLOBFROMFILE(
         dest_lob => v_json_data,
         src_bfile => v_bfile,
         amount => v_file_size,
         dest_offset => v_dest_offset,
         src_offset => v_src_offset,
         bfile_csid => DBMS_LOB.DEFAULT_CSID,
         lang_context => v_lang_ctx,
         warning => v_warning
      );
      
      DBMS_LOB.CLOSE(v_bfile);
      
      IF v_warning != 0 THEN
         DBMS_OUTPUT.PUT_LINE('ВНИМАНИЕ: предупреждение при загрузке файла: ' || v_warning);
      END IF;
      
      IF v_json_data IS NOT JSON THEN
         RAISE_APPLICATION_ERROR(-20400, 'Файл не содержит валидный JSON');
      END IF;
      
      DBMS_OUTPUT.PUT_LINE('Файл загружен, начало обработки данных...');
      
      import_users_from_json(v_json_data);
      
      DBMS_LOB.FREETEMPORARY(v_json_data);
      
      DBMS_OUTPUT.PUT_LINE('Импорт из файла завершен: ' || p_file_name);
   EXCEPTION
      WHEN OTHERS THEN
         IF DBMS_LOB.ISOPEN(v_bfile) = 1 THEN
            DBMS_LOB.CLOSE(v_bfile);
         END IF;
         IF DBMS_LOB.ISTEMPORARY(v_json_data) = 1 THEN
            DBMS_LOB.FREETEMPORARY(v_json_data);
         END IF;
         RAISE_APPLICATION_ERROR(-20003, 'Ошибка импорта из файла: ' || SQLERRM);
   END import_users_from_file;
END json_io;