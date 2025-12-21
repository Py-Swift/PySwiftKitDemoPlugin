import JavaScriptKit

/// JavaScript bridge for Monaco Editor API
struct MonacoEditor {
    let jsObject: JSObject
    
    /// Create Monaco editor instance without initial content
    static func create(containerId: String, readOnly: Bool = false) -> MonacoEditor? {
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
        
        // Create options object without value/language (set via model)
        let options = JSObject()
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
    
    /// Get the current model
    func getModel() -> MonacoModel? {
        let modelValue = jsObject.getModel!()
        guard let modelObj = modelValue.object else { return nil }
        return MonacoModel(jsObject: modelObj)
    }
    
    /// Set a different model
    func setModel(_ model: MonacoModel?) {
        if let model = model {
            _ = jsObject.setModel!(model.jsObject)
        } else {
            _ = jsObject.setModel!(JSValue.null)
        }
    }
    
    /// Update read-only state
    func updateOptions(readOnly: Bool) {
        let options = JSObject()
        options.readOnly = JSValue.boolean(readOnly)
        _ = jsObject.updateOptions!(options)
    }
}

/// JavaScript bridge for Monaco Model API
struct MonacoModel {
    let jsObject: JSObject
    
    /// Create a new text model
    static func create(value: String, language: String) -> MonacoModel? {
        let monaco = JSObject.global.monaco
        guard let monacoObj = monaco.object else {
            return nil
        }
        
        let editor = monacoObj.editor
        guard let editorObj = editor.object else {
            return nil
        }
        
        let model = editorObj.createModel!(
            JSValue.string(value),
            JSValue.string(language)
        )
        
        guard let modelObj = model.object else {
            return nil
        }
        
        return MonacoModel(jsObject: modelObj)
    }
    
    /// Get the current text content
    func getValue() -> String {
        let value = jsObject.getValue!()
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
        
        _ = jsObject.onDidChangeContent!(closure)
    }
    
    /// Dispose the model when no longer needed
    func dispose() {
        _ = jsObject.dispose!()
    }
}
