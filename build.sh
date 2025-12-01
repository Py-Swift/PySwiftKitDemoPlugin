#!/bin/bash
set -e

echo "Building PySwiftKit Demo Plugin for WASM..."

# Configuration
BUILD_DIR=".build/plugins/PackageToJS/outputs/Package"
DEMO_DIR="demo"

echo "Using Swift 6.2.1 with WASM SDK..."
swift --version

# Build using JavaScriptKit plugin
echo "Building Swift package for WASM target..."
swift package -c release --swift-sdk swift-6.2.1-RELEASE_wasm js --use-cdn --product PySwiftKitDemo
# Create demo directory if it doesn't exist
mkdir -p "$DEMO_DIR"

# Copy generated files to demo directory
echo "Copying build artifacts to demo directory..."
cp -r "$BUILD_DIR"/* "$DEMO_DIR/"

# Create index.html in demo directory
echo "Generating index.html..."
cat > "$DEMO_DIR/index.html" << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>PySwiftKit Demo - Dual Monaco Editor</title>
    <script type="importmap">
    {
        "imports": {
            "@bjorn3/browser_wasi_shim": "https://cdn.jsdelivr.net/npm/@bjorn3/browser_wasi_shim@0.3.0/dist/index.js"
        }
    }
    </script>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
            background: #1e1e1e;
            color: #d4d4d4;
            height: 100vh;
            display: flex;
            flex-direction: column;
        }
        
        header {
            background: #252526;
            padding: 1rem 2rem;
            border-bottom: 1px solid #3e3e42;
        }
        
        h1 {
            font-size: 1.2rem;
            font-weight: 600;
            color: #cccccc;
        }
        
        .subtitle {
            font-size: 0.85rem;
            color: #858585;
            margin-top: 0.25rem;
        }
        
        .container {
            flex: 1;
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 1px;
            background: #3e3e42;
            overflow: hidden;
        }
        
        .editor-panel {
            background: #1e1e1e;
            display: flex;
            flex-direction: column;
        }
        
        .panel-header {
            background: #252526;
            padding: 0.5rem 1rem;
            font-size: 0.9rem;
            font-weight: 500;
            border-bottom: 1px solid #3e3e42;
        }
        
        .editor-container {
            flex: 1;
            position: relative;
        }
        
        #swift-editor, #python-editor {
            position: absolute;
            top: 0;
            left: 0;
            right: 0;
            bottom: 0;
        }
        
        .status {
            position: fixed;
            bottom: 20px;
            right: 20px;
            background: #007acc;
            color: white;
            padding: 10px 20px;
            border-radius: 4px;
            font-size: 0.85rem;
            box-shadow: 0 2px 8px rgba(0,0,0,0.3);
            display: none;
        }
        
        .status.show {
            display: block;
        }
    </style>
</head>
<body>
    <header>
        <h1>🐍 PySwiftKit Demo Plugin</h1>
        <div class="subtitle">Swift WASM Edition with Monaco Editor - Stage 1</div>
    </header>
    
    <div class="container">
        <div class="editor-panel">
            <div class="panel-header">Swift Code (with PySwiftKit decorators)</div>
            <div class="editor-container">
                <div id="swift-editor"></div>
            </div>
        </div>
        
        <div class="editor-panel">
            <div class="panel-header">Generated Python API (Read-only)</div>
            <div class="editor-container">
                <div id="python-editor"></div>
            </div>
        </div>
    </div>
    
    <div id="status" class="status">Loading Swift WASM...</div>
    
    <!-- Monaco Editor -->
    <script src="https://cdn.jsdelivr.net/npm/monaco-editor@0.45.0/min/vs/loader.js"></script>
    
    <script type="module">
        import { init } from './index.js';
        
        const status = document.getElementById('status');
        
        function showStatus(message) {
            status.textContent = message;
            status.classList.add('show');
            setTimeout(() => status.classList.remove('show'), 3000);
        }
        
        showStatus('Loading Monaco Editor...');
        
        // Load Monaco Editor
        require.config({ 
            paths: { 
                'vs': 'https://cdn.jsdelivr.net/npm/monaco-editor@0.45.0/min/vs' 
            } 
        });
        
        require(['vs/editor/editor.main'], async function() {
            console.log('Monaco Editor loaded');
            
            // Make monaco globally accessible before Swift initializes
            window.monaco = monaco;
            
            // Wait a bit to ensure monaco is fully ready
            await new Promise(resolve => setTimeout(resolve, 100));
            
            showStatus('Initializing Swift WASM...');
            
            try {
                // Initialize Swift WASM - this will call setupEditors() via @main
                const swift = await init();
                console.log('Swift WASM initialized successfully!');
                showStatus('Swift WASM Ready!');
                
            } catch (error) {
                console.error('Failed to initialize Swift WASM:', error);
                showStatus('Error: ' + error.message);
            }
        });
    </script>
</body>
</html>
EOF

echo ""
echo "✅ Build complete!"
echo "   Output directory: $DEMO_DIR/"
echo "   WASM size: $(du -h "$DEMO_DIR/PySwiftKitDemo.wasm" | cut -f1)"
echo ""
echo "To test locally, run:"
echo "   cd demo && python3 -m http.server 8000"
echo "   Then open: http://localhost:8000/index.html"
