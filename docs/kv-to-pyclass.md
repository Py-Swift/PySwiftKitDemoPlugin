# KV to Python Classes Generator

Convert Kivy KV language to equivalent Python class definitions.

<iframe src="kv-to-pyclass/index.html" style="width: 100%; height: 800px; border: 1px solid #ccc;"></iframe>

## Features

- **KV Language Input**: Define widgets using Kivy's declarative KV syntax
- **Python Classes Output**: Generate equivalent Python code without needing Builder
- **Template Support**: Handles `<WidgetName@BaseClass>:` template syntax
- **Rule Support**: Converts `<WidgetName>:` rules to Python classes
- **Property Mapping**: Automatically maps KV properties to Python class attributes
- **Share Links**: Generate compressed URLs to share your code

## How It Works

The generator parses KV language rules and templates, then creates Python classes that produce the same widget tree structure. This allows you to use KV-style declarative syntax while generating pure Python code that doesn't require the Builder at runtime.

**Example:**
- `<MyButton@Button>:` becomes a `MyButton` class inheriting from `Button`
- `<UserProfile>:` becomes a `UserProfile` class with child widgets in `__init__`
- Properties are automatically converted to Python class attributes
