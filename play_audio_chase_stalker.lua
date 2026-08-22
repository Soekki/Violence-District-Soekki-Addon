local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer

-- ВАШИ ССЫЛКИ
local zones = {
    {name = "32M_MM",   soundUrl = "https://raw.githubusercontent.com/Soekki/Violence-District-Soekki-Addon/Sounds/Stalker/32m.mp3", minDist = 72, maxDist = 96},
    {name = "24M_MM",   soundUrl = "https://raw.githubusercontent.com/Soekki/Violence-District-Soekki-Addon/Sounds/Stalker/24m.mp3", minDist = 36, maxDist = 72},
    {name = "12M_MM",   soundUrl = "https://raw.githubusercontent.com/Soekki/Violence-District-Soekki-Addon/Sounds/Stalker/12m.mp3", minDist = 24, maxDist = 36},
    {name = "8M_MM",    soundUrl = "https://raw.githubusercontent.com/Soekki/Violence-District-Soekki-Addon/Sounds/Stalker/8m.mp3", minDist = 15, maxDist = 24},
    {name = "CHASE_MM", soundUrl = "https://raw.githubusercontent.com/Soekki/Violence-District-Soekki-Addon/Sounds/Stalker/chase_m.mp3", minDist = 0,  maxDist = 15},
}

local currentSound = nil
local currentUrl = nil
local currentTarget = nil

-- Функция воспроизведения с защитой
local function playSound(url)
    if currentSound then
        pcall(function() currentSound:Stop() end)
        currentSound = nil
    end
    
    if not url then return end
    
    -- Пробуем разные варианты syn.sound
    local sound = nil
    local success = false
    
    -- Вариант 1: syn.sound(url, "http")
    success, sound = pcall(function()
        return syn.sound(url, "http")
    end)
    
    -- Вариант 2: syn.sound({Url = url, Type = "http"})
    if not success or not sound then
        success, sound = pcall(function()
            return syn.sound({Url = url, Type = "http"})
        end)
    end
    
    -- Вариант 3: syn.sound(url) без второго аргумента
    if not success or not sound then
        success, sound = pcall(function()
            return syn.sound(url)
        end)
    end
    
    if success and sound then
        currentSound = sound
        currentUrl = url
        pcall(function()
            sound:Play()
            sound.Looped = true
            sound.Volume = 0.5
        end)
        print("🎵 Играет:", url)
        return true
    else
        print("❌ Не удалось загрузить звук:", url)
        if not success then
            print("Ошибка:", sound)
        end
        return false
    end
end

-- Проверка киллера (исправлена)
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
    -- Проверяем, является ли игрок убийцей (любое имя команды)
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
            currentUrl = nil
        end
        currentTarget = nil
        return
    end
    
    local dist = getDistance(stalker)
    if dist == nil then
        if currentSound then
            pcall(function() currentSound:Stop() end)
            currentSound = nil
            currentUrl = nil
        end
        currentTarget = nil
        return
    end
    
    local targetZone = getZoneForDistance(dist)
    local targetUrl = targetZone and targetZone.soundUrl or nil
    
    if stalker ~= currentTarget then
        if currentSound then
            pcall(function() currentSound:Stop() end)
            currentSound = nil
            currentUrl = nil
        end
        currentTarget = stalker
    end
    
    if targetUrl then
        if targetUrl ~= currentUrl then
            playSound(targetUrl)
        end
    else
        if currentSound then
            pcall(function() currentSound:Stop() end)
            currentSound = nil
            currentUrl = nil
        end
    end
end)

print("✅ Скрипт Stalker Audio загружен!")