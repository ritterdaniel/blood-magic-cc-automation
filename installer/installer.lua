-- a simple installer ofr CC: Tweaked Apps, based on wget.lua from CC: Tweaked
local BUFFER_SIZE = 1024

local function usage()
    print ([[
installer.lua [-h] [-f] [-t] [-p <path>] [-b <git branch>]

Options:
-h              - print usage
-f              - force reinstall
-t              - install additional test files
-p <path>       - target path for application, default = current location
-b <git branch> - git branch to be installed from, default = main
]])
end

local function get(url, binaryMode)
    local ok, err = http.checkURL(url)
    if not ok then
        print(err or "Invalid URL.")
        return
    end

    print("Connecting to " .. url .. "... ")

    local response = http.get(url , nil , binaryMode)
    if not response then
        print("Connect failed.")
        return nil
    end
    local status, message = response.getResponseCode()
    if status ~= 200 then
        print("Download failed: " .. status .. ": " ..message)
        return nil
    end

    print("Success.")

    return response
end

local function getAppConfiguration(data, includeTestFiles)
    local conf = {
        app = {},
        files = {}
    }
    local line = ""
    local state

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
    until not line

    return conf
end

local function downloadFiles(url, targetPath, files)
    for _, appFile in pairs(files) do
        local fileUrl = url .. "/" .. appFile
        local res = get(fileUrl, true)
        if not res then
            return
        end

        local fh, err = fs.open(targetPath .. "/" .. appFile, "wb")
        if not fh then
            print("Cannot save file '" .. appFile .. "': " .. err)
            return
        end
        local buffer = ""
        while buffer do
            buffer = res.read(BUFFER_SIZE)
            if buffer then
                fh.write(buffer)
            end
        end
        fh.flush()
        fh.close()
    end
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
local targetPath
local installTestfiles = false
local forceReinstall = false

if not http then
    print("Installer requires the http API")
    print("Set http.enabled to true in CC: Tweaked's config")
    return
end

local params = {...}
local i = 1
local exit = false

while i <= #params do
    local param = params[i]

    if param == "-h" then
        exit = true
        break
    elseif param == "-f" then
        forceReinstall = true
    elseif param == "-t" then
        installTestfiles = true
    elseif param == "-p" and #params >= i + 1  then
        i = i +1
        targetPath = params[i]
    elseif param == "-b" and #params >= i + 1 then
        i = i +1
        branch = params[i]
    else
        print("Unknown option or missing argument for '" .. param .. "'")
        exit = true
        break
    end
    i = i + 1
end

if exit then
    usage()
    return
end

local url = baseUrl .. "/" .. branch
local appConfUrl = url .."/" .. appFile

local data = get(appConfUrl, false)
if not data then
    print("App install file seems to be empty.")
    return
end
local appConf = getAppConfiguration(data, installTestfiles)
print(dump(appConf))

local appInstallPath
if targetPath then
    appInstallPath = targetPath
else
    appInstallPath = appConf.app.appFolder
end
if fs.exists(appInstallPath) then
    if not forceReinstall then
        print("App directory '" .. appInstallPath .. "' already exists. ")
        return
    else
        fs.delete(appInstallPath)
    end
end
fs.makeDir(appInstallPath)

downloadFiles(url, appInstallPath, appConf.files)