local TextBox = require "textbox"

-- test
local monitor = peripheral.find("monitor")
monitor.setBackgroundColor(colors.black)
monitor.clear()
local textBox = TextBox:new(monitor, 1, 2, 10)
textBox:setText("Test")

textBox = TextBox:new(monitor, 1, 4, 10)
textBox.orientation = textBox.CENTER
textBox:setText("Test")

textBox = TextBox:new(monitor, 1, 6, 10)
textBox.orientation = textBox.RIGHT
textBox:setText("Test")