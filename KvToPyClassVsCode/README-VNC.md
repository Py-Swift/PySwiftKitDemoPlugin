# Kivy VNC Streaming Setup

This Docker setup enables real-time streaming of Kivy applications from a Docker container to VSCode (or any browser) with minimal CPU overhead.

## Quick Start

### 1. Build the Docker Image

```bash
docker build -f Dockerfile.vnc -t kivy-vnc .
```

Or using docker-compose:

```bash
docker-compose -f docker-compose.vnc.yml build
```

### 2. Run the Container

```bash
docker run -p 5900:5900 -p 6080:6080 -v $(pwd)/kv_projs:/work kivy-vnc
```

Or using docker-compose:

```bash
docker-compose -f docker-compose.vnc.yml up
```

### 3. Access the Stream

**In Browser:**
- Open: http://localhost:6080/vnc.html
- Click "Connect"
- You should see the Xvfb display

**Test with Sample App:**

```bash
# In another terminal, execute the test app in the running container
docker exec -it kivy-vnc-preview python3 /work/test-kivy-app.py
```

Or copy the test app into the container:

```bash
docker cp test-kivy-app.py kivy-vnc-preview:/work/main.py
docker exec -it kivy-vnc-preview python3 /work/main.py
```

## Performance Optimization

This setup is optimized for **local streaming** with minimal CPU usage:

- **No compression** (`-speeds lan`)
- **No damage tracking** (`-noxdamage`)
- **No XFixes/XComposite** (`-noxfixes`, `-noxcomposite`)
- **Minimal defer time** (`-defer 5ms`)

Expected CPU usage: **2-5%** (vs 10-15% with full compression)

## Architecture

```
Docker Container
├── Xvfb :99 (Virtual framebuffer, 1024x768)
├── x11vnc :5900 (VNC server, no compression)
└── websockify :6080 (WebSocket bridge)
        ↓
    Browser/VSCode
    └── noVNC Client
```

## Ports

- **5900**: VNC port (for native VNC clients like RealVNC, TigerVNC)
- **6080**: WebSocket port (for browser/VSCode via noVNC)

## Testing Connection

```bash
# Check if VNC server is running
docker exec kivy-vnc-preview ps aux | grep x11vnc

# Check if websockify is running
docker exec kivy-vnc-preview ps aux | grep websockify

# Test with curl
curl -I http://localhost:6080/vnc.html
```

## Troubleshooting

### Can't connect to VNC

```bash
# Check logs
docker logs kivy-vnc-preview

# Ensure ports are exposed
docker ps | grep kivy-vnc
```

### Kivy app doesn't show

```bash
# Verify DISPLAY is set
docker exec kivy-vnc-preview echo $DISPLAY

# Check if Xvfb is running
docker exec kivy-vnc-preview ps aux | grep Xvfb
```

### Performance issues

The current setup prioritizes low CPU usage over bandwidth. For very high-resolution or high-framerate content, you might want to adjust:

```bash
# In start-vnc.sh, modify x11vnc parameters:
# For slightly better quality (5% more CPU):
-speeds dsl

# For compression (10-15% CPU):
-zlevel 1
```

## Next Steps

This is **Phase 1** of the implementation. Next steps:

1. **Integration with VSCode Extension**: Create webview panel that loads noVNC
2. **Dynamic App Loading**: API to send Kivy code and run it
3. **Hot Reload**: Watch for file changes and restart app
4. **Phase 2 (Optional)**: Evaluate xpra for even better performance

## Files

- `Dockerfile.vnc` - Docker image definition
- `start-vnc.sh` - Startup script for VNC streaming
- `docker-compose.vnc.yml` - Docker Compose configuration
- `test-kivy-app.py` - Sample Kivy app for testing
- `README-VNC.md` - This file
