
this python code
```py

class PyDataModel:

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

using @PyContainer

properties are all handled by the 
@dynamicMemberLookup

and should be added if py class contains variables/properties

when using @PyContainer

we instead need to use @PyCall 
to make the py functions callable from swift


so where @PyClass makes a py class out of a Swift Class
then @PyContainer makes a swift class out of a python class 

```swift

@PyContainer
@dynamicMemberLookup
class PyDataModel {

    @PyCall
    func greet(text: String) {

    }

    @PyCall
    func interests() -> [String] {

    }


}

```