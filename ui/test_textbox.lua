local TextBox = require "textbox"

-- test
local monitor = peripheral.find("monitor")
monitor.setBackgroundColor(colors.black)
monitor.clear()
local width, _ = monitor.getSize()
local textBox = TextBox:new(monitor, 1, 2, width)
textBox.textColor = colors.yellow
textBox:setText("TestTestTest")
textBox:setText("Test")

textBox = TextBox:new(monitor, 1, 4, width)
textBox.orientation = textBox.Orientation.CENTER
textBox.backgroundColor = colors.red
textBox:setText("Test")

textBox = TextBox:new(monitor, 1, 6, width)
textBox.orientation = textBox.Orientation.RIGHT
textBox:setText("Test")