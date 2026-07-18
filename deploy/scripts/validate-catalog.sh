#!/usr/bin/env bash
# TJ-ARCH-MOB-001 compliant
set -euo pipefail

repo_root="$(git rev-parse --show-toplevel)"
cd "$repo_root"

for file in deploy/sources.lock.yaml deploy/third-party.lock.yaml deploy/images.lock.yaml; do
  test -s "$file" || { echo "missing catalog file: $file" >&2; exit 1; }
done

python3 - <<'PY'
from pathlib import Path
import re
import yaml
locks = {}
for name in ('sources.lock.yaml', 'third-party.lock.yaml', 'images.lock.yaml'):
    with (Path('deploy') / name).open() as stream:
        value = yaml.safe_load(stream)
    if not isinstance(value, dict) or value.get('schema_version') != 1:
        raise SystemExit(f'invalid catalog schema: {name}')
    locks[name] = value

required = {'repository', 'commit', 'owner', 'dockerfile', 'context', 'platforms', 'license'}
for name, source in locks['sources.lock.yaml'].get('sources', {}).items():
    missing = required - source.keys()
    if missing:
        raise SystemExit(f'{name} is missing source fields: {sorted(missing)}')
    if not re.fullmatch(r'[0-9a-f]{40}', str(source['commit'])):
        raise SystemExit(f'{name} does not use a full commit SHA')
    if not str(source['repository']).startswith('https://'):
        raise SystemExit(f'{name} source must use HTTPS or an explicit authenticated BuildKit context')
    if not Path(source['dockerfile']).is_file():
        raise SystemExit(f'{name} Dockerfile does not exist: {source["dockerfile"]}')

for name, image in locks['third-party.lock.yaml'].get('images', {}).items():
    if not re.search(r'@sha256:[0-9a-f]{64}$', str(image.get('reference', ''))):
        raise SystemExit(f'{name} third-party image is not digest pinned')
    if not image.get('license'):
        raise SystemExit(f'{name} third-party image has no license record')

for name, artifact in locks['third-party.lock.yaml'].get('artifacts', {}).items():
    if not re.fullmatch(r'[0-9a-f]{64}', str(artifact.get('sha256', ''))):
        raise SystemExit(f'{name} artifact has no SHA-256 checksum')

image_lock = locks['images.lock.yaml']
if image_lock.get('status') == 'released':
    for name, image in image_lock.get('images', {}).items():
        if not re.fullmatch(r'sha256:[0-9a-f]{64}', str(image.get('digest', ''))):
            raise SystemExit(f'{name} released image has no immutable digest')
PY

if rg -n '(repository:.*#(main|master)|commit: (main|master|HEAD)$)' deploy/sources.lock.yaml; then
  echo "floating source revision found" >&2
  exit 1
fi

bad_commits="$(awk '/^[[:space:]]+commit:/ {print $2}' deploy/sources.lock.yaml | rg -v '^[0-9a-f]{40}$' || true)"
test -z "$bad_commits" || { echo "source commits must be full SHA-1 values: $bad_commits" >&2; exit 1; }

if rg -n '(^|[/:])latest([@:]|$)' deploy --glob '!README.md' --glob '!scripts/validate-catalog.sh'; then
  echo "floating latest image found" >&2
  exit 1
fi

if rg -n 'RUN[[:space:]]+git clone|git clone --depth' deploy/docker; then
  echo "Dockerfiles must consume pinned BuildKit contexts, not clone repositories in layers" >&2
  exit 1
fi

bad_bases="$(awk '
  FNR == 1 { delete stages }
  $1 == "FROM" {
    image=$2
    if (image != "scratch" && !(image in stages) && image !~ /@sha256:[0-9a-f]{64}$/) print FILENAME ":" FNR ":" image
    if (toupper($3) == "AS") stages[$4]=1
  }
' deploy/docker/*.Dockerfile site/Dockerfile apps/knowme-poc/Dockerfile)"
test -z "$bad_bases" || { echo "unpinned Docker base image found: $bad_bases" >&2; exit 1; }

docker buildx bake -f deploy/docker-bake.hcl --print >/dev/null
echo "deployment catalog validation passed"
