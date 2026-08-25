#!/usr/bin/env bash
#
# start-test-listeners.sh
#
# Spins up a handful of harmless dummy TCP listeners on common dev ports so
# PortMedic's scan/search/kill flow can be exercised manually without needing
# a real Node/Postgres/Redis/etc. stack running.
#
# Usage:
#   ./scripts/start-test-listeners.sh     # start listeners
#   ./scripts/stop-test-listeners.sh      # stop them again
#
# PIDs are recorded in /tmp/portmedic-test-pids so the stop script can clean up.

set -euo pipefail

PID_FILE="/tmp/portmedic-test-pids"
: > "$PID_FILE"

start_listener() {
    local port="$1"
    local label="$2"
    # `nc -l` just holds the port open; no data handling needed for this test.
    nc -l "$port" >/dev/null 2>&1 &
    local pid=$!
    echo "$pid" >> "$PID_FILE"
    echo "Started $label on port $port (PID $pid)"
}

# Ports chosen to exercise PortMedic's framework-detection badges:
start_listener 3000 "Next.js-style (Node port hint)"
start_listener 5173 "Vite Dev Server"
start_listener 5432 "PostgreSQL"
start_listener 6379 "Redis"
start_listener 27017 "MongoDB"
start_listener 8080 "Generic/Spring Boot-style"

echo ""
echo "All test listeners started. Run PortMedic and hit Refresh to see them."
echo "Run scripts/stop-test-listeners.sh when you're done testing."
