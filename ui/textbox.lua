local strings = require "cc.strings"

local TextBox = {
    Orientation = {
        LEFT = 0,
        CENTER = 1,
        RIGHT = 2
    },
    backgroundColor = colors.black,
    textColor = colors.white,
    orientation = 0,
    _text = "",
    _textLength = 0
}

function TextBox:new(monitor, xStart, yStart, width)
    local o = {}
    o.monitor = monitor
    o.x = xStart
    o.y = yStart
    local maxWidth, _ = monitor.getSize()
    o.width = math.min(xStart + width - 1, maxWidth)
    self._rightFormat = string.format("%%%ds", o.width)
    self._leftFormat = string.format("%%-%ds", o.width)
    setmetatable(o, self)
    self.__index = self
    return o
end

function TextBox:_paint()
    local currentBc = self.monitor.getBackgroundColor()
    local currentTc = self.monitor.getTextColor()
    self.monitor.setBackgroundColor(self.backgroundColor)
    self.monitor.setTextColor(self.textColor)
    self.monitor.setCursorPos(self.x, self.y)
    self.monitor.write(self._text)
    self.monitor.setBackgroundColor(currentBc)
    self.monitor.setTextColor(currentTc)
end

function TextBox:_justify(text)
    local justifiedText = ""
    local textLength = string.len(text)
    if textLength < self.width then
        if self.orientation == self.Orientation.RIGHT then
            justifiedText = string.format(self._rightFormat, text)
        elseif self.orientation == self.Orientation.CENTER then
            local remainingSpace = self.width - textLength
            local leftPadding = math.floor(remainingSpace / 2)
            for _ = 1, leftPadding do
                justifiedText = justifiedText .. " "
            end
            justifiedText = string.format(self._leftFormat, justifiedText .. text)
        else
            justifiedText = string.format(self._leftFormat, text)
        end
    end
    return justifiedText
end

function TextBox:setText(text)
    if not text then
        text = "None"
    end
    local trimmedText = strings.ensure_width(text, self.width)
    self._text = self:_justify(trimmedText)
    self:_paint()
end

function TextBox:reset()
    self._text = ""
    self:_paint()
end

return TextBox