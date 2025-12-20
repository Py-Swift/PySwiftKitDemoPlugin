#!/bin/bash
set -e

echo "Building PySwiftKit Demo Plugin for WASM..."

# Use absolute path to Swift 6.2.1 to bypass venv PATH issues
SWIFT_BIN="$HOME/.swiftly/bin/swift"

# Configuration
BUILD_DIR=".build/plugins/PackageToJS/outputs/Package"
DEMO_DIR="demo"

echo "Using Swift 6.2.1 with WASM SDK..."
$SWIFT_BIN --version

# Build using JavaScriptKit plugin
echo "Building Swift package for WASM target..."
$SWIFT_BIN package -c release --swift-sdk swift-6.2.1-RELEASE_wasm js --use-cdn --product PySwiftKitDemo
# Create demo directory if it doesn't exist
mkdir -p "$DEMO_DIR"

# Copy generated files to demo directory
echo "Copying build artifacts to demo directory..."
cp -r "$BUILD_DIR"/* "$DEMO_DIR/"

# Also copy the custom PySwiftKitDemo.js loader if it exists
if [ -f "build/PySwiftKitDemo.js" ]; then
    echo "Copying custom JS loader..."
    cp build/PySwiftKitDemo.js "$DEMO_DIR/"
fi

# Compress WASM with gzip (universally supported)
echo "Compressing WASM with gzip..."
if command -v gzip &> /dev/null; then
    # Get original size before compression
    original_size=$(stat -f%z "$DEMO_DIR/PySwiftKitDemo.wasm")
    
    # Compress with gzip -9 (max compression), keep original
    gzip -9 -f -k "$DEMO_DIR/PySwiftKitDemo.wasm"
    
    # Remove uncompressed to avoid LFS issues
    rm "$DEMO_DIR/PySwiftKitDemo.wasm"
    
    # Patch index.js to load .wasm.gz with client-side decompression
    echo "Patching index.js to load compressed WASM..."
    sed -i.bak 's|fetch(new URL("PySwiftKitDemo.wasm", import.meta.url))|fetch(new URL("PySwiftKitDemo.wasm.gz", import.meta.url)).then(async r => { const ds = new DecompressionStream("gzip"); return new Response(r.body.pipeThrough(ds), { headers: { "Content-Type": "application/wasm" } }); })|' "$DEMO_DIR/index.js"
    rm "$DEMO_DIR/index.js.bak"
    
    # Show compression stats
    compressed_size=$(stat -f%z "$DEMO_DIR/PySwiftKitDemo.wasm.gz")
    compression_ratio=$(echo "scale=1; 100 - ($compressed_size * 100 / $original_size)" | bc)
    
    echo "   Original:   $(numfmt --to=iec-i --suffix=B $original_size 2>/dev/null || echo "$(($original_size / 1024 / 1024))MB")"
    echo "   Compressed: $(numfmt --to=iec-i --suffix=B $compressed_size 2>/dev/null || echo "$(($compressed_size / 1024 / 1024))MB")"
    echo "   Saved:      ${compression_ratio}%"
    echo "   ✅ Client-side decompression (JS DecompressionStream API)"
else
    echo "   ⚠️  gzip not found (should be built-in)"
    echo "   Keeping uncompressed WASM..."
fi

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
            padding: 1rem 2rem 0;
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
        
        .tabs {
            display: flex;
            gap: 0.5rem;
            margin-top: 1rem;
        }
        
        .tab {
            padding: 0.5rem 1rem;
            background: transparent;
            border: none;
            color: #858585;
            cursor: pointer;
            font-size: 0.9rem;
            border-bottom: 2px solid transparent;
            transition: all 0.2s;
        }
        
        .tab:hover {
            color: #cccccc;
        }
        
        .tab.active {
            color: #cccccc;
            border-bottom-color: #007acc;
        }
        
        .tab-content {
            flex: 1;
            display: none;
            grid-template-columns: 1fr 1fr;
            gap: 1px;
            background: #3e3e42;
            overflow: hidden;
        }
        
        .tab-content.active {
            display: grid;
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
        
        #swift-editor, #python-editor, #python-input-editor, #swift-output-editor {
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
        <div class="subtitle">Swift WASM Edition with Monaco Editor - Bidirectional Code Generation</div>
        <div class="tabs">
            <button class="tab active" data-tab="swift-to-python">Swift → Python</button>
            <button class="tab" data-tab="python-to-swift">Python → Swift</button>
        </div>
    </header>
    
    <!-- Tab 1: Swift to Python -->
    <div id="swift-to-python" class="tab-content active">
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
    
    <!-- Tab 2: Python to Swift -->
    <div id="python-to-swift" class="tab-content">
        <div class="editor-panel">
            <div class="panel-header">Python Code</div>
            <div class="editor-container">
                <div id="python-input-editor"></div>
            </div>
        </div>
        
        <div class="editor-panel">
            <div class="panel-header">Generated Swift PySwiftKit Code (Read-only)</div>
            <div class="editor-container">
                <div id="swift-output-editor"></div>
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
            // Make monaco globally accessible before Swift initializes
            window.monaco = monaco;
            
            // Setup tab switching
            const tabs = document.querySelectorAll('.tab');
            const tabContents = document.querySelectorAll('.tab-content');
            
            tabs.forEach(tab => {
                tab.addEventListener('click', () => {
                    const targetTab = tab.dataset.tab;
                    
                    // Update active tab
                    tabs.forEach(t => t.classList.remove('active'));
                    tab.classList.add('active');
                    
                    // Update active content
                    tabContents.forEach(content => {
                        if (content.id === targetTab) {
                            content.classList.add('active');
                        } else {
                            content.classList.remove('active');
                        }
                    });
                    
                    // Trigger Monaco layout update
                    window.monaco.editor.getEditors().forEach(editor => {
                        setTimeout(() => editor.layout(), 0);
                    });
                });
            });
            
            // Wait a bit to ensure monaco is fully ready
            await new Promise(resolve => setTimeout(resolve, 100));
            
            showStatus('Initializing Swift WASM...');
            
            try {
                // Initialize Swift WASM - this will call setupEditors() via @main
                const swift = await init();
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

# Show appropriate file size based on what exists
if [ -f "$DEMO_DIR/PySwiftKitDemo.wasm.br" ]; then
    echo "   WASM size: $(du -h "$DEMO_DIR/PySwiftKitDemo.wasm.br" | cut -f1) (Brotli compressed)"
elif [ -f "$DEMO_DIR/PySwiftKitDemo.wasm" ]; then
    echo "   WASM size: $(du -h "$DEMO_DIR/PySwiftKitDemo.wasm" | cut -f1) (uncompressed)"
fi

# Trigger mkdocs reload if serving
if [ -d "docs" ]; then
    touch docs/demo.md 2>/dev/null || true
    echo "   🔄 Triggered mkdocs reload"
fi

echo ""
echo "To test locally, run:"
echo "   uv run mkdocs serve"
echo "   Then open: http://localhost:8000/"
