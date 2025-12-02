# Interactive Demo

Try editing the Swift code on the left to see the generated Python API on the right!

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

<div id="wasm-status" style="margin-top: 1rem; padding: 0.5rem; background: #f0f0f0; border-radius: 4px; font-size: 0.9rem;">
    Loading Monaco Editor and Swift WASM...
</div>

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
    background: #1e1e1e;
}

.editor-panel {
    border: 1px solid #3e3e42;
    border-radius: 4px;
    overflow: hidden;
    display: flex;
    flex-direction: column;
    background: #1e1e1e;
}

.editor-header {
    background: #252526;
    padding: 10px;
    font-weight: 500;
    border-bottom: 1px solid #3e3e42;
    color: #cccccc;
    font-size: 0.9rem;
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

<!-- Monaco Editor -->
<script src="https://cdn.jsdelivr.net/npm/monaco-editor@0.45.0/min/vs/loader.js"></script>

<script type="module">
    const status = document.getElementById('wasm-status');
    
    function updateStatus(message, isError = false) {
        status.textContent = message;
        status.style.background = isError ? '#ffebee' : '#e8f5e9';
        status.style.color = isError ? '#c62828' : '#2e7d32';
    }
    
    // Load Monaco Editor first
    require.config({ 
        paths: { 
            'vs': 'https://cdn.jsdelivr.net/npm/monaco-editor@0.45.0/min/vs' 
        } 
    });
    
    require(['vs/editor/editor.main'], async function() {
        console.log('Monaco Editor loaded');
        updateStatus('Monaco Editor loaded, initializing Swift WASM...');
        
        // Make monaco globally accessible before Swift initializes
        window.monaco = monaco;
        
        // Wait for Monaco to be fully ready
        await new Promise(resolve => setTimeout(resolve, 100));
        
        try {
            // Import and initialize Swift WASM
            const basePath = window.location.pathname.includes('/demo') ? '../demo/' : './demo/';
            const { init } = await import(basePath + 'index.js');
            
            console.log('Swift WASM module loaded, calling init...');
            const swift = await init();
            
            console.log('Swift WASM initialized successfully!');
            updateStatus('✅ Swift WASM Ready! Try editing the code on the left.');
            
        } catch (error) {
            console.error('Failed to initialize Swift WASM:', error);
            updateStatus('❌ Error loading Swift WASM: ' + error.message, true);
        }
    });
</script>
