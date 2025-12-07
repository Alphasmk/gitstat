--Представление для реализации технологии маскирования
CREATE OR REPLACE VIEW v_user_history AS
SELECT 
    a.id,
    a.user_id,
    a.repository_id AS obj_id,
    b.name AS obj_name,
    a.request_time,
    a.request_type
FROM SYSTEM.REQUEST_HISTORY a
INNER JOIN SYSTEM.REPOSITORIES b ON b.GIT_ID = a.REPOSITORY_ID
WHERE a.REQUEST_TYPE = 'REPOSITORY'
UNION ALL
SELECT 
    a.id,
    a.user_id,
    a.profile_id AS obj_id,
    b.login AS obj_name,
    a.request_time,
    a.request_type
FROM SYSTEM.REQUEST_HISTORY a
INNER JOIN SYSTEM.PROFILES b ON b.GIT_ID = a.PROFILE_ID
WHERE a.REQUEST_TYPE = 'PROFILE';