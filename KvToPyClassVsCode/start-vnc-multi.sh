#!/bin/bash
set -e

# Number of VNC instances to create
NUM_INSTANCES=${NUM_INSTANCES:-2}
START_DISPLAY=99
START_VNC_PORT=5900
START_WS_PORT=6080

echo "Starting $NUM_INSTANCES VNC instances..."

# Clean up any stale lock files
echo "Cleaning up stale X server lock files..."
rm -f /tmp/.X*-lock /tmp/.X11-unix/X*

XVFB_PIDS=()
X11VNC_PIDS=()
WEBSOCKIFY_PIDS=()

# Start each VNC instance
for i in $(seq 0 $((NUM_INSTANCES - 1))); do
    DISPLAY_NUM=$((START_DISPLAY + i))
    VNC_PORT=$((START_VNC_PORT + i))
    WS_PORT=$((START_WS_PORT + i))
    
    echo "================================================"
    echo "Starting VNC Instance $((i + 1))/$NUM_INSTANCES"
    echo "================================================"
    
    # Start Xvfb
    echo "Starting Xvfb on display :$DISPLAY_NUM..."
    Xvfb :$DISPLAY_NUM -screen 0 1024x768x24 -ac +extension GLX +render -noreset &
    XVFB_PID=$!
    XVFB_PIDS+=($XVFB_PID)
    
    # Wait for X server to be ready
    sleep 2
    
    # Start x11vnc
    echo "Starting x11vnc on port $VNC_PORT (display :$DISPLAY_NUM)..."
    x11vnc \
        -display :$DISPLAY_NUM \
        -forever \
        -shared \
        -rfbport $VNC_PORT \
        -nopw \
        -xkb \
        -ncache 0 \
        -ncache_cr \
        -noxdamage \
        -noxfixes \
        -noxcomposite \
        -skip_lockkeys \
        -speeds lan \
        -wait 5 \
        -defer 5 \
        -progressive 0 \
        -q \
        &
    X11VNC_PID=$!
    X11VNC_PIDS+=($X11VNC_PID)
    
    # Wait for VNC server to start
    sleep 2
    
    # Start websockify
    echo "Starting websockify on port $WS_PORT (VNC port $VNC_PORT)..."
    websockify --web /usr/share/novnc $WS_PORT localhost:$VNC_PORT &
    WEBSOCKIFY_PID=$!
    WEBSOCKIFY_PIDS+=($WEBSOCKIFY_PID)
    
    echo "✓ Instance $((i + 1)) ready!"
    echo "  Display: :$DISPLAY_NUM"
    echo "  VNC Port: $VNC_PORT"
    echo "  WebSocket Port: $WS_PORT"
    echo "  URL: http://localhost:$WS_PORT/vnc.html"
    echo ""
done

echo "================================================"
echo "All VNC Streaming Servers Ready!"
echo "================================================"
echo "Configuration: Optimized for local streaming"
echo "  - No compression"
echo "  - No damage tracking"
echo "  - LAN speed optimization"
echo "  - Minimal CPU overhead (~2-5% per instance)"
echo "================================================"
echo ""
echo "Access URLs:"
for i in $(seq 0 $((NUM_INSTANCES - 1))); do
    WS_PORT=$((START_WS_PORT + i))
    echo "  Instance $((i + 1)): http://localhost:$WS_PORT/vnc.html"
done
echo "================================================"

# Cleanup function
cleanup() {
    echo ""
    echo "Shutting down all VNC instances..."
    
    for pid in "${WEBSOCKIFY_PIDS[@]}"; do
        kill $pid 2>/dev/null || true
    done
    
    for pid in "${X11VNC_PIDS[@]}"; do
        kill $pid 2>/dev/null || true
    done
    
    for pid in "${XVFB_PIDS[@]}"; do
        kill $pid 2>/dev/null || true
    done
    
    # Clean up lock files
    rm -f /tmp/.X*-lock /tmp/.X11-unix/X*
    
    echo "All instances shut down."
    exit 0
}

# Keep container running and forward signals
trap cleanup EXIT TERM INT

# Wait for any process to exit
wait -n

# If any process exits, clean up all
cleanup
