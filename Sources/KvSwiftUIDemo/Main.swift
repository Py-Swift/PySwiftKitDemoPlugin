import JavaScriptKit
import JavaScriptKitExtensions
import KvParser
import KvSyntaxHighlight
import KvSwiftUI

@main
struct KvSwiftUIDemo {
    nonisolated(unsafe) static var leftEditor: JSObject?
    nonisolated(unsafe) static var rightEditor: JSObject?
    
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
        let urlCode = getCodeFromURL()
        
        // Default KV code
        let defaultCode = """
BoxLayout:
    orientation: 'vertical'
    padding: 20
    
    Label:
        text: 'Hello SwiftUI'
        font_size: 24
        color: [0.2, 0.5, 1.0, 1.0]
    
    Button:
        text: 'Click Me'
        size_hint: 1.0, 0.2
        background_color: [0.3, 0.7, 0.3, 1.0]
    
    BoxLayout:
        orientation: 'horizontal'
        
        Slider:
            value: 0.5
        
        Label:
            text: 'Volume'
"""
        
        let initialCode = urlCode ?? defaultCode
        
        // Create input editor (left)
        guard let leftContainer = document.getElementById("editor-left").object else {
            print("Left editor container not found")
            return
        }
        
        let leftOptions = JSObject()
        leftOptions.value = initialCode
        leftOptions.language = "kv"  // Use KV syntax highlighting
        leftOptions.theme = .string("vs-dark")
        leftOptions.automaticLayout = true
        leftOptions.minimap = [
            "enabled": false
        ]
        
        guard let leftEditorObj = editorObj.create.function?(leftContainer, leftOptions).object else {
            print("Failed to create left editor")
            return
        }
        leftEditor = leftEditorObj
        
        // Create output editor (right - SwiftUI Code)
        guard let rightContainer = document.getElementById("editor-right").object else {
            print("Right editor container not found")
            return
        }
        
        let initialSwiftUI = generateSwiftUI(from: initialCode)
        
        let rightOptions = JSObject()
        rightOptions.value = initialSwiftUI
        rightOptions.language = "swift"
        rightOptions.theme = "vs-dark"
        rightOptions.automaticLayout = true
        rightOptions.minimap = [
            "enabled": false
        ]
        rightOptions.readOnly = true
        
        guard let rightEditorObj  = editorObj.create?(rightContainer, rightOptions).object else {
            print("Failed to create right editor")
            return
        }
        rightEditor = rightEditorObj
        
        // Setup change handler
        guard let leftModel = leftEditorObj.getModel!().object else {
            print("Failed to get left model")
            return
        }
        
        let closure = JSClosure { args in
            guard let leftEditor = leftEditor, 
                  let rightEditor = rightEditor else {
                return .undefined
            }
            
            let newCode = leftEditor.getValue!().string ?? ""
            let swiftUIOutput = generateSwiftUI(from: newCode)
            _ = rightEditor.setValue!(swiftUIOutput)
            
            return .undefined
        }
        
        _ = leftModel.onDidChangeContent!(closure)
        
        // Setup share button
        setupShareButton(leftEditor: leftEditorObj)
    }
    
    static func generateSwiftUI(from kvSource: String) -> String {
        do {
            // Tokenize
            let tokenizer = KvTokenizer(source: kvSource)
            let tokens = try tokenizer.tokenize()
            
            // Parse
            let parser = KvParser(tokens: tokens)
            let module = try parser.parse()
            
            // Generate SwiftUI code
            let generator = KvSwiftUIGenerator()
            return generator.generate(from: module)
        } catch {
            return "// Error: \(error)"
        }
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
        _ = actionsContainer.appendChild(shareBtn)
    }
}
