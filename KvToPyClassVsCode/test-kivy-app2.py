#!/usr/bin/env python3
"""
Second test app for multi-instance VNC demo
"""

from kivy.app import App
from kivy.uix.boxlayout import BoxLayout
from kivy.uix.button import Button
from kivy.uix.label import Label
import time


class TestApp2(App):
    def build(self):
        layout = BoxLayout(orientation='vertical', padding=20, spacing=10)
        
        # Title with different color scheme
        title = Label(
            text='[b]Instance 2 - VNC Test[/b]',
            markup=True,
            font_size='32sp',
            size_hint=(1, 0.2),
            color=(0.2, 1, 0.5, 1)  # Green tint
        )
        layout.add_widget(title)
        
        # Counter label
        self.counter_label = Label(
            text='Clicks: 0',
            font_size='24sp',
            size_hint=(1, 0.3)
        )
        layout.add_widget(self.counter_label)
        
        # Button with different color
        btn = Button(
            text='Click Me (Instance 2)!',
            font_size='20sp',
            size_hint=(1, 0.2),
            background_color=(0.2, 0.8, 0.4, 1)
        )
        btn.bind(on_press=self.on_button_click)
        layout.add_widget(btn)
        
        # Status label
        self.status_label = Label(
            text='Status: Ready on :100\nInstance 2 - Port 6081',
            font_size='16sp',
            size_hint=(1, 0.3)
        )
        layout.add_widget(self.status_label)
        
        # Initialize counter
        self.counter = 0
        
        return layout
    
    def on_button_click(self, instance):
        self.counter += 1
        self.counter_label.text = f'Clicks: {self.counter}'
        self.status_label.text = f'Button clicked at: {time.strftime("%H:%M:%S")}\nClick count: {self.counter}\nInstance 2'


if __name__ == '__main__':
    TestApp2().run()
