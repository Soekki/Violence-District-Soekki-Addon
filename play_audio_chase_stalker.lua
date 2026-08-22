local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer

local zones = {
    {name = "32M_MM",   soundId = "rbxassetid://77174307474714", minDist = 72, maxDist = 96},
    {name = "24M_MM",   soundId = "rbxassetid://95921720815506", minDist = 36, maxDist = 72},
    {name = "12M_MM",   soundId = "rbxassetid://74560695406248", minDist = 24, maxDist = 36},
    {name = "8M_MM",    soundId = "rbxassetid://88596135233641", minDist = 15, maxDist = 24},
    {name = "CHASE_MM", soundId = "rbxassetid://122923530012311", minDist = 0,  maxDist = 15},
}

local sound = Instance.new("Sound")
sound.Name = "LocalStalkerChaseMusic"
sound.Looped = true
sound.Volume = 0.5
sound.Parent = player:WaitForChild("PlayerGui")

local currentSoundId = nil
local currentTarget = nil

local function getGameValue(obj, name)
    if not obj then return nil end

    local attr = obj:GetAttribute(name)
    if attr ~= nil then
        return attr
    end

    local child = obj:FindFirstChild(name)
    if child then
        local ok, value = pcall(function()
            return child.Value
        end)
        if ok then
            return value
        end
    end

    return nil
end

local function isStalkerKiller(p)
    if not p or p == player then
        return false
    end

    local teamName = (p.Team and p.Team.Name:lower()) or ""
    if not teamName:find("killer", 1, true) then
        return false
    end

    local selectedKiller = getGameValue(p, "SelectedKiller")
    return selectedKiller ~= nil
        and tostring(selectedKiller):lower() == "stalker"
end

local function getStalker()
    for _, p in ipairs(Players:GetPlayers()) do
        if isStalkerKiller(p) then
            return p
        end
    end

    return nil
end

local function getRoot(character)
    return character and character:FindFirstChild("HumanoidRootPart")
end

local function getDistance(target)
    local character = player.Character
    local myRoot = getRoot(character)
    if not myRoot or not target then
        return nil
    end

    local targetRoot = getRoot(target.Character)
    if not targetRoot then
        return nil
    end

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

local function stopMusic()
    if currentSoundId ~= nil then
        sound:Stop()
        currentSoundId = nil
    end

    currentTarget = nil
end

RunService.Heartbeat:Connect(function()
    local stalker = getStalker()

    if not stalker then
        stopMusic()
        return
    end

    local dist = getDistance(stalker)

    if dist == nil then
        stopMusic()
        return
    end

    local targetZone = getZoneForDistance(dist)
    local targetSoundId = targetZone and targetZone.soundId or nil

    if stalker ~= currentTarget then
        sound:Stop()
        currentSoundId = nil
        currentTarget = stalker
    end

    if targetSoundId ~= currentSoundId then
        sound:Stop()

        if targetSoundId then
            sound.SoundId = targetSoundId
            sound:Play()
        end

        currentSoundId = targetSoundId
    end
end)
