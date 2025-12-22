# KV AST Tree Parser

Interactive parser for Kivy's KV language using [SwiftyKvLang](https://github.com/Py-Swift/SwiftyKvLang).

## Demo

<iframe src="kv-ast-tree/index.html" style="width: 100%; height: 800px; border: 1px solid #444; border-radius: 4px;"></iframe>

## About

This demo uses **SwiftyKvLang**, a Swift parser for the Kivy KV language. Enter KV language code on the left to see the Abstract Syntax Tree (AST) on the right.

### Features

- ✅ Complete KV language support (directives, rules, widgets, canvas)
- ✅ Real-time AST visualization
- ✅ YAML-inspired indentation handling
- ✅ URL sharing for code snippets

### Example KV Code

```yaml
<Button>:
    text: 'Click me'
    size_hint: 0.5, 0.2
    canvas.before:
        Color:
            rgba: 0.2, 0.6, 0.8, 1
        RoundedRectangle:
            pos: self.pos
            size: self.size
```

### Learn More

- [SwiftyKvLang Repository](https://github.com/Py-Swift/SwiftyKvLang)
- [Kivy Documentation](https://kivy.org/)
