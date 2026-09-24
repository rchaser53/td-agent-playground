#!/usr/bin/env bash
set -euo pipefail

usage() {
  echo "Usage: $0 <nginx-log-file> [tag]" >&2
  echo "Example: $0 /var/log/nginx/access.log nginx.access" >&2
}

if [[ $# -lt 1 || $# -gt 2 ]]; then
  usage
  exit 1
fi

LOG_FILE="$1"
TAG="${2:-nginx.access}"

if [[ ! -f "$LOG_FILE" ]]; then
  echo "Error: log file not found: $LOG_FILE" >&2
  exit 1
fi

if [[ ! -r "$LOG_FILE" ]]; then
  echo "Error: log file is not readable: $LOG_FILE" >&2
  exit 1
fi

# Send every existing line in the specified nginx log file.
# fluent-cat reads one JSON object per line, so wrap each raw nginx log line
# in a JSON object without changing its contents.
python3 - "$LOG_FILE" <<'PY' | /opt/td-agent/bin/fluent-cat "$TAG"
import json
import sys

path = sys.argv[1]
with open(path, "r", encoding="utf-8", errors="replace") as f:
    for line in f:
        print(json.dumps({"message": line.rstrip("\n")}, ensure_ascii=False))
PY
