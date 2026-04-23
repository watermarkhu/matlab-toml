#!/bin/bash

MATLAB=${1:-octave-cli --eval}

# IPC files in /tmp – shared across ci.bash invocations
export TOML_WORKDIR="$(cd "$(dirname "$0")" && pwd)"
export TOML_IN="/tmp/.matlab_toml.in"
export TOML_OUT="/tmp/.matlab_toml.out"
export TOML_READY="/tmp/.matlab_toml.ready"
export TOML_DONE="/tmp/.matlab_toml.done"
export TOML_ERROR="/tmp/.matlab_toml.error"
export TOML_INIT="/tmp/.matlab_toml.init"
SERVER_PID_FILE="/tmp/.matlab_toml_server.pid"

is_server_running() {
    [ -f "$SERVER_PID_FILE" ] && kill -0 "$(cat "$SERVER_PID_FILE")" 2>/dev/null
}

start_server() {
    rm -f "$TOML_INIT"
    $MATLAB "run('$TOML_WORKDIR/ci_server.m')" >/dev/null 2>&1 &
    echo $! > "$SERVER_PID_FILE"

    echo "Starting MATLAB server (this may take a while)..." >&2
    for _ in $(seq 120); do
        [ -f "$TOML_INIT" ] && return 0
        is_server_running || { echo "MATLAB server died during startup" >&2; exit 1; }
        sleep 1
    done
    echo "Timed out waiting for MATLAB server to start" >&2
    exit 1
}

# Start server if not already running
is_server_running || start_server

# Read TOML from stdin; clear any stale signals from previous test
cat > "$TOML_IN"
rm -f "$TOML_DONE" "$TOML_ERROR"

# Signal server to process
touch "$TOML_READY"

# Poll for response (up to 30s)
for _ in $(seq 300); do
    [ -f "$TOML_DONE"  ] && { rm -f "$TOML_DONE";  cat "$TOML_OUT"; exit 0; }
    [ -f "$TOML_ERROR" ] && { rm -f "$TOML_ERROR"; exit 1; }
    sleep 0.1
done

echo "Timed out waiting for MATLAB server response" >&2
exit 1