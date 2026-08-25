#!/usr/bin/env bash
#
# stop-test-listeners.sh
#
# Kills any dummy listeners started by start-test-listeners.sh, in case you
# want to clean up without going through the PortMedic UI.

set -euo pipefail

PID_FILE="/tmp/portmedic-test-pids"

if [[ ! -f "$PID_FILE" ]]; then
    echo "No test listener PID file found at $PID_FILE — nothing to stop."
    exit 0
fi

while read -r pid; do
    if [[ -n "$pid" ]] && kill -0 "$pid" 2>/dev/null; then
        kill -9 "$pid" 2>/dev/null && echo "Killed PID $pid"
    fi
done < "$PID_FILE"

rm -f "$PID_FILE"
echo "Done."
