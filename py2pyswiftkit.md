
this python code
```py

class Person:

    name: str
    age: int

    def __init__(self, name, age):
        pass


    def greet(self, text: str):
        pass

    def interests(self) -> list[str]:
        pass

```

is writen in swift like this...

```swift

@PyClass
class Person {

    @PyProperty
    var name: String

    @PyProperty
    var age: Int

    @PyInit
    init(name: String, age: Int) {

    }

    @PyMethod
    func greet(text: String) {

    }

    @PyMethod
    func interests() -> [String] {

    }


}

```