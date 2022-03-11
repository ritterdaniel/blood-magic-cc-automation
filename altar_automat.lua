local TextBox = require("ui/textbox")
local ProgressBar = require("ui/progressbar")

local devices = {
    monitor = peripheral.find("monitor"),
    altar = peripheral.wrap("bottom"),
    inChest = peripheral.wrap("back"),
    outChest = peripheral.wrap("left"),
}

local config = {
    maxFillLevel = 10000,
    tick = 5, -- seconds
    debug = false
}

local params = {...}
config["debug"] = #params >= 1 and params[1] == "-d"

local function round(x)
    local f = math.floor(x)
    if (x == f) or (x % 2.0 == 0.5) then
        return f
    else
        return math.floor(x + 0.5)
    end
end

local function initUi()
    local monitor = devices.monitor
    monitor.setBackgroundColor(colors.black)
    monitor.clear()
    local label = TextBox:new(monitor, 1, 1, 18)
    label.backgroundColor = colors.red
    label.textColor = colors.yellow
    label.orientation = TextBox.Orientation.CENTER
    label:setText("Blood Magic Altar")

    label = TextBox:new(monitor, 1, 3, 18)
    label.backgroundColor = colors.green
    label:setText("Altar Fill Level")

    label = TextBox:new(monitor, 1, 6, 18)
    label.backgroundColor = colors.green
    label:setText("Current Item IN")

    label = TextBox:new(monitor, 1, 9, 18)
    label.backgroundColor = colors.green
    label:setText("Last Item OUT")

    label = TextBox:new(monitor, 1, 12, 18)
    label.backgroundColor = colors.red
    label:setText(" ")
end

local function getTank(container, slot)
    local tanks = container.tanks()
    if #tanks >= slot then
        local tank = tanks[slot]
        tank.slot = slot
        tank.container = container
        tank.fillLevel = function ()
            return tank.container.tanks()[tank.slot].amount
        end
        return tank
    end
    return nil
end

local function nextItem(inventory)
    for slot, items in pairs(inventory.list()) do
        return slot, items.name
    end
    return nil, nil
end

local function debug(...)
    if config.debug then
        print(...)
    end
end

local function crafter()
    local monitor = devices.monitor
    local altarName = peripheral.getName(devices.altar)
    local inChest = devices.inChest

    local itemInLabel = TextBox:new(monitor, 1, 7, 18)
    itemInLabel:setText(nil)

    local fillLevel = 0
    local inItemAvailable = false
    local item = {}
    local crafterAvailable = false
    local subscribedEvents = {
        tankStatus = true,
        inItemAvailable = true,
        redstone = true,
        crafterAvailable = true}
    repeat
        local event, param = coroutine.yield()
        if subscribedEvents[event] then
            debug("Crafter - Event - " .. event)
            if event == "tankStatus" then
                fillLevel = param.fillLevel
            elseif event == "inItemAvailable" then
                item = param
                inItemAvailable = true
            elseif event == "redstone" then
                itemInLabel:setText(nil)
            elseif event == "crafterAvailable" then
                crafterAvailable = true
            end

            debug("Crafter - FL:", fillLevel, " IA:", inItemAvailable, " CA:", crafterAvailable)
            if fillLevel == 100 and inItemAvailable and crafterAvailable then
                itemInLabel:setText(item.name)
                inChest.pushItems(altarName, item.slot, 1)
                inItemAvailable = false
                fillLevel = 0
            end
        end
    until event == "terminate"
end

local function inChestMonitor()
    local inChest = devices.inChest

    repeat
        debug("inChestMonitor - Event")
        local slot, itemName = nextItem(inChest)
        if slot then
            local item = inChest.getItemDetail(slot)
            debug("inChestMonitor - Item!")
            os.queueEvent("inItemAvailable", {slot = slot, name = item.displayName})
        end
        local event = coroutine.yield("timer")
    until event[1] == "terminate"
end

local function craftedItemTaker()
    local monitor = devices.monitor
    local altar = devices.altar
    local altarName = peripheral.getName(altar)
    local outChest = devices.outChest
    local itemOutLabel = TextBox:new(monitor, 1, 10, 18)
    itemOutLabel:setText(nil)

    repeat
        os.queueEvent("crafterAvailable")
        local event = coroutine.yield("redstone")
        debug("craftedItemTaker - Event " .. event)
        repeat
            local slot, itemName = nextItem(altar)
            if slot then
                local item = outChest.getItemDetail(slot)
                itemOutLabel:setText(item.displayName)
                outChest.pullItems(altarName, slot, 1)
            end
        until not slot
    until event == "terminate"
end

local function tankLevelMonitor()
    local tank = getTank(devices.altar, 1)
    if tank == nil then
        print("No tank found")
        return
    end

    repeat
        local fillPercentage = round(tank.fillLevel() * 100 / config.maxFillLevel)
        debug("tankLevelMonitor - fillLevel " .. fillPercentage)
        os.queueEvent("tankStatus", {fillLevel = fillPercentage})
        local event = coroutine.yield("timer")
    until event == "terminate"
end

local function tankDisplay()
    local monitor = devices.monitor
    local progressBar = ProgressBar:new(monitor, 4)
    progressBar:init()

    local lastFillLevel = 0
    repeat
        local event, tankStatus = coroutine.yield("tankStatus")
        debug("tankDisplay - Event " .. event)
        if event == "tankStatus" and tankStatus.fillLevel ~= lastFillLevel then
            progressBar:progress(tankStatus.fillLevel)
            lastFillLevel = tankStatus.fillLevel
        end
    until event == "terminate"
end

local function pulseGenerator()
    repeat
        os.startTimer(config.tick)
        local event = coroutine.yield("timer")
    until event == "terminate"
end

initUi()
parallel.waitForAny(
    tankLevelMonitor,
    tankDisplay,
    craftedItemTaker,
    inChestMonitor,
    crafter,
    pulseGenerator
)
