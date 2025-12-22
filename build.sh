#!/bin/bash
set -e

echo "Building PySwiftKit Demo Plugins for WASM..."

# Use absolute path to Swift 6.2.1 to bypass venv PATH issues
SWIFT_BIN="$HOME/.swiftly/bin/swift"

# Configuration
BUILD_DIR=".build/plugins/PackageToJS/outputs/Package"
DEMO_DIR="demo"

echo "Using Swift 6.2.1 with WASM SDK..."
$SWIFT_BIN --version

# Define all products to build
declare -a PRODUCTS=("PySwiftKitDemo" "SwiftToPythonDemo" "PythonToSwiftDemo" "PyDataModelDemo" "KvAstTree")
declare -a OUTPUT_DIRS=("$DEMO_DIR" "docs/swift-to-python" "docs/python-to-swift" "docs/python-datamodel" "docs/kv-ast-tree")
declare -a HTML_TEMPLATES=("templates/index.html" "templates/swift-to-python.html" "templates/python-to-swift.html" "templates/python-datamodel.html" "templates/kv-ast-tree.html")

# Build each product
for i in "${!PRODUCTS[@]}"; do
    PRODUCT="${PRODUCTS[$i]}"
    OUTPUT="${OUTPUT_DIRS[$i]}"
    TEMPLATE="${HTML_TEMPLATES[$i]}"
    
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Building: $PRODUCT"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    # Build using JavaScriptKit plugin
    echo "Building Swift package for WASM target..."
    $SWIFT_BIN package -c release --swift-sdk swift-6.2.1-RELEASE_wasm js --use-cdn --product "$PRODUCT"
    
    # Create output directory
    mkdir -p "$OUTPUT"
    
    # Copy generated files to output directory
    echo "Copying build artifacts to $OUTPUT..."
    cp -r "$BUILD_DIR"/* "$OUTPUT/"
    
    # Copy HTML template
    if [ -f "$TEMPLATE" ]; then
        echo "Copying HTML template..."
        cp "$TEMPLATE" "$OUTPUT/index.html"
    fi
    
    # Compress WASM with gzip
    echo "Compressing WASM with gzip..."
    if command -v gzip &> /dev/null; then
        # Get original size before compression
        original_size=$(stat -f%z "$OUTPUT/$PRODUCT.wasm")
        
        # Compress with gzip -9 (max compression), keep original
        gzip -9 -f -k "$OUTPUT/$PRODUCT.wasm"
        
        # Remove uncompressed to avoid LFS issues
        rm "$OUTPUT/$PRODUCT.wasm"
        
        # Patch index.js to load .wasm.gz with client-side decompression
        echo "Patching index.js to load compressed WASM..."
        sed -i.bak "s|fetch(new URL(\"$PRODUCT.wasm\", import.meta.url))|fetch(new URL(\"$PRODUCT.wasm.gz\", import.meta.url)).then(async r => { const ds = new DecompressionStream(\"gzip\"); return new Response(r.body.pipeThrough(ds), { headers: { \"Content-Type\": \"application/wasm\" } }); })|" "$OUTPUT/index.js"
        rm "$OUTPUT/index.js.bak"
        
        # Show compression stats
        compressed_size=$(stat -f%z "$OUTPUT/$PRODUCT.wasm.gz")
        compression_ratio=$(echo "scale=1; 100 - ($compressed_size * 100 / $original_size)" | bc)
        
        echo "   Original:   $(numfmt --to=iec-i --suffix=B $original_size 2>/dev/null || echo "$(($original_size / 1024 / 1024))MB")"
        echo "   Compressed: $(numfmt --to=iec-i --suffix=B $compressed_size 2>/dev/null || echo "$(($compressed_size / 1024 / 1024))MB")"
        echo "   Saved:      ${compression_ratio}%"
    else
        echo "   ⚠️  gzip not found"
    fi
    
    echo "✅ $PRODUCT complete → $OUTPUT"
done

# Trigger mkdocs reload if serving
if [ -d "docs" ]; then
    touch docs/demo.md 2>/dev/null || true
    echo ""
    echo "   🔄 Triggered mkdocs reload"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ All builds complete!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "To test locally, run:"
echo "   uv run mkdocs serve"
echo "   Then open: http://localhost:8000/"
