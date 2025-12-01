# PySwiftKit Demo

Welcome to the PySwiftKit demo - a Swift WASM powered plugin that generates Python API wrappers from Swift code decorated with PySwiftKit decorators.

## What is PySwiftKit?

[PySwiftKit](https://github.com/Py-Swift/PySwiftKit) is a framework that allows you to write Swift code that can be called from Python. Using decorators like `@PyClass`, `@PyMethod`, `@PyInit`, and `@PyProperty`, you can mark Swift classes and methods to be exposed to Python.

This demo shows how your Swift code with PySwiftKit decorators maps to Python API structure.

## Implementation Status

- ✅ **Stage 1**: Monaco Editor integration with JavaScriptKit
- ✅ **Stage 2**: SwiftSyntax + PySwiftAST parsing and Python code generation
- 🔄 **Stage 3**: Monaco completion providers (coming soon)
- ✅ **Stage 4**: MkDocs plugin integration

## Features

- **Real-time parsing**: Edit Swift code and instantly see the generated Python API
- **SwiftSyntax powered**: Uses Apple's official Swift parser compiled to WASM
- **Type mapping**: Swift types (String, Int, Bool) automatically map to Python types (str, int, bool)
- **Decorator support**: Full support for @PyClass, @PyMethod, @PyInit, @PyProperty, @staticmethod
- **Proper formatting**: Generated Python code follows PEP 8 style guidelines

## Try the Demo

Check out the [interactive demo](demo.md) to see it in action!
