import JavaScriptKit

/// JavaScript bridge for Monaco Editor API
struct MonacoEditor {
    let jsObject: JSObject
    
    /// Create Monaco editor instance
    static func create(containerId: String, value: String, language: String, readOnly: Bool = false) -> MonacoEditor? {
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
            return nil
        }
        
        // Create options object
        let options = JSObject()
        options.value = JSValue.string(value)
        options.language = JSValue.string(language)
        options.theme = JSValue.string("vs-dark")
        options.automaticLayout = JSValue.boolean(true)
        options.readOnly = JSValue.boolean(readOnly)
        
        let minimap = JSObject()
        minimap.enabled = JSValue.boolean(false)
        options.minimap = minimap.jsValue
        
        let createdEditor = editorObj.create!(container, options)
        guard let createdEditorObj = createdEditor.object else {
            return nil
        }
        
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
