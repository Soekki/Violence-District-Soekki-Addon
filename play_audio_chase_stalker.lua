local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer

-- ЗДЕСЬ ВАШИ ПРЯМЫЕ ССЫЛКИ НА MP3 (с GitHub или другого хостинга)
local zones = {
    {name = "32M_MM",   soundUrl = "https://raw.githubusercontent.com/Soekki/Violence-District-Soekki-Addon/Sounds/Stalker/32m.mp3", minDist = 72, maxDist = 96},
    {name = "24M_MM",   soundUrl = "https://raw.githubusercontent.com/Soekki/Violence-District-Soekki-Addon/Sounds/Stalker/24m.mp3", minDist = 36, maxDist = 72},
    {name = "12M_MM",   soundUrl = "https://raw.githubusercontent.com/Soekki/Violence-District-Soekki-Addon/Sounds/Stalker/12m.mp3", minDist = 24, maxDist = 36},
    {name = "8M_MM",    soundUrl = "https://raw.githubusercontent.com/Soekki/Violence-District-Soekki-Addon/Sounds/Stalker/8m.mp3", minDist = 15, maxDist = 24},
    {name = "CHASE_MM", soundUrl = "https://raw.githubusercontent.com/Soekki/Violence-District-Soekki-Addon/Sounds/Stalker/chase_m.mp3", minDist = 0,  maxDist = 15},
}

local currentSound = nil  -- теперь это syn.sound объект
local currentTarget = nil

-- Функция для создания/проигрывания звука через syn.sound
local function playSound(url)
    if currentSound then
        currentSound:Stop()
        currentSound = nil
    end
    
    if url then
        currentSound = syn.sound(url, "http")
        if currentSound then
            currentSound:Play()
            currentSound.Looped = true
            currentSound.Volume = 0.5
            print("🎵 Играет:", url)
        end
    end
end

-- Остальные функции без изменений (getGameValue, isStalkerKiller, getStalker, getRoot, getDistance, getZoneForDistance)
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
    if not teamName:find("killer", 1, true) then return false end
    local selectedKiller = getGameValue(p, "SelectedKiller")
    return selectedKiller ~= nil and tostring(selectedKiller):lower() == "Slasher"
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
            currentSound:Stop()
            currentSound = nil
        end
        currentTarget = nil
        return
    end
    
    local dist = getDistance(stalker)
    if dist == nil then
        if currentSound then
            currentSound:Stop()
            currentSound = nil
        end
        currentTarget = nil
        return
    end
    
    local targetZone = getZoneForDistance(dist)
    local targetUrl = targetZone and targetZone.soundUrl or nil
    
    if stalker ~= currentTarget then
        if currentSound then
            currentSound:Stop()
            currentSound = nil
        end
        currentTarget = stalker
    end
    
    -- Если текущий звук не соответствует нужной зоне или его нет
    if targetUrl then
        if not currentSound or currentSound._url ~= targetUrl then
            playSound(targetUrl)
        end
    else
        if currentSound then
            currentSound:Stop()
            currentSound = nil
        end
    end
end)