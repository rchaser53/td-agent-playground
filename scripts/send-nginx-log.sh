#!/usr/bin/env bash
set -euo pipefail

usage() {
  echo "Usage: $0 <nginx-log-file>" >&2
  echo "Example: $0 /path/to/access.log" >&2
}

if [[ $# -ne 1 ]]; then
  usage
  exit 1
fi

LOG_FILE="$1"

if [[ ! -f "$LOG_FILE" ]]; then
  echo "Error: log file not found: $LOG_FILE" >&2
  exit 1
fi

if [[ ! -r "$LOG_FILE" ]]; then
  echo "Error: log file is not readable: $LOG_FILE" >&2
  exit 1
fi

if ! command -v docker >/dev/null 2>&1; then
  echo "Error: docker command not found" >&2
  exit 1
fi

if ! docker compose ps --status running fluentd 2>/dev/null | grep -q fluentd; then
  echo "Error: fluentd service is not running. Run: docker compose up -d --build" >&2
  exit 1
fi

LINE_COUNT=$(wc -l < "$LOG_FILE" | tr -d ' ')
echo "Sending $LINE_COUNT lines from $LOG_FILE ..."

python3 - "$LOG_FILE" <<'PY' | docker compose exec -T fluentd /opt/td-agent/bin/fluent-cat nginx.raw
import json
import sys

path = sys.argv[1]
with open(path, "r", encoding="utf-8", errors="replace") as f:
    for line in f:
        print(json.dumps({"message": line.rstrip("\n")}, ensure_ascii=False))
PY

echo "Sent $LINE_COUNT lines with tag nginx.raw."
echo "Wait a few seconds, then check:"
echo "  curl 'http://localhost:9200/nginx-access-*/_count?pretty'"
