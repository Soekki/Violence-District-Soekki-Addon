local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer

-- ВАШИ ССЫЛКИ
local zoneConfigs = {
    {name = "32M_MM",   url = "https://raw.githubusercontent.com/Soekki/Violence-District-Soekki-Addon/Sounds/Stalker/32m.mp3", minDist = 72, maxDist = 96},
    {name = "24M_MM",   url = "https://raw.githubusercontent.com/Soekki/Violence-District-Soekki-Addon/Sounds/Stalker/24m.mp3", minDist = 36, maxDist = 72},
    {name = "12M_MM",   url = "https://raw.githubusercontent.com/Soekki/Violence-District-Soekki-Addon/Sounds/Stalker/12m.mp3", minDist = 24, maxDist = 36},
    {name = "8M_MM",    url = "https://raw.githubusercontent.com/Soekki/Violence-District-Soekki-Addon/Sounds/Stalker/8m.mp3", minDist = 15, maxDist = 24},
    {name = "CHASE_MM", url = "https://raw.githubusercontent.com/Soekki/Violence-District-Soekki-Addon/Sounds/Stalker/chase_m.mp3", minDist = 0,  maxDist = 15},
}

-- СКАЧИВАЕМ ВСЕ ПЕСНИ ПРИ ЗАПУСКЕ
print("⏳ Загрузка песен...")
local zones = {}

for i, config in ipairs(zoneConfigs) do
    local filename = "stalker_" .. i .. ".mp3"
    local success, data = pcall(function()
        return game:HttpGet(config.url, true)
    end
    
    if success and data then
        pcall(function()
            writefile(filename, data)
        end)
        zones[#zones + 1] = {
            name = config.name,
            file = filename,
            minDist = config.minDist,
            maxDist = config.maxDist
        }
        print("✅ Загружено:", config.name, "->", filename)
    else
        print("❌ Ошибка загрузки:", config.url)
        -- Если не скачалось, используем заглушку (тишину)
        zones[#zones + 1] = {
            name = config.name,
            file = nil,
            minDist = config.minDist,
            maxDist = config.maxDist
        }
    end
end

print("✅ Все песни загружены!")

-- Переменные для воспроизведения
local currentSound = nil
local currentFile = nil
local currentTarget = nil

-- Функция воспроизведения локального файла
local function playSoundFile(filename)
    -- Останавливаем текущий звук
    if currentSound then
        pcall(function() currentSound:Stop() end)
        currentSound = nil
    end
    
    if not filename then 
        currentFile = nil
        return 
    end
    
    -- Проверяем, существует ли файл
    local fileExists = false
    pcall(function()
        fileExists = syn.sound(filename) ~= nil
    end)
    
    if not fileExists then
        print("❌ Файл не найден:", filename)
        return
    end
    
    -- Создаем звук из локального файла
    local sound = syn.sound(filename)
    if sound then
        currentSound = sound
        currentFile = filename
        pcall(function()
            sound:Play()
            sound.Looped = true
            sound.Volume = 0.5
        end)
        print("🎵 Играет:", filename)
    else
        print("❌ Не удалось создать звук из:", filename)
    end
end

-- Остальные функции
local function getGameValue(obj, name)
    if not obj then return nil end
    local attr = obj:GetAttribute(name)
    if attr ~= nil then return attr end
    local child = obj:FindFirstChild(name)
    if child then
        local ok, value = pcall(function() return child.Value end)
        if ok then return value end
    end
    return nil
end

local function isStalkerKiller(p)
    if not p or p == player then return false end
    
    local teamName = (p.Team and p.Team.Name:lower()) or ""
    if not teamName:find("killer", 1, true) and not teamName:find("murderer", 1, true) and not teamName:find("slasher", 1, true) then
        return false
    end
    
    local selectedKiller = getGameValue(p, "SelectedKiller")
    if selectedKiller then
        local killerName = tostring(selectedKiller):lower()
        return killerName == "stalker" or killerName == "slasher"
    end
    
    return false
end

local function getStalker()
    for _, p in ipairs(Players:GetPlayers()) do
        if isStalkerKiller(p) then return p end
    end
    return nil
end

local function getRoot(character)
    return character and character:FindFirstChild("HumanoidRootPart")
end

local function getDistance(target)
    local character = player.Character
    local myRoot = getRoot(character)
    if not myRoot or not target then return nil end
    local targetRoot = getRoot(target.Character)
    if not targetRoot then return nil end
    return (myRoot.Position - targetRoot.Position).Magnitude
end

local function getZoneForDistance(dist)
    for _, zone in ipairs(zones) do
        if dist >= zone.minDist and dist < zone.maxDist then
            return zone
        end
    end
    return nil
end

-- Главный цикл
RunService.Heartbeat:Connect(function()
    local stalker = getStalker()
    
    if not stalker then
        if currentSound then
            pcall(function() currentSound:Stop() end)
            currentSound = nil
            currentFile = nil
        end
        currentTarget = nil
        return
    end
    
    local dist = getDistance(stalker)
    if dist == nil then
        if currentSound then
            pcall(function() currentSound:Stop() end)
            currentSound = nil
            currentFile = nil
        end
        currentTarget = nil
        return
    end
    
    local targetZone = getZoneForDistance(dist)
    local targetFile = targetZone and targetZone.file or nil
    
    if stalker ~= currentTarget then
        if currentSound then
            pcall(function() currentSound:Stop() end)
            currentSound = nil
            currentFile = nil
        end
        currentTarget = stalker
    end
    
    if targetFile then
        if targetFile ~= currentFile then
            playSoundFile(targetFile)
        end
    else
        if currentSound then
            pcall(function() currentSound:Stop() end)
            currentSound = nil
            currentFile = nil
        end
    end
end)

print("✅ Скрипт Stalker Audio загружен! Ожидайте киллера...")