// JavaScriptKit WASM Loader with gzip decompression support
async function loadSwiftWasm(wasmPath) {
    // Always try .wasm.gz first (we only deploy compressed files)
    let response = await fetch(wasmPath + '.gz');
    let buffer;
    
    if (response.ok) {
        // Decompress gzipped WASM using browser's native DecompressionStream
        const compressed = await response.arrayBuffer();
        const decompressedStream = new Response(
            new Response(compressed).body.pipeThrough(
                new DecompressionStream('gzip')
            )
        );
        buffer = await decompressedStream.arrayBuffer();
    } else {
        throw new Error(`Failed to load ${wasmPath}.gz: ${response.status} ${response.statusText}`);
    }
    
    // JavaScriptKit runtime state
    const runtime = {
        objects: new Map(),
        nextId: 1,
        stringBuffer: null
    };
    
    const importObject = {
        javascript_kit: {
            swift_retain_object: (id) => {
                // Object is already in map, just keep it
            },
            swift_release_object: (id) => {
                // Can remove from map when no longer needed
                // runtime.objects.delete(id);
            },
            swift_call_host: (hostFuncId, argv, argc, callbackFuncRef) => {
                // Host function callback mechanism
                return 0;
            },
            swift_get_member: (objId, propPtr, propLen) => {
                const obj = runtime.objects.get(objId);
                const prop = getString(propPtr, propLen);
                const value = obj[prop];
                return storeValue(value);
            },
            swift_set_member: (objId, propPtr, propLen, valueId) => {
                const obj = runtime.objects.get(objId);
                const prop = getString(propPtr, propLen);
                const value = runtime.objects.get(valueId);
                obj[prop] = value;
            },
            swift_call_function: (funcId, argv, argc) => {
                const func = runtime.objects.get(funcId);
                const args = [];
                for (let i = 0; i < argc; i++) {
                    const argId = new DataView(memory.buffer).getUint32(argv + i * 4, true);
                    args.push(runtime.objects.get(argId));
                }
                const result = func(...args);
                return storeValue(result);
            },
        },
        'bjs:swift': {
            'js_make_js_string': (ptr, len) => {
                const str = getString(ptr, len);
                return storeValue(str);
            },
        },
        wasi_snapshot_preview1: {
            fd_write: (fd, iovs, iovsLen, nwritten) => {
                let written = 0;
                const view = new DataView(memory.buffer);
                for (let i = 0; i < iovsLen; i++) {
                    const ptr = view.getUint32(iovs + i * 8, true);
                    const len = view.getUint32(iovs + i * 8 + 4, true);
                    written += len;
                }
                view.setUint32(nwritten, written, true);
                return 0;
            },
            fd_read: () => 0,
            fd_close: () => 0,
            fd_seek: () => 0,
            proc_exit: (code) => {
                console.log('Process exit:', code);
            },
            environ_sizes_get: (environc, environBufSize) => {
                const view = new DataView(memory.buffer);
                view.setUint32(environc, 0, true);
                view.setUint32(environBufSize, 0, true);
                return 0;
            },
            environ_get: () => 0,
        }
    };
    
    let memory;
    
    function getString(ptr, len) {
        const bytes = new Uint8Array(memory.buffer, ptr, len);
        return new TextDecoder().decode(bytes);
    }
    
    function storeValue(value) {
        const id = runtime.nextId++;
        runtime.objects.set(id, value);
        return id;
    }
    
    const { instance } = await WebAssembly.instantiate(buffer, importObject);
    memory = instance.exports.memory;
    
    // Store global object
    runtime.objects.set(0, globalThis);
    
    return instance;
}

// Initialize WASM module
window.initSwiftWasm = async function(wasmPath) {
    try {
        console.log('Loading Swift WASM module...');
        // Use provided path or default to same directory as this script
        if (!wasmPath) {
            wasmPath = './PySwiftKitDemo.wasm';
        }
        const instance = await loadSwiftWasm(wasmPath);
        
        // Call main if exported
        if (instance.exports._start) {
            instance.exports._start();
        } else if (instance.exports.main) {
            instance.exports.main();
        }
        
        console.log('Swift WASM module loaded successfully');
        return instance;
    } catch (error) {
        console.error('Failed to load Swift WASM:', error);
        throw error;
    }
};
