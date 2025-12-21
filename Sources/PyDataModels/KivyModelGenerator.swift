import PySwiftAST
import PyAstVisitors
import PySwiftCodeGen

/// Generates Kivy EventDispatcher models from Python class definitions
public enum KivyModelGenerator {
    
    /// Generates Kivy EventDispatcher code from Python source
    public static func generate(from pythonCode: String) -> String {
        do {
            let module = try parsePython(pythonCode)
            
            // Visit AST and collect class info
            let visitor = KivyClassVisitor()
            module.accept(visitor: visitor)
            
            // Build new Module with Kivy classes
            let kivyModule = buildKivyModule(from: visitor.classes)
            
            // Generate Python code from modified AST
            return generatePythonCode(from: kivyModule)
        } catch {
            return "# Error parsing Python code: \(error)"
        }
    }
    
    /// Build a new Module with Kivy EventDispatcher classes
    private static func buildKivyModule(from classes: [KivyClassInfo]) -> Module {
        var statements: [Statement] = []
        
        // Start with 2 blank lines
        statements.append(.blank(2))
        
        for (index, classInfo) in classes.enumerated() {
            // Add blank line between classes
            if index > 0 {
                statements.append(.blank(2))
            }
            let kivyClass = buildKivyClass(from: classInfo)
            statements.append(kivyClass)
        }
        
        return .module(statements)
    }
    
    /// Build a Kivy EventDispatcher ClassDef
    private static func buildKivyClass(from classInfo: KivyClassInfo) -> Statement {
        var body: [Statement] = []
        
        // Start class body with blank line
        body.append(.blank())
        
        // Add Kivy property assignments (not annotations!)
        for (index, property) in classInfo.properties.enumerated() {
            // Add blank line before each property after the first
            if index > 0 {
                body.append(.blank())
            }
            
            let kivyPropertyName = convertToKivyProperty(property.annotation)
            
            // Create property call: PropertyType(default_value)
            let defaultValue = getDefaultValue(for: property.annotation)
            let propertyCall = Expression.call(Call(
                fun: Expression.name(Name(
                    id: kivyPropertyName,
                    ctx: .load,
                    lineno: 0,
                    colOffset: 0,
                    endLineno: nil,
                    endColOffset: nil
                )),
                args: [defaultValue],
                keywords: [],
                lineno: 0,
                colOffset: 0,
                endLineno: nil,
                endColOffset: nil
            ))
            
            // Create assignment: name = PropertyType(default)
            let assign = Assign(
                targets: [Expression.name(Name(
                    id: property.name,
                    ctx: .store,
                    lineno: 0,
                    colOffset: 0,
                    endLineno: nil,
                    endColOffset: nil
                ))],
                value: propertyCall,
                typeComment: nil,
                lineno: 0,
                colOffset: 0,
                endLineno: nil,
                endColOffset: nil
            )
            
            body.append(.assign(assign))
        }
        
        // Add methods (already filtered, no __init__ or @property)
        for method in classInfo.methods {
            // Add blank line before each method
            body.append(.blank())
            body.append(method.stmt)
        }
        
        // If only blank line, add pass
        if body.count == 1 {
            body.append(.pass(Pass(lineno: 0, colOffset: 0, endLineno: nil, endColOffset: nil)))
        }
        
        // Create ClassDef with EventDispatcher base
        let eventDispatcherBase = Expression.name(Name(
            id: "EventDispatcher",
            ctx: .load,
            lineno: 0,
            colOffset: 0,
            endLineno: nil,
            endColOffset: nil
        ))
        
        let classDef = ClassDef(
            name: classInfo.name,
            bases: [eventDispatcherBase],
            keywords: [],
            body: body,
            decoratorList: [],
            typeParams: [],
            lineno: 0,
            colOffset: 0,
            endLineno: nil,
            endColOffset: nil
        )
        
        return .classDef(classDef)
    }
    
    /// Get default value for Python type
    private static func getDefaultValue(for expr: Expression) -> Expression {
        switch expr {
        case .name(let name):
            switch name.id {
            case "str":
                return .constant(Constant(value: .string(""), kind: nil, lineno: 0, colOffset: 0, endLineno: nil, endColOffset: nil))
            case "int":
                return .constant(Constant(value: .int(0), kind: nil, lineno: 0, colOffset: 0, endLineno: nil, endColOffset: nil))
            case "float":
                return .constant(Constant(value: .float(0.0), kind: nil, lineno: 0, colOffset: 0, endLineno: nil, endColOffset: nil))
            case "bool":
                return .constant(Constant(value: .bool(false), kind: nil, lineno: 0, colOffset: 0, endLineno: nil, endColOffset: nil))
            default:
                return .constant(Constant(value: .none, kind: nil, lineno: 0, colOffset: 0, endLineno: nil, endColOffset: nil))
            }
            
        case .subscriptExpr(let sub):
            guard case .name(let baseType) = sub.value else {
                return .constant(Constant(value: .none, kind: nil, lineno: 0, colOffset: 0, endLineno: nil, endColOffset: nil))
            }
            
            switch baseType.id {
            case "list", "List":
                return .list(List(elts: [], ctx: .load, lineno: 0, colOffset: 0, endLineno: nil, endColOffset: nil))
            case "dict", "Dict":
                return .dict(Dict(keys: [], values: [], lineno: 0, colOffset: 0, endLineno: nil, endColOffset: nil))
            case "set", "Set":
                return .list(List(elts: [], ctx: .load, lineno: 0, colOffset: 0, endLineno: nil, endColOffset: nil))
            case "Optional":
                return .constant(Constant(value: .none, kind: nil, lineno: 0, colOffset: 0, endLineno: nil, endColOffset: nil))
            default:
                return .constant(Constant(value: .none, kind: nil, lineno: 0, colOffset: 0, endLineno: nil, endColOffset: nil))
            }
            
        default:
            return .constant(Constant(value: .none, kind: nil, lineno: 0, colOffset: 0, endLineno: nil, endColOffset: nil))
        }
    }
    
    /// Converts Python AST type to Kivy property type name
    private static func convertToKivyProperty(_ expr: Expression) -> String {
        switch expr {
        case .name(let name):
            // Simple types: str, int, float, bool, etc.
            switch name.id {
            case "str": return "StringProperty"
            case "int": return "NumericProperty"
            case "float": return "NumericProperty"
            case "bool": return "BooleanProperty"
            default: return "ObjectProperty"
            }
            
        case .subscriptExpr(let sub):
            // Generic types: list[T], dict[K,V], set[T], etc.
            guard case .name(let baseType) = sub.value else {
                return "ObjectProperty"
            }
            
            switch baseType.id {
            case "list", "List": return "ListProperty"
            case "dict", "Dict": return "DictProperty"
            case "set", "Set": return "ListProperty"  // Kivy doesn't have SetProperty
            case "Optional": 
                // Optional[T] -> use T's property type
                return convertToKivyProperty(sub.slice)
            default: return "ObjectProperty"
            }
            
        case .binOp(let binOp):
            // Union types: int | None, str | int, etc.
            // Use left side type for Kivy property
            return convertToKivyProperty(binOp.left)
            
        case .attribute(let attr):
            // Module types: typing.List, collections.abc.Sequence, etc.
            switch attr.attr {
            case "List": return "ListProperty"
            case "Dict": return "DictProperty"
            case "Set": return "ListProperty"
            default: return "ObjectProperty"
            }
            
        default:
            return "ObjectProperty"
        }
    }
    
    // MARK: - Data Models
    
    private struct KivyClassInfo {
        let name: String
        var properties: [(name: String, annotation: Expression)]
        var methods: [(stmt: Statement, name: String)]
    }
    
    // MARK: - AST Visitor
    
    private class KivyClassVisitor: ASTVisitor {
        var classes: [KivyClassInfo] = []
        
        func visit(_ node: ClassDef) {
            var properties: [(name: String, annotation: Expression)] = []
            var methods: [(stmt: Statement, name: String)] = []
            
            // Collect properties and methods from class body
            for statement in node.body {
                // Properties (type annotations)
                if case .annAssign(let annAssign) = statement,
                   case .name(let target) = annAssign.target {
                    properties.append((name: target.id, annotation: annAssign.annotation))
                }
                
                // Methods (skip __init__ and @property)
                if case .functionDef(let funcDef) = statement {
                    // Skip __init__
                    if funcDef.name == "__init__" {
                        continue
                    }
                    
                    // Skip @property decorated methods
                    let isProperty = funcDef.decoratorList.contains { expr in
                        if case .name(let name) = expr {
                            return name.id == "property"
                        }
                        return false
                    }
                    
                    if !isProperty {
                        methods.append((stmt: statement, name: funcDef.name))
                    }
                }
            }
            
            classes.append(KivyClassInfo(
                name: node.name,
                properties: properties,
                methods: methods
            ))
        }
    }
}








