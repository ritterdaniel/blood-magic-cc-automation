local TextBox = require("ui/textbox")
local ProgressBar = require("ui/progressbar")

local altar = peripheral.wrap("bottom")
local inChest = peripheral.wrap("back")
local outChest = peripheral.wrap("left")
local lifeEssence = "bloodmagic:life_essence_fluid"
local monitor = peripheral.find("monitor")


local minFillLevel = 10000

local function resetUI()
    monitor.setBackgroundColor(colors.black)
    monitor.clear()
    local label = TextBox:new(monitor, 1, 1, 18)
    label.backgroundColor = colors.red
    label.textColor = colors.yellow
    label:setText("Blood Magic Altar")

    label = TextBox:new(monitor, 1, 3, 18)
    label.backgroundColor = colors.green
    label:setText("Life Essence Fill Level")

    local progressBar = ProgressBar:new(monitor, 4)
    progressBar:reset()

    label = TextBox:new(monitor, 1, 5, 18)
    label.backgroundColor = colors.green
    label:setText("")

    label = TextBox:new(monitor, 1, 7, 18)
    label.textColor = colors.green
    label:setText("Current item in Altar")

    label = TextBox:new(monitor, 1, 8, 18)
    label:setText("None")

    label = TextBox:new(monitor, 1, 10, 18)
    label.textColor = colors.green
    label:setText("Last item from Altar")

    label = TextBox:new(monitor, 1, 11, 18)
    label:setText("None")

    label = TextBox:new(monitor, 1, 12, 18)
    label.backgroundColor = colors.red
    label:setText("")
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


resetUI()

local tank = getTank(altar, 1)
if tank == nil then
    print("No tank found")
    return
end

while true do
    repeat
        os.sleep(0.5)
    until tank.fillLevel() >= minFillLevel
    local slot, itemName
    while true do
        slot, itemName = nextItem(inChest)
        if slot ~= nil then
            break
        end
        os.sleep(0.5)
    end
    inChest.pushItems(peripheral.getName(altar), slot, 1)
    os.pullEvent("redstone")
    outChest.pullItems(peripheral.getName(altar), 1)
end