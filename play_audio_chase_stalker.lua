print("🔥 STALKER AUDIO VERSION: WAV-TEST-001")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")

local player = Players.LocalPlayer

-- =========================================================
-- НАСТРОЙКИ
-- =========================================================

-- mp3

local zoneConfigs = {
    {
        name = "32M_MM",
        url = "https://raw.githubusercontent.com/Soekki/Violence-District-Soekki-Addon/Sounds/Stalker/32m.wav",
        minDist = 72,
        maxDist = 96
    },

    {
        name = "24M_MM",
        url = "https://raw.githubusercontent.com/Soekki/Violence-District-Soekki-Addon/Sounds/Stalker/24m.wav",
        minDist = 36,
        maxDist = 72
    },

    {
        name = "12M_MM",
        url = "https://raw.githubusercontent.com/Soekki/Violence-District-Soekki-Addon/Sounds/Stalker/12m.wav",
        minDist = 24,
        maxDist = 36
    },

    {
        name = "8M_MM",
        url = "https://raw.githubusercontent.com/Soekki/Violence-District-Soekki-Addon/Sounds/Stalker/8m.wav",
        minDist = 15,
        maxDist = 24
    },

    {
        name = "CHASE_MM",
        url = "https://raw.githubusercontent.com/Soekki/Violence-District-Soekki-Addon/Sounds/Stalker/chase_m.wav",
        minDist = 0,
        maxDist = 15
    }
}

-- =========================================================
-- ПРОВЕРКА API XENO
-- =========================================================

print("========================================")
print("   STALKER AUDIO / XENO")
print("========================================")

print("writefile:", type(writefile))
print("isfile:", type(isfile))
print("getcustomasset:", type(getcustomasset))
print("getsynasset:", type(getsynasset))

if type(writefile) ~= "function" then
    warn("❌ writefile недоступен!")
    return
end

if type(getcustomasset) ~= "function" and type(getsynasset) ~= "function" then
    warn("❌ Нет getcustomasset/getsynasset!")
    warn("❌ Xeno не может загрузить локальные звуки.")
    return
end

-- =========================================================
-- ПОЛУЧЕНИЕ LOCAL ASSET
-- =========================================================

local function getLocalAsset(filename)

    -- Основной вариант
    if type(getcustomasset) == "function" then
        local ok, result = pcall(function()
            return getcustomasset(filename)
        end)

        if ok and result then
            return result
        end
    end

    -- Запасной вариант
    if type(getsynasset) == "function" then
        local ok, result = pcall(function()
            return getsynasset(filename)
        end)

        if ok and result then
            return result
        end
    end

    return nil
end

-- =========================================================
-- ЗАГРУЗКА ЗВУКОВ
-- =========================================================

print("")
print("⏳ Проверяем звуки...")

local zones = {}

for i, config in ipairs(zoneConfigs) do

    local filename = "stalker_" .. i .. ".wav"

    local downloaded = false

    -- Если файла ещё нет — скачиваем
    if type(isfile) == "function" and isfile(filename) then

        print("📁 Уже есть:", filename)
        downloaded = true

    else

        print("⬇️ Скачивание:", config.name)

        local success, data = pcall(function()
            return game:HttpGet(config.url)
        end)

        if success and data and #data > 0 then

            local writeSuccess, writeError = pcall(function()
                writefile(filename, data)
            end)

            if writeSuccess then
                downloaded = true
                print("✅ Скачано:", filename)
            else
                warn("❌ Ошибка writefile:", writeError)
            end

        else

            warn("❌ Не удалось скачать:")
            warn(config.url)

        end
    end

    zones[#zones + 1] = {
        name = config.name,
        file = downloaded and filename or nil,
        minDist = config.minDist,
        maxDist = config.maxDist
    }

    if not downloaded then
        warn("⚠️ Зона без звука:", config.name)
    end
end

print("")
print("========================================")
print("   ЗАГРУЗКА ЗАВЕРШЕНА")
print("========================================")

for _, zone in ipairs(zones) do
    if zone.file then
        print("✅", zone.name, "->", zone.file)
    else
        print("❌", zone.name, "-> НЕТ ФАЙЛА")
    end
end

-- =========================================================
-- ПЕРЕМЕННЫЕ ЗВУКА
-- =========================================================

local currentSound = nil
local currentFile = nil
local currentTarget = nil

-- =========================================================
-- ОСТАНОВКА ТЕКУЩЕГО ЗВУКА
-- =========================================================

local function stopCurrentSound()

    if currentSound then

        pcall(function()
            currentSound:Stop()
        end)

        pcall(function()
            currentSound:Destroy()
        end)

        currentSound = nil
    end

    currentFile = nil
end

-- =========================================================
-- ВОСПРОИЗВЕДЕНИЕ ЛОКАЛЬНОГО MP3
-- =========================================================

local function playSoundFile(filename)

    -- Уже играет нужный файл
    if currentFile == filename and currentSound then
        return
    end

    -- Останавливаем предыдущий
    stopCurrentSound()

    if not filename then
        return
    end

    print("🔊 Загружаем:", filename)

    -- Получаем content URL
    local assetUrl = getLocalAsset(filename)

    if not assetUrl then
        warn("❌ getcustomasset не смог загрузить:", filename)
        return
    end

    print("🔗 Asset:", assetUrl)

    -- Создаём Sound
    local sound = Instance.new("Sound")

    sound.Name = "StalkerAudio"
    sound.SoundId = assetUrl
    sound.Volume = 0.5
    sound.Looped = true
    sound.Parent = SoundService

    currentSound = sound
    currentFile = filename

    -- Запускаем
    local ok, err = pcall(function()
        sound:Play()
    end)

    if not ok then

        warn("❌ Ошибка Play():", err)

        pcall(function()
            sound:Destroy()
        end)

        currentSound = nil
        currentFile = nil

        return
    end

    print("🎵 Играет:", filename)
end

-- =========================================================
-- ПОЛУЧЕНИЕ ЗНАЧЕНИЯ ИЗ ATTRIBUTE / VALUE
-- =========================================================

local function getGameValue(obj, name)

    if not obj then
        return nil
    end

    -- Attribute
    local attr = obj:GetAttribute(name)

    if attr ~= nil then
        return attr
    end

    -- Value object
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

-- =========================================================
-- ПРОВЕРКА: ЯВЛЯЕТСЯ ЛИ ИГРОК STALKER
-- =========================================================

local function isStalkerKiller(p)

    if not p or p == player then
        return false
    end

    -- Проверяем Team
    local teamName = ""

    if p.Team then
        teamName = string.lower(p.Team.Name)
    end

    local isKillerTeam =
        teamName:find("killer", 1, true)
        or teamName:find("murderer", 1, true)
        or teamName:find("slasher", 1, true)

    if not isKillerTeam then
        return false
    end

    -- Проверяем SelectedKiller
    local selectedKiller = getGameValue(p, "SelectedKiller")

    if selectedKiller then

        local killerName = string.lower(tostring(selectedKiller))

        if killerName == "stalker" or killerName == "slasher" then
            return true
        end

        return false
    end

    return false
end

-- =========================================================
-- ПОИСК STALKER
-- =========================================================

local function getStalker()

    for _, p in ipairs(Players:GetPlayers()) do

        if isStalkerKiller(p) then
            return p
        end
    end

    return nil
end

-- =========================================================
-- ROOT PART
-- =========================================================

local function getRoot(character)

    if not character then
        return nil
    end

    return character:FindFirstChild("HumanoidRootPart")
end

-- =========================================================
-- РАССТОЯНИЕ ДО STALKER
-- =========================================================

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

-- =========================================================
-- ВЫБОР ЗОНЫ
-- =========================================================

local function getZoneForDistance(dist)

    for _, zone in ipairs(zones) do

        if dist >= zone.minDist and dist < zone.maxDist then
            return zone
        end
    end

    return nil
end

-- =========================================================
-- ОСНОВНОЙ ЦИКЛ
-- =========================================================

RunService.Heartbeat:Connect(function()

    local stalker = getStalker()

    -- Нет Stalker
    if not stalker then

        if currentSound then
            stopCurrentSound()
        end

        currentTarget = nil

        return
    end

    -- Получаем дистанцию
    local dist = getDistance(stalker)

    if dist == nil then

        if currentSound then
            stopCurrentSound()
        end

        currentTarget = nil

        return
    end

    -- Если появился другой Stalker
    if stalker ~= currentTarget then

        stopCurrentSound()

        currentTarget = stalker
    end

    -- Выбираем звук по расстоянию
    local targetZone = getZoneForDistance(dist)

    local targetFile = targetZone and targetZone.file or nil

    -- Показываем дистанцию для отладки
    -- Можно убрать эти print, если они мешают
    -- print("Stalker:", math.floor(dist), "m")

    if targetFile then

        if targetFile ~= currentFile then
            playSoundFile(targetFile)
        end

    else

        if currentSound then
            stopCurrentSound()
        end
    end
end)

-- =========================================================
-- ГОТОВО
-- =========================================================

print("")
print("========================================")
print("✅ STALKER AUDIO ЗАПУЩЕН")
print("🎵 Ожидание Stalker...")
print("========================================")