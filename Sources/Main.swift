import JavaScriptKit

// MARK: - Main Application

@main
struct PySwiftKitDemoApp {
    static func main() {
        print("PySwiftKit Demo - Starting")
        // Setup editors immediately
        setupEditors()
    }
    
    static func setupEditors() {
        print("Setting up editors...")
        
        // Default Swift code with PySwiftKit decorators
        let defaultSwiftCode = """
import PySwiftKit

@PyClass
class Person {
    // Regular var → getter + setter
    @PyProperty
    var name: String
    
    // let constant → getter only
    @PyProperty
    let id: Int
    
    // Computed property (get only) → getter only
    @PyProperty
    var fullName: String {
        get {
            return name
        }
    }
    
    @PyInit
    init(name: String, id: Int) {
        self.name = name
        self.id = id
    }
    
    @PyMethod
    func greet() -> String {
        return "Hello, I'm \\(name)"
    }
    
    @PyMethod
    static func create(name: String) -> Person {
        return Person(name: name, id: 0)
    }
}
"""
        
        // Create left editor (Swift with PySwiftKit decorators)
        guard let leftEditor = MonacoEditor.create(
            containerId: "swift-editor",
            value: defaultSwiftCode,
            language: "swift"
        ) else {
            return
        }
        
        // Create right editor (Generated Python API)
        guard let rightEditor = MonacoEditor.create(
            containerId: "python-editor",
            value: "# Generated Python API will appear here...",
            language: "python",
            readOnly: true
        ) else {
            print("Failed to create right editor")
            return
        }
        
        print("Both editors created")
        
        // Setup completion providers for PySwiftKit decorators
        CompletionProvider.setupCompletionProviders(swiftEditor: leftEditor)
        
        // Set up text change callback
        leftEditor.onDidChangeContent { newContent in
            print("Content changed")
            
            // Stage 1: Simple stub generation
            let pythonOutput = generatePythonStub(from: newContent)
            rightEditor.setValue(pythonOutput)
        }
        
        // Generate initial Python output
        let initialPython = generatePythonStub(from: defaultSwiftCode)
        rightEditor.setValue(initialPython)
        
        print("Setup complete!")
    }
    
    /// Stage 2: Parse Swift code and generate Python using PySwiftAST + SwiftSyntax
    static func generatePythonStub(from swiftCode: String) -> String {
        return SwiftToPythonGenerator.generatePythonStub(from: swiftCode)
    }
    
}
