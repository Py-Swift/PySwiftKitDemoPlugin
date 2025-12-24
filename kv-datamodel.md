
original kv widget code (left top)
```kv

<MyWidget>:
    orientation: 'vertical'
    
    Label:
        text: root.title
        font_size: root.title_size
    
    TextInput:
        text: root.user_input
        on_text: root.user_input = self.text
    
    Button:
        text: 'Count: ' + str(root.counter)
        on_press: root.increment()
```

original python widget code (left bot)
```py

class MyWidget(BoxLayout):

    title = StringProperty("")

    title_size = NumericProperty(0)

    user_input = StringProperty("")

    counter = NumericProperty(0)

    state = BooleanProperty(False)
    
    def __init__(self, title: str, title_size: float, user_input: str, counter: int, state: bool):
        self.title = title
        self.title_size = title_size
        self.user_input = user_input
        self.counter = counter
        self.state = state
    
    def increment(self):
        self.counter += 1
```




convertes to:



converted kv widget code (right top)
```kv

<MyWidget>:
    orientation: 'vertical'
    
    Label:
        text: root.data.title
        font_size: root.title_size
    
    TextInput:
        text: root.data.user_input
        on_text: root.user_input = self.text
    
    Button:
        text: 'Count: ' + str(root.counter)
        on_press: root.data.increment()
```

converted python widget code (right bot)
```py

class MyWidgetData(EventDispatcher):

    title = StringProperty("")

    title_size = NumericProperty(0)

    user_input = StringProperty("")

    counter = NumericProperty(0)

    state = BooleanProperty(False)
    
    def __init__(self, title: str, title_size: float, user_input: str, counter: int, state: bool):
        self.title = title
        self.title_size = title_size
        self.user_input = user_input
        self.counter = counter
        self.state = state
    
    def increment(self):
        self.counter += 1


class MyWidget(BoxLayout):
    data: MyWidgetData

    def __init__(self, data: MyWidgetData):
        self.data = data

```
