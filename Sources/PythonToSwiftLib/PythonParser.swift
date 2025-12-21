import SwiftSyntax
import SwiftSyntaxBuilder
import PySwiftAST
import PyAstVisitors
import PySwiftTypeConverter

/// Python to Swift code generator for PySwiftKit
/// Uses PyAstVisitors to traverse Python AST and generate Swift code
public enum PythonToSwiftGenerator {
    
    /// Generate Swift PySwiftKit code from Python code
    public static func generateSwiftCode(from pythonCode: String, customFormatting: Bool = false) -> String {
        do {
            // Parse Python code using PySwiftAST parser
            let module = try parsePython(pythonCode)
            
            // Use visitor to extract class info
            let visitor = SwiftClassVisitor()
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
    
    /// Visitor that extracts class information from Python AST
    /// Uses PyAstVisitors protocol for automatic traversal
    class SwiftClassVisitor: ASTVisitor {
        var classes: [ClassInfo] = []
        private var currentProperties: [PropertyInfo] = []
        private var currentMethods: [MethodInfo] = []
        private var currentInitializer: InitInfo?
        
        func visit(_ node: ClassDef) {
            currentProperties = []
            currentMethods = []
            currentInitializer = nil
            
            // Collect properties and methods from class body
            for statement in node.body {
                // Properties (type annotations)
                if case .annAssign(let annAssign) = statement,
                   case .name(let target) = annAssign.target {
                    currentProperties.append(PropertyInfo(name: target.id, type: annAssign.annotation))
                }
                
                // Methods and __init__
                if case .functionDef(let funcDef) = statement {
                    if funcDef.name == "__init__" {
                        currentInitializer = extractInitInfo(from: funcDef)
                    } else {
                        // Check if it's a @property decorated function
                        let isProperty = funcDef.decoratorList.contains { expr in
                            if case .name(let name) = expr {
                                return name.id == "property"
                            }
                            return false
                        }
                        
                        // Check if it's a @name.setter decorated function
                        let isSetter = funcDef.decoratorList.contains { expr in
                            if case .attribute(let attr) = expr {
                                return attr.attr == "setter"
                            }
                            return false
                        }
                        
                        // Skip setters - they're handled with the getter
                        if !isSetter {
                            if isProperty {
                                // Convert @property function to PropertyInfo
                                let returnType = funcDef.returns ?? .name(Name(id: "object", ctx: .load, lineno: 0, colOffset: 0, endLineno: nil, endColOffset: nil))
                                currentProperties.append(PropertyInfo(name: funcDef.name, type: returnType))
                            } else {
                                currentMethods.append(extractMethodInfo(from: funcDef))
                            }
                        }
                    }
                }
            }
            
            classes.append(ClassInfo(
                name: node.name,
                properties: currentProperties,
                initializer: currentInitializer,
                methods: currentMethods
            ))
        }
        
        private func extractInitInfo(from funcDef: FunctionDef) -> InitInfo {
            var params: [ParameterInfo] = []
            
            // Skip first parameter (self)
            for arg in funcDef.args.args.dropFirst() {
                let paramType = arg.annotation ?? .name(Name(id: "object", ctx: .load, lineno: 0, colOffset: 0, endLineno: nil, endColOffset: nil))
                params.append(ParameterInfo(name: arg.arg, type: paramType))
            }
            
            return InitInfo(parameters: params)
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
    
    struct ClassInfo {
        let name: String
        let properties: [PropertyInfo]
        let initializer: InitInfo?
        let methods: [MethodInfo]
    }
    
    struct PropertyInfo {
        let name: String
        let type: Expression
    }
    
    struct InitInfo {
        let parameters: [ParameterInfo]
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
    
    /// Generate Swift code from extracted class info
    private static func generateSwiftCode(from classes: [ClassInfo], customFormatting: Bool = false) -> String {
        var declarations: [DeclSyntax] = []
        
        // Generate each class
        for classInfo in classes {
            let classDecl = buildClassDecl(from: classInfo)
                .with(\.trailingTrivia, .newline)
            declarations.append(DeclSyntax(classDecl))
        }
        
        let sourceFile = SourceFileSyntax(
            statements: CodeBlockItemListSyntax(
                declarations.map { CodeBlockItemSyntax(item: .decl($0)) }
            )
        )
        
        if customFormatting {
            return "\n\n" + SwiftCodeFormatter.format(sourceFile)
        }
        return "\n\n" + sourceFile.formatted().description
    }
    
    /// Build Swift class declaration from ClassInfo using SwiftSyntax
    private static func buildClassDecl(from classInfo: ClassInfo) -> ClassDeclSyntax {
        var members: [MemberBlockItemSyntax] = []
        
        // Add properties
        for (index, property) in classInfo.properties.enumerated() {
            let propertyDecl = buildPropertyDecl(name: property.name, type: property.type, isFirst: index == 0)
            members.append(propertyDecl)
        }
        
        // Add initializer
        if let initializer = classInfo.initializer {
            members.append(buildInitDecl(from: initializer, needsLeadingNewline: !classInfo.properties.isEmpty))
        }
        
        // Add methods
        for method in classInfo.methods {
            members.append(buildMethodDecl(from: method))
        }
        
        return ClassDeclSyntax(
            attributes: AttributeListSyntax {
                AttributeSyntax(
                    atSign: .atSignToken(),
                    attributeName: IdentifierTypeSyntax(
                        name: .identifier("PyClass", trailingTrivia: .newline)
                    )
                )
            },
            modifiers: DeclModifierListSyntax {
                DeclModifierSyntax(
                    name: .keyword(.public, trailingTrivia: .space)
                )
            },
            classKeyword: .keyword(.class, trailingTrivia: .space),
            name: .identifier(classInfo.name, trailingTrivia: .space),
            memberBlock: MemberBlockSyntax(
                leftBrace: .leftBraceToken(leadingTrivia: .space),
                members: MemberBlockItemListSyntax(members),
                rightBrace: .rightBraceToken(leadingTrivia: .newline)
            )
        )
    }
    
    /// Build property declaration
    private static func buildPropertyDecl(name: String, type: Expression, isFirst: Bool) -> MemberBlockItemSyntax {
        
        return MemberBlockItemSyntax(
            leadingTrivia: .newlines(2),
            decl: VariableDeclSyntax(
                attributes: AttributeListSyntax {
                    AttributeSyntax(
                        atSign: .atSignToken(),
                        attributeName: IdentifierTypeSyntax(
                            name: .identifier("PyProperty", trailingTrivia: .newline)
                        )
                    )
                },
                modifiers: DeclModifierListSyntax {
                    DeclModifierSyntax(
                        name: .keyword(.public, trailingTrivia: .space)
                    )
                },
                bindingSpecifier: .keyword(.var, trailingTrivia: .space),
                bindings: PatternBindingListSyntax {
                    PatternBindingSyntax(
                        pattern: IdentifierPatternSyntax(identifier: .identifier(name)),
                        typeAnnotation: TypeAnnotationSyntax(
                            colon: .colonToken(trailingTrivia: .space),
                            type: PythonTypeConverter.convertToSwiftType(type)
                        )
                    )
                }
            )
        )
    }
    
    /// Build initializer declaration
    private static func buildInitDecl(from initInfo: InitInfo, needsLeadingNewline: Bool) -> MemberBlockItemSyntax {
        let parameters = FunctionParameterListSyntax(
            initInfo.parameters.enumerated().map { index, param in
                FunctionParameterSyntax(
                    firstName: .identifier(param.name),
                    colon: .colonToken(trailingTrivia: .space),
                    type: PythonTypeConverter.convertToSwiftType(param.type),
                    trailingComma: index < initInfo.parameters.count - 1 ? .commaToken(trailingTrivia: .space) : nil
                )
            }
        )
        
        return MemberBlockItemSyntax(
            leadingTrivia: .newlines(2),
            decl: InitializerDeclSyntax(
                attributes: AttributeListSyntax {
                    AttributeSyntax(
                        atSign: .atSignToken(),
                        attributeName: IdentifierTypeSyntax(
                            name: .identifier("PyInit", trailingTrivia: .newline)
                        )
                    )
                },
                modifiers: DeclModifierListSyntax {
                    DeclModifierSyntax(
                        name: .keyword(.public, trailingTrivia: .space)
                    )
                },
                initKeyword: .keyword(.`init`),
                signature: FunctionSignatureSyntax(
                    parameterClause: FunctionParameterClauseSyntax(
                        leftParen: .leftParenToken(),
                        parameters: parameters,
                        rightParen: .rightParenToken(trailingTrivia: .space)
                    )
                ),
                body: CodeBlockSyntax(
                    leftBrace: .leftBraceToken(),
                    statements: CodeBlockItemListSyntax([]),
                    rightBrace: .rightBraceToken(leadingTrivia: .newline)
                )
            )
        )
    }
    
    /// Build method declaration
    private static func buildMethodDecl(from method: MethodInfo) -> MemberBlockItemSyntax {
        var modifiers = DeclModifierListSyntax()
        modifiers.append(DeclModifierSyntax(
            name: .keyword(.public, trailingTrivia: .space)
        ))
        if method.isStatic {
            modifiers.append(DeclModifierSyntax(
                name: .keyword(.static, trailingTrivia: .space)
            ))
        }
        
        let parameters = FunctionParameterListSyntax(
            method.parameters.enumerated().map { index, param in
                FunctionParameterSyntax(
                    firstName: .identifier(param.name),
                    colon: .colonToken(trailingTrivia: .space),
                    type: PythonTypeConverter.convertToSwiftType(param.type),
                    trailingComma: index < method.parameters.count - 1 ? .commaToken(trailingTrivia: .space) : nil
                )
            }
        )
        
        return MemberBlockItemSyntax(
            leadingTrivia: .newlines(2),
            decl: FunctionDeclSyntax(
                attributes: AttributeListSyntax {
                    AttributeSyntax(
                        atSign: .atSignToken(),
                        attributeName: IdentifierTypeSyntax(
                            name: .identifier("PyMethod", trailingTrivia: .newline)
                        )
                    )
                },
                modifiers: modifiers,
                funcKeyword: .keyword(.func, trailingTrivia: .space),
                name: .identifier(method.name),
                signature: FunctionSignatureSyntax(
                    parameterClause: FunctionParameterClauseSyntax(
                        leftParen: .leftParenToken(),
                        parameters: parameters,
                        rightParen: .rightParenToken()
                    ),
                    returnClause: method.returnType.map { returnType in
                        ReturnClauseSyntax(
                            arrow: .arrowToken(leadingTrivia: .space, trailingTrivia: .space),
                            type: PythonTypeConverter.convertToSwiftType(returnType)
                        )
                    }
                ),
                body: CodeBlockSyntax(
                    leftBrace: .leftBraceToken(leadingTrivia: .space),
                    statements: CodeBlockItemListSyntax {
                        
                    },
                    rightBrace: .rightBraceToken(leadingTrivia: .newline)
                )
            )
        )
    }
    
}
