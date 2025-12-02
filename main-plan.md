# New mkdocs plugin


# tools/packages needed/required


# python/mkdocs
* run the javascript as plugins with mkdocs

# javascript

* https://microsoft.github.io/monaco-editor/

# swift-wasm

* https://github.com/Py-Swift/PySwiftAST
* https://github.com/swiftwasm/JavaScriptKit


# research

https://microsoft.github.io/monaco-editor/playground.html?source=v0.55.1#example-creating-the-editor-hello-world

https://github.com/Py-Swift/PyFileGenerator/tree/master/Sources/Generator

https://swiftpackageindex.com/swiftwasm/javascriptkit/0.37.0/tutorials/javascriptkit/hello-world


# swift wasm building

https://github.com/Py-Swift/MobileWheelsDatabase/blob/master/build.sh

-Xswiftc -Xclang-linker -Xswiftc -mexec-model=reactor
is only needed for reactor 
we making standalone running main wasm module.


# goal

create a swift-wasm mkdocs plugin that showcase a monaco editor window
example swift syntax on the left using PySwiftKit decorators and then on the right the python api/structure, that represent the python wrapped 
swift class / struct / functions / properties..

https://github.com/Py-Swift/PySwiftKit/blob/master/README.md


# Stage 1

* create a swift wasm environment using javascriptkit, that launches a monaco editor view in the browser.
* assuming that its not needed to run it as a router, but just main
* create a js closure for text changes callback

# Stage 2

* implement PySwiftAst/PyCodeGenerator

# Stage 3

* create the part where same thing from PyFileGenerator, is generating python code based on the PySwiftKit decorators
* working as mkdoc plugin and mkdoc page displaying it
* in PyFileGenerator i handled @PyProperty so it detects if example if let , then getter only, normal var is get/set, same if computed property and it has a set {}, but if only a get {} then it should be getter only

# Stage 4

* js closures for monaco completion providers ect.
* provide completion handlers for @PyClass, @PyMethod, @PyProperty, @PyModule, @PyFunction macroes
* is it possible to add some kind of swift lsp also ?


# Stage 5

* implement PySwiftIDE / MonacoAPI
