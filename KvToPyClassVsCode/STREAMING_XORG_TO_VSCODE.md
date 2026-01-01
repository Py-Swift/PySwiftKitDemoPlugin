# Streaming X11/Xorg Display from Docker to VSCode

## The Problem
Currently, doctor-kivy runs Kivy apps in a Docker container with Xvfb (virtual framebuffer) and takes static screenshots. This doesn't allow for interactive previews or real-time updates.

## Is It Possible?
**Yes!** There are two excellent approaches to stream the X11 display from Docker to a VSCode webview panel with real-time interaction.

## Viable Approaches

### Option A: VNC + noVNC
Stream the display using VNC protocol and render it in a browser-based viewer.

**How it works:**
- Install `x11vnc` in the Docker container
- Run `x11vnc -display :99 -forever -shared` to expose the Xvfb display
- Use `novnc` or `websockify` to create a WebSocket bridge
- VSCode webview connects to the WebSocket and displays the VNC stream

**Pros:**
- Real-time interactive display
- Works perfectly in VSCode webview
- Low latency (50-100ms)
- Can capture mouse/keyboard input
- Well-established, mature technology
- Easy to debug and troubleshoot
- Wide browser support

**Cons:**
- Requires additional dependencies in Docker image (~50MB)
- Uses more bandwidth than xpra (~1-5 MB/s)

**Performance:**
- **Latency:** 50-100ms
- **Bandwidth:** ~1-5 MB/s for 1024x768 @ 30fps with compression
- **CPU:** x11vnc uses ~5-10% CPU for encoding
- **RAM:** ~50MB additional overhead

### Option B: xpra (X Persistent Remote Applications)
A screen forwarding system specifically designed for X11, with superior performance.

**How it works:**
- Run `xpra` server in Docker container attached to Xvfb
- Connect via HTML5 client in VSCode webview
- Uses more efficient encoding than VNC

**Pros:**
- Purpose-built for X11 forwarding
- Has native HTML5 client
- Better performance than VNC (30-50ms latency)
- Lower bandwidth usage (~500KB - 2MB/s)
- Superior compression algorithms
- Handles window management better
- Can seamlessly reconnect
- Better at handling partial updates

**Cons:**
- Less common, more niche (smaller community)
- Larger Docker image (~100MB additional)
- Slightly more complex setup than VNC
- Less documentation available

**Performance:**
- **Latency:** 30-50ms (better than VNC)
- **Bandwidth:** ~500KB - 2MB/s (better than VNC)
- **CPU:** ~3-8% CPU for encoding (better than VNC)
- **RAM:** ~70MB additional overhead

## Comparison: VNC vs xpra

| Feature | VNC + noVNC | xpra |
|---------|-------------|------|
| Latency | 50-100ms | 30-50ms ⭐ |
| Bandwidth | 1-5 MB/s | 500KB-2MB/s ⭐ |
| CPU Usage | 5-10% | 3-8% ⭐ |
| Image Size | +50MB | +100MB |
| Maturity | Very mature ⭐ | Mature |
| Community | Large ⭐ | Smaller |
| Setup Complexity | Simple ⭐ | Medium |
| HTML5 Client | Good | Excellent ⭐ |
| Reconnection | Manual | Automatic ⭐ |

## Recommendation: Start with VNC, Consider xpra Later

**Phase 1: VNC + noVNC**
- Simpler to implement
- Better documented
- Easier to debug
- Faster to get working

**Phase 2: Evaluate xpra**
- If VNC performance is insufficient
- If bandwidth becomes a concern
- If you want better window management

**Phase 2: Evaluate xpra**
- If VNC performance is insufficient
- If bandwidth becomes a concern
- If you want better window management

---

## Implementation Option A: VNC + noVNC

### Architecture

```
┌─────────────────────────────────────┐
│  Docker Container                   │
│  ┌──────────┐                       │
│  │  Kivy    │                       │
│  │   App    │                       │
│  └────┬─────┘                       │
│       │                             │
│  ┌────▼─────────┐                   │
│  │ Xvfb :99     │                   │
│  │ (1024x768)   │                   │
│  └────┬─────────┘                   │
│       │                             │
│  ┌────▼─────────┐                   │
│  │  x11vnc      │◄──────────────┐   │
│  │  :5900       │               │   │
│  └──────────────┘               │   │
│       │                         │   │
│  ┌────▼─────────┐               │   │
│  │ websockify   │               │   │
│  │  :6080       │               │   │
│  └────┬─────────┘               │   │
└───────┼─────────────────────────┼───┘
        │                         │
        │ WebSocket               │ Port mapping
        │                         │
┌───────▼─────────────────────────┼───┐
│ VSCode Extension                │   │
│  ┌───────────────────┐          │   │
│  │  Webview Panel    │          │   │
│  │  ┌─────────────┐  │          │   │
│  │  │ noVNC       │  │          │   │
│  │  │ Client      │◄─┼──────────┘   │
│  │  │             │  │              │
│  │  │ [Live Kivy  │  │              │
│  │  │  Preview]   │  │              │
│  │  └─────────────┘  │              │
│  └───────────────────┘              │
└─────────────────────────────────────┘
```

### Implementation Steps

#### 1. Update Docker Image

```dockerfile
FROM python:3.11-slim

# Install system dependencies
RUN apt-get update && apt-get install -y \
    xvfb \
    x11vnc \
    websockify \
    python3-dev \
    libgl1-mesa-glx \
    libgles2-mesa \
    xclip \
    xsel \
    && rm -rf /var/lib/apt/lists/*

# Install Python packages
RUN pip install kivy pillow

WORKDIR /work
```

#### 2. Update Server (`server.py`)

```python
async def start_vnc_stream(self, container, run_id: str):
    """Start VNC streaming for a container"""
    # Start x11vnc
    await container.exec([
        'x11vnc', 
        '-display', ':99',
        '-forever',
        '-shared',
        '-rfbport', '5900',
        '-nopw'  # No password for simplicity
    ], detach=True)
    
    # Start websockify
    await container.exec([
        'websockify',
        '--web=/usr/share/novnc',
        '6080',
        'localhost:5900'
    ], detach=True)
    
    return 6080  # Return the WebSocket port
```

#### 3. Update Extension (`kivyRenderService.ts`)

```typescript
export class KivyRenderService {
    async showLivePreview(code: string) {
        // Start rendering
        const response = await fetch('http://localhost:9876/render-stream', {
            method: 'POST',
            body: JSON.stringify({ code })
        });
        
        const { port } = await response.json();
        
        // Create webview with noVNC
        const panel = vscode.window.createWebviewPanel(
            'kivyLivePreview',
            'Kivy Live Preview',
            vscode.ViewColumn.Beside,
            { enableScripts: true }
        );
        
        panel.webview.html = this.getWebviewContent(port);
    }
    
    private getWebviewContent(port: number): string {
        return `
            <!DOCTYPE html>
            <html>
            <head>
                <title>Kivy Preview</title>
                <style>
                    body { margin: 0; padding: 0; overflow: hidden; }
                    #screen { width: 100vw; height: 100vh; }
                </style>
            </head>
            <body>
                <div id="screen"></div>
                <script src="http://localhost:${port}/vnc.html"></script>
            </body>
            </html>
        `;
    }
}
```

## Performance Considerations

- **Latency:** VNC over WebSocket typically adds 50-100ms latency
- **Bandwidth:** ~1-5 MB/s for 1024x768 @ 30fps with compression
- **CPU:** x11vnc uses ~5-10% CPU for encoding
- **RAM:** Minimal additional overhead (~50MB)

## Security Considerations

- VNC without password (acceptable for local Docker containers)
- Only expose ports on localhost (127.0.0.1)
- Use Docker network isolation
- Don't expose to external network

---

## Implementation Option B: xpra

### Architecture

```
┌─────────────────────────────────────┐
│  Docker Container                   │
│  ┌──────────┐                       │
│  │  Kivy    │                       │
│  │   App    │                       │
│  └────┬─────┘                       │
│       │                             │
│  ┌────▼─────────┐                   │
│  │ Xvfb :99     │                   │
│  │ (1024x768)   │                   │
│  └────┬─────────┘                   │
│       │                             │
│  ┌────▼─────────┐                   │
│  │ xpra server  │                   │
│  │  :10000      │                   │
│  │ (HTML5 mode) │                   │
│  └────┬─────────┘                   │
└───────┼─────────────────────────────┘
        │
        │ HTTP/WebSocket
        │
┌───────▼─────────────────────────────┐
│ VSCode Extension                    │
│  ┌───────────────────┐              │
│  │  Webview Panel    │              │
│  │  ┌─────────────┐  │              │
│  │  │ xpra HTML5  │  │              │
│  │  │ Client      │  │              │
│  │  │             │  │              │
│  │  │ [Live Kivy  │  │              │
│  │  │  Preview]   │  │              │
│  │  └─────────────┘  │              │
│  └───────────────────┘              │
└─────────────────────────────────────┘
```

### Implementation Steps

#### 1. Update Docker Image

```dockerfile
FROM python:3.11-slim

# Add xpra repository
RUN apt-get update && apt-get install -y \
    wget \
    gnupg2 \
    software-properties-common

RUN wget -O "/usr/share/keyrings/xpra.asc" https://xpra.org/xpra.asc
RUN wget -O "/etc/apt/sources.list.d/xpra.sources" https://xpra.org/repos/bookworm/xpra.sources

# Install system dependencies
RUN apt-get update && apt-get install -y \
    xvfb \
    xpra \
    xpra-html5 \
    python3-dev \
    libgl1-mesa-glx \
    libgles2-mesa \
    && rm -rf /var/lib/apt/lists/*

# Install Python packages
RUN pip install kivy pillow

WORKDIR /work
```

#### 2. Update Server (`server.py`)

```python
async def start_xpra_stream(self, container, run_id: str):
    """Start xpra streaming for a container"""
    # Start xpra server with HTML5 support
    await container.exec([
        'xpra',
        'start',
        ':99',  # Attach to existing Xvfb display
        '--bind-tcp=0.0.0.0:10000',
        '--html=on',
        '--daemon=no',
        '--sharing=yes',
        '--start-child=python3 /work/main.py'
    ], detach=True)
    
    # Wait for xpra to start
    await asyncio.sleep(1)
    
    return 10000  # Return the HTTP port
```

#### 3. Update Extension (`kivyRenderService.ts`)

```typescript
export class KivyRenderService {
    async showLivePreviewXpra(code: string) {
        // Start rendering
        const response = await fetch('http://localhost:9876/render-stream-xpra', {
            method: 'POST',
            body: JSON.stringify({ code })
        });
        
        const { port } = await response.json();
        
        // Create webview with xpra HTML5 client
        const panel = vscode.window.createWebviewPanel(
            'kivyLivePreview',
            'Kivy Live Preview (xpra)',
            vscode.ViewColumn.Beside,
            { enableScripts: true }
        );
        
        panel.webview.html = this.getXpraWebviewContent(port);
    }
    
    private getXpraWebviewContent(port: number): string {
        return `
            <!DOCTYPE html>
            <html>
            <head>
                <title>Kivy Preview (xpra)</title>
                <style>
                    body { margin: 0; padding: 0; overflow: hidden; }
                    iframe { width: 100vw; height: 100vh; border: none; }
                </style>
            </head>
            <body>
                <iframe src="http://localhost:${port}/index.html"></iframe>
            </body>
            </html>
        `;
    }
}
```

### xpra Command Reference

```bash
# Start xpra with HTML5 client
xpra start :99 --bind-tcp=0.0.0.0:10000 --html=on --sharing=yes

# Start with specific resolution
xpra start :99 --bind-tcp=0.0.0.0:10000 --html=on --resize-display=1024x768

# With better compression
xpra start :99 --bind-tcp=0.0.0.0:10000 --html=on --compression=9 --encoding=rgb

# With quality settings
xpra start :99 --bind-tcp=0.0.0.0:10000 --html=on --quality=90 --speed=90
```

## Conclusion

**Both approaches are viable:**

**Choose VNC if:**
- You want simpler, more familiar technology
- Community support is important
- You need to get it working quickly
- Easier debugging is a priority

**Choose xpra if:**
- Performance is critical
- You want lower latency and bandwidth
- You need better window management
- You're willing to invest more setup time

**Recommendation:** Start with VNC for proof-of-concept, then migrate to xpra if performance becomes an issue.
