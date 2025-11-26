from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
from contextlib import contextmanager, asynccontextmanager
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
    @asynccontextmanager
    async def get_cursor():
        conn = await oracledb.connect_async(user="system", password="1111", dsn="localhost:1522/freepdb1")
        conn.call_timeout = 10000
        try:
            cursor = conn.cursor()
            yield cursor
            await conn.commit()
        except:
            await conn.rollback()
            raise
        finally:
            cursor.close()
            await conn.close()
    
    @staticmethod
    async def execute_get(proc_name: str, value: str | int):
        try:
            async with DBHelper.get_cursor() as cursor:
                ref_cursor = cursor.var(oracledb.CURSOR)
                await cursor.callproc(proc_name, [str(value), ref_cursor])
                result_cursor = ref_cursor.getvalue()
                row = await result_cursor.fetchone()
                if not row:
                    return None
                columns = [col[0].lower() for col in result_cursor.description]
                row_dict = dict(zip(columns, row))
                return row_dict
        except Exception as e:
            raise
    
    @staticmethod
    async def execute_get_all(proc_name: str, value: str | int):
        try:
            async with DBHelper.get_cursor() as cursor:
                ref_cursor = cursor.var(oracledb.CURSOR)
                await cursor.callproc(proc_name, [value, ref_cursor])
                result_cursor = ref_cursor.getvalue()
                rows = await result_cursor.fetchall()
                columns = [col[0].lower() for col in result_cursor.description]
                result = [dict(zip(columns, row)) for row in rows]
                return result
        except Exception as e:
            raise

    @staticmethod
    async def is_was_request(proc_name: str, value: int):
        try:
            async with DBHelper.get_cursor() as cursor:
                out_param = cursor.var(oracledb.NUMBER)
                await cursor.callproc(proc_name, [value, out_param])
                result = out_param.getvalue()
                return result
        except Exception as e:
            raise
    
    @staticmethod
    def convert_date(date: str) -> datetime:
        return datetime.fromisoformat(date.replace('Z', '+00:00'))

    @staticmethod
    async def add_profile_to_history(data):
        created_at = None
        updated_at = None
        if data.get('created_at'):
            created_at = DBHelper.convert_date(data['created_at'])
        if data.get('updated_at'):
            updated_at = DBHelper.convert_date(data['updated_at'])
        async with DBHelper.get_cursor() as cursor:
            await cursor.callproc("add_profile_to_history", [
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
    async def update_profile_history(data):
        updated_at = None
        if data.get('updated_at'):
            updated_at = DBHelper.convert_date(data['updated_at'])
        async with DBHelper.get_cursor() as cursor:
            await cursor.callproc("update_profile_history", [
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
        async with DBHelper.get_cursor() as cursor:
            await cursor.callproc("add_repository_to_history", [
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
            
            if languages:
                for lang in languages:
                    await cursor.callproc("add_repository_language", [
                        data.get('id'),
                        lang,
                        languages.get(lang)
                    ])

            if data.get('topics'):
                for topic in data.get('topics'):
                    await cursor.callproc("add_repository_topic", [
                        data.get('id'),
                        topic
                    ])
        
            if data.get('license'):
                await cursor.callproc("add_or_update_repository_license", [
                    data.get('id'),
                    data.get('license').get('name'),
                    data.get('license').get('spdx_id')
                ])
            if commits and isinstance(commits, list):
                batch_data = []
                for commit in commits:
                    author = commit.get('commit', {}).get('author', {})
                    author_info = commit.get('author') or {}

                    commit_date = DBHelper.convert_date(author.get('date'))
                    batch_data.append((
                        data.get('id'),
                        commit.get('sha'),
                        author_info.get('login'),
                        author_info.get('avatar_url'),
                        commit_date,
                        commit.get('html_url')
                    ))

                if batch_data:
                    sql = """
                        BEGIN
                            add_commit(:1, :2, :3, :4, :5, :6);
                        END;
                    """
                    await cursor.executemany(sql, batch_data)
                
    @staticmethod
    async def update_repository_history(data, languages, commits):
        updated_at = None
        pushed_at = None
        print(json.dumps(data, indent=4))
        if data.get('updated_at'):
            updated_at = DBHelper.convert_date(data['updated_at'])
        if data.get('pushed_at'):
            pushed_at = DBHelper.convert_date(data['pushed_at'])

        async with DBHelper.get_cursor() as cursor:
            await cursor.callproc("update_repository_in_history", [
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
                await cursor.callproc("clear_repository_languages", [
                    data.get('id')
                ])

            for lang in languages:
                await cursor.callproc("add_repository_language", [
                    data.get('id'),
                    lang,
                    languages.get(lang)
                ])

            await cursor.callproc("clear_repository_topics", [
                data.get('id')
            ])

            if data.get('topics'):
                for topic in data.get('topics'):
                    await cursor.callproc("add_repository_topic", [
                        data.get('id'),
                        topic
                    ])

            if data.get('license'):
                await cursor.callproc("add_or_update_repository_license", [
                    data.get('id'),
                    data.get('license').get('name'),
                    data.get('license').get('spdx_id')
                ])
            else:
                await cursor.callproc("delete_repository_license", [
                    data.get('id')
                ])

            if commits and isinstance(commits, list):
                batch_data = []
                for commit in commits:
                    author = commit.get('commit', {}).get('author', {})
                    author_info = commit.get('author') or {}

                    commit_date = DBHelper.convert_date(author.get('date'))
                    batch_data.append((
                        data.get('id'),
                        commit.get('sha'),
                        author_info.get('login'),
                        author_info.get('avatar_url'),
                        commit_date,
                        commit.get('html_url')
                    ))

                if batch_data:
                    sql = """
                        BEGIN
                            add_commit(:1, :2, :3, :4, :5, :6);
                        END;
                    """
                    await cursor.executemany(sql, batch_data)
    
    @staticmethod
    async def get_repository_by_id(id: int):
        async with DBHelper.get_cursor() as cursor:
            repository = {}
            repository = await DBHelper.execute_get("get_repository_by_id", str(id))
            if repository:
                repository['languages'] = await DBHelper.execute_get_all("get_repository_languages", str(id))
                repository['topics'] = await DBHelper.execute_get_all("get_repository_topics", str(id))
                repository['license'] = await DBHelper.execute_get_all("get_repository_license", str(id))
                repository['commits'] = await DBHelper.execute_get_all("get_repository_commits", str(id))
            return repository
    
    @staticmethod
    async def process_repository(repository, current_user):
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

        count = await DBHelper.is_was_request("is_repository_info_exist", int(full_repo.get('id')))
        
        if count == 0:
            await DBHelper.add_repository_to_history(full_repo, languages, commits)
        else:
            await DBHelper.update_repository_history(full_repo, languages, commits)

        async with DBHelper.get_cursor() as cursor:
                await cursor.callproc("add_request_to_general_history", [
                    current_user.id,
                    repository.get('id'),
                    None,
                    'REPOSITORY' 
                ])


    @staticmethod
    async def get_user_repos_from_git(user: str, current_user):
        response = await HTTPHelper.async_http_get(f"https://api.github.com/users/{user}/repos?per_page=30&sort=updated&direction=desc")
        if not response:
            return
        tasks = []
        for repository in response:
            tasks.append(DBHelper.process_repository(repository, current_user))
        await asyncio.gather(*tasks)
    
    @staticmethod
    async def get_user_repos_from_db(user: str):
        repos = await DBHelper.execute_get_all("get_profile_repositories", user)
        return repos