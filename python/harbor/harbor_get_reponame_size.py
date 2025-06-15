import requests
from requests.auth import HTTPBasicAuth

HARBOR = "harbor.domain.com"
HARBOR_URL = f"http://{HARBOR}"
USERNAME = "user"
PASSWORD = "pass"

def get_projects():
    url = f"{HARBOR_URL}/api/projects"
    resp = requests.get(url, auth=HTTPBasicAuth(USERNAME, PASSWORD), verify=False)
    return resp.json()

def get_repositories(project_id):
    url = f"{HARBOR_URL}/api/repositories?project_id={project_id}"
    resp = requests.get(url, auth=HTTPBasicAuth(USERNAME, PASSWORD), verify=False)
    return resp.json()

def get_tags(repo_name):
    url = f"{HARBOR_URL}/api/repositories/{repo_name}/tags"
    resp = requests.get(url, auth=HTTPBasicAuth(USERNAME, PASSWORD), verify=False)
    return resp.json()

def get_manifest_size(repo_name, tag):
    headers = {"Accept": "application/vnd.docker.distribution.manifest.v2+json"}
    url = f"{HARBOR_URL}/api/repositories/{repo_name}/tags/{tag}/manifest"
    resp = requests.get(url, auth=HTTPBasicAuth(USERNAME, PASSWORD), headers=headers, verify=False)
    # print(f"resp.status_code: {resp.status_code}")
    if resp.status_code == 200:
        manifest = resp.json()
        size = 0
        # print(f"resp: {resp.json()}")
        if 'layers' in manifest['manifest']:
             for layer in manifest['manifest']['layers']:
                size += layer.get('size', 0)
                # print(f"size: {size}")
        return size
    return 0

def main():
    import urllib3
    urllib3.disable_warnings()

    project_usage = {}

    projects = get_projects()
    for project in projects:
        # print(project);
        project_id = project['project_id']
        project_name = project['name']
        total_size = 0
        # if project_name != 'base':
        #     continue

        print(f"Scanning project: {project_name}")
        repos = get_repositories(project_id)
        # print(repos);

        for repo in repos:
            repo_name = repo['name']
            tags = get_tags(repo_name)
            # print(tags);
            if not tags:
                continue

            for tag in tags:
                size = get_manifest_size(repo_name, tag['name'])
                print(f"{HARBOR}/{repo_name}:{tag}: {size / (1024 * 1024)} MB")
                total_size += size

        project_usage[project_name] = total_size / (1024 * 1024)  # Convert to MB

    print("\n=== Harbor Project Disk Usage (MB) ===")
    for proj, size in project_usage.items():
        print(f"{proj}: {size:.2f} MB")

if __name__ == "__main__":
    main()
