"""
Install the blog-post auto-render template into a list of repos.

For each target repo:
  1. (Optional) switch Pages build_type to legacy.
  2. PUT .github/workflows/render-blogs.yml at the default branch.
  3. PUT _blog-style.css at the default branch.
  4. PUT _blog-format.yml at the default branch.
  5. PUT .nojekyll at the Pages-served root (docs/.nojekyll or .nojekyll).
  6. Trigger the workflow so any existing blog*.qmd gets rendered.

Idempotent: PUT with --sha if file exists, PUT without --sha if not.
"""
import base64, json, os, subprocess, sys, time

OWNER = "adamdennett"

# repos to set up. Includes defibrillator-analysis to upgrade its workflow.
# (bh_school_choice + council_tax skipped — no Pages enabled.)
TARGETS = [
    "BH_Schools_2",
    "BH_Schools_Consultation",
    "school_attainment_tool",
    "BrightonRestaurantsMap",
    "west_london_alliance",
    "EPC_Analysis_Website",  # also needs build_type switched
    "EPC_Data_Analysis",
    "Synthetic-LS-spines",
    "SIModelling",
    "defibrillator-analysis",  # already set up; upgrade workflow + ensure consistency
]

ROOT = r"E:\ad_live_website\templates"
LOCAL_FILES = {
    ".github/workflows/render-blogs.yml": os.path.join(ROOT, "render-blogs.yml"),
    "_blog-style.css":                    os.path.join(ROOT, "_blog-style.css"),
    "_blog-format.yml":                   os.path.join(ROOT, "_blog-format.yml"),
}


def gh(args, input_bytes=None, capture=True):
    r = subprocess.run(["gh"] + args, input=input_bytes,
                       capture_output=capture, check=False)
    return r.returncode, r.stdout, r.stderr


def get_default_branch(repo):
    rc, out, _ = gh(["api", f"repos/{OWNER}/{repo}",
                     "--jq", ".default_branch"])
    return out.decode().strip() if rc == 0 else "main"


def get_pages(repo):
    rc, out, _ = gh(["api", f"repos/{OWNER}/{repo}/pages"])
    if rc != 0:
        return None
    return json.loads(out)


def ensure_legacy_build(repo):
    pg = get_pages(repo)
    if not pg:
        return
    if pg.get("build_type") != "legacy":
        print(f"  → switching Pages build_type to legacy")
        gh(["api", "-X", "PUT", f"repos/{OWNER}/{repo}/pages",
            "-f", "build_type=legacy"])


def get_existing_sha(repo, path, branch):
    rc, out, _ = gh(["api", f"repos/{OWNER}/{repo}/contents/{path}?ref={branch}",
                     "--jq", ".sha"])
    if rc != 0:
        return None
    sha = out.decode().strip()
    return sha if sha and not sha.startswith("{") else None


def put_file(repo, path, content_bytes, branch, message):
    sha = get_existing_sha(repo, path, branch)
    body = {
        "message": message,
        "content": base64.b64encode(content_bytes).decode("ascii"),
        "branch": branch,
    }
    if sha:
        body["sha"] = sha
    rc, out, err = gh(["api", "-X", "PUT",
                       f"repos/{OWNER}/{repo}/contents/{path}",
                       "--input", "-"],
                      input_bytes=json.dumps(body).encode("utf-8"))
    if rc != 0:
        sys.stderr.write(f"  ✗ {path}: {err.decode().strip()}\n")
        return None
    sha8 = json.loads(out)["commit"]["sha"][:8]
    verb = "updated" if sha else "created"
    print(f"  {verb} {path} → {sha8}")
    return sha8


def install_one(repo):
    print(f"=== {repo} ===")
    branch = get_default_branch(repo)
    print(f"  default branch: {branch}")

    ensure_legacy_build(repo)

    pg = get_pages(repo)
    src_path = pg.get("source", {}).get("path", "/") if pg else "/"
    nojekyll_dest = "docs/.nojekyll" if src_path == "/docs" else ".nojekyll"
    print(f"  Pages serves from: {src_path} → .nojekyll at {nojekyll_dest}")

    # Install the three template files
    for dest, src_local in LOCAL_FILES.items():
        with open(src_local, "rb") as f:
            content = f.read()
        put_file(repo, dest, content, branch,
                 f"Install {dest} (blog post auto-render template)")

    # Install .nojekyll
    put_file(repo, nojekyll_dest, b"", branch,
             "Add .nojekyll so Pages doesn't filter files starting with _ [skip ci]")

    print()


def main():
    for r in TARGETS:
        try:
            install_one(r)
        except Exception as e:
            print(f"  ✗ EXCEPTION: {e}")


if __name__ == "__main__":
    main()
