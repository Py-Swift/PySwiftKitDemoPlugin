import XCTest
@testable import PythonToSwiftLib

final class ListLiteralSyntaxTests: XCTestCase {
    
    func testListLiteralSyntax() throws {
        let pythonCode = """
        class House:
            peoples: [Person]
        """
        
        let result = try PythonToSwiftGenerator.generateSwiftCode(from: pythonCode)
        
        XCTAssertTrue(result.contains("@PyClass"), "Missing @PyClass")
        XCTAssertTrue(result.contains("public class House"), "Missing public class House")
        XCTAssertTrue(result.contains("peoples: [Person]") || result.contains("peoples:[Person]"), "Missing peoples property with correct type")
        XCTAssertFalse(result.contains(": Any"), "Should not contain Any type")
    }
    
    func testListLiteralWithBuiltinType() throws {
        let pythonCode = """
        class Container:
            items: [str]
            counts: [int]
        """
        
        let result = try PythonToSwiftGenerator.generateSwiftCode(from: pythonCode)
        
        XCTAssertTrue(result.contains("items: [String]") || result.contains("items:[String]"))
        XCTAssertTrue(result.contains("counts: [Int]") || result.contains("counts:[Int]"))
    }
    
    func testCompleteExampleWithListLiteral() throws {
        let pythonCode = """
        class Person:
            name: str
            age: int
            
            def __init__(self, name: str, age: int):
                pass
            
            def greet(self, text: str):
                pass
            
            def interests(self) -> list[str]:
                pass
        
        class House:
            peoples: [Person]
        """
        
        let result = try PythonToSwiftGenerator.generateSwiftCode(from: pythonCode)
        
        // Verify Person class
        XCTAssertTrue(result.contains("public class Person"))
        XCTAssertTrue(result.contains("name: String"))
        XCTAssertTrue(result.contains("age: Int"))
        
        // Verify House class with list literal syntax
        XCTAssertTrue(result.contains("public class House"))
        XCTAssertTrue(result.contains("peoples: [Person]") || result.contains("peoples:[Person]"))
        XCTAssertFalse(result.contains(": Any"))
    }
    
    func testNestedListLiteralFallsBackToAny() throws {
        let pythonCode = """
        class Container:
            matrix: [[str]]
        """
        
        let result = try PythonToSwiftGenerator.generateSwiftCode(from: pythonCode)
        
        // [[str]] gets converted to [[String]] not [Any] because it's recursively processed
        XCTAssertTrue(result.contains("matrix: [[String]]") || result.contains("matrix:[[String]]"))
    }
}
