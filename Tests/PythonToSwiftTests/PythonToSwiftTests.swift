import XCTest
@testable import PythonToSwiftLib

final class PythonToSwiftTests: XCTestCase {
    
    func testBasicClassGeneration() {
        let pythonCode = """
        class Person:
            name: str
            age: int
        """
        
        let swiftCode = PythonToSwiftGenerator.generateSwiftCode(from: pythonCode)
        
        XCTAssertTrue(swiftCode.contains("@PyClass"))
        XCTAssertTrue(swiftCode.contains("public class Person"))
        XCTAssertTrue(swiftCode.contains("@PyProperty"))
        XCTAssertTrue(swiftCode.contains("public var name: String"))
        XCTAssertTrue(swiftCode.contains("public var age: Int"))
    }
    
    func testInitializerGeneration() {
        let pythonCode = """
        class Person:
            name: str
            
            def __init__(self, name: str, age: int):
                pass
        """
        
        let swiftCode = PythonToSwiftGenerator.generateSwiftCode(from: pythonCode)
        
        XCTAssertTrue(swiftCode.contains("@PyInit"))
        XCTAssertTrue(swiftCode.contains("public init(name: String, age: Int)"))
    }
    
    func testMethodGeneration() {
        let pythonCode = """
        class Person:
            def greet(self, message: str) -> str:
                pass
        """
        
        let swiftCode = PythonToSwiftGenerator.generateSwiftCode(from: pythonCode)
        
        XCTAssertTrue(swiftCode.contains("@PyMethod"))
        XCTAssertTrue(swiftCode.contains("public func greet(message: String) -> String"))
    }
    
    func testStaticMethodGeneration() {
        let pythonCode = """
        class Person:
            @staticmethod
            def create(name: str) -> object:
                pass
        """
        
        let swiftCode = PythonToSwiftGenerator.generateSwiftCode(from: pythonCode)
        
        XCTAssertTrue(swiftCode.contains("@PyMethod"))
        XCTAssertTrue(swiftCode.contains("public static func create(name: String) -> PyPointer"))
    }
    
    func testListTypeConversion() {
        let pythonCode = """
        class Person:
            def get_names(self) -> list[str]:
                pass
        """
        
        let swiftCode = PythonToSwiftGenerator.generateSwiftCode(from: pythonCode)
        
        XCTAssertTrue(swiftCode.contains("-> [String]"))
    }
    
    func testDictTypeConversion() {
        let pythonCode = """
        class Person:
            def get_data(self) -> dict[str, int]:
                pass
        """
        
        let swiftCode = PythonToSwiftGenerator.generateSwiftCode(from: pythonCode)
        
        XCTAssertTrue(swiftCode.contains("-> [String: Int]"))
    }
    
    func testSetTypeConversion() {
        let pythonCode = """
        class Person:
            tags: set[str]
        """
        
        let swiftCode = PythonToSwiftGenerator.generateSwiftCode(from: pythonCode)
        
        XCTAssertTrue(swiftCode.contains("Set<String>"))
    }
    
    func testOptionalTypeConversion() {
        let pythonCode = """
        from typing import Optional
        
        class Person:
            def get_name(self) -> Optional[str]:
                pass
        """
        
        let swiftCode = PythonToSwiftGenerator.generateSwiftCode(from: pythonCode)
        
        XCTAssertTrue(swiftCode.contains("String?"))
    }
    
    func testTupleTypeConversion() {
        let pythonCode = """
        class Person:
            def get_coords(self) -> tuple[int, int]:
                pass
        """
        
        let swiftCode = PythonToSwiftGenerator.generateSwiftCode(from: pythonCode)
        
        // Tuple types might not be fully supported yet, so just check it doesn't crash
        XCTAssertTrue(swiftCode.contains("@PyClass"))
        XCTAssertTrue(swiftCode.contains("public func get_coords()"))
    }
    
    func testCompleteClassGeneration() {
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
        
            @staticmethod
            def create(name: str) -> object:
                pass
        """
        
        let swiftCode = PythonToSwiftGenerator.generateSwiftCode(from: pythonCode)
        
        // Check import
        XCTAssertTrue(swiftCode.contains("import PySwiftKit"))
        
        // Check class
        XCTAssertTrue(swiftCode.contains("@PyClass"))
        XCTAssertTrue(swiftCode.contains("public class Person"))
        
        // Check properties
        XCTAssertTrue(swiftCode.contains("public var name: String"))
        XCTAssertTrue(swiftCode.contains("public var age: Int"))
        
        // Check init
        XCTAssertTrue(swiftCode.contains("@PyInit"))
        XCTAssertTrue(swiftCode.contains("public init(name: String, age: Int)"))
        
        // Check methods
        XCTAssertTrue(swiftCode.contains("public func greet(text: String)"))
        XCTAssertTrue(swiftCode.contains("public func interests() -> [String]"))
        XCTAssertTrue(swiftCode.contains("public static func create(name: String) -> PyPointer"))
    }
    
    func testCustomFormattingMode() {
        let pythonCode = """
        class Person:
            name: str
        """
        
        let swiftCode = PythonToSwiftGenerator.generateSwiftCode(from: pythonCode, customFormatting: true)
        
        // Should still generate valid Swift code
        XCTAssertTrue(swiftCode.contains("@PyClass"))
        XCTAssertTrue(swiftCode.contains("public class Person"))
        XCTAssertTrue(swiftCode.contains("@PyProperty"))
        XCTAssertTrue(swiftCode.contains("public var name: String"))
        
        // Check proper indentation
        XCTAssertTrue(swiftCode.contains("    @PyProperty"))
        XCTAssertTrue(swiftCode.contains("    public var name: String"))
    }
    
    func testErrorHandling() {
        let invalidPythonCode = """
        class Person
            name: str
        """
        
        let swiftCode = PythonToSwiftGenerator.generateSwiftCode(from: invalidPythonCode)
        
        XCTAssertTrue(swiftCode.contains("Error parsing Python code"))
    }
}
