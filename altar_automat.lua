local TextBox = require("ui/textbox")
local ProgressBar = require("ui/progressbar")

local function initUi()
    local monitor = peripheral.find("monitor")
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

    label = TextBox:new(monitor, 1, 8, 18)
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

local function runAutomation()
    local monitor = peripheral.find("monitor")
    local altar = peripheral.wrap("bottom")
    local altarName = peripheral.getName(altar)
    local inChest = peripheral.wrap("back")
    local outChest = peripheral.wrap("left")
    local maxFillLevel = 10000
    local tank = getTank(altar, 1)
    if tank == nil then
        print("No tank found")
        return
    end

    local itemInLabel = TextBox:new(monitor, 1, 7, 18)
    itemInLabel:setText("None")
    local itemOutLabel = TextBox:new(monitor, 1, 9, 18)
    itemOutLabel:setText("None")

    while true do
        repeat
            os.sleep(0.5)
        until tank.fillLevel() >= maxFillLevel
        local slot, itemName
        repeat
            os.sleep(0.5)
            slot, itemName = nextItem(inChest)
            if slot ~= nil then
                break
            end
        until slot
        itemInLabel:setText(itemName)
        inChest.pushItems(altarName, slot, 1)

        os.pullEvent("redstone")
        itemInLabel.setText(nil)
        repeat
            slot, itemName = nextItem(inChest)
            if slot then
                itemOutLabel:setText(itemName)
                outChest.pullItems(altarName, slot, 1)
            end
        until not slot
    end
end

local function round(x)
    local f = math.floor(x)
    if (x == f) or (x % 2.0 == 0.5) then
        return f
    else
        return math.floor(x + 0.5)
    end
end

local function monitorTankLevel()
    local monitor = peripheral.find("monitor")
    local altar = peripheral.wrap("bottom")
    local tank = getTank(altar, 1)
    local maxFillLevel = 10000
    if tank == nil then
        print("No tank found")
        return
    end

    local progressBar = ProgressBar:new(monitor, 4)
    progressBar:init()

    while true do
        local fillPercentage = round(tank.fillLevel() * 100 / maxFillLevel)
        progressBar:progress(fillPercentage)
        os.sleep(.5)
    end
end

initUi()
parallel.waitForAll(monitorTankLevel(), runAutomation())



