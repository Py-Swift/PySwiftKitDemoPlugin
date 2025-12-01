"""
PySwiftKit MkDocs Plugin
Stage 1: Basic plugin structure that serves WASM files
"""
from mkdocs.plugins import BasePlugin
from mkdocs.config import config_options
import os
import shutil

class PySwiftKitPlugin(BasePlugin):
    config_scheme = (
        ('wasm_path', config_options.Type(str, default='demo')),
    )
    
    def on_config(self, config):
        """Add demo directory to docs_dir for serving"""
        # Copy WASM files to docs directory so they're served during development
        wasm_source = os.path.join(os.getcwd(), self.config['wasm_path'])
        docs_dir = config['docs_dir']
        wasm_dest = os.path.join(docs_dir, 'demo')
        
        if os.path.exists(wasm_source) and os.path.isdir(wasm_source):
            print(f"PySwiftKit Plugin: Copying WASM files to docs directory...")
            if os.path.exists(wasm_dest):
                shutil.rmtree(wasm_dest)
            shutil.copytree(wasm_source, wasm_dest)
            print(f"PySwiftKit Plugin: WASM files available at {wasm_dest}")
        
        return config
    
    def on_pre_build(self, config):
        """Copy WASM files to site directory before build"""
        print("PySwiftKit Plugin: Preparing WASM files...")
        
    def on_post_build(self, config):
        """Ensure WASM files are in output site directory"""
        wasm_source = os.path.join(os.getcwd(), self.config['wasm_path'])
        site_dir = config['site_dir']
        wasm_dest = os.path.join(site_dir, 'demo')
        
        if os.path.exists(wasm_source) and os.path.isdir(wasm_source):
            print(f"PySwiftKit Plugin: Copying WASM files from {wasm_source} to {wasm_dest}")
            if os.path.exists(wasm_dest):
                shutil.rmtree(wasm_dest)
            shutil.copytree(wasm_source, wasm_dest)
            print("PySwiftKit Plugin: WASM files copied successfully")
        else:
            print(f"PySwiftKit Plugin: Warning - WASM directory not found: {wasm_source}")
