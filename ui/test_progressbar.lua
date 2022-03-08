require "progressbar"

-- test
local monitor = peripheral.find("monitor")
while true do
    monitor.setBackgroundColor(colors.black)
    monitor.clear()
    local pb = progressBar:new(monitor, 3)
    pb:reset()
    for p = 0, 100, 10 do
        os.sleep(.5)
        pb:progress(p)
    end
    for p = 0, 100, 10 do
        os.sleep(.5)
        pb:progress(100 - p)
    end
end