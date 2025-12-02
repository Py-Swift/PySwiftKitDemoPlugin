import JavaScriptKit

/// Monaco Editor completion provider for PySwiftKit decorators
enum CompletionProvider {
    
    // Store editor reference (nonisolated for WASM single-threaded environment)
    private nonisolated(unsafe) static var swiftEditorRef: MonacoEditor?
    
    /// Setup all completion providers for PySwiftKit decorators
    static func setupCompletionProviders(swiftEditor: MonacoEditor) {
        // Store editor reference
        swiftEditorRef = swiftEditor
        
        guard let monaco = JSObject.global.monaco.object else {
            return
        }
        
        guard let languages = monaco.languages.object else {
            return
        }
        
        // Register completion provider for Swift language
        let completionProvider = JSClosure { args -> JSValue in
            // Monaco completion provider signature: (model, position, context, token)
            guard args.count >= 2 else {
                return .null
            }
            
            // We don't use the model from args because it gets disposed
            // Instead, use our stored editor reference
            guard let editor = swiftEditorRef else {
                return .null
            }
            
            let position = args[1]
            
            let lineNumber = position.lineNumber.number ?? 1
            let column = position.column.number ?? 1
            print("Line number: \(lineNumber), Column: \(column)")
            
            // Get text from our editor instance
            let fullText = editor.getValue()
            let lines = fullText.split(separator: "\n", omittingEmptySubsequences: false)
            
            guard lineNumber > 0 && Int(lineNumber) <= lines.count else {
                return .null
            }
            
            let lineContent = String(lines[Int(lineNumber) - 1])
            
            return providePySwiftKitCompletions(
                lineContent: lineContent,
                column: Int(column),
                lineNumber: Int(lineNumber)
            )
        }
        
        // Create provider object with trigger characters
        let providerObj = JSObject()
        providerObj.provideCompletionItems = completionProvider.jsValue
        
        // Set trigger characters: '@' for macros, ':' for type annotations, '.' for member access
        providerObj.triggerCharacters = JSObject.global.Array.function!(["@", ":", "."])
        
        // Register the provider
        _ = languages.registerCompletionItemProvider!("swift", providerObj)
    }
    
    /// Provide completion items based on context
    private static func providePySwiftKitCompletions(lineContent: String, column: Int, lineNumber: Int = 1) -> JSValue {
        var suggestions: [JSObject] = []
        
        // Check if user is typing '@' or after '@'
        let beforeCursor = String(lineContent.prefix(max(0, column - 1)))
        let trimmed = beforeCursor.trimmingCharacters(in: .whitespaces)
        
        // Show completions if typing after '@'
        // Check if the trimmed line contains '@' followed by any letters (or just '@')
        let hasAtSymbol = trimmed.contains("@")
        let afterAt = trimmed.components(separatedBy: "@").last ?? ""
        let afterAtLower = afterAt.lowercased()
        let isPySwiftKitPrefix = afterAt.isEmpty || "pyclass".hasPrefix(afterAtLower) || "pymethod".hasPrefix(afterAtLower) || 
                                  "pyproperty".hasPrefix(afterAtLower) || "pyinit".hasPrefix(afterAtLower) || 
                                  "pymodule".hasPrefix(afterAtLower) || "pyfunction".hasPrefix(afterAtLower)
        
        // Determine completion context
        if hasAtSymbol && isPySwiftKitPrefix {
            // Show PySwiftKit macro completions
            suggestions.append(contentsOf: createPySwiftKitCompletions())
        } else {
            // Always provide general Swift completions (types, keywords)
            suggestions.append(contentsOf: SwiftCompletions.createStdlibCompletions())
            suggestions.append(contentsOf: SwiftCompletions.createKeywordCompletions())
        }
        
        // Create suggestions object for Monaco
        guard let monaco = JSObject.global.monaco.object else {
            return .null
        }
        
        guard let completionItemKind = monaco.languages.object?.CompletionItemKind.object else {
            return .null
        }
        
        // Convert suggestions to Monaco format - create plain JavaScript objects
        let jsArray = JSObject.global.Array.function!()
        
        // Find where '@' starts in the line for proper range replacement (only for PySwiftKit macros)
        let atIndex = beforeCursor.lastIndex(of: "@") ?? beforeCursor.startIndex
        let atColumn = beforeCursor.distance(from: beforeCursor.startIndex, to: atIndex) + 1
        let shouldUseRange = hasAtSymbol && isPySwiftKitPrefix
        
        for (index, suggestion) in suggestions.enumerated() {
            // Extract string values
            let labelStr = suggestion.label.string ?? ""
            let insertTextStr = suggestion.insertText.string ?? labelStr
            let docStr = suggestion.documentation.string ?? ""
            let detailStr = suggestion.detail.string ?? ""
            
            // Create Monaco CompletionItem using object literal notation
            let item = JSObject()
            
            // Set properties directly as native JavaScript values
            item.label = .string(labelStr)
            item.insertText = .string(insertTextStr)
            item.kind = .number(14)
            item.detail = .string(detailStr)
            item.documentation = .string(docStr)
            
            // Only set range for PySwiftKit macros to replace the @ symbol
            if shouldUseRange {
                let rangeObj = JSObject()
                rangeObj.startLineNumber = .number(Double(lineNumber))
                rangeObj.startColumn = .number(Double(atColumn))
                rangeObj.endLineNumber = .number(Double(lineNumber))
                rangeObj.endColumn = .number(Double(column))
                
                item.range = rangeObj.jsValue
            }
            
            // Push to array
            _ = jsArray.push(item)
        }
        
        // Return result object with suggestions array
        let result = JSObject()
        result.suggestions = jsArray
        
        return result.jsValue
    }
    
    /// Create completion items for all PySwiftKit decorators
    private static func createPySwiftKitCompletions() -> [JSObject] {
        var completions: [JSObject] = []
        
        // @PyClass - Swift Macro
        completions.append(createCompletion(
            label: "@PyClass",
            insertText: "@PyClass",
            documentation: "Swift macro: Marks a class to be exposed to Python",
            detail: "PySwiftKit Macro",
            kind: "Keyword"
        ))
        
        // @PyMethod - Swift Macro
        completions.append(createCompletion(
            label: "@PyMethod",
            insertText: "@PyMethod",
            documentation: "Swift macro: Marks a method to be exposed to Python",
            detail: "PySwiftKit Macro",
            kind: "Keyword"
        ))
        
        // @PyProperty - Swift Macro
        completions.append(createCompletion(
            label: "@PyProperty",
            insertText: "@PyProperty",
            documentation: "Swift macro: Marks a property to be exposed to Python with getter/setter",
            detail: "PySwiftKit Macro",
            kind: "Keyword"
        ))
        
        // @PyInit - Swift Macro
        completions.append(createCompletion(
            label: "@PyInit",
            insertText: "@PyInit",
            documentation: "Swift macro: Marks an initializer to be exposed as Python __init__",
            detail: "PySwiftKit Macro",
            kind: "Keyword"
        ))
        
        // @PyModule - Swift Macro
        completions.append(createCompletion(
            label: "@PyModule",
            insertText: "@PyModule",
            documentation: "Swift macro: Marks a module-level declaration to be exposed to Python",
            detail: "PySwiftKit Macro",
            kind: "Keyword"
        ))
        
        // @PyFunction - Swift Macro
        completions.append(createCompletion(
            label: "@PyFunction",
            insertText: "@PyFunction",
            documentation: "Swift macro: Marks a module-level function to be exposed to Python",
            detail: "PySwiftKit Macro",
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
