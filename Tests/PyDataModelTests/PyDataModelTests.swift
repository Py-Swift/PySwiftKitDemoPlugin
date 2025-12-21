import XCTest
@testable import PyDataModels

final class PyDataModelTests: XCTestCase {
    
    func testBasicContainerGeneration() {
        let pythonCode = """
        class PyDataModel:
            name: str
            age: int
            
            def __init__(self, name, age):
                pass
            
            def greet(self, text: str):
                pass
            
            def interests(self) -> list[str]:
                pass
        """
        
        let result = PyDataModelGenerator.generateSwiftCode(from: pythonCode)
        
        XCTAssertTrue(result.contains("@PyContainer"))
        XCTAssertTrue(result.contains("@dynamicMemberLookup"))
        XCTAssertTrue(result.contains("class PyDataModel"))
        XCTAssertTrue(result.contains("@PyCall"))
        XCTAssertTrue(result.contains("func greet(text: String)"))
        XCTAssertTrue(result.contains("func interests() -> [String]"))
        XCTAssertFalse(result.contains("__init__"), "Should not include __init__")
        XCTAssertFalse(result.contains("@PyProperty"), "Properties handled by dynamicMemberLookup")
    }
    
    func testContainerWithoutProperties() {
        let pythonCode = """
        class Util:
            def calculate(self, x: int, y: int) -> int:
                pass
        """
        
        let result = PyDataModelGenerator.generateSwiftCode(from: pythonCode)
        
        XCTAssertTrue(result.contains("@PyContainer"))
        XCTAssertFalse(result.contains("@dynamicMemberLookup"), "No properties = no dynamicMemberLookup")
        XCTAssertTrue(result.contains("@PyCall"))
        XCTAssertTrue(result.contains("func calculate(x: Int, y: Int) -> Int"))
    }
    
    func testStaticMethods() {
        let pythonCode = """
        class Helper:
            @staticmethod
            def format(text: str) -> str:
                pass
        """
        
        let result = PyDataModelGenerator.generateSwiftCode(from: pythonCode)
        
        XCTAssertTrue(result.contains("@PyCall"))
        XCTAssertTrue(result.contains("static func format(text: String) -> String"))
    }
    
    func testComplexTypes() {
        let pythonCode = """
        class Data:
            items: list[str]
            mapping: dict[str, int]
            
            def process(self, data: list[str]) -> dict[str, int]:
                pass
        """
        
        let result = PyDataModelGenerator.generateSwiftCode(from: pythonCode)
        
        XCTAssertTrue(result.contains("@PyContainer"))
        XCTAssertTrue(result.contains("@dynamicMemberLookup"))
        XCTAssertTrue(result.contains("func process(data: [String]) -> [String: Int]"))
    }
    
    func testListLiteralSyntax() {
        let pythonCode = """
        class Container:
            peoples: [str]
            
            def getPeoples(self) -> [str]:
                pass
        """
        
        let result = PyDataModelGenerator.generateSwiftCode(from: pythonCode)
        
        XCTAssertTrue(result.contains("@PyContainer"))
        XCTAssertTrue(result.contains("@dynamicMemberLookup"))
        XCTAssertTrue(result.contains("func getPeoples() -> [String]"))
    }
    
    func testCustomFormatting() {
        let pythonCode = """
        class Model:
            def test(self):
                pass
        """
        
        let result = PyDataModelGenerator.generateSwiftCode(from: pythonCode, customFormatting: true)
        
        XCTAssertTrue(result.contains("@PyContainer"))
        XCTAssertTrue(result.contains("@PyCall"))
        XCTAssertTrue(result.contains("class Model"))
    }
}
