import trio
from kivy.lang import Builder
from kivy_reloader.app import App
from os.path import dirname, join

from kivy.uix.boxlayout import BoxLayout

kv = """
Button:
    text: "Hello World"
StackLayout:
    orientation: "lr-tb"
    $0    
"""



class MyApp(App):
    def build(self):
        return Builder.load_file(join(dirname(__file__), "my.kv"))




def main():
    app = MyApp()
    app.run()