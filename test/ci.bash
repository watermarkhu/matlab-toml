#!/bin/bash

MATLAB=${1:-octave-cli --eval}

# IPC files in /tmp – namespaced by TOML_USE_DICT so two modes can coexist
SUFFIX="${TOML_USE_DICT:-0}"
export TOML_IN="/tmp/.matlab_toml_${SUFFIX}.in"
export TOML_OUT="/tmp/.matlab_toml_${SUFFIX}.out"
export TOML_READY="/tmp/.matlab_toml_${SUFFIX}.ready"
export TOML_DONE="/tmp/.matlab_toml_${SUFFIX}.done"
export TOML_ERROR="/tmp/.matlab_toml_${SUFFIX}.error"
export TOML_INIT="/tmp/.matlab_toml_${SUFFIX}.init"
SERVER_PID_FILE="/tmp/.matlab_toml_server_${SUFFIX}.pid"
SERVER_LOG="/tmp/.matlab_toml_server_${SUFFIX}.log"

start_server() {
    rm -f "$TOML_INIT"
    $MATLAB "addpath('$GITHUB_WORKSPACE'); addpath('$GITHUB_WORKSPACE/test'); ci_server" >"$SERVER_LOG" 2>&1 &
    echo $! > "$SERVER_PID_FILE"

    echo "Starting MATLAB server (this may take a while)..." >&2
    for _ in $(seq 120); do
        [ -f "$TOML_INIT" ] && return 0
        sleep 1
    done

    echo "Timed out waiting for MATLAB server to start. Log:" >&2
    cat "$SERVER_LOG" >&2
    exit 1
}

is_server_running() {
    [ -f "$TOML_INIT" ] && [ -f "$SERVER_PID_FILE" ] && kill -0 "$(cat "$SERVER_PID_FILE")" 2>/dev/null
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

echo "Timed out waiting for MATLAB server response. Log:" >&2
cat "$SERVER_LOG" >&2
exit 1
