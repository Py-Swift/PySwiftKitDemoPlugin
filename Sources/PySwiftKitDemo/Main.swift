import JavaScriptKit
import PythonToSwiftLib
import SwiftToPythonLib
import PyDataModels

// MARK: - Main Application

@main
struct PySwiftKitDemoApp {
    // Shared editor instances
    nonisolated(unsafe) static var leftEditor: MonacoEditor?
    nonisolated(unsafe) static var middleEditor: MonacoEditor?
    nonisolated(unsafe) static var rightEditor: MonacoEditor?
    
    // Models for different tabs
    nonisolated(unsafe) static var swiftToPythonModels: (input: MonacoModel, output: MonacoModel)?
    nonisolated(unsafe) static var pythonToSwiftModels: (input: MonacoModel, output: MonacoModel)?
    nonisolated(unsafe) static var pythonDataModelModels: (input: MonacoModel, output: MonacoModel)?
    
    static func main() {
        // Setup editors and models immediately
        setupEditors()
    }
    
    static func setupEditors() {
        // Create editor instances
        leftEditor = MonacoEditor.create(containerId: "editor-left", readOnly: false)
        middleEditor = MonacoEditor.create(containerId: "editor-middle", readOnly: false)
        rightEditor = MonacoEditor.create(containerId: "editor-right", readOnly: true)
        
        guard leftEditor != nil, middleEditor != nil, rightEditor != nil else {
            return
        }
        
        // Create models for all tabs
        setupSwiftToPythonModels()
        setupPythonToSwiftModels()
        setupPythonDataModelModels()
        
        // Set initial tab (Swift → Python)
        switchToTab(tab: "swift-to-python")
        
        // Setup tab switching
        setupTabSwitching()
    }
    
    static func setupTabSwitching() {
        let document = JSObject.global.document
        
        // Tab 1: Swift → Python
        if let tab1 = document.getElementById("tab-swift-to-python").object {
            let closure1 = JSClosure { _ in
                switchToTab(tab: "swift-to-python")
                return .undefined
            }
            _ = tab1.addEventListener!("click", closure1)
        }
        
        // Tab 2: Python → Swift
        if let tab2 = document.getElementById("tab-python-to-swift").object {
            let closure2 = JSClosure { _ in
                switchToTab(tab: "python-to-swift")
                return .undefined
            }
            _ = tab2.addEventListener!("click", closure2)
        }
        
        // Tab 3: Python → Swift Container
        if let tab3 = document.getElementById("tab-python-datamodel").object {
            let closure3 = JSClosure { _ in
                switchToTab(tab: "python-datamodel")
                return .undefined
            }
            _ = tab3.addEventListener!("click", closure3)
        }
    }
    
    static func switchToTab(tab: String) {
        guard let leftEditor = leftEditor, let rightEditor = rightEditor else {
            return
        }
        
        let document = JSObject.global.document
        
        // Update active tab styling
        if let tabs = document.querySelectorAll(".tab").object {
            let length = Int(tabs.length.number ?? 0)
            for i in 0..<length {
                if let tabElement = tabs[i].object {
                    _ = tabElement.classList.remove("active")
                }
            }
        }
        
        // Hide middle panel by default
        if let middlePanel = document.getElementById("panel-middle").object {
            _ = middlePanel.classList.add("hidden")
        }
        
        // Remove three-column class
        if let container = document.getElementById("editor-container").object {
            _ = container.classList.remove("three-column")
        }
        
        switch tab {
        case "swift-to-python":
            if let models = swiftToPythonModels {
                leftEditor.setModel(models.input)
                rightEditor.setModel(models.output)
                leftEditor.updateOptions(readOnly: false)
                
                // Update panel headers
                if let leftHeader = document.getElementById("panel-left-header").object {
                    leftHeader.textContent = "Swift Code (with PySwiftKit decorators)"
                }
                if let rightHeader = document.getElementById("panel-right-header").object {
                    rightHeader.textContent = "Generated Python API (Read-only)"
                }
                
                // Update active tab
                if let tabElement = document.getElementById("tab-swift-to-python").object {
                    _ = tabElement.classList.add("active")
                }
            }
            
        case "python-to-swift":
            if let models = pythonToSwiftModels {
                leftEditor.setModel(models.input)
                rightEditor.setModel(models.output)
                leftEditor.updateOptions(readOnly: false)
                
                // Update panel headers
                if let leftHeader = document.getElementById("panel-left-header").object {
                    leftHeader.textContent = "Python Code"
                }
                if let rightHeader = document.getElementById("panel-right-header").object {
                    rightHeader.textContent = "Generated Swift PySwiftKit Code (Read-only)"
                }
                
                // Update active tab
                if let tabElement = document.getElementById("tab-python-to-swift").object {
                    _ = tabElement.classList.add("active")
                }
            }
            
        case "python-datamodel":
            if let models = pythonDataModelModels {
                leftEditor.setModel(models.input)
                rightEditor.setModel(models.output)
                leftEditor.updateOptions(readOnly: false)
                
                // Update panel headers
                if let leftHeader = document.getElementById("panel-left-header").object {
                    leftHeader.textContent = "Python Data Model"
                }
                if let rightHeader = document.getElementById("panel-right-header").object {
                    rightHeader.textContent = "Generated Swift Container (Read-only)"
                }
                
                // Update active tab
                if let tabElement = document.getElementById("tab-python-datamodel").object {
                    _ = tabElement.classList.add("active")
                }
            }
            
        default:
            break
        }
        
        // Trigger layout update
        let monaco = JSObject.global.monaco
        if let monacoObj = monaco.object,
           let editor = monacoObj.editor.object {
            let editors = editor.getEditors!()
            if let editorsArray = editors.object {
                let length = Int(editorsArray.length.number ?? 0)
                for i in 0..<length {
                    if let editorInstance = editorsArray[i].object {
                        _ = editorInstance.layout!()
                    }
                }
            }
        }
    }
    
    static func setupSwiftToPythonModels() {
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
        
        // Create models
        guard let inputModel = MonacoModel.create(value: defaultSwiftCode, language: "swift"),
              let outputModel = MonacoModel.create(value: "# Generated Python API will appear here...", language: "python") else {
            return
        }
        
        // Setup change handler on input model
        inputModel.onDidChangeContent { newContent in
            let pythonOutput = generatePythonStub(from: newContent)
            outputModel.setValue(pythonOutput)
        }
        
        // Generate initial output
        let initialPython = generatePythonStub(from: defaultSwiftCode)
        outputModel.setValue(initialPython)
        
        swiftToPythonModels = (inputModel, outputModel)
        
        // Setup completion providers for first model
        if let leftEditor = leftEditor {
            CompletionProvider.setupCompletionProviders(swiftEditor: leftEditor)
        }
    }
    
    static func setupPythonToSwiftModels() {
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

    peoples: list[Person]
    
"""
        
        // Create models
        guard let inputModel = MonacoModel.create(value: defaultPythonCode, language: "python"),
              let outputModel = MonacoModel.create(value: "// Generated Swift PySwiftKit code will appear here...", language: "swift") else {
            return
        }
        
        // Setup change handler on input model
        inputModel.onDidChangeContent { newContent in
            let swiftOutput = generateSwiftCode(from: newContent)
            outputModel.setValue(swiftOutput)
        }
        
        // Generate initial output
        let initialSwift = generateSwiftCode(from: defaultPythonCode)
        outputModel.setValue(initialSwift)
        
        pythonToSwiftModels = (inputModel, outputModel)
    }
    
    static func setupPythonDataModelModels() {
        // Default Python data model code
        let defaultPythonCode = """
class PyDataModel:

    name: str
    age: int

    def __init__(self, name, age):
        pass

    def greet(self, text: str):
        pass

    def interests(self) -> list[str]:
        pass
"""
        
        // Create models
        guard let inputModel = MonacoModel.create(value: defaultPythonCode, language: "python"),
              let outputModel = MonacoModel.create(value: "// Generated Swift Container code will appear here...", language: "swift") else {
            return
        }
        
        // Setup change handler on input model
        inputModel.onDidChangeContent { newContent in
            let swiftOutput = generateSwiftContainer(from: newContent)
            outputModel.setValue(swiftOutput)
        }
        
        // Generate initial output
        let initialSwift = generateSwiftContainer(from: defaultPythonCode)
        outputModel.setValue(initialSwift)
        
        pythonDataModelModels = (inputModel, outputModel)
    }
    
    /// Stage 2: Parse Swift code and generate Python using PySwiftAST + SwiftSyntax
    static func generatePythonStub(from swiftCode: String) -> String {
        return SwiftToPythonGenerator.generatePythonStub(from: swiftCode)
    }
    
    // /// Generate Swift PySwiftKit code from Python
    static func generateSwiftCode(from pythonCode: String) -> String {
        return PythonToSwiftGenerator.generateSwiftCode(from: pythonCode, customFormatting: true)
    }
    
    /// Generate Swift Container code from Python using @PyContainer pattern
    static func generateSwiftContainer(from pythonCode: String) -> String {
        return PyDataModelGenerator.generateSwiftCode(from: pythonCode, customFormatting: true)
    }
}
