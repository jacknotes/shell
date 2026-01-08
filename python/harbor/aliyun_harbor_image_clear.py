#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import requests
import time
import sys
from urllib3.exceptions import InsecureRequestWarning

# 禁用 SSL 警告（适用于自签名证书）
requests.packages.urllib3.disable_warnings(category=InsecureRequestWarning)


class ClearHarborV1:
    def __init__(self, harbor_domain, username, password, schema="https", verify_ssl=False, keep_tags=10):
        """
        初始化 Harbor 清理器（适配 Harbor 1.x）
        :param harbor_domain: 如 "harbor.homsom.com"
        :param username: 用户名
        :param password: 密码
        :param schema: http 或 https
        :param verify_ssl: 是否验证 SSL 证书（内网通常设为 False）
        :param keep_tags: 每个仓库保留的最新 tag 数量
        """
        self.harbor_domain = harbor_domain.rstrip('/')
        self.base_url = f"{schema}://{self.harbor_domain}"
        self.api_url = f"{self.base_url}/api"  # Harbor 1.x
        self.username = username
        self.password = password
        self.verify_ssl = verify_ssl
        self.keep_tags = keep_tags

    def _request(self, method, url, **kwargs):
        """通用 HTTP 请求方法，自动添加 Basic Auth"""
        kwargs.setdefault('auth', (self.username, self.password))
        kwargs.setdefault('verify', self.verify_ssl)
        try:
            resp = requests.request(method, url, **kwargs)
            # Harbor 1.x 删除成功返回 200，部分操作可能返回 204
            if resp.status_code not in (200, 201, 204):
                print(f"[ERROR] HTTP {resp.status_code} on {method} {url}")
                print(f"Response: {resp.text}")
                resp.raise_for_status()
            return resp
        except Exception as e:
            print(f"[ERROR] Request failed for {url}: {e}")
            raise

    def get_project_ids(self):
        """获取所有项目的 project_id 列表"""
        print("[INFO] Fetching all projects...")
        url = f"{self.api_url}/projects"
        try:
            resp = self._request("GET", url)
            projects = resp.json()
            if not isinstance(projects, list):
                raise ValueError("Unexpected response format from /api/projects")
            project_ids = [p['project_id'] for p in projects]
            print(f"[INFO] Found {len(project_ids)} projects.")
            return project_ids
        except Exception as e:
            print(f"[FATAL] Failed to fetch projects: {e}")
            sys.exit(1)

    def get_repositories(self, project_id):
        """获取指定项目下的所有仓库（repositories）"""
        print(f"[INFO] Fetching repositories for project_id={project_id}...")
        url = f"{self.api_url}/repositories"
        try:
            resp = self._request("GET", url, params={"project_id": project_id})
            repos = resp.json()
            if not isinstance(repos, list):
                raise ValueError("Unexpected repository list format")
            # 筛选 tags_count > keep_tags 的仓库
            repos_to_clean = [
                repo for repo in repos
                if repo.get("tags_count", 0) > self.keep_tags
            ]
            print(f"[INFO] Project {project_id}: {len(repos)} repos total, "
                  f"{len(repos_to_clean)} need cleaning.")
            return [repo['name'] for repo in repos_to_clean]
        except Exception as e:
            print(f"[WARN] Skip project {project_id} due to error: {e}")
            return []

    def delete_old_tags(self, repo_name):
        """删除仓库中超出保留数量的旧 tag"""
        tag_url = f"{self.api_url}/repositories/{repo_name}/tags"
        try:
            resp = self._request("GET", tag_url)
            tags = resp.json()
            if not isinstance(tags, list):
                print(f"[WARN] Unexpected tag format for {repo_name}, skip.")
                return

            # 按创建时间排序（升序：最早 → 最晚）
            sorted_tags = sorted(tags, key=lambda t: t.get("created", ""))
            total = len(sorted_tags)
            to_delete = sorted_tags[:-self.keep_tags]  # 保留最后 keep_tags 个

            print(f"[INFO] Repo {repo_name}: {total} tags, deleting {len(to_delete)} old ones.")

            for tag in to_delete:
                tag_name = tag['name']
                delete_url = f"{tag_url}/{tag_name}"
                try:
                    self._request("DELETE", delete_url)
                    print(f"[INFO] Deleted tag: {repo_name}:{tag_name}")
                except Exception:
                    print(f"[ERROR] Failed to delete {delete_url}, continue...")
        except Exception as e:
            print(f"[ERROR] Failed to process repo {repo_name}: {e}")

    def trigger_manual_gc(self):
        """触发手动垃圾回收（GC）"""
        print("[INFO] Triggering manual garbage collection...")
        url = f"{self.api_url}/system/gc/schedule"
        data = {"schedule": {"type": "Manual"}}
        try:
            self._request("POST", url, json=data)
            print("[INFO] Manual GC scheduled successfully!")
        except Exception as e:
            print(f"[ERROR] Failed to trigger GC: {e}")


if __name__ == "__main__":
    print("=" * 60)
    print("Harbor 1.x Image Cleaner (Basic Auth)")
    print("DATETIME:", time.strftime("%Y-%m-%d %H:%M:%S", time.localtime()))
    print("=" * 60)

    # ====== 配置区（请按需修改）======
    HARBOR_DOMAIN = "harbor.test.com"
    USERNAME = "username"       
    PASSWORD = "password"       
    KEEP_TAGS = 10                      
    SCHEMA = "https"
    VERIFY_SSL = False                  
    # ================================

    cleaner = ClearHarborV1(
        harbor_domain=HARBOR_DOMAIN,
        username=USERNAME,
        password=PASSWORD,
        schema=SCHEMA,
        verify_ssl=VERIFY_SSL,
        keep_tags=KEEP_TAGS
    )

    try:
        project_ids = cleaner.get_project_ids()

        for pid in project_ids:
            repo_names = cleaner.get_repositories(pid)
            for repo in repo_names:
                cleaner.delete_old_tags(repo)

        print("\n[INFO] All deletions completed. Triggering GC...")
        time.sleep(2)
        cleaner.trigger_manual_gc()

        print("\n✅ Cleanup finished successfully!")
    except KeyboardInterrupt:
        print("\n[INFO] Interrupted by user.")
    except Exception as e:
        print(f"\n[FATAL] Unexpected error: {e}")
        sys.exit(1)