#!/usr/bin/env python3
"""Losslessly consolidate Prometheus wikis and event logs from Git worktrees."""

from __future__ import annotations

from collections import defaultdict
from dataclasses import dataclass
import argparse
import hashlib
import json
from pathlib import Path
import re
import subprocess
from typing import Iterable


SCOPES = {
    "root": ".prometheus",
    "desktop": "apps/knowme-poc/desktop/.prometheus",
    "src-tauri": "apps/knowme-poc/desktop/src-tauri/.prometheus",
    "rust": "apps/knowme-poc/rust/.prometheus",
}
SNAPSHOT_REF = "codex/pre-consolidation-main-snapshot"
CONSOLIDATION_DATE = "2026-07-17"


@dataclass(frozen=True)
class Source:
    name: str
    branch: str
    root: Path | None = None
    git_ref: str | None = None


@dataclass(frozen=True)
class FileVariant:
    source: Source
    repository_path: str
    scope_path: str
    data: bytes

    @property
    def sha256(self) -> str:
        return hashlib.sha256(self.data).hexdigest()

    @property
    def text(self) -> str:
        return self.data.decode("utf-8", errors="replace")


class DisjointSet:
    def __init__(self, size: int) -> None:
        self.parent = list(range(size))

    def find(self, item: int) -> int:
        while self.parent[item] != item:
            self.parent[item] = self.parent[self.parent[item]]
            item = self.parent[item]
        return item

    def union(self, left: int, right: int) -> None:
        left_root = self.find(left)
        right_root = self.find(right)
        if left_root != right_root:
            self.parent[right_root] = left_root


def git(repo: Path, *args: str, text: bool = True) -> str | bytes:
    result = subprocess.run(
        ["git", *args], cwd=repo, check=True, capture_output=True, text=text
    )
    return result.stdout


def sources(repo: Path) -> list[Source]:
    result = [Source("primary", "main-pre-consolidation", git_ref=SNAPSHOT_REF)]
    # Include implementation-authored wiki pages while preferring the frozen primary snapshot.
    result.append(Source("integration", "codex/consolidate-main", root=repo))
    porcelain = str(git(repo, "worktree", "list", "--porcelain"))
    for block in porcelain.strip().split("\n\n"):
        values: dict[str, str] = {}
        for line in block.splitlines():
            key, _, value = line.partition(" ")
            values[key] = value
        root = Path(values["worktree"])
        if root == repo:
            continue
        result.append(
            Source(
                root.name,
                values.get("branch", "detached").removeprefix("refs/heads/"),
                root=root,
            )
        )
    return result


def source_files(repo: Path, source: Source, scope_root: str) -> list[FileVariant]:
    variants: list[FileVariant] = []
    if source.git_ref:
        output = str(git(repo, "ls-tree", "-r", "--name-only", source.git_ref, "--", scope_root))
        for repository_path in output.splitlines():
            data = git(repo, "show", f"{source.git_ref}:{repository_path}", text=False)
            assert isinstance(data, bytes)
            variants.append(
                FileVariant(
                    source,
                    repository_path,
                    Path(repository_path).relative_to(scope_root).as_posix(),
                    data,
                )
            )
        return variants

    assert source.root is not None
    root = source.root / scope_root
    if not root.is_dir():
        return variants
    for path in sorted(candidate for candidate in root.rglob("*") if candidate.is_file()):
        # A rerun must not ingest its own generated provenance as a new historical source.
        relative = path.relative_to(root).as_posix()
        if relative.startswith("consolidation/worktree-wiki-merge/"):
            continue
        if relative.startswith("knowledge/wiki/history/worktree-consolidation/"):
            continue
        variants.append(
            FileVariant(
                source,
                path.relative_to(source.root).as_posix(),
                relative,
                path.read_bytes(),
            )
        )
    return variants


def frontmatter(text: str) -> dict[str, str]:
    if not text.startswith("---\n"):
        return {}
    end = text.find("\n---\n", 4)
    if end == -1:
        return {}
    values: dict[str, str] = {}
    for line in text[4:end].splitlines():
        key, separator, value = line.partition(":")
        if separator and key in {"type", "id", "title", "revision", "timestamp", "created_at", "updated_at"}:
            values[key] = value.strip().strip('"\'')
    return values


def body(text: str) -> str:
    if text.startswith("---\n"):
        end = text.find("\n---\n", 4)
        if end != -1:
            return text[end + 5 :].lstrip()
    return text


def redact(text: str) -> tuple[str, list[tuple[str, int]]]:
    replacements = (
        (
            "repository-worktree-path",
            re.compile(r"/Users/gqadonis/Projects/hybrid-mobile-architecture-src(?:/\.claude/worktrees/[^\s`\"']+)?"),
            "$REPO_ROOT",
        ),
        (
            "home-directory",
            re.compile(r"/Users/gqadonis(?=/|\b)"),
            "$HOME",
        ),
        ("aws-access-key", re.compile(r"\bAKIA[0-9A-Z]{16}\b"), "[REDACTED_SECRET]"),
        (
            "github-token",
            re.compile(r"\bgh[pousr]_[A-Za-z0-9_]{20,}\b"),
            "[REDACTED_SECRET]",
        ),
        (
            "openai-style-key",
            re.compile(r"\bsk-[A-Za-z0-9_-]{20,}\b"),
            "[REDACTED_SECRET]",
        ),
        (
            "bearer-token",
            re.compile(r"(?i)\bBearer\s+[A-Za-z0-9._~+/-]{16,}=*"),
            "Bearer [REDACTED_SECRET]",
        ),
    )
    records: list[tuple[str, int]] = []
    redacted = text
    for kind, pattern, replacement in replacements:
        redacted, count = pattern.subn(replacement, redacted)
        if count:
            records.append((kind, count))
    return redacted, records


def source_rank(source: Source) -> tuple[int, str]:
    preferred = {"primary": 0, "integration": 1}
    return preferred.get(source.name, 2), source.name


def wiki_components(pages: list[FileVariant]) -> list[list[FileVariant]]:
    dsu = DisjointSet(len(pages))
    by_filename: dict[str, int] = {}
    by_id: dict[str, int] = {}
    for index, page in enumerate(pages):
        filename = Path(page.scope_path).name
        if filename in by_filename:
            dsu.union(index, by_filename[filename])
        else:
            by_filename[filename] = index
        page_id = frontmatter(page.text).get("id")
        if page_id:
            if page_id in by_id:
                dsu.union(index, by_id[page_id])
            else:
                by_id[page_id] = index
    grouped: dict[int, list[FileVariant]] = defaultdict(list)
    for index, page in enumerate(pages):
        grouped[dsu.find(index)].append(page)
    return list(grouped.values())


def event_timestamp(line: str) -> str:
    try:
        value = json.loads(line)
    except json.JSONDecodeError:
        return "9999-invalid"
    return str(value.get("timestamp", "9999-missing"))


def build_events(
    scope_name: str,
    output_root: Path,
    variants: list[FileVariant],
    manifest: dict,
) -> None:
    provenance: dict[str, dict] = {}
    by_id: dict[str, list[dict]] = defaultdict(list)
    for variant in variants:
        if variant.scope_path != "events.jsonl":
            continue
        for line_number, original_line in enumerate(variant.text.splitlines(), 1):
            if not original_line.strip():
                continue
            line_hash = hashlib.sha256(original_line.encode()).hexdigest()
            redacted_line, redactions = redact(original_line)
            entry = provenance.setdefault(
                line_hash,
                {
                    "original_sha256": line_hash,
                    "record": redacted_line,
                    "sources": [],
                    "redactions": [{"kind": kind, "occurrences": count} for kind, count in redactions],
                },
            )
            entry["sources"].append(
                {
                    "source": variant.source.name,
                    "branch": variant.source.branch,
                    "path": variant.repository_path,
                    "line": line_number,
                }
            )
            try:
                event_id = str(json.loads(original_line).get("id", ""))
            except json.JSONDecodeError:
                event_id = ""
            if event_id:
                by_id[event_id].append(entry)
    records = sorted(provenance.values(), key=lambda item: (event_timestamp(item["record"]), item["original_sha256"]))
    (output_root / "events.jsonl").write_text(
        "".join(item["record"].rstrip() + "\n" for item in records), encoding="utf-8"
    )
    conflicts = []
    for event_id, entries in sorted(by_id.items()):
        unique = {entry["original_sha256"]: entry for entry in entries}
        if len(unique) > 1:
            conflicts.append({"id": event_id, "variants": list(unique.values())})
    provenance_root = output_root / "consolidation/worktree-wiki-merge"
    provenance_root.mkdir(parents=True, exist_ok=True)
    (provenance_root / "event-provenance.json").write_text(
        json.dumps(records, indent=2, sort_keys=True) + "\n", encoding="utf-8"
    )
    (provenance_root / "event-conflicts.json").write_text(
        json.dumps(conflicts, indent=2, sort_keys=True) + "\n", encoding="utf-8"
    )
    manifest["scopes"][scope_name]["events"] = {
        "unique_records": len(records),
        "conflicting_ids": len(conflicts),
        "provenance": str((provenance_root / "event-provenance.json").relative_to(output_root)),
        "conflicts": str((provenance_root / "event-conflicts.json").relative_to(output_root)),
    }


def build_log(output_root: Path, variants: list[FileVariant]) -> None:
    entries: dict[str, list[str]] = defaultdict(list)
    seen: dict[str, set[str]] = defaultdict(set)
    for variant in sorted(variants, key=lambda item: source_rank(item.source)):
        if variant.scope_path != "knowledge/wiki/log.md":
            continue
        current_date = "Undated"
        redacted, _ = redact(variant.text)
        for line in redacted.splitlines():
            if line.startswith("## "):
                current_date = line[3:].strip()
            elif line.startswith("* ") and line not in seen[current_date]:
                seen[current_date].add(line)
                entries[current_date].append(line)
    lines = ["# Update Log", ""]
    for date in sorted(entries):
        lines.extend((f"## {date}", *entries[date], ""))
    (output_root / "knowledge/wiki/log.md").write_text("\n".join(lines).rstrip() + "\n", encoding="utf-8")


def build_index(output_root: Path) -> None:
    categories: dict[str, list[tuple[str, str]]] = defaultdict(list)
    wiki_root = output_root / "knowledge/wiki"
    for path in sorted(wiki_root.glob("*.md")):
        if path.name in {"index.md", "log.md"}:
            continue
        metadata = frontmatter(path.read_text(encoding="utf-8", errors="replace"))
        title = metadata.get("title", path.stem.replace("-", " ").title())
        categories[metadata.get("type", "Reference")].append((title, path.name))
    lines = ["# Wiki Index", ""]
    for category in sorted(categories):
        lines.extend((f"## {category}", ""))
        for title, filename in sorted(categories[category], key=lambda value: value[0].casefold()):
            lines.append(f"* [{title}](/${filename})".replace("/$", "/"))
        lines.append("")
    (wiki_root / "index.md").write_text("\n".join(lines).rstrip() + "\n", encoding="utf-8")


def build_wiki(
    scope_name: str,
    output_root: Path,
    variants: list[FileVariant],
    manifest: dict,
) -> None:
    wiki_root = output_root / "knowledge/wiki"
    wiki_root.mkdir(parents=True, exist_ok=True)
    for path in wiki_root.glob("*.md"):
        path.unlink()
    pages = [
        variant
        for variant in variants
        if variant.scope_path.startswith("knowledge/wiki/")
        and variant.scope_path.endswith(".md")
        and Path(variant.scope_path).name not in {"index.md", "log.md"}
    ]
    mappings = []
    for component in wiki_components(pages):
        component.sort(key=lambda page: (source_rank(page.source), page.scope_path, page.sha256))
        selected = component[0]
        destination = Path(selected.scope_path).name
        unique_variants: list[FileVariant] = []
        seen_hashes: set[str] = set()
        for variant in component:
            if variant.sha256 not in seen_hashes:
                seen_hashes.add(variant.sha256)
                unique_variants.append(variant)
        canonical, canonical_redactions = redact(selected.text)
        history_destinations: dict[str, str] = {}
        if len(unique_variants) > 1:
            canonical = canonical.rstrip() + "\n\n## Consolidated source variants\n"
            for variant in unique_variants:
                redacted, redactions = redact(variant.text)
                history_path = (
                    wiki_root
                    / "history/worktree-consolidation"
                    / variant.source.name
                    / Path(variant.scope_path).name
                )
                history_path.parent.mkdir(parents=True, exist_ok=True)
                history_path.write_text(
                    f"<!-- source={variant.source.name}; branch={variant.source.branch}; "
                    f"original_sha256={variant.sha256} -->\n{redacted}",
                    encoding="utf-8",
                )
                history_destinations[variant.sha256] = history_path.relative_to(output_root).as_posix()
                if variant.sha256 != selected.sha256:
                    canonical += (
                        f"\n### Variant from `{variant.source.name}`\n\n"
                        f"Original path: `{variant.repository_path}`  \n"
                        f"Original SHA-256: `{variant.sha256}`\n\n"
                        f"{body(redacted).rstrip()}\n"
                    )
                for kind, count in redactions:
                    manifest["redactions"].append(
                        {
                            "scope": scope_name,
                            "source": variant.source.name,
                            "path": variant.repository_path,
                            "original_sha256": variant.sha256,
                            "kind": kind,
                            "occurrences": count,
                        }
                    )
        else:
            for kind, count in canonical_redactions:
                manifest["redactions"].append(
                    {
                        "scope": scope_name,
                        "source": selected.source.name,
                        "path": selected.repository_path,
                        "original_sha256": selected.sha256,
                        "kind": kind,
                        "occurrences": count,
                    }
                )
        (wiki_root / destination).write_text(canonical.rstrip() + "\n", encoding="utf-8")

        filenames = sorted({Path(variant.scope_path).name for variant in component})
        metadata = frontmatter(selected.text)
        for filename in filenames:
            if filename == destination:
                continue
            alias_id = f"{metadata.get('id', Path(destination).stem)}-alias-{Path(filename).stem}"
            alias_title = f"Alias for {metadata.get('title', Path(destination).stem)}"
            (wiki_root / filename).write_text(
                "---\n"
                "type: Reference\n"
                f"id: {alias_id}\n"
                f"title: {alias_title}\n"
                f"timestamp: {CONSOLIDATION_DATE}T00:00:00Z\n"
                "revision: 1\n"
                "---\n\n"
                f"This historical filename now resolves to [{metadata.get('title', destination)}]"
                f"(/{destination}). Its original variants are retained in the worktree-consolidation history.\n",
                encoding="utf-8",
            )

        for variant in component:
            metadata = frontmatter(variant.text)
            mappings.append(
                {
                    "source": variant.source.name,
                    "branch": variant.source.branch,
                    "original_path": variant.repository_path,
                    "original_sha256": variant.sha256,
                    "id": metadata.get("id"),
                    "revision": metadata.get("revision"),
                    "timestamp": metadata.get("timestamp") or metadata.get("updated_at"),
                    "canonical_destination": f"knowledge/wiki/{destination}",
                    "history_destination": history_destinations.get(variant.sha256),
                    "byte_identical_deduplicated": len(unique_variants) == 1,
                }
            )
    build_log(output_root, variants)
    build_index(output_root)
    final_pages = list(wiki_root.glob("*.md"))
    manifest["scopes"][scope_name]["wiki"] = {
        "source_entries": len(pages),
        "canonical_page_paths": len(final_pages),
        "mappings": mappings,
    }


def build_other_files(output_root: Path, variants: list[FileVariant], manifest: dict, scope_name: str) -> None:
    groups: dict[str, list[FileVariant]] = defaultdict(list)
    for variant in variants:
        if variant.scope_path == "events.jsonl" or variant.scope_path.startswith("knowledge/wiki/"):
            continue
        if variant.scope_path.startswith("consolidation/"):
            continue
        groups[variant.scope_path].append(variant)
    records = []
    for relative, group in sorted(groups.items()):
        group.sort(key=lambda item: source_rank(item.source))
        selected = group[0]
        canonical, redactions = redact(selected.text)
        destination = output_root / relative
        destination.parent.mkdir(parents=True, exist_ok=True)
        destination.write_text(canonical, encoding="utf-8")
        unique: dict[str, FileVariant] = {variant.sha256: variant for variant in group}
        preserved = []
        if len(unique) > 1:
            for variant in unique.values():
                redacted, variant_redactions = redact(variant.text)
                history = output_root / "consolidation/worktree-wiki-merge/files" / variant.source.name / relative
                history.parent.mkdir(parents=True, exist_ok=True)
                history.write_text(redacted, encoding="utf-8")
                preserved.append(history.relative_to(output_root).as_posix())
                redactions.extend(variant_redactions)
        records.append(
            {
                "path": relative,
                "canonical_source": selected.source.name,
                "source_hashes": sorted(unique),
                "preserved_variants": preserved,
            }
        )
        for kind, count in redactions:
            manifest["redactions"].append(
                {"scope": scope_name, "path": relative, "kind": kind, "occurrences": count}
            )
    manifest["scopes"][scope_name]["other_files"] = records


def verify(manifest: dict) -> None:
    minimums = {"root": 238, "desktop": 20, "src-tauri": 3, "rust": 34}
    errors = []
    for scope, minimum in minimums.items():
        actual = manifest["scopes"][scope]["wiki"]["canonical_page_paths"]
        if actual < minimum:
            errors.append(f"{scope}: {actual} < {minimum}")
        for mapping in manifest["scopes"][scope]["wiki"]["mappings"]:
            if not mapping["canonical_destination"]:
                errors.append(f"unmapped {scope} entry: {mapping['original_path']}")
    if errors:
        raise RuntimeError("wiki consolidation proof failed: " + "; ".join(errors))


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--manifest", default=".prometheus/consolidation/2026-07-17/wiki-consolidation-manifest.json")
    args = parser.parse_args()
    repo = Path(str(git(Path.cwd(), "rev-parse", "--show-toplevel")).strip())
    all_sources = sources(repo)
    manifest = {
        "schema_version": 1,
        "purpose": "Lossless Prometheus wiki and event consolidation",
        "snapshot_ref": SNAPSHOT_REF,
        "sources": [{"name": source.name, "branch": source.branch} for source in all_sources],
        "scopes": {scope: {} for scope in SCOPES},
        "redactions": [],
    }
    for scope_name, scope_relative in SCOPES.items():
        variants = [
            variant
            for source in all_sources
            for variant in source_files(repo, source, scope_relative)
        ]
        output_root = repo / scope_relative
        output_root.mkdir(parents=True, exist_ok=True)
        build_events(scope_name, output_root, variants, manifest)
        build_wiki(scope_name, output_root, variants, manifest)
        build_other_files(output_root, variants, manifest, scope_name)
    verify(manifest)
    manifest_path = repo / args.manifest
    manifest_path.parent.mkdir(parents=True, exist_ok=True)
    manifest_path.write_text(json.dumps(manifest, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    for scope in SCOPES:
        print(scope, manifest["scopes"][scope]["wiki"]["canonical_page_paths"])
    print(manifest_path)


if __name__ == "__main__":
    main()
