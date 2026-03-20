#!/usr/bin/env bash
set -e

# Setup environment
export XDG_RUNTIME_DIR=/tmp/runtime-root
mkdir -p $XDG_RUNTIME_DIR
chmod 700 $XDG_RUNTIME_DIR

# Start virtual framebuffer (required by RealityScan)
export DISPLAY=:99

# Kill any existing Xvfb on display 99 or remove stale lock
if pgrep -x "Xvfb" > /dev/null; then
    echo "Killing existing Xvfb process..."
    pkill -x Xvfb || true
    sleep 1
fi

# Remove stale lock file if exists
rm -f /tmp/.X99-lock

Xvfb :99 -screen 0 1024x768x24 -nolisten tcp &
XVFB_PID=$!
sleep 1

export RS_BIN="/opt/realityscan/bin/realityscan"
WINE="/opt/realityscan/bin/wine"

export INSTANCE_NAME="rs_$$"

export WINEPREFIX=/tmp/wine-realityscan
export WINEDEBUG="-all"

# Helper function to run RealityScan with Wine
run_rs() {
    if [ -f "$WINE" ] && [ "$RS_BIN" = "/opt/realityscan/bin/realityscan" ]; then
        # RealityScan on Linux uses Wine
        echo running "$WINE" "$RS_BIN" "$@"
        "$WINE" "$RS_BIN" "$@"
    else
        echo running "$RS_BIN" "$@"
        "$RS_BIN" "$@"
    fi
}

shutdown() {
    local exit_code=$?

    if [ -n "${KEEPALIVE_PID:-}" ] && kill -0 "$KEEPALIVE_PID" 2>/dev/null; then
        kill "$KEEPALIVE_PID" 2>/dev/null || true
    fi

    if [ -n "${XVFB_PID:-}" ] && kill -0 "$XVFB_PID" 2>/dev/null; then
        kill "$XVFB_PID" 2>/dev/null || true
    fi

    pkill -f "/opt/realityscan/bin/realityscan" 2>/dev/null || true
    pkill -f "/opt/realityscan/bin/wine" 2>/dev/null || true

    wait "${KEEPALIVE_PID:-}" 2>/dev/null || true
    wait "${XVFB_PID:-}" 2>/dev/null || true

    exit "$exit_code"
}

keep_container_alive() {
    sleep infinity &
    KEEPALIVE_PID=$!
    wait "$KEEPALIVE_PID"
}

trap shutdown EXIT INT TERM

export RS_PLUGIN="/opt/RealityScan.RemoteCommandPlugin.rsplugin"

case "$1" in
    server|rest)
        PORT=${RS_REST_PORT:-8080}
        echo "Starting RealityScan with REST server on port $PORT"
        echo "Instance name: $INSTANCE_NAME"
        
        # Start RealityScan instance with plugin registered
        if [ -n "$RS_PLUGIN" ]; then
            run_rs -setInstanceName "$INSTANCE_NAME" -registerPlugin "$RS_PLUGIN" -headless &
        else
            run_rs -setInstanceName "$INSTANCE_NAME" -headless &
        fi
        sleep 5
        
        # Delegate to instance and start REST server
        run_rs -delegateTo "$INSTANCE_NAME" -RsRemoteStartREST "http://0.0.0.0:$PORT"
        echo "RealityCapture REST server running on port $PORT"
        keep_container_alive
        ;;
    grpc)
        PORT=${RS_GRPC_PORT:-50051}
        echo "Starting RealityScan with gRPC server on port $PORT"
        echo "Instance name: $INSTANCE_NAME"
        
        # Start RealityScan instance with plugin registered
        if [ -n "$RS_PLUGIN" ]; then
            run_rs -setInstanceName "$INSTANCE_NAME" -registerPlugin "$RS_PLUGIN" -headless &
        else
            run_rs -setInstanceName "$INSTANCE_NAME" -headless &
        fi
        sleep 5
        
        # Delegate to instance and start gRPC server
        run_rs -delegateTo "$INSTANCE_NAME" -RsRemoteStartGRPC "0.0.0.0:$PORT"

        echo "RealityCapture GRPC server running on port $PORT"
        keep_container_alive
        ;;
    both)
        REST=${RS_REST_PORT:-8080}
        GRPC=${RS_GRPC_PORT:-50051}
        echo "Starting RealityScan with REST ($REST) + gRPC ($GRPC)"
        echo "Instance name: $INSTANCE_NAME"
        
        # Start RealityScan instance with plugin registered
        if [ -n "$RS_PLUGIN" ]; then
            run_rs -setInstanceName "$INSTANCE_NAME" -registerPlugin "$RS_PLUGIN" -headless &
        else
            run_rs -setInstanceName "$INSTANCE_NAME" -headless &
        fi
        sleep 5
        
        # Start REST server in background
        run_rs -delegateTo "$INSTANCE_NAME" -RsRemoteStartREST "http://0.0.0.0:$REST" &
        sleep 2
        
        # Start gRPC server, then keep the container alive while the daemonized processes run.
        run_rs -delegateTo "$INSTANCE_NAME" -RsRemoteStartGRPC "0.0.0.0:$GRPC"

        echo "RealityCapture GRPC server running on port $GRPC. REST server running on port $REST"
        keep_container_alive
        ;;
    bash|sh)
        exec /bin/bash
        ;;
    *)
        run_rs -headless "$@" &
        KEEPALIVE_PID=$!
        wait "$KEEPALIVE_PID"
        ;;
esac
