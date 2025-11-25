from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
from contextlib import contextmanager
from datetime import datetime
from typing import Any, Dict
from tools.http_helper import HTTPHelper
import asyncio
import oracledb
import json
import logging
import time

class DBHelper:
    DATABASE_URL = "oracle+oracledb://system:1111@localhost:1522/?service_name=freepdb1"
    engine = create_engine(DATABASE_URL)
    Base = declarative_base()
    SessionLocal = sessionmaker(bind=engine, autoflush=False)

    @staticmethod
    def get_db():
        db = DBHelper.SessionLocal()
        try:
            yield db
        finally:
            db.close()

    @staticmethod
    @contextmanager
    def get_cursor():
        conn = oracledb.connect(user="system", password="1111", dsn="localhost:1522/freepdb1")
        conn.call_timeout = 10000
        try:
            cursor = conn.cursor()
            yield cursor
            conn.commit()
        except:
            conn.rollback()
            raise
        finally:
            cursor.close()
            conn.close()
    
    @staticmethod
    def execute_get(proc_name: str, value: str | int):
        try:
            with DBHelper.get_cursor() as cursor:
                ref_cursor = cursor.var(oracledb.CURSOR)
                cursor.callproc(proc_name, [str(value), ref_cursor])
                result_cursor = ref_cursor.getvalue()
                row = result_cursor.fetchone()
                if not row:
                    return None
                columns = [col[0].lower() for col in result_cursor.description]
                row_dict = dict(zip(columns, row))
                return row_dict
        except Exception as e:
            raise
    
    @staticmethod
    def execute_get_all(proc_name: str, value: str | int):
        try:
            with DBHelper.get_cursor() as cursor:
                ref_cursor = cursor.var(oracledb.CURSOR)
                cursor.callproc(proc_name, [value, ref_cursor])
                result_cursor = ref_cursor.getvalue()
                rows = result_cursor.fetchall()
                columns = [col[0].lower() for col in result_cursor.description]
                result = [dict(zip(columns, row)) for row in rows]
                result_cursor.close()
                return result
        except Exception as e:
            raise

    @staticmethod
    def is_was_request(proc_name: str, value: int):
        try:
            with DBHelper.get_cursor() as cursor:
                out_param = cursor.var(oracledb.NUMBER)
                cursor.callproc(proc_name, [value, out_param])
                result = out_param.getvalue()
                return result
        except Exception as e:
            raise
    
    @staticmethod
    def convert_date(date: str) -> datetime:
        return datetime.fromisoformat(date.replace('Z', '+00:00'))

    @staticmethod
    def add_profile_to_history(data):
        created_at = None
        updated_at = None
        if data.get('created_at'):
            created_at = DBHelper.convert_date(data['created_at'])
        if data.get('updated_at'):
            updated_at = DBHelper.convert_date(data['updated_at'])
        with DBHelper.get_cursor() as cursor:
            cursor.callproc("add_profile_to_history", [
                data.get('id'),
                data.get('login'),
                data.get('avatar_url'),
                data.get('html_url'),
                data.get('type'),
                data.get('name'),
                data.get('company'),
                data.get('location'),
                data.get('email'),
                data.get('blog'),
                data.get('bio'),
                data.get('twitter_username'),
                data.get('followers'),
                data.get('following'),
                data.get('public_repos'),
                created_at,
                updated_at])
    
    @staticmethod
    def update_profile_history(data):
        updated_at = None
        if data.get('updated_at'):
            updated_at = DBHelper.convert_date(data['updated_at'])
        with DBHelper.get_cursor() as cursor:
            cursor.callproc("update_profile_history", [
                data.get('id'),
                data.get('login'),
                data.get('avatar_url'),
                data.get('html_url'),
                data.get('type'),
                data.get('name'),
                data.get('company'),
                data.get('location'),
                data.get('email'),
                data.get('blog'),
                data.get('bio'),
                data.get('twitter_username'),
                data.get('followers'),
                data.get('following'),
                data.get('public_repos'),
                updated_at])
            
    @staticmethod
    async def add_repository_to_history(data, languages, commits):
        created_at = None
        updated_at = None
        pushed_at = None
        if data.get('created_at'):
            created_at = DBHelper.convert_date(data['created_at'])
        if data.get('updated_at'):
            updated_at = DBHelper.convert_date(data['updated_at'])
        if data.get('pushed_at'):
            pushed_at = DBHelper.convert_date(data['pushed_at'])
        with DBHelper.get_cursor() as cursor:
            cursor.callproc("add_repository_to_history", [
                str(data.get('id')),
                data.get('name'),
                data.get('owner').get('login'),
                data.get('owner').get('avatar_url'),
                data.get('html_url'),
                data.get('description'),
                data.get('size'),
                data.get('stargazers_count'),
                data.get('forks'),
                data.get('default_branch'),
                data.get('open_issues'),
                data.get('subscribers_count'),
                created_at,
                updated_at,
                pushed_at
            ])
            
            for lang in languages:
                cursor.callproc("add_repository_language", [
                    data.get('id'),
                    lang,
                    languages.get(lang)
                ])
        
            if data.get('topics'):
                for topic in data.get('topics'):
                    cursor.callproc("add_repository_topic", [
                        data.get('id'),
                        topic
                    ])
        
            if data.get('license'):
                cursor.callproc("add_or_update_repository_license", [
                    data.get('id'),
                    data.get('license').get('name'),
                    data.get('license').get('spdx_id')
                ])

            for commit in commits:
                commit_date = DBHelper.convert_date(commit.get('commit').get('author').get('date'))
                cursor.callproc("add_commit", [
                data.get('id'),
                commit.get('sha'),
                commit.get('author').get('login') if commit.get('author') else None,
                commit.get('author').get('avatar_url') if commit.get('author') else None,
                commit_date,
                commit.get('commit').get('url')
            ])
                
    @staticmethod
    async def update_repository_history(data, languages, commits):
        updated_at = None
        pushed_at = None
        if data.get('updated_at'):
            updated_at = DBHelper.convert_date(data['updated_at'])
        if data.get('pushed_at'):
            pushed_at = DBHelper.convert_date(data['pushed_at'])
        with DBHelper.get_cursor() as cursor:
            cursor.callproc("update_repository_in_history", [
                str(data.get('id')),
                data.get('name'),
                data.get('owner').get('login'),
                data.get('owner').get('avatar_url'),
                data.get('html_url'),
                data.get('description'),
                data.get('size'),
                data.get('stargazers_count'),
                data.get('forks'),
                data.get('default_branch'),
                data.get('open_issues'),
                data.get('subscribers_count'),
                updated_at,
                pushed_at
            ])

            if languages:
                cursor.callproc("clear_repository_languages", [
                    data.get('id')
                ])

            for lang in languages:
                cursor.callproc("add_repository_language", [
                    data.get('id'),
                    lang,
                    languages.get(lang)
                ])
            
            cursor.callproc("clear_repository_topics", [
                data.get('id')
            ])

            if data.get('topics'):
                for topic in data.get('topics'):
                    cursor.callproc("add_repository_topic", [
                        data.get('id'),
                        topic
                    ])
            
            if data.get('license'):
                cursor.callproc("add_or_update_repository_license", [
                    data.get('id'),
                    data.get('license').get('name'),
                    data.get('license').get('spdx_id')
                ])
            else:
                cursor.callproc("delete_repository_license", [
                    data.get('id')
                ])


            for commit in commits:
                commit_date = DBHelper.convert_date(commit.get('commit').get('author').get('date'))
                cursor.callproc("add_commit", [
                data.get('id'),
                commit.get('sha'),
                commit.get('author').get('login') if commit.get('author') else None,
                commit.get('author').get('avatar_url') if commit.get('author') else None,
                commit_date,
                commit.get('commit').get('url')
            ])
    
    @staticmethod
    def get_repository_by_id(id: int):
        with DBHelper.get_cursor() as cursor:
            repository = {}
            repository = DBHelper.execute_get("get_repository_by_id", str(id))
            if repository:
                repository['languages'] = DBHelper.execute_get_all("get_repository_languages", str(id))
                repository['topics'] = DBHelper.execute_get_all("get_repository_topics", str(id))
                repository['license'] = DBHelper.execute_get_all("get_repository_license", str(id))
                repository['commits'] = DBHelper.execute_get_all("get_repository_commits", str(id))
            return repository
    
    @staticmethod
    async def process_repository(repository):
        full_repo = await HTTPHelper.async_http_get(
            f"https://api.github.com/repos/{repository.get('owner').get('login')}/{repository.get('name')}"
        )

        languages_task = HTTPHelper.async_http_get(
            f"https://api.github.com/repos/{repository.get('owner').get('login')}/{repository.get('name')}/languages"
        )
        commits_task = HTTPHelper.async_http_get(
            f"https://api.github.com/repos/{repository.get('owner').get('login')}/{repository.get('name')}/commits?per_page=25"
        )

        languages, commits = await asyncio.gather(languages_task, commits_task)

        count = DBHelper.is_was_request("is_repository_info_exist", int(full_repo.get('id')))

        if count == 0:
            await DBHelper.add_repository_to_history(full_repo, languages, commits)
        else:
            await DBHelper.update_repository_history(full_repo, languages, commits)


    @staticmethod
    async def get_user_repos_from_git(user: str):
        response = await HTTPHelper.async_http_get(f"https://api.github.com/users/{user}/repos?per_page=20")
        if not response:
            return
        tasks = []
        for repository in response:
            tasks.append(DBHelper.process_repository(repository))
        await asyncio.gather(*tasks)
    
    @staticmethod
    def get_user_repos_from_db(user: str):
        repos = DBHelper.execute_get_all("get_profile_repositories", user)
        return repos