import PySwiftAST
import PyAstVisitors
import SwiftSyntax
import SwiftSyntaxBuilder
import PySwiftTypeConverter

/// Generates Swift wrapper classes for Python data models using @PyContainer
/// This is the inverse of PythonToSwift - it wraps existing Python classes in Swift
public enum PyDataModelGenerator {
    
    /// Generate Swift code from Python code using @PyContainer pattern
    /// - Parameters:
    ///   - pythonCode: Python source code containing class definitions
    ///   - customFormatting: Use custom formatter for WASM (default: false)
    /// - Returns: Generated Swift code with @PyContainer decorators
    public static func generateSwiftCode(from pythonCode: String, customFormatting: Bool = false) -> String {
        do {
            // Parse Python code using PySwiftAST parser
            let module = try parsePython(pythonCode)
            
            // Visit AST and collect classes
            let visitor = SwiftContainerVisitor()
            module.accept(visitor: visitor)
            
            // Generate Swift code from extracted classes
            return generateSwiftCode(from: visitor.classes, customFormatting: customFormatting)
        } catch {
            return """
// Error parsing Python code:
// \(error)

// Please check your Python syntax
"""
        }
    }
    
    /// Generate Swift source file from container classes
    private static func generateSwiftCode(from classes: [ContainerClassInfo], customFormatting: Bool) -> String {
        // Generate Swift source file
        let sourceFile = SourceFileSyntax(
            statements: CodeBlockItemListSyntax {
                // Generate each class
                for classInfo in classes {
                    generateContainerClass(classInfo)
                }
            }
        )
        
        // Format and return
        if customFormatting {
            return "\n\n" + SwiftCodeFormatter.format(sourceFile)
        } else {
            return "\n\n" + sourceFile.formatted().description
        }
    }
    
    /// Generate a Swift wrapper class with @PyContainer
    private static func generateContainerClass(_ classInfo: ContainerClassInfo) -> ClassDeclSyntax {
        let hasProperties = !classInfo.properties.isEmpty
        
        var methods: [FunctionDeclSyntax] = []
        for method in classInfo.methods {
            methods.append(generatePyCallMethod(method))
        }
        
        return ClassDeclSyntax(
            attributes: AttributeListSyntax {
                AttributeSyntax(
                    attributeName: IdentifierTypeSyntax(name: .identifier("PyContainer"))
                )
                if hasProperties {
                    AttributeSyntax(
                        attributeName: IdentifierTypeSyntax(name: .identifier("dynamicMemberLookup"))
                    )
                }
            },
            name: .identifier(classInfo.name),
            memberBlock: MemberBlockSyntax(
                members: MemberBlockItemListSyntax {
                    // Generate @PyCall methods with blank line before first
                    for (index, method) in methods.enumerated() {
                        if index == 0 {
                            MemberBlockItemSyntax(
                                leadingTrivia: .newline,
                                decl: method
                            )
                        } else {
                            MemberBlockItemSyntax(decl: method)
                        }
                    }
                }
            )
        )
    }
    
    /// Generate a method with @PyCall decorator
    private static func generatePyCallMethod(_ method: MethodInfo) -> FunctionDeclSyntax {
        FunctionDeclSyntax(
            attributes: AttributeListSyntax {
                AttributeSyntax(
                    attributeName: IdentifierTypeSyntax(name: .identifier("PyCall"))
                )
            },
            modifiers: DeclModifierListSyntax {
                if method.isStatic {
                    DeclModifierSyntax(name: .keyword(.static))
                }
            },
            name: .identifier(method.name),
            signature: FunctionSignatureSyntax(
                parameterClause: FunctionParameterClauseSyntax(
                    parameters: FunctionParameterListSyntax {
                        for param in method.parameters {
                            FunctionParameterSyntax(
                                firstName: .identifier(param.name),
                                type: PythonTypeConverter.convertToSwiftType(param.type)
                            )
                        }
                    }
                ),
                returnClause: method.returnType.map { returnType in
                    ReturnClauseSyntax(
                        type: PythonTypeConverter.convertToSwiftType(returnType)
                    )
                }
            )
        )
    }
    
    // MARK: - AST Visitor
    
    private class SwiftContainerVisitor: ASTVisitor {
        var classes: [ContainerClassInfo] = []
        
        private var currentProperties: [PropertyInfo] = []
        private var currentMethods: [MethodInfo] = []
        
        func visit(_ node: ClassDef) {
            currentProperties = []
            currentMethods = []
            
            // Collect properties and methods from class body
            for statement in node.body {
                // Properties (type annotations)
                if case .annAssign(let annAssign) = statement,
                   case .name(let target) = annAssign.target {
                    currentProperties.append(PropertyInfo(name: target.id, type: annAssign.annotation))
                }
                
                // Methods (skip __init__ for containers)
                if case .functionDef(let funcDef) = statement {
                    if funcDef.name == "__init__" {
                        // Skip __init__ - containers don't have initializers
                        continue
                    }
                    
                    // Check if it's a @property decorated function - skip for containers
                    let isProperty = funcDef.decoratorList.contains { expr in
                        if case .name(let name) = expr {
                            return name.id == "property"
                        }
                        return false
                    }
                    
                    // Check if it's a @name.setter - skip
                    let isSetter = funcDef.decoratorList.contains { expr in
                        if case .attribute(let attr) = expr {
                            return attr.attr == "setter"
                        }
                        return false
                    }
                    
                    if !isProperty && !isSetter {
                        currentMethods.append(extractMethodInfo(from: funcDef))
                    }
                }
            }
            
            classes.append(ContainerClassInfo(
                name: node.name,
                properties: currentProperties,
                methods: currentMethods
            ))
        }
        
        private func extractMethodInfo(from funcDef: FunctionDef) -> MethodInfo {
            var params: [ParameterInfo] = []
            
            // Check for @staticmethod decorator
            let isStatic = funcDef.decoratorList.contains { expr in
                if case .name(let name) = expr {
                    return name.id == "staticmethod"
                }
                return false
            }
            
            // Skip first parameter (self) for non-static methods
            let argsToProcess = isStatic ? funcDef.args.args : Array(funcDef.args.args.dropFirst())
            
            for arg in argsToProcess {
                let paramType = arg.annotation ?? .name(Name(id: "object", ctx: .load, lineno: 0, colOffset: 0, endLineno: nil, endColOffset: nil))
                params.append(ParameterInfo(name: arg.arg, type: paramType))
            }
            
            let returnType = funcDef.returns
            
            return MethodInfo(
                name: funcDef.name,
                parameters: params,
                returnType: returnType,
                isStatic: isStatic
            )
        }
    }
    
    // MARK: - Data Structures
    
    struct ContainerClassInfo {
        let name: String
        let properties: [PropertyInfo]
        let methods: [MethodInfo]
    }
    
    struct PropertyInfo {
        let name: String
        let type: Expression
    }
    
    struct MethodInfo {
        let name: String
        let parameters: [ParameterInfo]
        let returnType: Expression?
        let isStatic: Bool
    }
    
    struct ParameterInfo {
        let name: String
        let type: Expression
    }
}
