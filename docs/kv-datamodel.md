# KV to EventDispatcher DataModel Generator

Generate Kivy EventDispatcher data models from KV language and Python class definitions.

<iframe src="kv-datamodel/index.html" style="width: 100%; height: 800px; border: 1px solid #ccc;"></iframe>

## Features

- **Dual Input**: KV language (top-left) and Python class (bottom-left)
- **EventDispatcher Generation**: Converts Python classes to Kivy EventDispatcher models
- **Property Binding**: Automatically generates properties referenced in KV
- **Share Links**: Generate compressed URLs to share your code

## How It Works

1. **KV Language**: Define your widget structure with property references (e.g., `root.title`)
2. **Python Class**: Define a plain Python class with those properties
3. **Generated Model**: Get an EventDispatcher model with Kivy properties that replace the Python class

The generator analyzes the KV file to find property references, then converts the Python class to use Kivy properties (StringProperty, NumericProperty, etc.) based on the property types.
