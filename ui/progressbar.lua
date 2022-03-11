local ProgressBar = {
    monitor = nil,
    width = -1,
    x = 1,
    y = -1,
    offset = 0,
    backgroundColor = colors.gray,
    color = colors.yellow
}

function ProgressBar:new(monitor, y)
    local o = {}
    o.monitor = monitor
    o.y = y
    o.width = monitor.getSize() + 1
    o.center = o.width / 2 -1
    setmetatable(o, self)
    self.__index = self
    return o
end

function ProgressBar:init()
    local currentBc = self.monitor.getBackgroundColor()
    local currentTc = self.monitor.getTextColor()
    self.monitor.setCursorPos(self.x, self.y)
    self.monitor.setBackgroundColor(self.backgroundColor)
    for _ = 1, self.width do
        self.monitor.write(" ")
    end
    self.offset = 1
    self.monitor.setBackgroundColor(currentBc)
    self.monitor.setTextColor(currentTc)
end

function ProgressBar:_writePercentage(percentage)
    local pText = string.format("%03d", percentage)
    for offset = 0, 2 do
        local xPos = self.center + offset
        if self.offset >= xPos then
            self.monitor.setBackgroundColor(self.color)
            self.monitor.setTextColor(self.backgroundColor)
        else
            self.monitor.setBackgroundColor(self.backgroundColor)
            self.monitor.setTextColor(self.color)
        end
        self.monitor.setCursorPos(self.center + offset, self.y)
        self.monitor.write(string.sub(pText, offset + 1, offset + 2))
    end
end

function ProgressBar:progress(percentage)
    local newOffset = math.floor(percentage * self.width / 100)
    if newOffset < self.offset then
        self:init()
    end
    local diff = newOffset - self.offset
    if diff > 0 then
        self.monitor.setCursorPos(self.offset, self.y)
        self.monitor.setBackgroundColor(self.color)
        for _ = 1, diff do
            self.monitor.write(" ")
        end
        self.offset = newOffset
    end
    self:_writePercentage(percentage)
end

return ProgressBar
