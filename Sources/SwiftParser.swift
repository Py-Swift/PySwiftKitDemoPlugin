import PySwiftAST
import PySwiftCodeGen
import SwiftSyntax
import SwiftParser

/// Swift to Python code generator using SwiftSyntax and PySwiftAST
enum SwiftToPythonGenerator {
    
    /// Generate Python stub code from Swift source
    static func generatePythonStub(from swiftCode: String) -> String {
        print("Parsing Swift code with SwiftSyntax...")
        
        do {
            // Parse Swift code using SwiftSyntax (like PyFileGenerator)
            let sourceFile = Parser.parse(source: swiftCode)
            
            // Build Python AST from Swift AST
            let pythonAST = try buildPythonAST(from: sourceFile)
            
            // Generate Python code from AST
            let pythonCode = generatePythonCode(from: pythonAST)
            
            return pythonCode
            
        } catch {
            return """
# Error parsing Swift code
# \(error)

# Please check your Swift syntax and PySwiftKit decorators
"""
        }
    }
    
    /// Build Python AST from Swift SourceFileSyntax using PySwiftAST
    private static func buildPythonAST(from sourceFile: SourceFileSyntax) throws -> Module {
        var statements: [Statement] = []
        
        // Extract all @PyClass decorated classes
        for statement in sourceFile.statements {
            guard let decl = statement.item.as(DeclSyntax.self),
                  let classDecl = decl.as(ClassDeclSyntax.self) else {
                continue
            }
            
            // Check for @PyClass attribute (like PyFileGenerator does)
            let hasPyClass = classDecl.attributes.contains { attr in
                attr.trimmedDescription.contains("@PyClass")
            }
            
            if hasPyClass {
                // Add blank line between classes (if not first)
                if !statements.isEmpty {
                    statements.append(.blank(2))
                }
                let classStmt = try buildClassDef(from: classDecl)
                statements.append(classStmt)
            }
        }
        
        return .module(statements)
    }
    
    /// Build ClassDef from ClassDeclSyntax
    private static func buildClassDef(from classDecl: ClassDeclSyntax) throws -> Statement {
        let className = classDecl.name.text
        var body: [Statement] = []
        var addedAnyMember = false
        
        // Parse class members
        for member in classDecl.memberBlock.members {
            let decl = member.decl
            var memberAdded = false
            
            // Handle @PyInit (constructors -> __init__)
            if let initDecl = decl.as(InitializerDeclSyntax.self) {
                let hasPyInit = initDecl.attributes.contains { attr in
                    attr.trimmedDescription.contains("@PyInit")
                }
                if hasPyInit {
                    // Add blank line before this member (if not first)
                    if addedAnyMember {
                        body.append(.blank())
                    }
                    let initFunc = try buildInitFunction(from: initDecl)
                    body.append(initFunc)
                    memberAdded = true
                }
            }
            
            // Handle @PyMethod (methods)
            if let funcDecl = decl.as(FunctionDeclSyntax.self), !memberAdded {
                let hasPyMethod = funcDecl.attributes.contains { attr in
                    attr.trimmedDescription.contains("@PyMethod")
                }
                if hasPyMethod {
                    // Add blank line before this member (if not first)
                    if addedAnyMember {
                        body.append(.blank())
                    }
                    let method = try buildMethodFunction(from: funcDecl)
                    body.append(method)
                    memberAdded = true
                }
            }
            
            // Handle @PyProperty (properties)
            if let varDecl = decl.as(VariableDeclSyntax.self), !memberAdded {
                let hasPyProperty = varDecl.attributes.contains { attr in
                    attr.trimmedDescription.contains("@PyProperty")
                }
                if hasPyProperty {
                    // Add blank line before this member (if not first)
                    if addedAnyMember {
                        body.append(.blank())
                    }
                    let propertyStatements = try buildPropertyStatements(from: varDecl)
                    body.append(contentsOf: propertyStatements)
                    memberAdded = true
                }
            }
            
            if memberAdded {
                addedAnyMember = true
            }
        }
        
        // Add default pass if body is empty
        if body.isEmpty {
            body.append(.pass(Pass(lineno: 0, colOffset: 0, endLineno: nil, endColOffset: nil)))
        }
        
        return .classDef(ClassDef(
            name: className,
            bases: [],
            keywords: [],
            body: body,
            decoratorList: [],
            typeParams: [],
            lineno: 0,
            colOffset: 0,
            endLineno: nil,
            endColOffset: nil
        ))
    }
    
    /// Build __init__ FunctionDef from InitializerDeclSyntax
    private static func buildInitFunction(from initDecl: InitializerDeclSyntax) throws -> Statement {
        let signature = initDecl.signature
        var args: [Arg] = []
        
        // Add 'self' parameter
        args.append(Arg(
            arg: "self",
            annotation: nil,
            typeComment: nil
        ))
        
        // Add parameters
        for param in signature.parameterClause.parameters {
            let paramName = (param.secondName ?? param.firstName).text
            let annotation = swiftTypeToExpression(param.type)
            
            args.append(Arg(
                arg: paramName,
                annotation: annotation,
                typeComment: nil
            ))
        }
        
        let arguments = Arguments(
            posonlyArgs: [],
            args: args,
            vararg: nil,
            kwonlyArgs: [],
            kwDefaults: [],
            kwarg: nil,
            defaults: []
        )
        
        return .functionDef(FunctionDef(
            name: "__init__",
            args: arguments,
            body: [.pass(Pass(lineno: 0, colOffset: 0, endLineno: nil, endColOffset: nil))],
            decoratorList: [],
            returns: nil,
            typeComment: nil,
            typeParams: [],
            lineno: 0,
            colOffset: 0,
            endLineno: nil,
            endColOffset: nil
        ))
    }
    
    /// Build method FunctionDef from FunctionDeclSyntax
    private static func buildMethodFunction(from funcDecl: FunctionDeclSyntax) throws -> Statement {
        let methodName = funcDecl.name.text
        let signature = funcDecl.signature
        var args: [Arg] = []
        var decorators: [Expression] = []
        
        // Check if static method
        let isStatic = funcDecl.modifiers.contains { modifier in
            modifier.name.text == "static"
        }
        
        if isStatic {
            decorators.append(.name(Name(
                id: "staticmethod",
                ctx: .load,
                lineno: 0,
                colOffset: 0,
                endLineno: nil,
                endColOffset: nil
            )))
        } else {
            // Add 'self' parameter for instance methods
            args.append(Arg(
                arg: "self",
                annotation: nil,
                typeComment: nil
            ))
        }
        
        // Add parameters
        for param in signature.parameterClause.parameters {
            let paramName = (param.secondName ?? param.firstName).text
            let annotation = swiftTypeToExpression(param.type)
            
            args.append(Arg(
                arg: paramName,
                annotation: annotation,
                typeComment: nil
            ))
        }
        
        let arguments = Arguments(
            posonlyArgs: [],
            args: args,
            vararg: nil,
            kwonlyArgs: [],
            kwDefaults: [],
            kwarg: nil,
            defaults: []
        )
        
        // Parse return type
        let returnType = signature.returnClause.map { returnClause in
            swiftTypeToExpression(returnClause.type)
        }
        
        return .functionDef(FunctionDef(
            name: methodName,
            args: arguments,
            body: [.pass(Pass(lineno: 0, colOffset: 0, endLineno: nil, endColOffset: nil))],
            decoratorList: decorators,
            returns: returnType,
            typeComment: nil,
            typeParams: [],
            lineno: 0,
            colOffset: 0,
            endLineno: nil,
            endColOffset: nil
        ))
    }
    
    /// Build property FunctionDef(s) from VariableDeclSyntax
    /// Handles getter-only and getter+setter detection like PyFileGenerator
    /// Returns array of statements (getter, and optionally setter with blank line)
    private static func buildPropertyStatements(from varDecl: VariableDeclSyntax) throws -> [Statement] {
        guard let binding = varDecl.bindings.first,
              let pattern = binding.pattern.as(IdentifierPatternSyntax.self) else {
            throw ParserError.invalidProperty
        }
        
        let propertyName = pattern.identifier.text
        let annotation = binding.typeAnnotation.map { typeAnnotation in
            swiftTypeToExpression(typeAnnotation.type)
        }
        
        // Determine if property is getter-only or getter+setter
        let propertyType = detectPropertyType(binding: binding, varDecl: varDecl)
        
        var statements: [Statement] = []
        
        // Always create getter
        let getterArgs = Arguments(
            posonlyArgs: [],
            args: [Arg(arg: "self", annotation: nil, typeComment: nil)],
            vararg: nil,
            kwonlyArgs: [],
            kwDefaults: [],
            kwarg: nil,
            defaults: []
        )
        
        let propertyDecorator: Expression = .name(Name(
            id: "property",
            ctx: .load,
            lineno: 0,
            colOffset: 0,
            endLineno: nil,
            endColOffset: nil
        ))
        
        statements.append(.functionDef(FunctionDef(
            name: propertyName,
            args: getterArgs,
            body: [.pass(Pass(lineno: 0, colOffset: 0, endLineno: nil, endColOffset: nil))],
            decoratorList: [propertyDecorator],
            returns: annotation,
            typeComment: nil,
            typeParams: [],
            lineno: 0,
            colOffset: 0,
            endLineno: nil,
            endColOffset: nil
        )))
        
        // Add setter if property is not getter-only
        if propertyType == .getterAndSetter {
            statements.append(.blank())
            
            let setterArgs = Arguments(
                posonlyArgs: [],
                args: [
                    Arg(arg: "self", annotation: nil, typeComment: nil),
                    Arg(arg: "value", annotation: annotation, typeComment: nil)
                ],
                vararg: nil,
                kwonlyArgs: [],
                kwDefaults: [],
                kwarg: nil,
                defaults: []
            )
            
            // Create @propertyName.setter decorator
            let setterDecorator: Expression = .attribute(Attribute(
                value: .name(Name(
                    id: propertyName,
                    ctx: .load,
                    lineno: 0,
                    colOffset: 0,
                    endLineno: nil,
                    endColOffset: nil
                )),
                attr: "setter",
                ctx: .load,
                lineno: 0,
                colOffset: 0,
                endLineno: nil,
                endColOffset: nil
            ))
            
            statements.append(.functionDef(FunctionDef(
                name: propertyName,
                args: setterArgs,
                body: [.pass(Pass(lineno: 0, colOffset: 0, endLineno: nil, endColOffset: nil))],
                decoratorList: [setterDecorator],
                returns: nil,
                typeComment: nil,
                typeParams: [],
                lineno: 0,
                colOffset: 0,
                endLineno: nil,
                endColOffset: nil
            )))
        }
        
        return statements
    }
    
    /// Detect if property is getter-only or getter+setter
    /// Based on PyFileGenerator logic
    private static func detectPropertyType(binding: PatternBindingSyntax, varDecl: VariableDeclSyntax) -> PropertyType {
        // 1. Check for 'if let' binding → getter only
        if let _ = binding.pattern.as(OptionalBindingConditionSyntax.self) {
            return .getterOnly
        }
        
        // 2. Check if it's 'let' declaration → getter only
        if varDecl.bindingSpecifier.tokenKind == .keyword(.let) {
            return .getterOnly
        }
        
        // 3. Check for computed property with accessors
        if let accessorBlock = binding.accessorBlock {
            switch accessorBlock.accessors {
            case .accessors(let accessors):
                // Check if there's a setter accessor
                let hasSetter = accessors.contains { accessor in
                    accessor.accessorSpecifier.tokenKind == .keyword(.set)
                }
                return hasSetter ? .getterAndSetter : .getterOnly
                
            case .getter:
                // Getter-only computed property
                return .getterOnly
            }
        }
        
        // 4. Regular 'var' without explicit accessors → getter + setter
        if varDecl.bindingSpecifier.tokenKind == .keyword(.var) {
            return .getterAndSetter
        }
        
        // Default to getter-only for safety
        return .getterOnly
    }
    
    enum PropertyType {
        case getterOnly
        case getterAndSetter
    }
    
    /// Convert Swift TypeSyntax to Python Expression
    private static func swiftTypeToExpression(_ type: TypeSyntax) -> Expression {
        // Handle identifier types (String, Int, etc.)
        if let identType = type.as(IdentifierTypeSyntax.self) {
            let typeName = identType.name.text
            let pythonType = swiftTypeToPython(typeName)
            return .name(Name(
                id: pythonType,
                ctx: .load,
                lineno: 0,
                colOffset: 0,
                endLineno: nil,
                endColOffset: nil
            ))
        }
        
        // Handle optional types (String? -> Optional[str])
        if let optType = type.as(OptionalTypeSyntax.self) {
            let wrapped = swiftTypeToExpression(optType.wrappedType)
            // Return just the wrapped type for simplicity
            return wrapped
        }
        
        // Handle array types ([String] -> list[str])
        if type.as(ArrayTypeSyntax.self) != nil {
            // For now, just return "list"
            return .name(Name(
                id: "list",
                ctx: .load,
                lineno: 0,
                colOffset: 0,
                endLineno: nil,
                endColOffset: nil
            ))
        }
        
        // Default to "object"
        return .name(Name(
            id: "object",
            ctx: .load,
            lineno: 0,
            colOffset: 0,
            endLineno: nil,
            endColOffset: nil
        ))
    }
    
    /// Map Swift type names to Python type names
    private static func swiftTypeToPython(_ swiftType: String) -> String {
        switch swiftType {
        case "String": return "str"
        case "Int", "Int32", "Int64", "UInt", "UInt32", "UInt64": return "int"
        case "Float", "Double": return "float"
        case "Bool": return "bool"
        case "Void": return "None"
        default: return "object"
        }
    }
    
    enum ParserError: Error {
        case invalidClass
        case invalidProperty
    }
}

// Helper extension to check if Statement is blank
extension Statement {
    var isBlank: Bool {
        if case .blank = self {
            return true
        }
        return false
    }
}
