import JavaScriptKit
import PythonToSwiftLib
import SwiftToPythonLib

// MARK: - Main Application

@main
struct PySwiftKitDemoApp {
    static func main() {
        // Setup editors immediately
        setupEditors()
    }
    
    static func setupEditors() {
        // Setup Swift → Python editors
        setupSwiftToPythonEditors()
        
        // Temporarily disable Python → Swift editors
        setupPythonToSwiftEditors()
    }
    
    static func setupSwiftToPythonEditors() {
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
            return
        }
        
        // Setup completion providers for PySwiftKit decorators
        CompletionProvider.setupCompletionProviders(swiftEditor: leftEditor)
        
        // Set up text change callback
        leftEditor.onDidChangeContent { newContent in
            let pythonOutput = generatePythonStub(from: newContent)
            rightEditor.setValue(pythonOutput)
        }
        
        // Generate initial Python output
        let initialPython = generatePythonStub(from: defaultSwiftCode)
        rightEditor.setValue(initialPython)
    }
    
    static func setupPythonToSwiftEditors() {
        // Default Python code
        let defaultPythonCode = """
class Person:

    name: str
    age: int

    def __init__(self, name: str, age: int):
        pass

    def greet(self, text: str):
        pass

    def interests(self) -> list[str]:
        pass


class House:

    peoples: [Person]
    
"""
        
        // Create Python input editor
        guard let pythonInputEditor = MonacoEditor.create(
            containerId: "python-input-editor",
            value: defaultPythonCode,
            language: "python"
        ) else {
            return
        }
        
        // Create Swift output editor
        guard let swiftOutputEditor = MonacoEditor.create(
            containerId: "swift-output-editor",
            value: "// Generated Swift PySwiftKit code will appear here...",
            language: "swift",
            readOnly: true
        ) else {
            return
        }
        
        // Set up text change callback
        pythonInputEditor.onDidChangeContent { newContent in
            let swiftOutput = generateSwiftCode(from: newContent)
            swiftOutputEditor.setValue(swiftOutput)
        }
        
        // Generate initial Swift output
        let initialSwift = generateSwiftCode(from: defaultPythonCode)
        swiftOutputEditor.setValue(initialSwift)
    }
    
    /// Stage 2: Parse Swift code and generate Python using PySwiftAST + SwiftSyntax
    static func generatePythonStub(from swiftCode: String) -> String {
        return SwiftToPythonGenerator.generatePythonStub(from: swiftCode)
    }
    
    // /// Generate Swift PySwiftKit code from Python
    static func generateSwiftCode(from pythonCode: String) -> String {
        return PythonToSwiftGenerator.generateSwiftCode(from: pythonCode, customFormatting: true)
    }
    
}
