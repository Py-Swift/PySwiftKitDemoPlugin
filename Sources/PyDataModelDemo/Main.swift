import JavaScriptKit
import PyDataModels

@main
struct PyDataModelDemo {
    nonisolated(unsafe) static var leftEditor: JSObject?
    nonisolated(unsafe) static var middleEditor: JSObject?
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
        
        // Check for URL parameter first
        let urlCode = getCodeFromURL()
        
        // Default Python code
        let defaultCode = """


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
        
        let initialCode = urlCode ?? defaultCode
        
        // Create input editor (left)
        guard let leftContainer = document.getElementById("editor-left").object else {
            print("Left editor container not found")
            return
        }
        
        let leftOptions = JSObject.global.Object.function!()
        leftOptions.value = .string(initialCode)
        leftOptions.language = .string("python")
        leftOptions.theme = .string("vs-dark")
        leftOptions.automaticLayout = .boolean(true)
        leftOptions.minimap = JSObject.global.Object.function!()
        leftOptions.minimap.enabled = .boolean(false)
        
        guard let leftEditorObj = editorObj.create.function?(leftContainer, leftOptions).object else {
            print("Failed to create left editor")
            return
        }
        leftEditor = leftEditorObj
        
        // Create middle editor (Kivy output - hidden by default)
        guard let middleContainer = document.getElementById("editor-middle").object else {
            print("Middle editor container not found")
            return
        }
        
        let initialKivy = generateKivyModel(from: initialCode)
        
        let middleOptions = JSObject.global.Object.function!()
        middleOptions.value = .string(initialKivy)
        middleOptions.language = .string("python")
        middleOptions.theme = .string("vs-dark")
        middleOptions.automaticLayout = .boolean(true)
        middleOptions.minimap = JSObject.global.Object.function!()
        middleOptions.minimap.enabled = .boolean(false)
        middleOptions.readOnly = .boolean(true)
        
        guard let middleEditorObj = editorObj.create.function?(middleContainer, middleOptions).object else {
            print("Failed to create middle editor")
            return
        }
        middleEditor = middleEditorObj
        
        // Create output editor (right - Swift Container)
        guard let rightContainer = document.getElementById("editor-right").object else {
            print("Right editor container not found")
            return
        }
        
        let initialSwift = generateSwiftContainer(from: initialCode)
        
        let rightOptions = JSObject.global.Object.function!()
        rightOptions.value = .string(initialSwift)
        rightOptions.language = .string("swift")
        rightOptions.theme = .string("vs-dark")
        rightOptions.automaticLayout = .boolean(true)
        rightOptions.minimap = JSObject.global.Object.function!()
        rightOptions.minimap.enabled = .boolean(false)
        rightOptions.readOnly = .boolean(true)
        
        guard let rightEditorObj = editorObj.create.function?(rightContainer, rightOptions).object else {
            print("Failed to create right editor")
            return
        }
        rightEditor = rightEditorObj
        
        // Setup change handler to update both Kivy and Swift outputs
        guard let leftModel = leftEditorObj.getModel!().object else {
            print("Failed to get left model")
            return
        }
        
        let closure = JSClosure { args in
            guard let leftEditor = leftEditor, 
                  let middleEditor = middleEditor,
                  let rightEditor = rightEditor else {
                return .undefined
            }
            
            let newCode = leftEditor.getValue!().string ?? ""
            
            // Update Kivy output
            let kivyOutput = generateKivyModel(from: newCode)
            _ = middleEditor.setValue!(kivyOutput)
            
            // Update Swift output
            let swiftOutput = generateSwiftContainer(from: newCode)
            _ = rightEditor.setValue!(swiftOutput)
            
            return .undefined
        }
        
        _ = leftModel.onDidChangeContent!(closure)
        
        // Setup Kivy mode checkbox
        setupKivyModeCheckbox()
        
        // Setup share button
        setupShareButton(leftEditor: leftEditorObj)
    }
    
    static func setupKivyModeCheckbox() {
        let document = JSObject.global.document
        guard let optionsContainer = document.querySelector(".panel-header-options").object else {
            print("❌ Could not find panel-header-options")
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
    
    static func toggleKivyMode(enabled: Bool) {
        let document = JSObject.global.document
        guard let middlePanel = document.getElementById("panel-middle").object,
              let container = document.getElementById("editor-container").object else {
            return
        }
        
        if enabled {
            // Show middle panel
            _ = middlePanel.classList.remove("hidden")
            _ = container.classList.add("three-column")
        } else {
            // Hide middle panel
            _ = middlePanel.classList.add("hidden")
            _ = container.classList.remove("three-column")
        }
        
        // Trigger layout update for all editors
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
    
    static func generateSwiftContainer(from pythonCode: String) -> String {
        return PyDataModelGenerator.generateSwiftCode(from: pythonCode, customFormatting: true)
    }
    
    static func generateKivyModel(from pythonCode: String) -> String {
        return KivyModelGenerator.generate(from: pythonCode)
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
