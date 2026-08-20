#!/usr/bin/env bash
# scripts/render-supervisor-plist.sh
# Render a supervisor definition that carries the 9 supervision fixes.
#
# Usage:
#   bash scripts/render-supervisor-plist.sh \
#     --label ai.prometheus.demo \
#     --program /usr/local/bin/demo [--arg --port --arg 8943] \
#     [--format launchd|systemd] [--throttle 15] \
#     [--description "..."] [--log-dir DIR] [--working-dir DIR] \
#     [--env KEY=VALUE ...] [--out FILE]
#
# Defaults to launchd on macOS and systemd elsewhere. Writes to stdout unless
# --out is given. Rendering the same inputs twice produces identical bytes.
#
# Validate a rendered plist before loading it:
#   plutil -lint <file>

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE_DIR="$SCRIPT_DIR/../assets/templates/launchagent-supervisor"

LABEL=""
PROGRAM=""
DESCRIPTION=""
THROTTLE=15
LOG_DIR=""
WORKING_DIR=""
OUT=""
FORMAT=""
ARGS=()
ENV_PAIRS=()

usage() {
  sed -n '2,20p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
}

while [ $# -gt 0 ]; do
  case "$1" in
    --label)       LABEL="${2:?--label needs a value}"; shift 2 ;;
    --program)     PROGRAM="${2:?--program needs a value}"; shift 2 ;;
    --arg)         ARGS+=("${2:?--arg needs a value}"); shift 2 ;;
    --env)         ENV_PAIRS+=("${2:?--env needs KEY=VALUE}"); shift 2 ;;
    --format)      FORMAT="${2:?--format needs a value}"; shift 2 ;;
    --throttle)    THROTTLE="${2:?--throttle needs a value}"; shift 2 ;;
    --description) DESCRIPTION="${2:?--description needs a value}"; shift 2 ;;
    --log-dir)     LOG_DIR="${2:?--log-dir needs a value}"; shift 2 ;;
    --working-dir) WORKING_DIR="${2:?--working-dir needs a value}"; shift 2 ;;
    --out)         OUT="${2:?--out needs a value}"; shift 2 ;;
    -h|--help)     usage; exit 0 ;;
    *) echo "render-supervisor-plist: unknown option: $1" >&2; usage >&2; exit 1 ;;
  esac
done

[ -n "$LABEL" ]   || { echo "render-supervisor-plist: --label is required" >&2; exit 1; }
[ -n "$PROGRAM" ] || { echo "render-supervisor-plist: --program is required" >&2; exit 1; }

case "$LABEL" in
  *[!A-Za-z0-9._-]*) echo "render-supervisor-plist: invalid label: $LABEL" >&2; exit 1 ;;
esac

# R1.1: a throttle below launchd's threshold is the crash-loop-removal bug the
# template exists to prevent, so refuse to render one.
case "$THROTTLE" in
  ''|*[!0-9]*) echo "render-supervisor-plist: --throttle must be an integer" >&2; exit 1 ;;
esac
if [ "$THROTTLE" -lt 10 ]; then
  echo "render-supervisor-plist: --throttle $THROTTLE is below the 10s floor (R1.1)" >&2
  exit 1
fi

if [ -z "$FORMAT" ]; then
  if [ "$(uname -s)" = "Darwin" ]; then FORMAT="launchd"; else FORMAT="systemd"; fi
fi

: "${DESCRIPTION:=$LABEL}"
: "${LOG_DIR:=\$HOME/.prometheus/logs}"
: "${WORKING_DIR:=\$HOME}"

STDOUT_PATH="$LOG_DIR/$LABEL.log"
STDERR_PATH="$LOG_DIR/$LABEL.err"

# XML-escape a value bound for the plist.
xml_escape() {
  printf '%s' "$1" | sed -e 's/&/\&amp;/g' -e 's/</\&lt;/g' -e 's/>/\&gt;/g'
}

render_launchd() {
  local template="$TEMPLATE_DIR/supervisor.plist.template"
  [ -f "$template" ] || { echo "render-supervisor-plist: missing template: $template" >&2; exit 1; }

  local program_block
  program_block="    <string>$(xml_escape "$PROGRAM")</string>"
  local arg
  for arg in ${ARGS+"${ARGS[@]}"}; do
    program_block="$program_block
    <string>$(xml_escape "$arg")</string>"
  done

  # PATH is set explicitly: a LaunchAgent inherits a minimal environment, and a
  # service that works in a shell but not under launchd is usually this.
  local env_block="    <key>PATH</key>
    <string>/usr/local/bin:/opt/homebrew/bin:/usr/bin:/bin:/usr/sbin:/sbin</string>"
  local pair key value
  for pair in ${ENV_PAIRS+"${ENV_PAIRS[@]}"}; do
    key="${pair%%=*}"
    value="${pair#*=}"
    env_block="$env_block
    <key>$(xml_escape "$key")</key>
    <string>$(xml_escape "$value")</string>"
  done

  TPL_LABEL="$LABEL" TPL_THROTTLE="$THROTTLE" TPL_PROGRAM="$program_block" \
  TPL_STDOUT="$STDOUT_PATH" TPL_STDERR="$STDERR_PATH" TPL_WORKDIR="$WORKING_DIR" \
  TPL_ENV="$env_block" python3 -c '
import os, sys

subs = {
    "@@LABEL@@": os.environ["TPL_LABEL"],
    "@@THROTTLE@@": os.environ["TPL_THROTTLE"],
    "@@STDOUT_PATH@@": os.environ["TPL_STDOUT"],
    "@@STDERR_PATH@@": os.environ["TPL_STDERR"],
    "@@WORKING_DIRECTORY@@": os.environ["TPL_WORKDIR"],
}
blocks = {
    "@@PROGRAM_ARGUMENTS@@": os.environ["TPL_PROGRAM"],
    "@@ENVIRONMENT@@": os.environ["TPL_ENV"],
}
for line in open(sys.argv[1], encoding="utf-8"):
    line = line.rstrip("\n")
    replaced = None
    for token, block in blocks.items():
        if token in line:
            replaced = block
            break
    if replaced is not None:
        print(replaced)
        continue
    for token, value in subs.items():
        line = line.replace(token, value)
    print(line)
' "$template"
}

render_systemd() {
  local template="$TEMPLATE_DIR/supervisor.service.template"
  [ -f "$template" ] || { echo "render-supervisor-plist: missing template: $template" >&2; exit 1; }

  local exec_start="$PROGRAM"
  local arg
  for arg in ${ARGS+"${ARGS[@]}"}; do
    exec_start="$exec_start $arg"
  done

  local env_block='Environment="PATH=/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"'
  local pair
  for pair in ${ENV_PAIRS+"${ENV_PAIRS[@]}"}; do
    env_block="$env_block
Environment=\"$pair\""
  done

  # systemd expands %h to the user's home; the launchd side uses $HOME.
  local sd_stdout="${STDOUT_PATH/\$HOME/%h}"
  local sd_stderr="${STDERR_PATH/\$HOME/%h}"
  local sd_workdir="${WORKING_DIR/\$HOME/%h}"

  TPL_LABEL="$LABEL" TPL_DESCRIPTION="$DESCRIPTION" TPL_THROTTLE="$THROTTLE" \
  TPL_EXEC="$exec_start" TPL_STDOUT="$sd_stdout" TPL_STDERR="$sd_stderr" \
  TPL_WORKDIR="$sd_workdir" TPL_ENV="$env_block" python3 -c '
import os, sys

subs = {
    "@@LABEL@@": os.environ["TPL_LABEL"],
    "@@DESCRIPTION@@": os.environ["TPL_DESCRIPTION"],
    "@@THROTTLE@@": os.environ["TPL_THROTTLE"],
    "@@EXEC_START@@": os.environ["TPL_EXEC"],
    "@@STDOUT_PATH@@": os.environ["TPL_STDOUT"],
    "@@STDERR_PATH@@": os.environ["TPL_STDERR"],
    "@@WORKING_DIRECTORY@@": os.environ["TPL_WORKDIR"],
}
for line in open(sys.argv[1], encoding="utf-8"):
    line = line.rstrip("\n")
    if "@@ENVIRONMENT@@" in line:
        print(os.environ["TPL_ENV"])
        continue
    for token, value in subs.items():
        line = line.replace(token, value)
    print(line)
' "$template"
}

case "$FORMAT" in
  launchd) RENDERED="$(render_launchd)" ;;
  systemd) RENDERED="$(render_systemd)" ;;
  *) echo "render-supervisor-plist: unknown --format: $FORMAT (want launchd or systemd)" >&2; exit 1 ;;
esac

if [ -n "$OUT" ]; then
  mkdir -p "$(dirname "$OUT")"
  printf '%s\n' "$RENDERED" > "$OUT"
  # A plist that fails plutil -lint is rejected by launchd with no useful
  # message, so catch it here rather than at load time.
  if [ "$FORMAT" = "launchd" ] && command -v plutil >/dev/null 2>&1; then
    plutil -lint "$OUT" >/dev/null || {
      echo "render-supervisor-plist: rendered plist failed plutil -lint: $OUT" >&2
      exit 1
    }
  fi
  echo "render-supervisor-plist: wrote $OUT ($FORMAT)"
else
  printf '%s\n' "$RENDERED"
fi
