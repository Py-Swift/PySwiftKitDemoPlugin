#!/usr/bin/env python3
"""
Simple Kivy test application for VNC streaming validation
"""

from kivy.app import App
from kivy.uix.boxlayout import BoxLayout
from kivy.uix.button import Button
from kivy.uix.label import Label
import time


class TestApp(App):
    def build(self):
        layout = BoxLayout(orientation='vertical', padding=20, spacing=10)
        
        # Title
        title = Label(
            text='[b]Kivy VNC Streaming Test[/b]',
            markup=True,
            font_size='32sp',
            size_hint=(1, 0.2)
        )
        layout.add_widget(title)
        
        # Counter label
        self.counter_label = Label(
            text='Counter: 0',
            font_size='24sp',
            size_hint=(1, 0.3)
        )
        layout.add_widget(self.counter_label)
        
        # Button
        btn = Button(
            text='Click Me!',
            font_size='20sp',
            size_hint=(1, 0.2)
        )
        btn.bind(on_press=self.on_button_click)
        layout.add_widget(btn)
        
        # Status label
        self.status_label = Label(
            text='Status: Ready\nStreaming via VNC (no compression)',
            font_size='16sp',
            size_hint=(1, 0.3)
        )
        layout.add_widget(self.status_label)
        
        # Initialize counter (only increments on button click)
        self.counter = 0
        
        return layout
    
    def on_button_click(self, instance):
        self.counter += 1
        self.counter_label.text = f'Counter: {self.counter}'
        self.status_label.text = f'Button clicked at: {time.strftime("%H:%M:%S")}\nClick count: {self.counter}'


if __name__ == '__main__':
    TestApp().run()
