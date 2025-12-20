import PySwiftAST
import SwiftSyntax

/// Converts Python AST Expression types to Swift TypeSyntax
/// Handles all Python type annotations including generics (list[], dict[], set[], tuple[], Optional[])
enum PythonTypeConverter {
    
    /// Convert Python Expression AST node to Swift TypeSyntax AST node
    static func convertToSwiftType(_ expr: Expression) -> TypeSyntax {
        switch expr {
        case .name(let name):
            return convertSimpleType(name.id)
            
        case .subscriptExpr(let sub):
            return convertGenericType(sub)
            
        case .binOp(let binOp):
            // Handle union types: int | None -> Int?
            return convertUnionType(binOp)
            
        case .constant(let constant):
            // Handle None type
            if case .none = constant.value {
                return TypeSyntax(IdentifierTypeSyntax(name: .identifier("Void")))
            }
            
        case .attribute(let attr):
            // Handle module.Type like datetime.datetime
            return convertAttributeType(attr)
            
        case .list(let list):
            // Handle [Type] syntax (alternative to list[Type])
            return convertListLiteralType(list)
            
        default:
            break
        }
        
        // Fallback
        return TypeSyntax(IdentifierTypeSyntax(name: .identifier("Any")))
    }
    
    /// Convert simple Python type name to Swift type
    private static func convertSimpleType(_ pythonType: String) -> TypeSyntax {
        let swiftType: String
        
        switch pythonType {
        // String types
        case "str": swiftType = "String"
        case "Substring": swiftType = "Substring"
        
        // Integer types
        case "int": swiftType = "Int"
        
        // Float types
        case "float": swiftType = "Double"
        
        // Boolean
        case "bool": swiftType = "Bool"
        
        // Binary data
        case "bytes", "bytearray": swiftType = "Data"
        
        // Date/Time
        case "datetime": swiftType = "Date"
        
        // URL
        case "url": swiftType = "URL"
        
        // None/Void
        case "None": swiftType = "Void"
        
        // Raw Python object
        case "object": swiftType = "PyPointer"
        
        default: swiftType = pythonType
        }
        
        return TypeSyntax(IdentifierTypeSyntax(name: .identifier(swiftType)))
    }
    
    /// Convert Python generic types (subscript expressions) to Swift
    /// Handles: list[T], dict[K,V], set[T], tuple[T...], Optional[T]
    private static func convertGenericType(_ sub: Subscript) -> TypeSyntax {
        // Get base type name
        guard case .name(let baseTypeName) = sub.value else {
            return TypeSyntax(IdentifierTypeSyntax(name: .identifier("Any")))
        }
        
        switch baseTypeName.id {
        case "list":
            return convertListType(sub.slice)
            
        case "dict":
            return convertDictType(sub.slice)
            
        case "set":
            return convertSetType(sub.slice)
            
        case "tuple":
            return convertTupleType(sub.slice)
            
        case "Optional":
            return convertOptionalType(sub.slice)
            
        default:
            // Generic type we don't specifically handle
            return convertUnknownGenericType(baseTypeName.id, slice: sub.slice)
        }
    }
    
    /// Convert list[T] to [T]
    private static func convertListType(_ slice: Expression) -> TypeSyntax {
        let elementType = convertToSwiftType(slice)
        return TypeSyntax(ArrayTypeSyntax(element: elementType))
    }
    
    /// Convert [Type] syntax to [Type] (Python's alternative list annotation)
    private static func convertListLiteralType(_ list: List) -> TypeSyntax {
        // [Type] has a single element in the list
        guard list.elts.count == 1 else {
            // Multiple elements or empty - fallback to [Any]
            return TypeSyntax(ArrayTypeSyntax(
                element: TypeSyntax(IdentifierTypeSyntax(name: .identifier("Any")))
            ))
        }
        
        let elementType = convertToSwiftType(list.elts[0])
        return TypeSyntax(ArrayTypeSyntax(element: elementType))
    }
    
    /// Convert dict[K, V] to [K: V]
    private static func convertDictType(_ slice: Expression) -> TypeSyntax {
        // dict[K, V] has slice as tuple with 2 elements
        if case .tuple(let tuple) = slice, tuple.elts.count == 2 {
            let keyType = convertToSwiftType(tuple.elts[0])
            let valueType = convertToSwiftType(tuple.elts[1])
            return TypeSyntax(DictionaryTypeSyntax(key: keyType, value: valueType))
        }
        
        // Fallback to [String: Any]
        return TypeSyntax(DictionaryTypeSyntax(
            key: TypeSyntax(IdentifierTypeSyntax(name: .identifier("String"))),
            value: TypeSyntax(IdentifierTypeSyntax(name: .identifier("Any")))
        ))
    }
    
    /// Convert set[T] to Set<T>
    private static func convertSetType(_ slice: Expression) -> TypeSyntax {
        let elementType = convertToSwiftType(slice)
        return TypeSyntax(IdentifierTypeSyntax(
            name: .identifier("Set"),
            genericArgumentClause: GenericArgumentClauseSyntax(
                arguments: GenericArgumentListSyntax([
                    GenericArgumentSyntax(argument: .type(elementType))
                ])
            )
        ))
    }
    
    /// Convert tuple[T1, T2, ...] to (T1, T2, ...)
    private static func convertTupleType(_ slice: Expression) -> TypeSyntax {
        var elementTypes: [TypeSyntax] = []
        
        // tuple[T1, T2] has slice as tuple with multiple elements
        if case .tuple(let tuple) = slice {
            elementTypes = tuple.elts.map { convertToSwiftType($0) }
        } else {
            // Single element tuple
            elementTypes = [convertToSwiftType(slice)]
        }
        
        return TypeSyntax(TupleTypeSyntax(
            elements: TupleTypeElementListSyntax(
                elementTypes.map { TupleTypeElementSyntax(type: $0) }
            )
        ))
    }
    
    /// Convert Optional[T] to T?
    private static func convertOptionalType(_ slice: Expression) -> TypeSyntax {
        let wrappedType = convertToSwiftType(slice)
        return TypeSyntax(OptionalTypeSyntax(wrappedType: wrappedType))
    }
    
    /// Convert unknown generic types like CustomType[T] to CustomType<T>
    private static func convertUnknownGenericType(_ baseName: String, slice: Expression) -> TypeSyntax {
        let swiftBaseName = convertSimpleType(baseName)
        let argumentType = convertToSwiftType(slice)
        
        // Extract identifier from swiftBaseName
        guard let identType = swiftBaseName.as(IdentifierTypeSyntax.self) else {
            return swiftBaseName
        }
        
        return TypeSyntax(IdentifierTypeSyntax(
            name: identType.name,
            genericArgumentClause: GenericArgumentClauseSyntax(
                arguments: GenericArgumentListSyntax([
                    GenericArgumentSyntax(argument: .type(argumentType))
                ])
            )
        ))
    }
    
    /// Convert attribute types like datetime.datetime
    private static func convertAttributeType(_ attr: Attribute) -> TypeSyntax {
        // For now, just use the attribute name
        // Could expand this to handle module.Type properly
        return TypeSyntax(IdentifierTypeSyntax(name: .identifier(attr.attr)))
    }
    
    /// Convert union types (Type | None) to optionals
    /// Python 3.10+ uses BinOp with | operator for union types
    private static func convertUnionType(_ binOp: BinOp) -> TypeSyntax {
        // Check if it's a union with None (Type | None or None | Type)
        let isLeftNone = isNoneType(binOp.left)
        let isRightNone = isNoneType(binOp.right)
        
        if isLeftNone {
            // None | Type -> Type?
            let wrappedType = convertToSwiftType(binOp.right)
            return TypeSyntax(OptionalTypeSyntax(wrappedType: wrappedType))
        } else if isRightNone {
            // Type | None -> Type?
            let wrappedType = convertToSwiftType(binOp.left)
            return TypeSyntax(OptionalTypeSyntax(wrappedType: wrappedType))
        }
        
        // Union of multiple non-None types - can't represent in Swift directly
        // Fallback to Any
        return TypeSyntax(IdentifierTypeSyntax(name: .identifier("Any")))
    }
    
    /// Check if an expression represents None type
    private static func isNoneType(_ expr: Expression) -> Bool {
        switch expr {
        case .constant(let constant):
            if case .none = constant.value {
                return true
            }
        case .name(let name):
            return name.id == "None"
        default:
            break
        }
        return false
    }
}
