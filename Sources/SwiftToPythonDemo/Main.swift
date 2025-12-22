import JavaScriptKit
import SwiftToPythonLib

@main
struct SwiftToPythonDemo {
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
        
        // Check for URL parameter first
        let urlCode = getCodeFromURL()
        
        // Default Swift code
        let defaultCode = """
import PySwiftKit

@PyClass
class Person {
    @PyProperty
    var name: String
    
    @PyProperty
    let id: Int
    
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
        
        let initialCode = urlCode ?? defaultCode
        
        // Create input editor (left)
        guard let leftContainer = document.getElementById("editor-left").object else {
            print("Left editor container not found")
            return
        }
        
        let leftOptions = JSObject.global.Object.function!()
        leftOptions.value = .string(initialCode)
        leftOptions.language = .string("swift")
        leftOptions.theme = .string("vs-dark")
        leftOptions.automaticLayout = .boolean(true)
        leftOptions.minimap = JSObject.global.Object.function!()
        leftOptions.minimap.enabled = .boolean(false)
        
        guard let leftEditor = editorObj.create.function?(leftContainer, leftOptions).object else {
            print("Failed to create left editor")
            return
        }
        
        // Create output editor (right)
        guard let rightContainer = document.getElementById("editor-right").object else {
            print("Right editor container not found")
            return
        }
        
        let initialPython = generatePython(from: initialCode)
        
        let rightOptions = JSObject.global.Object.function!()
        rightOptions.value = .string(initialPython)
        rightOptions.language = .string("python")
        rightOptions.theme = .string("vs-dark")
        rightOptions.automaticLayout = .boolean(true)
        rightOptions.minimap = JSObject.global.Object.function!()
        rightOptions.minimap.enabled = .boolean(false)
        rightOptions.readOnly = .boolean(true)
        
        guard let rightEditor = editorObj.create.function?(rightContainer, rightOptions).object else {
            print("Failed to create right editor")
            return
        }
        
        // Setup change handler
        guard let leftModel = leftEditor.getModel!().object else {
            print("Failed to get left model")
            return
        }
        
        let closure = JSClosure { args in
            let newCode = leftEditor.getValue!().string ?? ""
            let pythonOutput = generatePython(from: newCode)
            _ = rightEditor.setValue!(pythonOutput)
            return .undefined
        }
        
        _ = leftModel.onDidChangeContent!(closure)
        
        // Setup share button
        setupShareButton(leftEditor: leftEditor)
    }
    
    static func generatePython(from swiftCode: String) -> String {
        return SwiftToPythonGenerator.generatePythonStub(from: swiftCode)
    }
    
    static func getCodeFromURL() -> String? {
        guard JSObject.global.LZString.jsValue != .undefined,
              let lzString = JSObject.global.LZString.object else {
            return nil
        }
        
        let searchString = JSObject.global.location.search.string ?? ""
        if searchString.isEmpty || !searchString.contains("code=") {
            return nil
        }
        
        let params = searchString.dropFirst()
        let pairs = params.split(separator: "&")
        var codeStr: String?
        
        for pair in pairs {
            let parts = pair.split(separator: "=", maxSplits: 1)
            if parts.count == 2 && parts[0] == "code" {
                codeStr = String(parts[1])
                break
            }
        }
        
        guard let code = codeStr,
              let decompressFn = lzString.decompressFromEncodedURIComponent.function else {
            return nil
        }
        
        let result = decompressFn(code)
        return result.string
    }
    
    static func setupShareButton(leftEditor: JSObject) {
        let document = JSObject.global.document
        
        let tabsContainer = document.querySelector(".header-actions")
        guard tabsContainer.jsValue != .undefined,
              tabsContainer.jsValue != .null else {
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
            
            let code = leftEditor.getValue!().string ?? ""
            let compressed = compressFn(code)
            
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
        _ = tabsContainer.appendChild(shareBtn)
    }
}
