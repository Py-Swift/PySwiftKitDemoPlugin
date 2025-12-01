# Interactive Demo

<div id="pyswiftkit-editor"></div>

<script type="importmap">
{
    "imports": {
        "@bjorn3/browser_wasi_shim": "https://cdn.jsdelivr.net/npm/@bjorn3/browser_wasi_shim@0.3.0/dist/index.js"
    }
}
</script>

<style>
#pyswiftkit-editor {
    width: 100%;
    height: 600px;
    display: grid;
    grid-template-columns: 1fr 1fr;
    gap: 10px;
    margin: 20px 0;
}

.editor-panel {
    border: 1px solid #ddd;
    border-radius: 4px;
    overflow: hidden;
    display: flex;
    flex-direction: column;
}

.editor-header {
    background: #f5f5f5;
    padding: 10px;
    font-weight: bold;
    border-bottom: 1px solid #ddd;
}

.editor-container {
    flex: 1;
    position: relative;
}

#swift-editor, #python-editor {
    position: absolute;
    top: 0;
    left: 0;
    right: 0;
    bottom: 0;
}
</style>

<div id="pyswiftkit-editor">
    <div class="editor-panel">
        <div class="editor-header">Swift Code (with PySwiftKit decorators)</div>
        <div class="editor-container">
            <div id="swift-editor"></div>
        </div>
    </div>
    
    <div class="editor-panel">
        <div class="editor-header">Generated Python API (Read-only)</div>
        <div class="editor-container">
            <div id="python-editor"></div>
        </div>
    </div>
</div>

<!-- Monaco Editor -->
<script src="https://cdn.jsdelivr.net/npm/monaco-editor@0.45.0/min/vs/loader.js"></script>

<script type="module">
    // Load from demo directory with cache busting
    const basePath = '../demo/';
    const timestamp = Date.now();
    
    import(basePath + 'index.js?v=' + timestamp).then(({ init }) => {
        // Load Monaco Editor
        require.config({ 
            paths: { 
                'vs': 'https://cdn.jsdelivr.net/npm/monaco-editor@0.45.0/min/vs' 
            } 
        });
        
        require(['vs/editor/editor.main'], async function() {
            console.log('Monaco Editor loaded in MkDocs');
            
            // Make monaco globally accessible
            window.monaco = monaco;
            
            await new Promise(resolve => setTimeout(resolve, 100));
            
            try {
                const swift = await init();
                console.log('Swift WASM initialized in MkDocs!');
            } catch (error) {
                console.error('Failed to initialize Swift WASM:', error);
            }
        });
    });
</script>
