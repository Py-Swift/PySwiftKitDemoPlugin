import XCTest
@testable import PythonToSwiftLib

final class PropertyDecoratorTests: XCTestCase {
    
    func testPropertyDecorator() {
        let pythonCode = """
        class Person:
            @property
            def name(self) -> str:
                pass
        """
        
        let swiftCode = PythonToSwiftGenerator.generateSwiftCode(from: pythonCode)
        
        XCTAssertTrue(swiftCode.contains("@PyProperty"))
        XCTAssertTrue(swiftCode.contains("public var name: String"))
        XCTAssertFalse(swiftCode.contains("public func name"))
    }
    
    func testPropertyWithSetter() {
        let pythonCode = """
        class Person:
            @property
            def name(self) -> str:
                pass
        
            @name.setter
            def name(self, value: str):
                pass
        """
        
        let swiftCode = PythonToSwiftGenerator.generateSwiftCode(from: pythonCode)
        
        // Should only generate one property, not two
        XCTAssertTrue(swiftCode.contains("@PyProperty"))
        XCTAssertTrue(swiftCode.contains("public var name: String"))
        
        // Count occurrences of "name:"
        let nameCount = swiftCode.components(separatedBy: "name:").count - 1
        XCTAssertEqual(nameCount, 1, "Should only have one 'name:' declaration")
    }
    
    func testReadOnlyProperty() {
        let pythonCode = """
        class Person:
            @property
            def id(self) -> int:
                pass
        """
        
        let swiftCode = PythonToSwiftGenerator.generateSwiftCode(from: pythonCode)
        
        XCTAssertTrue(swiftCode.contains("@PyProperty"))
        XCTAssertTrue(swiftCode.contains("public var id: Int"))
    }
    
    func testMixedPropertiesAndMethods() {
        let pythonCode = """
        class Person:
            @property
            def name(self) -> str:
                pass
        
            @name.setter
            def name(self, value: str):
                pass
        
            @property
            def id(self) -> int:
                pass
        
            @property
            def fullName(self) -> str:
                pass
        
            def __init__(self, name: str, id: int):
                pass
        
            def greet(self) -> str:
                pass
        
            @staticmethod
            def create(name: str) -> object:
                pass
        """
        
        let swiftCode = PythonToSwiftGenerator.generateSwiftCode(from: pythonCode)
        
        // Check properties
        XCTAssertTrue(swiftCode.contains("public var name: String"))
        XCTAssertTrue(swiftCode.contains("public var id: Int"))
        XCTAssertTrue(swiftCode.contains("public var fullName: String"))
        
        // Check init
        XCTAssertTrue(swiftCode.contains("@PyInit"))
        XCTAssertTrue(swiftCode.contains("public init(name: String, id: Int)"))
        
        // Check methods
        XCTAssertTrue(swiftCode.contains("public func greet() -> String"))
        XCTAssertTrue(swiftCode.contains("public static func create(name: String) -> PyPointer"))
        
        // Should not have method declarations for properties
        XCTAssertFalse(swiftCode.contains("public func name()"))
        XCTAssertFalse(swiftCode.contains("public func id()"))
        XCTAssertFalse(swiftCode.contains("public func fullName()"))
    }
}
