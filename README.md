# PySwiftKit Demo Plugin

A Swift-WASM powered MkDocs plugin featuring dual Monaco editors that demonstrate PySwiftKit decorators and real-time Python API generation.

## Overview

This plugin showcases:
- **Left Editor**: Swift code with PySwiftKit decorators (`@PyClass`, `@PyMethod`, `@PyProperty`, etc.)
- **Right Editor**: Auto-generated Python API stubs that match the Swift interface

All processing happens in the browser via WebAssembly, with no server-side dependencies.

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                      MkDocs Page                            │
│  ┌─────────────────────┐  ┌──────────────────────────┐    │
│  │  Monaco Editor      │  │  Monaco Editor           │    │
│  │  (Swift Input)      │  │  (Python Output)         │    │
│  │                     │  │                          │    │
│  │  @PyClass          │  │  class Person:            │    │
│  │  class Person {...}│─▶│      def __init__(...):   │    │
│  │                     │  │          ...              │    │
│  └─────────────────────┘  └──────────────────────────┘    │
│              │                                              │
│              ▼                                              │
│  ┌──────────────────────────────────────┐                  │
│  │   Swift WASM (JavaScriptKit)         │                  │
│  │   - Text change callbacks            │                  │
│  │   - PySwiftAST parser (Stage 2)      │                  │
│  │   - Python code generator (Stage 3)  │                  │
│  └──────────────────────────────────────┘                  │
└─────────────────────────────────────────────────────────────┘
```

## Project Structure

```
PySwiftKitDemoPlugin/
├── Package.swift              # Swift package manifest
├── Sources/
│   └── Main.swift             # Swift WASM entry point
├── build.sh                   # WASM build script
├── build/                     # Compiled WASM outputs (gitignored)
│   ├── PySwiftKitDemo.wasm
│   └── PySwiftKitDemo.js
├── demo/
│   └── index.html             # Standalone demo page
├── mkdocs_plugin/
│   ├── pyswiftkit_demo.py     # MkDocs plugin implementation
│   └── setup.py               # Python package setup
└── README.md
```

## Stage 1 (Current) ✅

- [x] Swift package with JavaScriptKit dependency
- [x] Monaco Editor JavaScript bridge
- [x] Dual editor layout with text change callbacks
- [x] Basic Python stub generation (placeholder)
- [x] WASM build script (standalone module)
- [x] Standalone HTML demo
- [x] MkDocs plugin scaffold

## Stage 2 (Next)

- [ ] Integrate PySwiftAST parser for Swift code analysis
- [ ] Implement PySwiftIDE / MonacoAPI wrappers
- [ ] Add JavaScript closures for Monaco completion providers
- [ ] Parse PySwiftKit decorators accurately
- [ ] Hover tooltips for decorator information

## Stage 3 (Later)

- [ ] Port PyFileGenerator logic for Python code generation
- [ ] Generate accurate Python stubs from parsed AST
- [ ] Handle complex types and generics
- [ ] Support all PySwiftKit decorator types

## Prerequisites

### Swift WASM Toolchain

Install the SwiftWasm toolchain:

```bash
# Download from: https://github.com/swiftwasm/swift/releases
# Or use swiftenv:
swiftenv install wasm-5.9.0-RELEASE
swiftenv global wasm-5.9.0-RELEASE
```

Verify installation:

```bash
swift --version
# Should show "Swift version X.X.X (wasm)" or similar
```

### Python Dependencies (for MkDocs plugin)

```bash
pip install mkdocs>=1.4.0
```

## Building

### 1. Build the WASM Module

```bash
chmod +x build.sh
./build.sh
```

This generates:
- `build/PySwiftKitDemo.wasm` - The Swift code compiled to WebAssembly
- `build/PySwiftKitDemo.js` - JavaScriptKit loader

### 2. Test Standalone Demo

```bash
python3 -m http.server 8000
```

Open: http://localhost:8000/demo/index.html

### 3. Install MkDocs Plugin

```bash
cd mkdocs_plugin
pip install -e .
```

### 4. Use in MkDocs

Add to your `mkdocs.yml`:

```yaml
plugins:
  - pyswiftkit_demo:
      wasm_path: "assets/wasm"
      enable_on:
        - "demo"
        - "playground"
```

Create a page (e.g., `docs/demo.md`):

```markdown
# PySwiftKit Interactive Demo

Try editing the Swift code below!

<!-- The plugin will inject the editors here -->
```

Build your docs:

```bash
mkdocs build
mkdocs serve
```

## Development

### Modifying the Swift Code

1. Edit `Sources/Main.swift`
2. Run `./build.sh`
3. Refresh your browser

### Testing Changes

The `demo/index.html` file provides a quick way to test without MkDocs:

```bash
./build.sh
python3 -m http.server 8000
# Open http://localhost:8000/demo/index.html
```

## References

- [JavaScriptKit Documentation](https://swiftpackageindex.com/swiftwasm/javascriptkit/0.37.0/tutorials/javascriptkit/hello-world)
- [Monaco Editor API](https://microsoft.github.io/monaco-editor/playground.html)
- [PySwiftAST](https://github.com/Py-Swift/PySwiftAST)
- [PyFileGenerator](https://github.com/Py-Swift/PyFileGenerator)
- [PySwiftKit](https://github.com/Py-Swift/PySwiftKit)

## License

MIT
