#!/usr/bin/env bash
# TJ-ARCH-MOB-001 compliant
set -euo pipefail

container="${1:-prometheus-postgres18-verification}"
required=(vector pgcrypto pg_net pg_cron flint_llm flint_vault flint_meta flint_auth flint_hooks)

actual="$(docker exec "$container" psql -U flint -d flint -Atc 'select extname from pg_extension order by extname')"
for extension in "${required[@]}"; do
  grep -Fxq "$extension" <<<"$actual" || { echo "missing extension: $extension" >&2; exit 1; }
done
docker exec "$container" wal-g --version
docker exec "$container" psql -U flint -d flint -Atc 'show wal_level' | grep -Fxq logical
echo "PostgreSQL extension and replication verification passed"
