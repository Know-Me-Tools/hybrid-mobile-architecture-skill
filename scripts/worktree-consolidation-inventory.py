#!/usr/bin/env python3
"""Create a loss-prevention manifest for every Git worktree and Prometheus scope."""

from __future__ import annotations

import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import subprocess
from typing import Any


PROMETHEUS_SCOPES = {
    "root": ".prometheus",
    "desktop": "apps/knowme-poc/desktop/.prometheus",
    "src-tauri": "apps/knowme-poc/desktop/src-tauri/.prometheus",
    "rust": "apps/knowme-poc/rust/.prometheus",
}
FRONTMATTER_FIELDS = (
    "id",
    "revision",
    "timestamp",
    "created_at",
    "updated_at",
)


def run(repo: Path, *args: str) -> str:
    return subprocess.run(
        args,
        cwd=repo,
        check=True,
        capture_output=True,
        text=True,
    ).stdout


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def frontmatter(path: Path) -> dict[str, str]:
    if path.suffix != ".md":
        return {}
    text = path.read_text(encoding="utf-8", errors="replace")
    if not text.startswith("---\n"):
        return {}
    end = text.find("\n---\n", 4)
    if end == -1:
        return {}
    header = text[4:end]
    values: dict[str, str] = {}
    for field in FRONTMATTER_FIELDS:
        match = re.search(rf"(?m)^{re.escape(field)}:\s*(.*?)\s*$", header)
        if match:
            values[field] = match.group(1).strip('"\'')
    return values


def parse_worktrees(repo: Path) -> list[dict[str, str]]:
    blocks = run(repo, "git", "worktree", "list", "--porcelain").strip().split("\n\n")
    worktrees: list[dict[str, str]] = []
    for block in blocks:
        record: dict[str, str] = {}
        for line in block.splitlines():
            key, _, value = line.partition(" ")
            record[key] = value
        worktrees.append(record)
    return worktrees


def status_entries(worktree: Path) -> list[dict[str, Any]]:
    output = subprocess.run(
        ["git", "status", "--porcelain=v1", "-z", "--untracked-files=all"],
        cwd=worktree,
        check=True,
        capture_output=True,
    ).stdout
    parts = output.split(b"\0")
    entries: list[dict[str, Any]] = []
    index = 0
    while index < len(parts):
        raw = parts[index]
        if not raw:
            break
        status = raw[:2].decode("ascii", errors="replace")
        path_text = raw[3:].decode("utf-8", errors="surrogateescape")
        entry: dict[str, Any] = {"status": status, "path": path_text}
        if "R" in status or "C" in status:
            index += 1
            entry["source_path"] = parts[index].decode("utf-8", errors="surrogateescape")
        candidate = worktree / path_text
        if candidate.is_file():
            entry["sha256"] = sha256(candidate)
            entry["size"] = candidate.stat().st_size
        elif candidate.is_symlink():
            entry["symlink_target"] = os.readlink(candidate)
        entries.append(entry)
        index += 1
    return entries


def scope_inventory(worktree: Path, scope_rel: str) -> dict[str, Any]:
    scope_root = worktree / scope_rel
    files: list[dict[str, Any]] = []
    if scope_root.is_dir():
        for path in sorted(candidate for candidate in scope_root.rglob("*") if candidate.is_file()):
            record: dict[str, Any] = {
                "path": path.relative_to(worktree).as_posix(),
                "scope_path": path.relative_to(scope_root).as_posix(),
                "sha256": sha256(path),
                "size": path.stat().st_size,
            }
            metadata = frontmatter(path)
            if metadata:
                record["frontmatter"] = metadata
            files.append(record)
    return {
        "exists": scope_root.is_dir(),
        "file_count": len(files),
        "wiki_markdown_count": sum(
            1 for record in files if record["scope_path"].startswith("knowledge/wiki/")
            and record["scope_path"].endswith(".md")
        ),
        "files": files,
    }


def branch_inventory(repo: Path) -> list[dict[str, str]]:
    format_string = "%(refname)|%(objectname)|%(upstream)|%(upstream:track)"
    records: list[dict[str, str]] = []
    output = run(repo, "git", "for-each-ref", f"--format={format_string}", "refs/heads", "refs/remotes")
    for line in output.splitlines():
        ref, sha, upstream, tracking = line.split("|", 3)
        records.append({"ref": ref, "sha": sha, "upstream": upstream, "tracking": tracking})
    return records


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("output", type=Path)
    args = parser.parse_args()

    repo = Path(run(Path.cwd(), "git", "rev-parse", "--show-toplevel").strip())
    worktree_records = []
    for raw in parse_worktrees(repo):
        worktree = Path(raw["worktree"])
        display_name = "primary" if worktree == repo else worktree.name
        worktree_records.append(
            {
                "name": display_name,
                "path": "$REPO_ROOT" if worktree == repo else f"$REPO_ROOT/.claude/worktrees/{worktree.name}",
                "head": raw.get("HEAD", ""),
                "branch": raw.get("branch", "").removeprefix("refs/heads/"),
                "locked": raw.get("locked"),
                "dirty_files": status_entries(worktree),
                "prometheus_scopes": {
                    name: scope_inventory(worktree, relative)
                    for name, relative in PROMETHEUS_SCOPES.items()
                },
            }
        )

    manifest = {
        "schema_version": 1,
        "purpose": "Pre-consolidation loss-prevention inventory",
        "repository": "$REPO_ROOT",
        "baseline_main": run(repo, "git", "rev-parse", "main").strip(),
        "branches": branch_inventory(repo),
        "worktrees": worktree_records,
    }
    output = args.output if args.output.is_absolute() else repo / args.output
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(json.dumps(manifest, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    print(output)


if __name__ == "__main__":
    main()
