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
    nonisolated(unsafe) static var pythonDataModelModels: (input: MonacoModel, kivy: MonacoModel, swift: MonacoModel)?
    
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
        
        // Clear left panel options
        if let optionsContainer = document.getElementById("panel-left-options").object {
            optionsContainer.innerHTML = ""
        }
        
        switch tab {
        case "swift-to-python":
            if let models = swiftToPythonModels {
                leftEditor.setModel(models.input)
                rightEditor.setModel(models.output)
                leftEditor.updateOptions(readOnly: false)
                
                // Update panel headers
                updatePanelHeader(headerId: "panel-left-header", title: "Swift Code (with PySwiftKit decorators)")
                updatePanelHeader(headerId: "panel-right-header", title: "Generated Python API (Read-only)")
                
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
                updatePanelHeader(headerId: "panel-left-header", title: "Python Code")
                updatePanelHeader(headerId: "panel-right-header", title: "Generated Swift PySwiftKit Code (Read-only)")
                
                // Update active tab
                if let tabElement = document.getElementById("tab-python-to-swift").object {
                    _ = tabElement.classList.add("active")
                }
            }
            
        case "python-datamodel":
            if let models = pythonDataModelModels {
                leftEditor.setModel(models.input)
                rightEditor.setModel(models.swift)
                leftEditor.updateOptions(readOnly: false)
                
                // Update panel headers
                updatePanelHeader(headerId: "panel-left-header", title: "Python Data Model")
                updatePanelHeader(headerId: "panel-right-header", title: "Generated Swift Container (Read-only)")
                
                // Add Kivy mode checkbox
                setupKivyModeCheckbox()
                
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
        // Check for URL parameter first
        let urlCode = getCodeFromURL()
        
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
        
        // Use URL code if available, otherwise use default
        let initialCode = urlCode ?? defaultSwiftCode
        
        // Create models
        guard let inputModel = MonacoModel.create(value: initialCode, language: "swift"),
              let outputModel = MonacoModel.create(value: "# Generated Python API will appear here...", language: "python") else {
            return
        }
        
        // Setup change handler on input model
        inputModel.onDidChangeContent { newContent in
            let pythonOutput = generatePythonStub(from: newContent)
            outputModel.setValue(pythonOutput)
            // Don't update URL here - too frequent, causes issues
        }
        
        // Generate initial output
        let initialPython = generatePythonStub(from: initialCode)
        outputModel.setValue(initialPython)
        
        swiftToPythonModels = (inputModel, outputModel)
        
        // Setup completion providers for first model
        if let leftEditor = leftEditor {
            CompletionProvider.setupCompletionProviders(swiftEditor: leftEditor)
        }
        
        // Setup share button
        setupShareButton()
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
              let kivyModel = MonacoModel.create(value: "# Generated Kivy EventDispatcher code will appear here...", language: "python"),
              let swiftModel = MonacoModel.create(value: "// Generated Swift Container code will appear here...", language: "swift") else {
            return
        }
        
        // Setup change handler on input model to update both outputs
        inputModel.onDidChangeContent { newContent in
            let kivyOutput = generateKivyModel(from: newContent)
            kivyModel.setValue(kivyOutput)
            
            let swiftOutput = generateSwiftContainer(from: newContent)
            swiftModel.setValue(swiftOutput)
        }
        
        // Generate initial outputs
        let initialKivy = generateKivyModel(from: defaultPythonCode)
        kivyModel.setValue(initialKivy)
        
        let initialSwift = generateSwiftContainer(from: defaultPythonCode)
        swiftModel.setValue(initialSwift)
        
        pythonDataModelModels = (inputModel, kivyModel, swiftModel)
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
    
    /// Generate Kivy EventDispatcher model from Python
    static func generateKivyModel(from pythonCode: String) -> String {
        return KivyModelGenerator.generate(from: pythonCode)
    }
    
    /// Helper to update panel header title
    private static func updatePanelHeader(headerId: String, title: String) {
        let document = JSObject.global.document
        if let header = document.getElementById(headerId).object,
           let titleSpan = header.querySelector!(".panel-header-title").object {
            titleSpan.textContent = .string(title)
        }
    }
    
    /// Setup Kivy mode checkbox for datamodel tab
    private static func setupKivyModeCheckbox() {
        let document = JSObject.global.document
        guard let optionsContainer = document.getElementById("panel-left-options").object else {
            print("❌ Could not find panel-left-options")
            return
        }
        
        // Create label
        let label = document.createElement("label")
        guard let labelElement = label.object else { 
            print("❌ Could not create label element")
            return 
        }
        labelElement.className = .string("checkbox-label")
        
        // Create checkbox
        let checkbox = document.createElement("input")
        guard let checkboxElement = checkbox.object else { 
            print("❌ Could not create checkbox element")
            return 
        }
        checkboxElement.type = .string("checkbox")
        checkboxElement.id = .string("kivy-mode-checkbox")
        
        // Create text node
        let textNode = document.createTextNode(" Kivy Mode")
        
        // Append elements
        _ = labelElement.appendChild!(checkbox)
        _ = labelElement.appendChild!(textNode)
        _ = optionsContainer.appendChild!(label)
        
        print("✅ Kivy mode checkbox created successfully")
        
        // Add change event listener
        let changeHandler = JSClosure { _ in
            toggleKivyMode(enabled: checkboxElement.checked.boolean ?? false)
            return .undefined
        }
        _ = checkboxElement.addEventListener!("change", changeHandler)
    }
    
    /// Toggle Kivy mode (show/hide middle panel)
    private static func toggleKivyMode(enabled: Bool) {
        let document = JSObject.global.document
        guard let middlePanel = document.getElementById("panel-middle").object,
              let container = document.getElementById("editor-container").object else {
            return
        }
        
        if enabled {
            // Show middle panel
            _ = middlePanel.classList.remove("hidden")
            _ = container.classList.add("three-column")
            
            // Update middle panel header
            updatePanelHeader(headerId: "panel-middle-header", title: "Kivy EventDispatcher (Read-only)")
            
            // Set middle editor model to Kivy output and make it read-only
            if let models = pythonDataModelModels,
               let middle = middleEditor {
                middle.setModel(models.kivy)
                middle.updateOptions(readOnly: true)
            }
            
        } else {
            // Hide middle panel
            _ = middlePanel.classList.add("hidden")
            _ = container.classList.remove("three-column")
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
}

// MARK: - URL Code Sharing

extension PySwiftKitDemoApp {
    /// Get code from URL parameter (LZ-compressed)
    static func getCodeFromURL() -> String? {
        // Safety check - make sure LZString is loaded
        guard JSObject.global.LZString.jsValue != .undefined,
              let lzString = JSObject.global.LZString.object else {
            return nil
        }
        
        // Get URL search params directly from location.search
        let searchString = JSObject.global.location.search.string ?? ""
        if searchString.isEmpty || !searchString.contains("code=") {
            return nil
        }
        
        // Parse manually to avoid URLSearchParams issues
        let params = searchString.dropFirst() // Remove leading '?'
        let pairs = params.split(separator: "&")
        var codeStr: String?
        
        for pair in pairs {
            let parts = pair.split(separator: "=", maxSplits: 1)
            if parts.count == 2 && parts[0] == "code" {
                codeStr = String(parts[1])
                break
            }
        }
        
        guard let code = codeStr else {
            return nil
        }
        
        // Decompress using LZ-String
        if let decompressFn = lzString.decompressFromEncodedURIComponent.function {
            let result = decompressFn(code)
            return result.string
        }
        
        return nil
    }
    
    /// Setup share button
    static func setupShareButton() {
        let document = JSObject.global.document
        
        // Find the tabs container - keep it as JSValue, not .object
        let tabsContainer = document.querySelector(".tabs")
        guard tabsContainer.jsValue != .undefined,
              tabsContainer.jsValue != .null else {
            return
        }
        
        // Create share button
        let shareBtn = document.createElement("button")
        _ = shareBtn.classList.add("tab")
        shareBtn.textContent = "📋 Share"
        shareBtn.title = "Copy shareable link to clipboard"
        shareBtn.style = "margin-left: auto;"
        
        // Add click handler
        let closure = JSClosure { _ in
            guard let models = swiftToPythonModels,
                  JSObject.global.LZString.jsValue != .undefined,
                  let lzString = JSObject.global.LZString.object,
                  let compressFn = lzString.compressToEncodedURIComponent.function else {
                return .undefined
            }
            
            let code = models.input.getValue()
            let compressed = compressFn(code)
            
            guard let compressedStr = compressed.string else {
                return .undefined
            }
            
            let origin = JSObject.global.location.origin.string ?? ""
            let pathname = JSObject.global.location.pathname.string ?? ""
            let shareURL = "\(origin)\(pathname)?code=\(compressedStr)"
            
            // Copy to clipboard - use direct member lookup like appendChild
            _ = JSObject.global.navigator.clipboard.writeText(shareURL)
            
            // Show feedback
            let originalText = shareBtn.textContent.string ?? "📋 Share"
            shareBtn.textContent = "✅ Copied!"
            
            _ = JSObject.global.setTimeout!(JSClosure { _ in
                shareBtn.textContent = .string(originalText)
                return .undefined
            }, 2000)
            
            return .undefined
        }
        
        _ = shareBtn.addEventListener("click", closure)
        
        // Append to tabs - use the same pattern as setupKivyModeCheckbox
        _ = tabsContainer.appendChild(shareBtn)
    }
}
