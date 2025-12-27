#!/bin/bash
set -e

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Building All PySwiftKit Demo Plugins"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Build each demo
./build-pyswiftkit.sh
echo ""
./build-swift-to-python.sh
echo ""
./build-python-to-swift.sh
echo ""
./build-datamodel.sh
echo ""
./build-kv-ast-tree.sh
echo ""
./build-kv-swiftui-demo.sh
echo ""
./build-kv-datamodel-demo.sh
echo ""
./build-kv-to-pyclass.sh
echo ""

# Trigger mkdocs reload
if [ -d "docs" ]; then
    touch docs/demo.md 2>/dev/null || true
    echo ""
    echo "🔄 Triggered mkdocs reload"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ All builds complete!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "To test locally: uv run mkdocs serve"
echo "Then open: http://localhost:8000/"
