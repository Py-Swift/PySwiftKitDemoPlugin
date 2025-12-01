import JavaScriptKit

/// JavaScript bridge for Monaco Editor API
struct MonacoEditor {
    let jsObject: JSObject
    
    /// Create Monaco editor instance
    static func create(containerId: String, value: String, language: String, readOnly: Bool = false) -> MonacoEditor? {
        print("Creating editor")
        let monaco = JSObject.global.monaco
        guard let monacoObj = monaco.object else {
            return nil
        }
        
        let editor = monacoObj.editor
        guard let editorObj = editor.object else {
            return nil
        }
        
        let container = JSObject.global.document.getElementById(JSValue.string(containerId))
        guard container.object != nil else {
            print("Container not found")
            return nil
        }
        
        print("Creating options")
        // Create options object
        print("js global: \(JSObject.global.Object)")
        let options = JSObject()
        print("Created options object")
        options.value = JSValue.string(value)
        print("Setted value in options")
        options.language = JSValue.string(language)
        print("Setted language in options")
        options.theme = JSValue.string("vs-dark")
        print("Setted theme in options")
        options.automaticLayout = JSValue.boolean(true)
        print("Setted automaticLayout in options")
        options.readOnly = JSValue.boolean(readOnly)
        print("Setted readOnly in options")
        
        let minimap = JSObject()
        minimap.enabled = JSValue.boolean(false)
        options.minimap = minimap.jsValue
        
        print("Calling Monaco create")
        let createdEditor = editorObj.create!(container, options)
        guard let createdEditorObj = createdEditor.object else {
            print("Failed to create editor object")
            return nil
        }
        print("Editor created successfully")
        
        return MonacoEditor(jsObject: createdEditorObj)
    }
    
    /// Get the current text content
    func getValue() -> String {
        let model = jsObject.getModel!()
        guard let modelObj = model.object else { return "" }
        let value = modelObj.getValue!()
        return value.string ?? ""
    }
    
    /// Set the text content
    func setValue(_ value: String) {
        _ = jsObject.setValue!(JSValue.string(value))
    }
    
    /// Register onChange callback
    func onDidChangeContent(handler: @escaping (String) -> Void) {
        let closure = JSClosure { _ in
            let content = self.getValue()
            handler(content)
            return .undefined
        }
        
        let model = jsObject.getModel!()
        guard let modelObj = model.object else { return }
        _ = modelObj.onDidChangeContent!(closure)
    }
}
