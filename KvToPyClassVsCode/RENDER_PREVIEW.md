# Kivy Widget Render Preview

This feature allows you to see live rendered previews of Kivy widgets when you hover over them in VSCode.

## Setup

### Prerequisites

1. **Docker** must be installed and running
   - On macOS: Start Docker Desktop
   - On Linux: Ensure Docker daemon is running (`sudo systemctl start docker`)
   - On Windows: Start Docker Desktop
   - Verify Docker is running: `docker ps`
2. **Python 3.11+** with pip/uv

### Installation Steps

1. **Build the Docker Image**

```bash
cd doctor-kivy
docker build -t doctor-kivy:latest -f Dockerfile .
```

2. **Install Python Dependencies**

```bash
cd doctor-kivy
pip install -e .
# or with uv:
uv pip install -e .
```

3. **Enable the Feature in VSCode**

Add to your VSCode settings (`settings.json`):

```json
{
    "kvToPyClass.enableRenderPreview": true
}
```

4. **Start the Render Server** (Optional - auto-starts on first hover)

**Easy way (recommended):**
```bash
cd doctor-kivy
chmod +x start_server.sh
./start_server.sh
```

This script will automatically:
- Check if Docker is running
- Build the Docker image if needed
- Install Python dependencies if needed
- Start the server

**Manual way:**
```bash
cd doctor-kivy
python3 server.py
```

The server will listen on `http://127.0.0.1:9876`.

## Usage

1. Open any `.kv` file in VSCode
2. Hover over a widget definition (e.g., `Button:`, `BoxLayout:`, etc.)
3. Wait a moment for the preview to render
4. The hover tooltip will show a rendered image of the widget

### Example

```kv
BoxLayout:
    orientation: 'vertical'
    Button:
        text: 'Click me!'
        background_color: 1, 0, 0, 1
    Label:
        text: 'Hello World'
```

Hovering over `BoxLayout:` will show a rendered preview of the entire layout with its children.

## Configuration

### Settings

- `kvToPyClass.enableRenderPreview` (boolean, default: `false`) - Enable/disable widget render previews

### Performance

- Renders are cached, so hovering over the same widget again will be instant
- Only widgets with 2+ lines are rendered (skips simple single-line properties)
- Rendering timeout: 30 seconds per widget

## Troubleshooting

### Server Won't Start

- **First, ensure Docker is running:**
  - macOS: Open Docker Desktop and wait for it to fully start
  - Linux: `sudo systemctl status docker` or `sudo systemctl start docker`
  - Windows: Open Docker Desktop and wait for it to fully start
  - Verify: `docker ps` should not return an error
- Check that port 9876 is available: `lsof -i :9876` (or `netstat -an | grep 9876` on Windows)
- Check Python dependencies: `pip list | grep aiohttp`
- Check Docker socket:
  - macOS/Linux: Should exist at `/var/run/docker.sock` or `~/.docker/run/docker.sock`
  - Set DOCKER_HOST if needed: `export DOCKER_HOST=unix://$HOME/.docker/run/docker.sock`

### No Preview Showing

- Check the Output panel → "KV to PyClass" for errors
- Verify the Docker image exists: `docker images | grep doctor-kivy`
- Try manually starting the server: `cd doctor-kivy && python3 server.py`

### Slow Rendering

- First render will be slower (Docker container startup)
- Subsequent renders use cached containers and are faster
- Complex widgets with many children take longer to render

## Architecture

```
VSCode Extension (TypeScript)
    ↓ HTTP POST /render
KivyRenderService (Python server.py)
    ↓ Docker API
Docker Container (doctor-kivy:latest)
    ↓ Kivy App
Rendered Screenshot (PNG)
    ↑ Base64 encoded
VSCode Hover Tooltip
```

## Security

- The render server only listens on localhost (127.0.0.1)
- Docker containers run with:
  - No network access (`NetworkMode: none`)
  - Dropped capabilities (`CapDrop: ALL`)
  - No new privileges (`no-new-privileges`)
  - Auto-remove on exit

## License

Same as the parent project.
