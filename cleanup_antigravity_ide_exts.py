#!/usr/bin/env python3
"""Deduplicate extension versions under ~/.antigravity-ide/extensions.

Groups extension dirs by ID (package.json -> publisher.name, or dir-name
fallback), keeps the newest semver dir per ID, deletes older duplicates.
Honors a `.obsolete` marker convention: reports markers, still only deletes
non-newest versions.
"""
import json
import shutil
import sys
from pathlib import Path

EXT_ROOT = Path("/Users/gqadonis/.antigravity-ide/extensions")

def semver_key(v: str):
    parts = []
    for chunk in v.strip().lstrip("vV").split("."):
        num = ""
        for ch in chunk:
            if ch.isdigit():
                num += ch
            else:
                break
        parts.append(int(num) if num else 0)
    while len(parts) < 3:
        parts.append(0)
    return tuple(parts)

def dir_size(p: Path) -> int:
    total = 0
    for f in p.rglob("*"):
        try:
            if f.is_file() or f.is_symlink():
                total += f.lstat().st_size
        except OSError:
            pass
    return total

def main():
    if not EXT_ROOT.is_dir():
        print(f"ERROR: {EXT_ROOT} missing", file=sys.stderr)
        sys.exit(1)

    groups = {}  # id -> list of (dir, version, size, obsolete)
    skipped_dirs = []
    for d in sorted(EXT_ROOT.iterdir()):
        if not d.is_dir():
            continue
        pkg = d / "package.json"
        ext_id = None
        version = None
        if pkg.is_file():
            try:
                meta = json.loads(pkg.read_text(encoding="utf-8", errors="replace"))
                pub = meta.get("publisher")
                name = meta.get("name")
                if pub and name:
                    ext_id = f"{pub}.{name}"
                version = meta.get("version")
            except Exception:
                pass
        if ext_id is None or version is None:
            # Fallback: parse dir name publisher.name-x.y.z
            stem = d.name
            if "-" in stem:
                base, _, ver = stem.rpartition("-")
                if ver and ver[0].isdigit():
                    ext_id = ext_id or base
                    version = version or ver
        if ext_id is None or version is None:
            skipped_dirs.append(d.name)
            continue
        obsolete = (d / ".obsolete").exists()
        groups.setdefault(ext_id, []).append((d, version, obsolete))

    total_freed = 0
    report = []
    for ext_id, entries in sorted(groups.items()):
        if len(entries) < 2:
            continue
        entries.sort(key=lambda e: semver_key(e[1]))
        newest = entries[-1]
        for d, version, obsolete in entries[:-1]:
            size = dir_size(d)
            try:
                shutil.rmtree(d)
                total_freed += size
                report.append((ext_id, version, d.name, size, "deleted", obsolete))
            except OSError as e:
                report.append((ext_id, version, d.name, size, f"FAILED: {e}", obsolete))
        report.append((ext_id, newest[1], newest[0].name, 0, "KEPT (newest)", newest[2]))

    for ext_id, version, dirname, size, status, obsolete in report:
        ob = " [had .obsolete]" if obsolete else ""
        mb = size / 1024 / 1024
        print(f"{ext_id} v{version} | {dirname} | {mb:.1f} MB | {status}{ob}")
    if skipped_dirs:
        print("\nDirs skipped (no parsable id/version):")
        for n in skipped_dirs:
            print(f"  {n}")
    print(f"\nTOTAL FREED: {total_freed/1024/1024:.1f} MB ({total_freed/1024**3:.2f} GB)")

if __name__ == "__main__":
    main()
