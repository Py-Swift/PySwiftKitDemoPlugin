import KvParser
import SwiftSyntax
import SwiftSyntaxBuilder
import Foundation

/// Generates SwiftUI code from KV language AST
///
/// This generator translates Kivy widget trees into SwiftUI view hierarchies.
/// It focuses on common layouts and widgets that make sense for SwiftUI/WidgetKit.
///
/// Design approach:
/// - Widget instances (KvWidget) → SwiftUI View structs or view expressions
/// - KV properties → SwiftUI view modifiers
/// - Layout widgets → SwiftUI container views (VStack, HStack, ZStack)
/// - Child widgets → nested SwiftUI views
///
/// Limitations:
/// - Canvas instructions are not translated (SwiftUI uses different drawing model)
/// - Screen/WindowManager concepts skipped (not needed for widgets)
/// - Event handlers converted to simple Swift closures where possible
/// - Dynamic properties (self.*, root.*) require manual translation
public struct KvSwiftUIGenerator {
    
    /// Configuration for code generation
    public struct Config {
        /// Whether to generate complete View structs or just view expressions
        public var generateStructs: Bool = true
        
        /// Whether to include comments explaining translations
        public var includeComments: Bool = true
        
        /// Whether to generate @State properties for dynamic bindings
        public var generateStateProperties: Bool = true
        
        public init() {}
    }
    
    public let config: Config
    
    public init(config: Config = Config()) {
        self.config = config
    }
    
    /// Generate SwiftUI code from a KV module
    ///
    /// - Parameter module: Parsed KV module containing widgets and rules
    /// - Returns: Swift source code as string
    public func generate(from module: KvModule) -> String {
        var results: [String] = []
        
        // Add import statements
        results.append("import SwiftUI")
        results.append("")
        
        // Generate rules first (these become View structs)
        for rule in module.rules {
            results.append(generateViewStructFromRule(rule))
            results.append("")
        }
        
        // Generate code for root widget if present
        if let root = module.root {
            // Check if root is a built-in layout/container widget
            if config.generateStructs && !isBuiltInLayoutWidget(root) {
                results.append(generateViewStruct(for: root))
            } else {
                // For built-in layouts or when not generating structs,
                // just output the view expression directly
                results.append(generateViewExpression(for: root, indent: 0))
            }
        }
        
        return results.joined(separator: "\n")
    }
    
    /// Generate a View struct from a KV rule
    private func generateViewStructFromRule(_ rule: KvRule) -> String {
        let structName = rule.selector.primaryName
        
        var lines: [String] = []
        
        if config.includeComments {
            lines.append("// Generated from KV rule: <\(structName)>")
        }
        
        lines.append("struct \(structName): View {")
        
        // Generate @State properties if needed
        if config.generateStateProperties {
            var stateProps: [String] = []
            var usedNames = Set<String>()
            
            // Collect from rule's children
            for child in rule.children {
                collectStateProperties(from: child, into: &stateProps, usedNames: &usedNames)
            }
            
            if !stateProps.isEmpty {
                lines.append("")
                for prop in stateProps {
                    lines.append("    \(prop)")
                }
            }
        }
        
        lines.append("")
        lines.append("    var body: some View {")
        
        // Generate content - if there's only one child, use it directly
        // Otherwise wrap in a Group or the first child if it's a layout
        if rule.children.count == 1 {
            let childCode = generateViewExpression(for: rule.children[0], indent: 2)
            lines.append(childCode)
        } else if rule.children.isEmpty {
            lines.append("        EmptyView()")
        } else {
            // Multiple children - wrap in VStack
            lines.append("        VStack {")
            for child in rule.children {
                let childCode = generateViewExpression(for: child, indent: 3)
                lines.append(childCode)
            }
            lines.append("        }")
        }
        
        lines.append("    }")
        lines.append("}")
        
        return lines.joined(separator: "\n")
    }
    
    /// Check if widget is a built-in layout container that shouldn't be wrapped in a struct
    private func isBuiltInLayoutWidget(_ widget: KvWidget) -> Bool {
        switch widget.name {
        case "BoxLayout", "GridLayout", "FloatLayout", "RelativeLayout",
             "StackLayout", "ScrollView", "Widget":
            return true
        default:
            return false
        }
    }
    
    /// Generate a complete View struct for a widget
    private func generateViewStruct(for widget: KvWidget) -> String {
        let structName = widget.id?.capitalizingFirstLetter() ?? widget.name
        
        var lines: [String] = []
        
        if config.includeComments {
            lines.append("// Generated from KV widget: \(widget.name)")
        }
        
        lines.append("struct \(structName): View {")
        
        // Generate @State properties if needed
        if config.generateStateProperties {
            let stateProps = extractStateProperties(from: widget)
            if !stateProps.isEmpty {
                lines.append("")
                for prop in stateProps {
                    lines.append("    \(prop)")
                }
            }
        }
        
        lines.append("")
        lines.append("    var body: some View {")
        
        // Generate the view body
        let viewCode = generateViewExpression(for: widget, indent: 2)
        lines.append(viewCode)
        
        lines.append("    }")
        lines.append("}")
        
        return lines.joined(separator: "\n")
    }
    
    /// Generate SwiftUI view expression for a widget
    private func generateViewExpression(for widget: KvWidget, indent: Int) -> String {
        let indentStr = String(repeating: "    ", count: indent)
        
        // Map widget to SwiftUI view
        let swiftUIView = mapWidgetToSwiftUI(widget)
        
        // Check if this is a container view (needs children in closure)
        let isContainer = isContainerView(widget.name) && !widget.children.isEmpty
        
        var lines: [String] = []
        
        if isContainer {
            lines.append("\(indentStr)\(swiftUIView) {")
            
            // Generate children
            for child in widget.children {
                let childCode = generateViewExpression(for: child, indent: indent + 1)
                lines.append(childCode)
            }
            
            lines.append("\(indentStr)}")
        } else {
            // Simple view without children
            lines.append("\(indentStr)\(swiftUIView)")
        }
        
        // Apply modifiers from properties
        let modifiers = generateModifiers(from: widget.properties, indent: indent + 1)
        for modifier in modifiers {
            lines.append(modifier)
        }
        
        return lines.joined(separator: "\n")
    }
    
    /// Check if widget is a container that needs trailing closure for children
    private func isContainerView(_ widgetName: String) -> Bool {
        let containers = [
            "BoxLayout", "GridLayout", "FloatLayout", "RelativeLayout",
            "StackLayout", "ScrollView", "Widget", "AnchorLayout"
        ]
        return containers.contains(widgetName)
    }
    
    /// Map Kivy widget name to SwiftUI view
    private func mapWidgetToSwiftUI(_ widget: KvWidget) -> String {
        // Get text content if Label
        if widget.name == "Label" {
            let textValue = widget.properties.first(where: { $0.name == "text" })?.value ?? "\"Text\""
            return "Text(\(textValue))"
        }
        
        // Map layouts
        switch widget.name {
        case "BoxLayout":
            // Check orientation property
            let orientation = widget.properties.first(where: { $0.name == "orientation" })?.value ?? "'vertical'"
            if orientation.contains("horizontal") {
                return "HStack"
            } else {
                return "VStack"
            }
            
        case "GridLayout":
            // SwiftUI LazyVGrid or simple Grid
            return "LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))])"
            
        case "FloatLayout", "RelativeLayout":
            // ZStack with position modifiers
            return "ZStack(alignment: .topLeading)"
            
        case "StackLayout":
            return "VStack"
            
        case "ScrollView":
            return "ScrollView"
            
        case "Button":
            let textValue = widget.properties.first(where: { $0.name == "text" })?.value ?? "\"Button\""
            return "Button(\(textValue))"
            
        case "TextInput":
            let propName = widget.id.map { "\($0)_text" } ?? "text"
            return "TextField(\"Input\", text: $\(propName))"
            
        case "Image":
            let source = widget.properties.first(where: { $0.name == "source" })?.value ?? "\"image\""
            return "Image(\(source))"
            
        case "Slider":
            let propName = widget.id.map { "\($0)_value" } ?? "value"
            return "Slider(value: $\(propName))"
            
        case "Switch":
            let propName = widget.id.map { "\($0)_isOn" } ?? "isOn"
            return "Toggle(\"Switch\", isOn: $\(propName))"
            
        case "ProgressBar":
            return "ProgressView(value: progress)"
            
        case "Widget":
            // Generic container
            return "VStack"
            
        default:
            // Unknown widget - use VStack as fallback
            if config.includeComments {
                return "VStack /* Unknown widget: \(widget.name) */"
            }
            return "VStack"
        }
    }
    
    /// Generate SwiftUI modifiers from KV properties
    private func generateModifiers(from properties: [KvProperty], indent: Int) -> [String] {
        let indentStr = String(repeating: "    ", count: indent)
        var modifiers: [String] = []
        
        for prop in properties {
            // Skip properties already handled in view construction
            if ["text", "source", "orientation", "value", "isOn"].contains(prop.name) {
                continue
            }
            
            // Map property to SwiftUI modifier
            switch prop.name {
            case "size":
                // Parse size tuple: "100, 200" or "self.width, self.height"
                let sizeValue = prop.value.trimmingCharacters(in: .whitespaces)
                if sizeValue.contains(",") {
                    let parts = sizeValue.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
                    if parts.count == 2 {
                        modifiers.append("\(indentStr).frame(width: \(parts[0]), height: \(parts[1]))")
                    }
                }
                
            case "size_hint":
                // In SwiftUI, use flexible frames
                modifiers.append("\(indentStr).frame(maxWidth: .infinity, maxHeight: .infinity)")
                
            case "width":
                modifiers.append("\(indentStr).frame(width: \(prop.value))")
                
            case "height":
                modifiers.append("\(indentStr).frame(height: \(prop.value))")
                
            case "pos":
                // Position offset
                let posValue = prop.value.trimmingCharacters(in: .whitespaces)
                if posValue.contains(",") {
                    let parts = posValue.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
                    if parts.count == 2 {
                        modifiers.append("\(indentStr).offset(x: \(parts[0]), y: \(parts[1]))")
                    }
                }
                
            case "padding":
                modifiers.append("\(indentStr).padding(\(prop.value))")
                
            case "color", "foreground_color":
                // Convert color value to SwiftUI Color
                let colorValue = translateColor(prop.value)
                modifiers.append("\(indentStr).foregroundColor(\(colorValue))")
                
            case "background_color":
                let colorValue = translateColor(prop.value)
                modifiers.append("\(indentStr).background(\(colorValue))")
                
            case "font_size":
                modifiers.append("\(indentStr).font(.system(size: \(prop.value)))")
                
            case "opacity":
                modifiers.append("\(indentStr).opacity(\(prop.value))")
                
            case "disabled":
                modifiers.append("\(indentStr).disabled(\(prop.value))")
                
            case "halign":
                // Horizontal alignment
                if prop.value.contains("left") {
                    modifiers.append("\(indentStr).frame(maxWidth: .infinity, alignment: .leading)")
                } else if prop.value.contains("right") {
                    modifiers.append("\(indentStr).frame(maxWidth: .infinity, alignment: .trailing)")
                } else if prop.value.contains("center") {
                    modifiers.append("\(indentStr).frame(maxWidth: .infinity, alignment: .center)")
                }
                
            case "valign":
                // Vertical alignment
                if prop.value.contains("top") {
                    modifiers.append("\(indentStr).frame(maxHeight: .infinity, alignment: .top)")
                } else if prop.value.contains("bottom") {
                    modifiers.append("\(indentStr).frame(maxHeight: .infinity, alignment: .bottom)")
                } else if prop.value.contains("middle") || prop.value.contains("center") {
                    modifiers.append("\(indentStr).frame(maxHeight: .infinity, alignment: .center)")
                }
                
            default:
                // Unknown property - add as comment if enabled
                if config.includeComments && !prop.name.hasPrefix("id") {
                    modifiers.append("\(indentStr)// TODO: \(prop.name): \(prop.value)")
                }
            }
        }
        
        return modifiers
    }
    
    /// Translate KV color format to SwiftUI Color
    private func translateColor(_ colorValue: String) -> String {
        let value = colorValue.trimmingCharacters(in: .whitespaces)
        
        // Handle common color formats
        if value.hasPrefix("[") && value.hasSuffix("]") {
            // RGBA array: [1, 0, 0, 1] → Color(red: 1, green: 0, blue: 0, opacity: 1)
            let components = value
                .trimmingCharacters(in: CharacterSet(charactersIn: "[]"))
                .split(separator: ",")
                .map { $0.trimmingCharacters(in: .whitespaces) }
            
            if components.count >= 3 {
                let r = components[0]
                let g = components[1]
                let b = components[2]
                let a = components.count >= 4 ? components[3] : "1"
                return "Color(red: \(r), green: \(g), blue: \(b), opacity: \(a))"
            }
        }
        
        // Named colors
        switch value.lowercased().replacingOccurrences(of: "'", with: "").replacingOccurrences(of: "\"", with: "") {
        case "red": return ".red"
        case "blue": return ".blue"
        case "green": return ".green"
        case "yellow": return ".yellow"
        case "orange": return ".orange"
        case "purple": return ".purple"
        case "pink": return ".pink"
        case "white": return ".white"
        case "black": return ".black"
        case "gray", "grey": return ".gray"
        case "clear": return ".clear"
        default: return ".primary"
        }
    }
    
    /// Extract @State properties needed for dynamic bindings
    private func extractStateProperties(from widget: KvWidget) -> [String] {
        var stateProps: [String] = []
        var usedNames = Set<String>()
        
        // Recursively collect state properties from widget tree
        collectStateProperties(from: widget, into: &stateProps, usedNames: &usedNames)
        
        return stateProps
    }
    
    /// Recursively collect state properties from widget and its children
    private func collectStateProperties(from widget: KvWidget, into stateProps: inout [String], usedNames: inout Set<String>) {
        // Generate state property name based on widget id if available
        let propertyPrefix = widget.id.map { "\($0)_" } ?? ""
        
        // Check if we need text binding
        if widget.name == "TextInput" {
            let propName = "\(propertyPrefix)text"
            if !usedNames.contains(propName) {
                stateProps.append("@State private var \(propName): String = \"\"")
                usedNames.insert(propName)
            }
        }
        
        // Check if we need value binding
        if widget.name == "Slider" {
            let propName = "\(propertyPrefix)value"
            if !usedNames.contains(propName) {
                stateProps.append("@State private var \(propName): Double = 0.5")
                usedNames.insert(propName)
            }
        }
        
        // Check if we need toggle binding
        if widget.name == "Switch" {
            let propName = "\(propertyPrefix)isOn"
            if !usedNames.contains(propName) {
                stateProps.append("@State private var \(propName): Bool = false")
                usedNames.insert(propName)
            }
        }
        
        // Check for dynamic size properties
        if !usedNames.contains("dynamicWidth") {
            let hasDynamicSize = widget.properties.contains { prop in
                prop.value.contains("self.") || prop.value.contains("root.")
            }
            
            if hasDynamicSize {
                stateProps.append("@State private var dynamicWidth: CGFloat = 100")
                stateProps.append("@State private var dynamicHeight: CGFloat = 100")
                usedNames.insert("dynamicWidth")
                usedNames.insert("dynamicHeight")
            }
        }
        
        // Recurse into children
        for child in widget.children {
            collectStateProperties(from: child, into: &stateProps, usedNames: &usedNames)
        }
    }
}

// MARK: - Helper Extensions

private extension String {
    /// Capitalize first letter
    func capitalizingFirstLetter() -> String {
        guard let first = first else { return self }
        return first.uppercased() + dropFirst()
    }
}
