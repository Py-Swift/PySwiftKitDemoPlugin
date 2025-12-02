import JavaScriptKit

/// Swift standard library and keyword completions
enum SwiftCompletions {
    
    // Cache completions as static constants for performance
    // nonisolated(unsafe) is safe here because WASM is single-threaded and values are immutable after initialization
    private nonisolated(unsafe) static let stdlibCompletions: [JSObject] = createStdlibCompletionsOnce()
    private nonisolated(unsafe) static let keywordCompletions: [JSObject] = createKeywordCompletionsOnce()
    
    /// Get cached Swift standard library type completions
    static func createStdlibCompletions() -> [JSObject] {
        return stdlibCompletions
    }
    
    /// Get cached Swift keyword completions
    static func createKeywordCompletions() -> [JSObject] {
        return keywordCompletions
    }
    
    /// Create completion items for Swift standard library types (called once)
    private static func createStdlibCompletionsOnce() -> [JSObject] {
        var completions: [JSObject] = []
        
        // Basic types
        completions.append(createCompletion(
            label: "String",
            insertText: "String",
            documentation: "A Unicode string value that is a collection of characters",
            detail: "Swift Standard Library",
            kind: "Class"
        ))
        
        completions.append(createCompletion(
            label: "Int",
            insertText: "Int",
            documentation: "A signed integer value type",
            detail: "Swift Standard Library",
            kind: "Struct"
        ))
        
        completions.append(createCompletion(
            label: "Double",
            insertText: "Double",
            documentation: "A double-precision, floating-point value type",
            detail: "Swift Standard Library",
            kind: "Struct"
        ))
        
        completions.append(createCompletion(
            label: "Float",
            insertText: "Float",
            documentation: "A single-precision, floating-point value type",
            detail: "Swift Standard Library",
            kind: "Struct"
        ))
        
        completions.append(createCompletion(
            label: "Bool",
            insertText: "Bool",
            documentation: "A value type whose instances are either true or false",
            detail: "Swift Standard Library",
            kind: "Struct"
        ))
        
        completions.append(createCompletion(
            label: "Character",
            insertText: "Character",
            documentation: "A single extended grapheme cluster that approximates a user-perceived character",
            detail: "Swift Standard Library",
            kind: "Struct"
        ))
        
        // Collection types
        completions.append(createCompletion(
            label: "Array",
            insertText: "Array",
            documentation: "An ordered, random-access collection",
            detail: "Swift Standard Library",
            kind: "Struct"
        ))
        
        completions.append(createCompletion(
            label: "Dictionary",
            insertText: "Dictionary",
            documentation: "A collection whose elements are key-value pairs",
            detail: "Swift Standard Library",
            kind: "Struct"
        ))
        
        completions.append(createCompletion(
            label: "Set",
            insertText: "Set",
            documentation: "An unordered collection of unique elements",
            detail: "Swift Standard Library",
            kind: "Struct"
        ))
        
        // Optional
        completions.append(createCompletion(
            label: "Optional",
            insertText: "Optional",
            documentation: "A type that represents either a wrapped value or nil, the absence of a value",
            detail: "Swift Standard Library",
            kind: "Enum"
        ))
        
        // Result
        completions.append(createCompletion(
            label: "Result",
            insertText: "Result",
            documentation: "A value that represents either a success or a failure, including an associated value in each case",
            detail: "Swift Standard Library",
            kind: "Enum"
        ))
        
        // Ranges
        completions.append(createCompletion(
            label: "Range",
            insertText: "Range",
            documentation: "A half-open interval from a lower bound up to, but not including, an upper bound",
            detail: "Swift Standard Library",
            kind: "Struct"
        ))
        
        completions.append(createCompletion(
            label: "ClosedRange",
            insertText: "ClosedRange",
            documentation: "An interval from a lower bound up to, and including, an upper bound",
            detail: "Swift Standard Library",
            kind: "Struct"
        ))
        
        return completions
    }
    
    /// Create completion items for Swift keywords (called once)
    private static func createKeywordCompletionsOnce() -> [JSObject] {
        var completions: [JSObject] = []
        
        // Declaration keywords
        completions.append(createCompletion(
            label: "func",
            insertText: "func ",
            documentation: "Declares a function",
            detail: "Swift Keyword",
            kind: "Keyword"
        ))
        
        completions.append(createCompletion(
            label: "var",
            insertText: "var ",
            documentation: "Declares a variable",
            detail: "Swift Keyword",
            kind: "Keyword"
        ))
        
        completions.append(createCompletion(
            label: "let",
            insertText: "let ",
            documentation: "Declares a constant",
            detail: "Swift Keyword",
            kind: "Keyword"
        ))
        
        completions.append(createCompletion(
            label: "class",
            insertText: "class ",
            documentation: "Declares a class",
            detail: "Swift Keyword",
            kind: "Keyword"
        ))
        
        completions.append(createCompletion(
            label: "struct",
            insertText: "struct ",
            documentation: "Declares a structure",
            detail: "Swift Keyword",
            kind: "Keyword"
        ))
        
        completions.append(createCompletion(
            label: "enum",
            insertText: "enum ",
            documentation: "Declares an enumeration",
            detail: "Swift Keyword",
            kind: "Keyword"
        ))
        
        completions.append(createCompletion(
            label: "protocol",
            insertText: "protocol ",
            documentation: "Declares a protocol",
            detail: "Swift Keyword",
            kind: "Keyword"
        ))
        
        completions.append(createCompletion(
            label: "extension",
            insertText: "extension ",
            documentation: "Extends an existing type",
            detail: "Swift Keyword",
            kind: "Keyword"
        ))
        
        completions.append(createCompletion(
            label: "typealias",
            insertText: "typealias ",
            documentation: "Declares a type alias",
            detail: "Swift Keyword",
            kind: "Keyword"
        ))
        
        completions.append(createCompletion(
            label: "import",
            insertText: "import ",
            documentation: "Imports a module",
            detail: "Swift Keyword",
            kind: "Keyword"
        ))
        
        // Control flow keywords
        completions.append(createCompletion(
            label: "if",
            insertText: "if ",
            documentation: "Conditional statement",
            detail: "Swift Keyword",
            kind: "Keyword"
        ))
        
        completions.append(createCompletion(
            label: "else",
            insertText: "else ",
            documentation: "Alternative branch of conditional",
            detail: "Swift Keyword",
            kind: "Keyword"
        ))
        
        completions.append(createCompletion(
            label: "guard",
            insertText: "guard ",
            documentation: "Early exit statement",
            detail: "Swift Keyword",
            kind: "Keyword"
        ))
        
        completions.append(createCompletion(
            label: "switch",
            insertText: "switch ",
            documentation: "Switch statement",
            detail: "Swift Keyword",
            kind: "Keyword"
        ))
        
        completions.append(createCompletion(
            label: "case",
            insertText: "case ",
            documentation: "Case in switch or enum",
            detail: "Swift Keyword",
            kind: "Keyword"
        ))
        
        completions.append(createCompletion(
            label: "default",
            insertText: "default",
            documentation: "Default case in switch",
            detail: "Swift Keyword",
            kind: "Keyword"
        ))
        
        completions.append(createCompletion(
            label: "for",
            insertText: "for ",
            documentation: "For-in loop",
            detail: "Swift Keyword",
            kind: "Keyword"
        ))
        
        completions.append(createCompletion(
            label: "while",
            insertText: "while ",
            documentation: "While loop",
            detail: "Swift Keyword",
            kind: "Keyword"
        ))
        
        completions.append(createCompletion(
            label: "repeat",
            insertText: "repeat ",
            documentation: "Repeat-while loop",
            detail: "Swift Keyword",
            kind: "Keyword"
        ))
        
        completions.append(createCompletion(
            label: "return",
            insertText: "return ",
            documentation: "Returns from function",
            detail: "Swift Keyword",
            kind: "Keyword"
        ))
        
        completions.append(createCompletion(
            label: "break",
            insertText: "break",
            documentation: "Breaks out of loop or switch",
            detail: "Swift Keyword",
            kind: "Keyword"
        ))
        
        completions.append(createCompletion(
            label: "continue",
            insertText: "continue",
            documentation: "Continues to next iteration",
            detail: "Swift Keyword",
            kind: "Keyword"
        ))
        
        // Modifiers
        completions.append(createCompletion(
            label: "public",
            insertText: "public ",
            documentation: "Public access level",
            detail: "Swift Keyword",
            kind: "Keyword"
        ))
        
        completions.append(createCompletion(
            label: "private",
            insertText: "private ",
            documentation: "Private access level",
            detail: "Swift Keyword",
            kind: "Keyword"
        ))
        
        completions.append(createCompletion(
            label: "internal",
            insertText: "internal ",
            documentation: "Internal access level (default)",
            detail: "Swift Keyword",
            kind: "Keyword"
        ))
        
        completions.append(createCompletion(
            label: "fileprivate",
            insertText: "fileprivate ",
            documentation: "File-private access level",
            detail: "Swift Keyword",
            kind: "Keyword"
        ))
        
        completions.append(createCompletion(
            label: "static",
            insertText: "static ",
            documentation: "Declares a type-level property or method",
            detail: "Swift Keyword",
            kind: "Keyword"
        ))
        
        completions.append(createCompletion(
            label: "final",
            insertText: "final ",
            documentation: "Prevents overriding",
            detail: "Swift Keyword",
            kind: "Keyword"
        ))
        
        completions.append(createCompletion(
            label: "override",
            insertText: "override ",
            documentation: "Overrides superclass member",
            detail: "Swift Keyword",
            kind: "Keyword"
        ))
        
        completions.append(createCompletion(
            label: "mutating",
            insertText: "mutating ",
            documentation: "Marks method as mutating (for value types)",
            detail: "Swift Keyword",
            kind: "Keyword"
        ))
        
        // Special keywords
        completions.append(createCompletion(
            label: "init",
            insertText: "init",
            documentation: "Initializer",
            detail: "Swift Keyword",
            kind: "Keyword"
        ))
        
        completions.append(createCompletion(
            label: "deinit",
            insertText: "deinit",
            documentation: "Deinitializer",
            detail: "Swift Keyword",
            kind: "Keyword"
        ))
        
        completions.append(createCompletion(
            label: "self",
            insertText: "self",
            documentation: "Current instance",
            detail: "Swift Keyword",
            kind: "Keyword"
        ))
        
        completions.append(createCompletion(
            label: "Self",
            insertText: "Self",
            documentation: "Current type",
            detail: "Swift Keyword",
            kind: "Keyword"
        ))
        
        completions.append(createCompletion(
            label: "nil",
            insertText: "nil",
            documentation: "Absence of a value",
            detail: "Swift Keyword",
            kind: "Keyword"
        ))
        
        completions.append(createCompletion(
            label: "true",
            insertText: "true",
            documentation: "Boolean true value",
            detail: "Swift Keyword",
            kind: "Keyword"
        ))
        
        completions.append(createCompletion(
            label: "false",
            insertText: "false",
            documentation: "Boolean false value",
            detail: "Swift Keyword",
            kind: "Keyword"
        ))
        
        return completions
    }
    
    /// Create a single completion item
    private static func createCompletion(
        label: String,
        insertText: String,
        documentation: String,
        detail: String,
        kind: String
    ) -> JSObject {
        let completion = JSObject()
        completion.label = .string(label)
        completion.insertText = .string(insertText)
        completion.documentation = .string(documentation)
        completion.detail = .string(detail)
        completion.kind = .string(kind)
        return completion
    }
}
