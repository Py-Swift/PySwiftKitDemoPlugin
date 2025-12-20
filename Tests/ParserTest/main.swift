import PythonToSwiftLib

// Test the user's example with list literal syntax
let testPythonCode = """
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

print("Testing Python → Swift code generation with [Person] syntax...")
print("\nInput Python code:")
print(testPythonCode)
print("\n" + String(repeating: "=", count: 60))

let result = PythonToSwiftGenerator.generateSwiftCode(from: testPythonCode)

print("\n✅ Generated Swift code (with .formatted()):\n")
print(result)

print("\n" + String(repeating: "=", count: 60))
print("\n✅ Generated Swift code (with customFormatting=true for WASM):\n")
let customResult = PythonToSwiftGenerator.generateSwiftCode(from: testPythonCode, customFormatting: true)
print(customResult)


