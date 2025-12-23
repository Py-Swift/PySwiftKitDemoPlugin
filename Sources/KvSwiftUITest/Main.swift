import KvParser
import KvSwiftUI

/// Test executable for KvSwiftUI generator
/// Demonstrates converting KV language to SwiftUI code

let kvSource = """
BoxLayout:
    orientation: 'vertical'
    padding: 20
    
    Label:
        text: 'Hello SwiftUI'
        font_size: 24
        color: [0.2, 0.5, 1.0, 1.0]
    
    Button:
        text: 'Click Me'
        size_hint: 1.0, 0.2
        background_color: [0.3, 0.7, 0.3, 1.0]
    
    BoxLayout:
        orientation: 'horizontal'
        
        Slider:
            value: 0.5
        
        Label:
            text: 'Volume'
"""

print("=== KV Source ===")
print(kvSource)
print()

// Parse KV source
do {
    // First tokenize
    let tokenizer = KvTokenizer(source: kvSource)
    let tokens = try tokenizer.tokenize()
    
    print("=== Tokenized ===")
    print("Token count: \(tokens.count)")
    print()
    
    // Then parse
    let parser = KvParser(tokens: tokens)
    let module = try parser.parse()
    
    print("=== Parsed KV Module ===")
    print("Root widget: \(module.root?.name ?? "none")")
    print("Properties: \(module.root?.properties.count ?? 0)")
    print("Children: \(module.root?.children.count ?? 0)")
    print()
    
    // Generate SwiftUI code
    let generator = KvSwiftUIGenerator()
    let swiftCode = generator.generate(from: module)
    
    print("=== Generated SwiftUI Code ===")
    print(swiftCode)
    print()
    
} catch {
    print("Error parsing KV: \(error)")
}
