import JavaScriptKit
import JavaScriptKitExtensions
import KvParser
import KvSyntaxHighlight
import PyDataModels

@main
struct KvToDataModelDemo {
    nonisolated(unsafe) static var kvEditor: JSObject?
    nonisolated(unsafe) static var pythonEditor: JSObject?
    nonisolated(unsafe) static var kvOutputEditor: JSObject?
    nonisolated(unsafe) static var pythonOutputEditor: JSObject?
    
    static func main() {
        setupEditor()
    }
    
    static func setupEditor() {
        let document = JSObject.global.document
        let monaco = JSObject.global.monaco
        
        guard let monacoObj = monaco.object,
              let editorObj = monacoObj.editor.object else {
            print("Monaco editor not available")
            return
        }
        
        // Register KV language syntax highlighting
        KvSyntaxHighlight.register()
        
        // Check for URL parameter first
        let urlData = getDataFromURL()
        
        // Default KV code
        let defaultKvCode = """

<MyWidget>:
    orientation: 'vertical'
    
    Label:
        text: root.title
        font_size: root.title_size
    
    TextInput:
        text: root.user_input
        on_text: root.user_input = self.text
    
    Button:
        text: 'Count: ' + str(root.counter)
        on_press: root.increment()
"""
        
        // Default Python code - Kivy Widget with properties
        let defaultPythonCode = """


class MyWidget(BoxLayout):

    title = StringProperty("")

    title_size = NumericProperty(0)

    user_input = StringProperty("")

    counter = NumericProperty(0)

    state = BooleanProperty(False)
    
    def __init__(self, title: str, title_size: float, user_input: str, counter: int, state: bool):
        self.title = title
        self.title_size = title_size
        self.user_input = user_input
        self.counter = counter
        self.state = state
    
    def increment(self):
        self.counter += 1
"""
        
        let initialKvCode = urlData?.kv ?? defaultKvCode
        let initialPythonCode = urlData?.python ?? defaultPythonCode
        
        // Create KV editor (top-left)
        guard let kvContainer = document.getElementById("editor-kv").object else {
            print("KV editor container not found")
            return
        }
        
        let kvOptions = JSObject()
        kvOptions.value = initialKvCode
        kvOptions.language = "kv"
        kvOptions.theme = .string("vs-dark")
        kvOptions.automaticLayout = true
        kvOptions.minimap = ["enabled": false]
        
        guard let kvEditorObj = editorObj.create.function?(kvContainer, kvOptions).object else {
            print("Failed to create KV editor")
            return
        }
        kvEditor = kvEditorObj
        
        // Create Python editor (bottom-left)
        guard let pythonContainer = document.getElementById("editor-python").object else {
            print("Python editor container not found")
            return
        }
        
        let pythonOptions = JSObject()
        pythonOptions.value = initialPythonCode
        pythonOptions.language = "python"
        pythonOptions.theme = .string("vs-dark")
        pythonOptions.automaticLayout = true
        pythonOptions.minimap = ["enabled": false]
        
        guard let pythonEditorObj = editorObj.create.function?(pythonContainer, pythonOptions).object else {
            print("Failed to create Python editor")
            return
        }
        pythonEditor = pythonEditorObj
        
        // Create KV output editor (top-right)
        guard let kvOutputContainer = document.getElementById("editor-kv-output").object else {
            print("KV output editor container not found")
            return
        }
        
        let (initialKvOutput, initialPythonOutput) = generateDataModel(kvCode: initialKvCode, pythonCode: initialPythonCode)
        
        let kvOutputOptions = JSObject()
        kvOutputOptions.value = initialKvOutput
        kvOutputOptions.language = "kv"
        kvOutputOptions.theme = "vs-dark"
        kvOutputOptions.automaticLayout = true
        kvOutputOptions.minimap = ["enabled": false]
        kvOutputOptions.readOnly = true
        
        guard let kvOutputEditorObj = editorObj.create?(kvOutputContainer, kvOutputOptions).object else {
            print("Failed to create KV output editor")
            return
        }
        kvOutputEditor = kvOutputEditorObj
        
        // Create Python output editor (bottom-right)
        guard let pythonOutputContainer = document.getElementById("editor-python-output").object else {
            print("Python output editor container not found")
            return
        }
        
        let pythonOutputOptions = JSObject()
        pythonOutputOptions.value = initialPythonOutput
        pythonOutputOptions.language = "python"
        pythonOutputOptions.theme = "vs-dark"
        pythonOutputOptions.automaticLayout = true
        pythonOutputOptions.minimap = ["enabled": false]
        pythonOutputOptions.readOnly = true
        
        guard let pythonOutputEditorObj = editorObj.create?(pythonOutputContainer, pythonOutputOptions).object else {
            print("Failed to create Python output editor")
            return
        }
        pythonOutputEditor = pythonOutputEditorObj
        
        // Setup change handlers for both editors
        guard let kvModel = kvEditorObj.getModel!().object,
              let pythonModel = pythonEditorObj.getModel!().object else {
            print("Failed to get editor models")
            return
        }
        
        let updateClosure = JSClosure { _ in
            guard let kvEditor = kvEditor,
                  let pythonEditor = pythonEditor,
                  let kvOutputEditor = kvOutputEditor,
                  let pythonOutputEditor = pythonOutputEditor else {
                return .undefined
            }
            
            let kvCode = kvEditor.getValue!().string ?? ""
            let pythonCode = pythonEditor.getValue!().string ?? ""
            let (kvOutput, pythonOutput) = generateDataModel(kvCode: kvCode, pythonCode: pythonCode)
            _ = kvOutputEditor.setValue!(kvOutput)
            _ = pythonOutputEditor.setValue!(pythonOutput)
            
            return .undefined
        }
        
        _ = kvModel.onDidChangeContent!(updateClosure)
        _ = pythonModel.onDidChangeContent!(updateClosure)
        
        // Setup share button
        setupShareButton(kvEditor: kvEditorObj, pythonEditor: pythonEditorObj)
    }
    
    static func generateDataModel(kvCode: String, pythonCode: String) -> (String, String) {
        // Convert KV bindings from root.prop to root.data.prop
        let convertedKv = convertKvBindings(kvCode)
        
        // Generate EventDispatcher data model from Python widget class
        let convertedPython = KivyModelGenerator.generate(from: pythonCode)
        
        return (convertedKv, convertedPython)
    }
    
    /// Converts KV bindings from root.property to root.data.property
    private static func convertKvBindings(_ kvCode: String) -> String {
        // Simple regex replacement: root. → root.data.
        // This handles cases like: root.title, root.increment(), etc.
        let lines = kvCode.split(separator: "\n", omittingEmptySubsequences: false)
        let converted = lines.map { line -> String in
            let lineStr = String(line)
            // Replace root.property with root.data.property, but not root.data.property
            if lineStr.contains("root.") && !lineStr.contains("root.data.") {
                return lineStr.replacingOccurrences(
                    of: #"\broot\.(\w+)"#,
                    with: "root.data.$1",
                    options: .regularExpression
                )
            }
            return lineStr
        }
        return converted.joined(separator: "\n")
    }
    
    static func getDataFromURL() -> (kv: String, python: String)? {
        guard JSObject.global.LZString.jsValue != .undefined,
              let lzString = JSObject.global.LZString.object else {
            return nil
        }
        
        let searchString = JSObject.global.location.search.string ?? ""
        if searchString.isEmpty {
            return nil
        }
        
        let params = searchString.dropFirst()
        let pairs = params.split(separator: "&")
        var kvCode: String?
        var pythonCode: String?
        
        for pair in pairs {
            let parts = pair.split(separator: "=", maxSplits: 1)
            if parts.count == 2 {
                let key = String(parts[0])
                let value = String(parts[1])
                
                if key == "kv", let decompressFn = lzString.decompressFromEncodedURIComponent.function {
                    kvCode = decompressFn(value).string
                } else if key == "python", let decompressFn = lzString.decompressFromEncodedURIComponent.function {
                    pythonCode = decompressFn(value).string
                }
            }
        }
        
        if let kv = kvCode, let python = pythonCode {
            return (kv, python)
        }
        return nil
    }
    
    static func setupShareButton(kvEditor: JSObject, pythonEditor: JSObject) {
        let document = JSObject.global.document
        
        let actionsContainer = document.querySelector(".header-actions")
        guard actionsContainer.jsValue != .undefined,
              actionsContainer.jsValue != .null else {
            return
        }
        
        let shareBtn = document.createElement("button")
        _ = shareBtn.classList.add("share-btn")
        shareBtn.textContent = "📋 Share"
        shareBtn.title = "Copy shareable link to clipboard"
        
        let closure = JSClosure { _ in
            guard JSObject.global.LZString.jsValue != .undefined,
                  let lzString = JSObject.global.LZString.object,
                  let compressFn = lzString.compressToEncodedURIComponent.function else {
                return .undefined
            }
            
            let kvCode = kvEditor.getValue!().string ?? ""
            let pythonCode = pythonEditor.getValue!().string ?? ""
            
            let kvCompressed = compressFn(kvCode)
            let pythonCompressed = compressFn(pythonCode)
            
            guard let kvStr = kvCompressed.string,
                  let pythonStr = pythonCompressed.string else {
                return .undefined
            }
            
            let origin = JSObject.global.location.origin.string ?? ""
            let pathname = JSObject.global.location.pathname.string ?? ""
            let shareURL = "\(origin)\(pathname)?kv=\(kvStr)&python=\(pythonStr)"
            
            _ = JSObject.global.navigator.clipboard.writeText(shareURL)
            
            let originalText = shareBtn.textContent.string ?? "📋 Share"
            shareBtn.textContent = "✅ Copied!"
            
            _ = JSObject.global.setTimeout!(JSClosure { _ in
                shareBtn.textContent = .string(originalText)
                return .undefined
            }, 2000)
            
            return .undefined
        }
        
        _ = shareBtn.addEventListener("click", closure)
        _ = actionsContainer.appendChild(shareBtn)
    }
}
