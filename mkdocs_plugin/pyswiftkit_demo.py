"""
PySwiftKit Demo Plugin for MkDocs

This plugin integrates the Swift WASM Monaco Editor into MkDocs pages,
allowing interactive demonstration of PySwiftKit decorators and Python API generation.

Includes support for serving gzip-compressed WASM files for faster loading.
"""

import os
from pathlib import Path
from mkdocs.plugins import BasePlugin
from mkdocs.config import config_options


class PySwiftKitDemoPlugin(BasePlugin):
    """
    MkDocs plugin that injects Monaco Editor with Swift WASM support.
    
    Usage in mkdocs.yml:
        plugins:
          - pyswiftkit_demo:
              wasm_path: "assets/wasm"
    """
    
    config_scheme = (
        ('wasm_path', config_options.Type(str, default='assets/wasm')),
        ('enable_on', config_options.Type(list, default=['demo', 'playground'])),
    )
    
    def __init__(self):
        self.wasm_files_copied = False
        self.plugin_dir = Path(__file__).parent
        
    def on_config(self, config):
        """
        Called once during MkDocs config phase.
        Set up paths and verify WASM files exist.
        """
        self.wasm_path = self.config['wasm_path']
        self.enable_on = self.config['enable_on']
        
        # Add demo directory to watch list for live reload (build.sh outputs here)
        demo_dir = self.plugin_dir.parent / 'demo'
        if demo_dir.exists():
            if 'watch' not in config:
                config['watch'] = []
            config['watch'].append(str(demo_dir))
            print(f"PySwiftKit Plugin: Watching {demo_dir} for changes (run ./build.sh to trigger reload)")
        
        # Find WASM files in demo directory (built by build.sh)
        wasm_build_dir = self.plugin_dir.parent / 'demo'
        self.wasm_file = wasm_build_dir / 'PySwiftKitDemo.wasm'
        self.wasm_gz_file = wasm_build_dir / 'PySwiftKitDemo.wasm.gz'
        
        if not self.wasm_file.exists() and not self.wasm_gz_file.exists():
            print(f"⚠️  Warning: WASM build not found at {self.wasm_file}")
            print(f"   Run ./build.sh to build the WASM module")
        elif self.wasm_gz_file.exists():
            print(f"PySwiftKit Plugin: Gzip-compressed WASM found at {wasm_build_dir}")
        else:
            print(f"PySwiftKit Plugin: WASM files found at {wasm_build_dir}")
        
        return config
    
    def on_pre_build(self, config):
        """
        Copy WASM files to docs directory before build.
        """
        if not self.wasm_file.exists() and not self.wasm_gz_file.exists():
            print("PySwiftKit Plugin: Skipping WASM copy (files not found)")
            return
        
        # Copy entire demo directory to docs
        import shutil
        source_dir = self.plugin_dir.parent / 'demo'
        docs_dir = Path(config['docs_dir']) / 'demo'
        
        print(f"PySwiftKit Plugin: Copying WASM files to docs directory...")
        if docs_dir.exists():
            shutil.rmtree(docs_dir)
        shutil.copytree(source_dir, docs_dir)
        print(f"PySwiftKit Plugin: WASM files available at {docs_dir}")
        
    def on_files(self, files, config):
        """
        Called after files are collected. Ensure WASM files are included.
        """
        print(f"PySwiftKit Plugin: Preparing WASM files...")
        return files
    
    def on_post_build(self, config):
        """
        Copy WASM files to the output directory after build.
        Also set up a custom server handler for gzip compression.
        """
        if not self.wasm_file.exists() and not self.wasm_gz_file.exists():
            return
        
        # Copy demo directory to site output
        import shutil
        source_dir = self.plugin_dir.parent / 'demo'
        site_dir = Path(config['site_dir'])
        output_dir = site_dir / 'demo'
        
        print(f"PySwiftKit Plugin: Copying WASM files from {source_dir} to {output_dir}")
        if output_dir.exists():
            shutil.rmtree(output_dir)
        shutil.copytree(source_dir, output_dir)
        
        # Check if gzip compressed version exists
        wasm_gz = output_dir / 'PySwiftKitDemo.wasm.gz'
        if wasm_gz.exists():
            print(f"PySwiftKit Plugin: Gzip compressed WASM available ({wasm_gz.stat().st_size / 1024 / 1024:.1f}MB)")
            print(f"   Tip: Browsers will automatically decompress .gz files")
        
        print(f"PySwiftKit Plugin: WASM files copied successfully")
    
    def on_serve(self, server, config, builder):
        """
        Hook into the development server to add Brotli support.
        Also watch the demo directory for changes.
        """
        print(f"PySwiftKit Plugin: on_serve called with server type: {type(server)}")
        
        # Watch the demo directory for changes
        demo_dir = self.plugin_dir.parent / 'demo'
        templates_dir = self.plugin_dir.parent / 'templates'
        
        if demo_dir.exists():
            try:
                server.watch(str(demo_dir))
                print(f"PySwiftKit Plugin: Watching {demo_dir} for changes")
            except Exception as e:
                print(f"PySwiftKit Plugin: Failed to watch {demo_dir}: {e}")
        
        if templates_dir.exists():
            try:
                server.watch(str(templates_dir))
                print(f"PySwiftKit Plugin: Watching {templates_dir} for changes")
            except Exception as e:
                print(f"PySwiftKit Plugin: Failed to watch {templates_dir}: {e}")
        
        # Store original _serve_request method
        original_serve_request = server._serve_request
        
        def custom_serve_request(environ, start_response):
            """Intercept .wasm requests and serve .wasm.gz if available."""
            path = environ.get("PATH_INFO", "")
            
            if path.endswith(".wasm"):
                # Convert WSGI path to filesystem path
                rel_path = path[len(server.mount_path):] if path.startswith(server.mount_path) else path.lstrip("/")
                wasm_file = os.path.join(server.root, rel_path)
                gz_file = wasm_file + ".gz"
                
                # If .wasm doesn't exist but .gz does, serve the gzip version
                if not os.path.exists(wasm_file) and os.path.exists(gz_file):
                    try:
                        with open(gz_file, 'rb') as f:
                            content = f.read()
                        
                        headers = [
                            ("Content-Type", "application/wasm"),
                            ("Content-Encoding", "gzip"),
                            ("Content-Length", str(len(content))),
                            ("Cross-Origin-Embedder-Policy", "require-corp"),
                            ("Cross-Origin-Opener-Policy", "same-origin"),
                        ]
                        start_response("200 OK", headers)
                        return [content]
                    except Exception:
                        # Fall through to 404
                        pass
            
            # Pass through to original handler for all other requests
            return original_serve_request(environ, start_response)
        
        # Replace the _serve_request method
        server._serve_request = custom_serve_request
        
        return server
        
    def on_page_content(self, html, page, config, files):
        """
        Inject Monaco Editor and WASM loader into specific pages.
        """
        # Check if this page should have the editor
        page_path = page.file.src_path
        should_inject = any(pattern in page_path for pattern in self.enable_on)
        
        if not should_inject:
            return html
        
        # Generate the editor HTML
        editor_html = self._generate_editor_html()
        
        # Inject before closing body tag or append
        if '</body>' in html:
            html = html.replace('</body>', f'{editor_html}</body>')
        else:
            html += editor_html
        
        return html
    
    def _generate_editor_html(self):
        """Generate the HTML/JS for the Monaco Editor integration."""
        return f"""
        <div id="pyswiftkit-demo" style="margin: 2rem 0;">
            <style>
                #pyswiftkit-container {{
                    display: flex;
                    height: 600px;
                    border: 1px solid #ddd;
                    border-radius: 8px;
                    overflow: hidden;
                    background: #1e1e1e;
                }}
                
                .pyswift-editor-panel {{
                    flex: 1;
                    display: flex;
                    flex-direction: column;
                }}
                
                .pyswift-panel-header {{
                    background: #2d2d30;
                    padding: 0.75rem 1rem;
                    border-bottom: 1px solid #3e3e42;
                    color: #cccccc;
                    font-weight: 500;
                    font-size: 0.875rem;
                }}
                
                .pyswift-editor {{
                    flex: 1;
                }}
                
                #pyswift-loading {{
                    position: absolute;
                    top: 50%;
                    left: 50%;
                    transform: translate(-50%, -50%);
                    text-align: center;
                    color: #888;
                }}
            </style>
            
            <div id="pyswiftkit-container">
                <div id="pyswift-loading">Loading Monaco Editor...</div>
                <div class="pyswift-editor-panel" style="display:none;">
                    <div class="pyswift-panel-header">Swift with PySwiftKit Decorators</div>
                    <div id="swift-editor" class="pyswift-editor"></div>
                </div>
                <div class="pyswift-editor-panel" style="display:none;">
                    <div class="pyswift-panel-header">Generated Python API</div>
                    <div id="python-editor" class="pyswift-editor"></div>
                </div>
            </div>
        </div>
        
        <script src="https://cdn.jsdelivr.net/npm/monaco-editor@0.45.0/min/vs/loader.js"></script>
        <script>
            require.config({{ paths: {{ 'vs': 'https://cdn.jsdelivr.net/npm/monaco-editor@0.45.0/min/vs' }} }});
            
            require(['vs/editor/editor.main'], function() {{
                document.getElementById('pyswift-loading').style.display = 'none';
                document.querySelectorAll('.pyswift-editor-panel').forEach(el => el.style.display = 'flex');
                
                // Load WASM module
                const script = document.createElement('script');
                script.src = '/{self.wasm_path}/PySwiftKitDemo.js';
                script.onload = async function() {{
                    if (window.initSwiftWasm) {{
                        await window.initSwiftWasm();
                    }}
                }};
                document.head.appendChild(script);
            }});
        </script>
        """


def get_plugin():
    """Entry point for MkDocs plugin discovery."""
    return PySwiftKitDemoPlugin
