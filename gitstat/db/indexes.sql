CREATE INDEX idx_profiles_login_upper ON PROFILES(UPPER(login));
CREATE INDEX idx_request_history_user_id ON REQUEST_HISTORY(user_id);
CREATE INDEX idx_request_history_profile_id ON REQUEST_HISTORY(profile_id);
CREATE INDEX idx_request_history_repo_id ON REQUEST_HISTORY(repository_id);
CREATE INDEX idx_repositories_owner_git_id ON REPOSITORIES(owner_git_id);
CREATE INDEX idx_repositories_pushed_at ON REPOSITORIES(pushed_at);
CREATE INDEX idx_repo_languages_repo_id ON REPOSITORY_LANGUAGES(repository_id);
CREATE INDEX idx_repo_topics_repo_id ON REPOSITORY_TOPICS(repository_id);
CREATE INDEX idx_repo_licenses_repo_id ON REPOSITORY_LICENSES(repository_id);
CREATE INDEX idx_users_created_at ON USERS(created_at DESC);
CREATE INDEX idx_users_username_upper ON USERS(UPPER(username));
CREATE INDEX idx_users_email_upper ON USERS(UPPER(email));

SELECT * FROM USERS WHERE email = 'M0V5oravjn3Z9cjMi8CvjY2tQD79RXNZPBV688JqPF0=';
DROP INDEX idx_users_is_blocked;

EXPLAIN PLAN FOR
SELECT * FROM USERS WHERE email = 'M0V5oravjn3Z9cjMi8CvjY2tQD79RXNZPBV688JqPF0=';

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);

EXPLAIN PLAN FOR
SELECT * FROM USERS 
WHERE created_at >= SYSDATE - 30
ORDER BY created_at DESC;
EXEC DBMS_STATS.GATHER_TABLE_STATS('SYSTEM', 'USERS');
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);

CREATE INDEX idx_users_created_at ON USERS(created_at DESC);
DROP INDEX idx_users_created_at;