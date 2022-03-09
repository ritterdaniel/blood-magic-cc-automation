-- a simple installer using parts of code from wget.lua from CC: Tweaked mod

local function usage()
    print ([[
installer.lua [-h] [-t] [-p <path>] [-b <git branch>]

Options:
-h              - print usage
-t              - install additional test files
-p <path>       - target path for application, default = current location
-b <git branch> - git branch to be installed from, default = main
]])
end

local function get(sUrl, binary)
    -- Check if the URL is valid
    local ok, err = http.checkURL(sUrl)
    if not ok then
        print(err or "Invalid URL.")
        return
    end

    print("Connecting to " .. sUrl .. "... ")

    local response = http.get(sUrl , nil , binary)
    if not response then
        print("Download failed: " .. sUrl)
        return nil
    end

    print("Success.")

    local sResponse = response.readAll()
    response.close()
    return sResponse or ""
end

local function getAppConfiguration(data, includeTestFiles)
    local conf = {
        app = {},
        files = {}
    }
    local line = ""
    local state = nil

    repeat
        if string.match(line, "^%[Application%]") then
            state = "app"
        elseif string.match(line, "^%[Files%]") then
            state = "file"
        elseif string.match(line, "^%[TestFiles%]") then
            state = "testFile"
        elseif state == "app" then
            local k, v = string.match(line, "(%w+)%s*=%s*(%w+)")
            if k and v then
                conf.app[k] = v
            end
        elseif state == "file" or (state == "testFile" and includeTestFiles) then
            local f = string.match(line, "([%w/._-]+)")
            if f then
                table.insert(conf.files, f)
            end
        end

        line = data.readLine()
    until line == nil

    return conf
end

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

local branch = "main"
local baseUrl = "https://raw.githubusercontent.com/ritterdaniel/blood-magic-cc-automation"
local appFile = "app.ccinstall"
local targetPath = nil
local installTestfiles = false

if not http then
    print("Installer requires the http API")
    print("Set http.enabled to true in CC: Tweaked's config")
    return
end

local params = {...}
local i = 1
local fail = false

while i <= #params do
    local param = params[i]

    if param == "-h" then
        usage()
        break
    elseif param == "-t" then
        installTestfiles = true
    elseif param == "-p" and i + 1 >= #params then
        i = i +1
        targetPath = params[i]
    elseif param == "-b" and i + 1 >= #params then
        i = i +1
        branch = params[i]
    else
        print("Unknown option or missing argument for '" .. param .. "'")
        fail = true
        break
    end
    i = i + 1
end

if fail then
    usage()
    return
end

local url = baseUrl .. "/" .. branch
local appConfUrl = url .."/" .. appFile

local data = get(appConfUrl, false)
if not data then
    return
end
local appConf = getAppConfiguration(data, installTestfiles)
print(dump(appConf))