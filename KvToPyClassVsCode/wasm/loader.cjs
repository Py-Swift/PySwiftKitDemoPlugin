/**
 * CommonJS WASM Loader for Node.js/VSCode Extension
 * Dynamically imports ESM modules using Node.js module system
 */

const fs = require('fs');
const path = require('path');
const zlib = require('zlib');

/**
 * Load and initialize the Swift WASM module
 */
async function loadWasm() {
    try {
        // Read compressed WASM
        const wasmGzPath = path.join(__dirname, 'KvToPyClassVsCodeExtension.wasm.gz');
        const compressedData = fs.readFileSync(wasmGzPath);
        const wasmData = zlib.gunzipSync(compressedData);
        
        // Use dynamic import to load ESM modules
        const runtimePath = 'file://' + path.join(__dirname, 'runtime.js');
        const { SwiftRuntime } = await import(runtimePath);
        
        const { WASI } = require('wasi');
        const wasi = new WASI({
            version: 'preview1',
            args: [],
            env: process.env,
            preopens: {}
        });
        
        // Create Swift runtime
        const swift = new SwiftRuntime({});
        
        // Add BridgeJS stubs (legacy compatibility)
        const unexpectedBjsCall = () => { throw new Error("Unexpected call to BridgeJS function") };
        const bjsStubs = {
            swift_js_return_string: unexpectedBjsCall,
            swift_js_init_memory: unexpectedBjsCall,
            swift_js_make_js_string: unexpectedBjsCall,
            swift_js_init_memory_with_result: unexpectedBjsCall,
            swift_js_throw: unexpectedBjsCall,
            swift_js_retain: unexpectedBjsCall,
            swift_js_release: unexpectedBjsCall,
            swift_js_push_tag: unexpectedBjsCall,
            swift_js_push_int: unexpectedBjsCall,
            swift_js_push_f32: unexpectedBjsCall,
            swift_js_push_f64: unexpectedBjsCall,
            swift_js_push_string: unexpectedBjsCall,
            swift_js_pop_param_int32: unexpectedBjsCall,
            swift_js_pop_param_f32: unexpectedBjsCall,
            swift_js_pop_param_f64: unexpectedBjsCall,
            swift_js_return_optional_bool: unexpectedBjsCall,
            swift_js_return_optional_int: unexpectedBjsCall,
            swift_js_return_optional_string: unexpectedBjsCall,
            swift_js_return_optional_double: unexpectedBjsCall,
            swift_js_return_optional_float: unexpectedBjsCall,
            swift_js_return_optional_heap_object: unexpectedBjsCall,
            swift_js_return_optional_object: unexpectedBjsCall,
            swift_js_get_optional_int_presence: unexpectedBjsCall,
            swift_js_get_optional_int_value: unexpectedBjsCall,
            swift_js_get_optional_string: unexpectedBjsCall,
            swift_js_get_optional_float_presence: unexpectedBjsCall,
            swift_js_get_optional_float_value: unexpectedBjsCall,
            swift_js_get_optional_double_presence: unexpectedBjsCall,
            swift_js_get_optional_double_value: unexpectedBjsCall,
            swift_js_get_optional_heap_object_pointer: unexpectedBjsCall,
        };
        
        // Create imports
        const imports = {
            wasi_snapshot_preview1: wasi.wasiImport,
            javascript_kit: swift.wasmImports,
            bjs: bjsStubs
        };
        
        // Compile and instantiate WASM
        const wasmModule = await WebAssembly.compile(wasmData);
        const instance = await WebAssembly.instantiate(wasmModule, imports);
        
        // Initialize WASI and Swift runtime
        wasi.initialize(instance);
        swift.setInstance(instance);
        
        // Call main
        if (swift.main) {
            swift.main();
        } else if (instance.exports._start) {
            instance.exports._start();
        } else if (instance.exports.main) {
            instance.exports.main();
        }
        
        // Give Swift time to expose global functions
        await new Promise(resolve => setTimeout(resolve, 300));
        
        return {
            instance,
            swift,
            wasi,
            ready: true
        };
    } catch (error) {
        console.error('[WASM Loader] Failed to load:', error);
        throw error;
    }
}

module.exports = { loadWasm };
