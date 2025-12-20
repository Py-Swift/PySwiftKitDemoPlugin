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

# Copy index.html template
if [ -f "templates/index.html" ]; then
    echo "Copying index.html template..."
    cp templates/index.html "$DEMO_DIR/"
fi

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
