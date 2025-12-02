import PySwiftKit

@PyClass
class PropertyTests {
    
    // Case 1: Regular var → getter + setter
    @PyProperty
    var name: String
    
    // Case 2: let constant → getter only
    @PyProperty
    let id: Int
    
    // Case 3: Computed property with get only → getter only
    @PyProperty
    var fullName: String {
        get {
            return name
        }
    }
    
    // Case 4: Computed property with get and set → getter + setter
    @PyProperty
    var displayName: String {
        get {
            return name
        }
        set {
            name = newValue
        }
    }
    
    // Case 5: Regular var with type annotation → getter + setter
    @PyProperty
    var age: Int
}
