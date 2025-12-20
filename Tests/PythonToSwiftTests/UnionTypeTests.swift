import XCTest
@testable import PythonToSwiftLib

final class UnionTypeTests: XCTestCase {
    
    func testUnionTypeWithNone() {
        let pythonCode = """
        class Person:
            def get_age(self) -> int | None:
                pass
        """
        
        let swiftCode = PythonToSwiftGenerator.generateSwiftCode(from: pythonCode)
        
        XCTAssertTrue(swiftCode.contains("Int?"), "Expected 'Int?' but got: \(swiftCode)")
    }
    
    func testUnionTypeWithNoneReversed() {
        let pythonCode = """
        class Person:
            def get_name(self) -> None | str:
                pass
        """
        
        let swiftCode = PythonToSwiftGenerator.generateSwiftCode(from: pythonCode)
        
        XCTAssertTrue(swiftCode.contains("String?"), "Expected 'String?' but got: \(swiftCode)")
    }
    
    func testPropertyWithUnionType() {
        let pythonCode = """
        class Person:
            age: int | None
        """
        
        let swiftCode = PythonToSwiftGenerator.generateSwiftCode(from: pythonCode)
        
        XCTAssertTrue(swiftCode.contains("Int?"), "Expected 'Int?' but got: \(swiftCode)")
    }
    
    func testInitWithUnionTypeParameter() {
        let pythonCode = """
        class Person:
            def __init__(self, name: str, age: int | None):
                pass
        """
        
        let swiftCode = PythonToSwiftGenerator.generateSwiftCode(from: pythonCode)
        
        XCTAssertTrue(swiftCode.contains("age: Int?"), "Expected 'age: Int?' but got: \(swiftCode)")
    }
}
