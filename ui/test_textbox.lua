require "textbox"

-- test
local monitor = peripheral.find("monitor")
monitor.setBackgroundColor(colors.black)
monitor.reset()
local tb = TextBox:new(monitor, 1, 2, 10)
tb:setText("Test")

tb = TextBox:new(monitor, 1, 4, 10)
tb.orientation = tb.CENTER
tb:setText("Test")

tb = TextBox:new(monitor, 1, 6, 10)
tb.orientation = tb.RIGHT
tb:setText("Test")