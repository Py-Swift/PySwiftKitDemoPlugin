import SwiftSyntax

/// Custom Swift code formatter for WASM environment
/// Handles indentation and formatting when SwiftSyntax's .formatted() is unavailable
public enum SwiftCodeFormatter {
    
    /// Format SourceFileSyntax with proper indentation
    public static func format(_ sourceFile: SourceFileSyntax) -> String {
        let formatter = SourceFileFormatter()
        return formatter.format(sourceFile)
    }
}

/// Formatter for SourceFileSyntax
private class SourceFileFormatter {
    private var indentLevel = 0
    private let indentString = "    " // 4 spaces
    
    func format(_ sourceFile: SourceFileSyntax) -> String {
        var output = ""
        
        for (index, item) in sourceFile.statements.enumerated() {
            if index > 0 {
                output += "\n"
            }
            output += formatCodeBlockItem(item)
        }
        
        return output
    }
    
    private func formatCodeBlockItem(_ item: CodeBlockItemSyntax) -> String {
        switch item.item {
        case .decl(let decl):
            return formatDecl(decl)
        default:
            return item.description
        }
    }
    
    private func formatDecl(_ decl: DeclSyntax) -> String {
        if let importDecl = decl.as(ImportDeclSyntax.self) {
            return formatImportDecl(importDecl)
        } else if let classDecl = decl.as(ClassDeclSyntax.self) {
            return formatClassDecl(classDecl)
        }
        return decl.description
    }
    
    private func formatImportDecl(_ importDecl: ImportDeclSyntax) -> String {
        return "import \(importDecl.path.map { $0.name.text }.joined(separator: "."))"
    }
    
    private func formatClassDecl(_ classDecl: ClassDeclSyntax) -> String {
        var output = ""
        
        // Format attributes (@PyClass)
        for attr in classDecl.attributes {
            output += indent() + "@\(attr.trimmedDescription.dropFirst())\n"
        }
        
        // Format modifiers and class keyword
        output += indent()
        for modifier in classDecl.modifiers {
            output += "\(modifier.name.text) "
        }
        output += "class \(classDecl.name.text) {\n"
        
        // Format members
        indentLevel += 1
        for (index, member) in classDecl.memberBlock.members.enumerated() {
            if index > 0 {
                output += "\n"
            }
            output += formatMemberBlockItem(member)
        }
        indentLevel -= 1
        
        output += indent() + "}\n"
        
        return output
    }
    
    private func formatMemberBlockItem(_ item: MemberBlockItemSyntax) -> String {
        if let varDecl = item.decl.as(VariableDeclSyntax.self) {
            return formatVariableDecl(varDecl)
        } else if let initDecl = item.decl.as(InitializerDeclSyntax.self) {
            return formatInitializerDecl(initDecl)
        } else if let funcDecl = item.decl.as(FunctionDeclSyntax.self) {
            return formatFunctionDecl(funcDecl)
        }
        return item.description
    }
    
    private func formatVariableDecl(_ varDecl: VariableDeclSyntax) -> String {
        var output = ""
        
        // Format attributes (@PyProperty)
        for attr in varDecl.attributes {
            output += indent() + "@\(attr.trimmedDescription.dropFirst())\n"
        }
        
        // Format modifiers and var keyword
        output += indent()
        for modifier in varDecl.modifiers {
            output += "\(modifier.name.text) "
        }
        output += "\(varDecl.bindingSpecifier.text) "
        
        // Format bindings
        for binding in varDecl.bindings {
            if let pattern = binding.pattern.as(IdentifierPatternSyntax.self) {
                output += pattern.identifier.text
            }
            if let typeAnnotation = binding.typeAnnotation {
                output += ": \(typeAnnotation.type.trimmedDescription)"
            }
        }
        
        output += "\n"
        return output
    }
    
    private func formatInitializerDecl(_ initDecl: InitializerDeclSyntax) -> String {
        var output = ""
        
        // Format attributes (@PyInit)
        for attr in initDecl.attributes {
            output += indent() + "@\(attr.trimmedDescription.dropFirst())\n"
        }
        
        // Format modifiers and init keyword
        output += indent()
        for modifier in initDecl.modifiers {
            output += "\(modifier.name.text) "
        }
        output += "init"
        
        // Format parameters
        output += formatFunctionParameters(initDecl.signature.parameterClause)
        
        // Format body
        output += " {\n"
        output += indent() + "}\n"
        
        return output
    }
    
    private func formatFunctionDecl(_ funcDecl: FunctionDeclSyntax) -> String {
        var output = ""
        
        // Format attributes (@PyMethod)
        for attr in funcDecl.attributes {
            output += indent() + "@\(attr.trimmedDescription.dropFirst())\n"
        }
        
        // Format modifiers and func keyword
        output += indent()
        for modifier in funcDecl.modifiers {
            output += "\(modifier.name.text) "
        }
        output += "func \(funcDecl.name.text)"
        
        // Format parameters
        output += formatFunctionParameters(funcDecl.signature.parameterClause)
        
        // Format return type
        if let returnClause = funcDecl.signature.returnClause {
            output += " -> \(returnClause.type.trimmedDescription)"
        }
        
        // Format body
        output += " {\n"
        output += indent() + "}\n"
        
        return output
    }
    
    private func formatFunctionParameters(_ paramClause: FunctionParameterClauseSyntax) -> String {
        var output = "("
        
        for (index, param) in paramClause.parameters.enumerated() {
            if index > 0 {
                output += ", "
            }
            output += param.firstName.text
            output += ": \(param.type.trimmedDescription)"
        }
        
        output += ")"
        return output
    }
    
    private func indent() -> String {
        String(repeating: indentString, count: indentLevel)
    }
}
