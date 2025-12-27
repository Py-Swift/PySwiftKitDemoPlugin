import Foundation
import JavaScriptKit
import JavaScriptKitExtensions
import KvParser
import KvSyntaxHighlight
import KvToPyClass

struct ShareData: Codable {
    let kv: String
    let py: String
}

@main
struct KvToPyClassDemo {
    nonisolated(unsafe) static var pythonEditor: JSObject?
    nonisolated(unsafe) static var kvEditor: JSObject?
    nonisolated(unsafe) static var outputEditor: JSObject?
    
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

<MyButton@Button>:
    text: app.title
    background_color: 0.2, 0.6, 1, 1
    font_size: 18
    size_hint: None, None
    size: 200, 50

<AppInfo@BoxLayout>:
    orientation: 'vertical'
    padding: 20
    spacing: 10
    
    Label:
        text: f"{app.title}-{app.version}"
        font_size: 24
        size_hint_y: None
        height: 40
    
    Label:
        text: str(app.description)
        font_size: 16
        size_hint_y: None
        height: 60

<UserProfile>:
    orientation: 'vertical'
    spacing: 10
    padding: 20
    
    Label:
        text: 'User Profile'
        font_size: 24
        size_hint_y: None
        height: 40
    
    BoxLayout:
        orientation: 'horizontal'
        spacing: 10
        
        Label:
            text: 'Name:'
            size_hint_x: 0.3
        
        TextInput:
            id: name_input
            multiline: False
    
    BoxLayout:
        orientation: 'horizontal'
        spacing: 10
        
        Label:
            text: 'Email:'
            size_hint_x: 0.3
        
        TextInput:
            id: email_input
            multiline: False
    
    MyButton:
        text: 'Save Profile'
        on_press: root.save_profile()
"""
        
        // Default Python widget code
        let defaultPythonCode = """

class UserProfile(BoxLayout):
    def save_profile(self):
        name = self.ids.name_input.text
        email = self.ids.email_input.text
        print(f"Saving profile: {name}, {email}")
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
        
        // Create output editor (right)
        guard let outputContainer = document.getElementById("editor-output").object else {
            print("Output editor container not found")
            return
        }
        
        let initialOutput = generatePythonClasses(kvCode: initialKvCode, pythonCode: initialPythonCode)
        
        let outputOptions = JSObject()
        outputOptions.value = initialOutput
        outputOptions.language = "python"
        outputOptions.theme = "vs-dark"
        outputOptions.automaticLayout = true
        outputOptions.minimap = ["enabled": false]
        outputOptions.readOnly = true
        
        guard let outputEditorObj = editorObj.create?(outputContainer, outputOptions).object else {
            print("Failed to create output editor")
            return
        }
        outputEditor = outputEditorObj
        
        // Setup change handlers for both editors
        guard let kvModel = kvEditorObj.getModel!().object,
              let pythonModel = pythonEditorObj.getModel!().object else {
            print("Failed to get editor models")
            return
        }
        
        let updateClosure = JSClosure { _ in
            guard let kvEditor = kvEditor,
                  let pythonEditor = pythonEditor,
                  let outputEditor = outputEditor else {
                return .undefined
            }
            
            let kvCode = kvEditor.getValue!().string ?? ""
            let pythonCode = pythonEditor.getValue!().string ?? ""
            let output = generatePythonClasses(kvCode: kvCode, pythonCode: pythonCode)
            _ = outputEditor.setValue!(output)
            
            return .undefined
        }
        
        _ = kvModel.onDidChangeContent!(updateClosure)
        _ = pythonModel.onDidChangeContent!(updateClosure)
        
        // Setup share button
        setupShareButton(kvEditor: kvEditorObj, pythonEditor: pythonEditorObj)
    }
    
    static func generatePythonClasses(kvCode: String, pythonCode: String) -> String {
        do {
            // Parse KV
            let tokenizer = KvTokenizer(source: kvCode)
            let tokens = try tokenizer.tokenize()
            let parser = KvParser(tokens: tokens)
            let module = try parser.parse()
            
            // Parse Python input to extract class definitions
            let pythonParser = PythonClassParser(source: pythonCode)
            let pythonClasses = pythonParser.parse()
            
            // Generate Python classes with information from both KV and Python code
            let generator = KvToPyClassGenerator(module: module, pythonClasses: pythonClasses)
            let generatedCode = try generator.generate()
            
            return generatedCode
        } catch let error as KvParserError {
            return "# Error parsing KV file:\n# \(error)"
        } catch {
            return "# Error generating Python classes:\n# \(error)"
        }
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
        let pairs = params.split(separator: "=", maxSplits: 1)
        
        guard pairs.count == 2,
              String(pairs[0]) == "code",
              let decompressFn = lzString.decompressFromEncodedURIComponent.function else {
            return nil
        }
        
        let compressed = String(pairs[1])
        guard let decompressed = decompressFn(compressed).string else {
            return nil
        }
        
        // Parse JSON: {"kv": "...", "py": "..."}
        guard let jsonData = decompressed.data(using: .utf8),
              let shareData = try? JSONDecoder().decode(ShareData.self, from: jsonData) else {
            return nil
        }
        
        return (kv: shareData.kv, python: shareData.py)
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
            
            // Create JSON: {"kv": "...", "py": "..."}
            let shareData = ShareData(kv: kvCode, py: pythonCode)
            guard let jsonData = try? JSONEncoder().encode(shareData),
                  let jsonString = String(data: jsonData, encoding: .utf8) else {
                return .undefined
            }
            
            let compressed = compressFn(jsonString)
            guard let compressedStr = compressed.string else {
                return .undefined
            }
            
            let origin = JSObject.global.location.origin.string ?? ""
            let pathname = JSObject.global.location.pathname.string ?? ""
            let shareURL = "\(origin)\(pathname)?code=\(compressedStr)"
            
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
