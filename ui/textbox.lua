local Orientation = {
    LEFT = 0,
    CENTER = 1,
    RIGHT = 2
}

local TextBox = {
    backgroundColor = colors.black,
    textColor = colors.white,
    orientation = Orientation.LEFT,
    _text = "",
    _textLength = 0
}

local function dump(o)
    if type(o) == 'table' then
        local s = '{ '
        for k,v in pairs(o) do
            if type(k) ~= 'number' then k = '"'..k..'"' end
            s = s .. '['..k..'] = ' .. dump(v) .. ','
        end
        return s .. '} '
    else
        return tostring(o)
    end
end

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
    -- local newTextLength = string.len(self._text)
    -- if newTextLength < self._textLength then
    --     self.monitor.setCursorPos(self.x + newTextLength, self.y)
    --     print("P " .. "write space at x:" .. (self.x + newTextLength) .. " for " .. (self._textLength - newTextLength) .. " chars")
    --     for _ = 1, self._textLength - newTextLength do
    --         self.monitor.write(" ")
    --     end
    --     self._textLength = newTextLength
    -- end
    self.monitor.setCursorPos(self.x, self.y)
    self.monitor.write(self._text)
    print("P x:" .. self.x .. " y:" .. self.y .. " t:'" .. self._text .. "'")
    self.monitor.setBackgroundColor(currentBc)
    self.monitor.setTextColor(currentTc)
end

function TextBox:_justify(text)
    local justifiedText = ""
    local textLength = string.len(text)
    if textLength < self.width then
        if self.orientation == Orientation.RIGHT then
            justifiedText = string.format(self._rightFormat, text)
        elseif self.orientation == Orientation.CENTER then
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
    local textLength = string.len(text)
    local trimmedText
    if textLength <=self.width then
        trimmedText = text
    else
        local tEnd = math.min(textLength, self.width)
        trimmedText = string.sub(text, 1, tEnd)
    end
    self._text = self:_justify(trimmedText)
    print(self._text)
    self:_paint()
end

function TextBox:reset()
    self._text = ""
    self:_paint()
end

return TextBox