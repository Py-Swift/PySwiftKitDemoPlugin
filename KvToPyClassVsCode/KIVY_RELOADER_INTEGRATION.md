# Kivy-Reloader Integration for VSCode Extension

## How Kivy-Reloader Works

Kivy-reloader uses a **TCP server** on Android devices that receives hot-reload updates from the desktop.

### Architecture

```
┌─────────────────┐                    ┌──────────────────┐
│  Desktop App    │                    │  Android Device  │
│  (watchdog)     │                    │  (TCP server)    │
├─────────────────┤                    ├──────────────────┤
│ 1. Watch files  │                    │ 1. Listen on     │
│ 2. Detect       │                    │    port 8050     │
│    changes      │                    │                  │
│ 3. Create ZIP   │   ─────────────>   │ 2. Receive ZIP   │
│    (delta/full) │   TCP Connection   │                  │
│ 4. Send via ADB │                    │ 3. Extract files │
│    WiFi (TCP)   │   <─────────────   │ 4. Send ACK "OK" │
│                 │                    │ 5. Hot reload    │
└─────────────────┘                    └──────────────────┘
```

### Key Components

1. **Port**: `8050` (default, configurable via `RELOADER_PORT` in `kivy-reloader.toml`)
2. **Protocol**: TCP over WiFi (requires Android device on same network)
3. **Package Format**: ZIP file containing changed files + metadata

## Configuration

### kivy-reloader.toml
```toml
[kivy_reloader]
RELOADER_PORT = 8050  # TCP port on Android
ADB_PORT = 5555       # ADB TCP/IP port
PHONE_IPS = ["192.168.1.100"]  # Optional: manual IP addresses
```

## Transfer Protocol

### 1. Delta Transfer (Optimized)
```json
{
  "type": "delta",
  "timestamp": 1234567890.0,
  "file_count": 3,
  "files": ["main.py", "screens/home.py"],
  "deleted_files": ["old_screen.py"]
}
```

### 2. Full Transfer (Fallback)
```json
{
  "type": "full",
  "timestamp": 1234567890.0,
  "file_count": 50,
  "files": ["main.py", "..."]
}
```

## Integration Steps for VSCode Extension

### Step 1: Detect Android Device IP
```typescript
// Use adb to get device WiFi IP
async function getDeviceIP(): Promise<string | null> {
    const result = await exec('adb shell ip addr show wlan0');
    // Parse IP from: inet 192.168.1.100/24
    const match = result.match(/inet (\\d+\\.\\d+\\.\\d+\\.\\d+)/);
    return match ? match[1] : null;
}
```

### Step 2: Create ZIP Package
```typescript
import * as JSZip from 'jszip';

async function createDeltaPackage(changedFiles: string[]): Promise<Buffer> {
    const zip = new JSZip();
    
    // Add metadata
    const metadata = {
        type: 'delta',
        timestamp: Date.now() / 1000,
        file_count: changedFiles.length,
        files: changedFiles,
        deleted_files: []
    };
    zip.file('_delta_metadata.json', JSON.stringify(metadata, null, 2));
    
    // Add changed files
    for (const file of changedFiles) {
        const content = await fs.readFile(file);
        zip.file(file, content);
    }
    
    return await zip.generateAsync({ type: 'nodebuffer' });
}
```

### Step 3: Send to Android
```typescript
import * as net from 'net';

async function sendToAndroid(deviceIP: string, zipBuffer: Buffer): Promise<boolean> {
    return new Promise((resolve, reject) => {
        const client = net.connect({ host: deviceIP, port: 8050 }, () => {
            console.log('Connected to Android device');
            
            // Send ZIP data in chunks
            const CHUNK_SIZE = 256 * 1024; // 256KB chunks
            let offset = 0;
            
            while (offset < zipBuffer.length) {
                const chunk = zipBuffer.slice(offset, offset + CHUNK_SIZE);
                client.write(chunk);
                offset += CHUNK_SIZE;
            }
            
            client.end();
        });
        
        // Wait for ACK
        client.on('data', (data) => {
            if (data.toString().startsWith('OK')) {
                console.log('ACK received from Android');
                resolve(true);
            }
        });
        
        client.on('error', (err) => {
            console.error('Connection error:', err);
            reject(err);
        });
        
        client.on('timeout', () => {
            console.error('Connection timeout');
            reject(new Error('Timeout waiting for ACK'));
        });
        
        client.setTimeout(3000); // 3 second timeout for ACK
    });
}
```

### Step 4: Docker Container Integration

Since we're running Kivy apps in Docker, we need to simulate the Android server:

```python
# kivy_reloader_server.py - Run inside Docker
import socket
import os
import zipfile
import json
from pathlib import Path

def start_reloader_server(port=8050):
    """Simulate Android kivy-reloader TCP server"""
    server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    server.bind(('0.0.0.0', port))
    server.listen(1)
    print(f'Kivy-Reloader server listening on port {port}')
    
    while True:
        client, addr = server.accept()
        print(f'Connection from {addr}')
        
        # Receive ZIP data
        data = b''
        while True:
            chunk = client.recv(256 * 1024)
            if not chunk:
                break
            data += chunk
        
        # Save and extract ZIP
        zip_path = '/tmp/app_update.zip'
        with open(zip_path, 'wb') as f:
            f.write(data)
        
        # Extract files
        with zipfile.ZipFile(zip_path, 'r') as zip_file:
            # Read metadata
            if '_delta_metadata.json' in zip_file.namelist():
                metadata = json.loads(zip_file.read('_delta_metadata.json'))
                print(f"Received {metadata['type']} update with {metadata['file_count']} files")
                
                # Extract changed files
                for file_name in metadata.get('files', []):
                    zip_file.extract(file_name, '/work')
                
                # Delete removed files
                for file_name in metadata.get('deleted_files', []):
                    file_path = Path('/work') / file_name
                    if file_path.exists():
                        file_path.unlink()
            else:
                # Full transfer
                zip_file.extractall('/work')
        
        # Send ACK
        client.sendall(b'OK')
        client.close()
        
        # Trigger hot reload (restart Kivy app)
        print('Files updated, reloading app...')
        # TODO: Signal Kivy app to reload

if __name__ == '__main__':
    start_reloader_server()
```

### Step 5: Update Docker Setup

```dockerfile
# Dockerfile.vnc-multi
# Add kivy-reloader server port
EXPOSE 5900-5901 6080-6081 8050
```

```yaml
# docker-compose.vnc-multi.yml
services:
  kivy-vnc-multi:
    ports:
      - "5900-5901:5900-5901"
      - "6080-6081:6080-6081"
      - "8050:8050"  # Kivy-reloader port
```

### Step 6: VSCode Extension Commands

```typescript
// extension.ts
context.subscriptions.push(
    vscode.commands.registerCommand('kvToPyClass.sendToKivyReloader', async () => {
        const editor = vscode.window.activeTextEditor;
        if (!editor) return;
        
        // Get changed files (from git or file watcher)
        const changedFiles = await getChangedFiles();
        
        // Create delta package
        const zipBuffer = await createDeltaPackage(changedFiles);
        
        // Send to Docker container (localhost:8050)
        const success = await sendToAndroid('localhost', zipBuffer);
        
        if (success) {
            vscode.window.showInformationMessage('✅ Hot reload sent to Kivy app');
        } else {
            vscode.window.showErrorMessage('❌ Failed to send hot reload');
        }
    })
);
```

## Testing

1. **Start Docker container** with kivy-reloader server:
   ```bash
   docker-compose -f docker-compose.vnc-multi.yml up -d
   ```

2. **Test connection**:
   ```bash
   nc -v localhost 8050
   ```

3. **Send test package** from VSCode extension

4. **Verify hot reload** in VNC preview window

## Benefits

- ✅ **Fast updates**: Only changed files are sent (delta transfer)
- ✅ **No app restart**: Hot reload preserves app state
- ✅ **Real-time preview**: See changes instantly in VNC window
- ✅ **Drag & drop widgets**: Place widgets and update code
- ✅ **Multi-instance support**: Test on multiple displays simultaneously

## Next Steps

1. Implement `kivy_reloader_server.py` in Docker
2. Add file watcher in VSCode extension
3. Create `sendToKivyReloader` command
4. Add status bar indicator for connection
5. Implement widget placement collision detection
