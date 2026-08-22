local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")

local player = Players.LocalPlayer

-- =========================================================
-- STALKER AUDIO / XENO
-- =========================================================

print("========================================")
print("   STALKER AUDIO / XENO")
print("========================================")

-- =========================================================
-- НАСТРОЙКИ
-- =========================================================

local SOUND_VOLUME = 0.5

-- Как часто проверять расстояние до Stalker.
-- 0.05 = примерно 20 проверок в секунду.
local UPDATE_INTERVAL = 0.05

-- Версия имён локальных файлов.
-- Благодаря этому старые битые stalker_1.wav и т.п.
-- не будут использоваться.
local CACHE_VERSION = "v2"

-- =========================================================
-- ЗВУКИ
-- =========================================================

local zoneConfigs = {

    {
        name = "32M_MM",

        -- ВАЖНО:
        -- здесь обязательно должен быть /main/
        url = "https://raw.githubusercontent.com/Soekki/Violence-District-Soekki-Addon/main/Sounds/Stalker/32m.wav",

        minDist = 72,
        maxDist = 96
    },

    {
        name = "24M_MM",

        url = "https://raw.githubusercontent.com/Soekki/Violence-District-Soekki-Addon/main/Sounds/Stalker/24m.wav",

        minDist = 36,
        maxDist = 72
    },

    {
        name = "12M_MM",

        url = "https://raw.githubusercontent.com/Soekki/Violence-District-Soekki-Addon/main/Sounds/Stalker/12m.wav",

        minDist = 24,
        maxDist = 36
    },

    {
        name = "8M_MM",

        url = "https://raw.githubusercontent.com/Soekki/Violence-District-Soekki-Addon/main/Sounds/Stalker/8m.wav",

        minDist = 15,
        maxDist = 24
    },

    {
        name = "CHASE_MM",

        url = "https://raw.githubusercontent.com/Soekki/Violence-District-Soekki-Addon/main/Sounds/Stalker/chase_m.wav",

        minDist = 0,
        maxDist = 15
    }
}

-- =========================================================
-- ПРОВЕРКА API XENO
-- =========================================================

print("writefile:", type(writefile))
print("isfile:", type(isfile))
print("readfile:", type(readfile))
print("getcustomasset:", type(getcustomasset))
print("getsynasset:", type(getsynasset))

if type(writefile) ~= "function" then
    warn("❌ writefile недоступен!")
    warn("❌ Xeno не сможет сохранить WAV-файлы.")
    return
end

if type(getcustomasset) ~= "function"
    and type(getsynasset) ~= "function" then

    warn("❌ Нет getcustomasset/getsynasset!")
    warn("❌ Xeno не сможет загрузить локальные звуки.")
    return
end

-- =========================================================
-- ПРОВЕРКА WAV
-- =========================================================

local function isValidWav(data)

    if type(data) ~= "string" then
        return false
    end

    -- WAV должен быть минимум 12 байт.
    if #data < 12 then
        return false
    end

    -- WAV начинается с RIFF
    local riff = string.sub(data, 1, 4)

    -- В позиции 9-12 должно находиться WAVE
    local wave = string.sub(data, 9, 12)

    if riff ~= "RIFF" then
        return false
    end

    if wave ~= "WAVE" then
        return false
    end

    return true
end

-- =========================================================
-- ПОЛУЧЕНИЕ LOCAL ASSET
-- =========================================================

local function getLocalAsset(filename)

    -- Основной вариант Xeno
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
-- ПОЛУЧЕНИЕ ИМЕНИ КЭШ-ФАЙЛА
-- =========================================================

local function getCacheFilename(index, config)

    return "stalker_" .. CACHE_VERSION .. "_" .. index .. ".wav"
end

-- =========================================================
-- ПРОВЕРКА УЖЕ СКАЧАННОГО ФАЙЛА
-- =========================================================

local function isCachedWavValid(filename)

    if type(isfile) ~= "function" then
        return false
    end

    local exists = false

    local ok = pcall(function()
        exists = isfile(filename)
    end)

    if not ok or not exists then
        return false
    end

    -- Если readfile доступен — проверяем содержимое.
    if type(readfile) == "function" then

        local readOk, data = pcall(function()
            return readfile(filename)
        end)

        if not readOk then
            return false
        end

        return isValidWav(data)
    end

    -- Если readfile нет, файл считаем существующим.
    -- Но на первом запуске новый CACHE_VERSION
    -- всё равно заставит скачать новый файл.
    return true
end

-- =========================================================
-- СКАЧИВАНИЕ WAV
-- =========================================================

local function downloadSound(config, filename)

    print("")
    print("⬇️ Скачивание:", config.name)
    print("🔗 URL:", config.url)

    local success, data = pcall(function()
        return game:HttpGet(config.url)
    end)

    if not success then

        warn("❌ HttpGet завершился ошибкой:")
        warn(tostring(data))

        return false
    end

    if type(data) ~= "string" then

        warn("❌ GitHub вернул данные неизвестного типа.")

        return false
    end

    if #data == 0 then

        warn("❌ GitHub вернул пустой ответ.")

        return false
    end

    -- Очень важная проверка.
    -- Без неё HTML-страница GitHub может сохраниться как .wav.
    if not isValidWav(data) then

        warn("❌ Ответ НЕ является корректным WAV!")
        warn("❌ Файл не будет сохранён.")
        warn("❌ Первые 32 байта ответа:")

        local preview = string.sub(data, 1, 32)

        warn(preview)

        return false
    end

    print("✅ WAV проверен")
    print("📦 Размер:", #data, "bytes")

    local writeSuccess, writeError = pcall(function()
        writefile(filename, data)
    end)

    if not writeSuccess then

        warn("❌ Ошибка writefile:")
        warn(tostring(writeError))

        return false
    end

    -- Проверяем, что файл реально записался.
    if type(readfile) == "function" then

        local checkOk, savedData = pcall(function()
            return readfile(filename)
        end)

        if not checkOk or not isValidWav(savedData) then

            warn("❌ После записи файл оказался повреждённым!")

            return false
        end
    end

    print("✅ Сохранено:", filename)

    return true
end

-- =========================================================
-- ЗАГРУЗКА ВСЕХ ЗВУКОВ
-- =========================================================

print("")
print("========================================")
print("   ПРОВЕРКА STALKER WAV")
print("========================================")

local zones = {}

for i, config in ipairs(zoneConfigs) do

    local filename = getCacheFilename(i, config)

    local downloaded = false

    -- Проверяем существующий файл.
    if isCachedWavValid(filename) then

        print("📁 Уже есть корректный WAV:", filename)

        downloaded = true

    else

        -- Если старого файла нет или он битый,
        -- скачиваем заново.
        print("🔄 Файл отсутствует или повреждён:", filename)

        downloaded = downloadSound(config, filename)

    end

    zones[#zones + 1] = {

        name = config.name,

        file = downloaded and filename or nil,

        minDist = config.minDist,

        maxDist = config.maxDist
    }

    if downloaded then

        print(
            "✅",
            config.name,
            "|",
            config.minDist .. "-" .. config.maxDist .. "m",
            "|",
            filename
        )

    else

        warn(
            "❌",
            config.name,
            "-> звук недоступен"
        )

    end
end

print("")
print("========================================")
print("   ЗАГРУЗКА ЗАВЕРШЕНА")
print("========================================")

for _, zone in ipairs(zones) do

    if zone.file then

        print(
            "✅",
            zone.name,
            "->",
            zone.file
        )

    else

        warn(
            "❌",
            zone.name,
            "-> НЕТ ФАЙЛА"
        )

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
-- ВОСПРОИЗВЕДЕНИЕ ЛОКАЛЬНОГО WAV
-- =========================================================

local function playSoundFile(filename)

    if not filename then
        stopCurrentSound()
        return
    end

    -- Если уже играет нужный файл,
    -- ничего не делаем.
    if currentFile == filename
        and currentSound then

        return
    end

    -- Останавливаем предыдущий звук.
    stopCurrentSound()

    print("")
    print("🔊 Загружаем:", filename)

    local assetUrl = getLocalAsset(filename)

    if not assetUrl then

        warn(
            "❌ getcustomasset/getsynasset не смог загрузить:",
            filename
        )

        return
    end

    print("🔗 Asset:", assetUrl)

    -- =====================================================
    -- СОЗДАНИЕ SOUND
    -- =====================================================

    local sound = Instance.new("Sound")

    sound.Name = "StalkerAudio"

    sound.SoundId = assetUrl

    sound.Volume = SOUND_VOLUME

    sound.Looped = true

    sound.Parent = SoundService

    currentSound = sound
    currentFile = filename

    -- =====================================================
    -- PRELOAD
    -- =====================================================

    local preloadOk, preloadError = pcall(function()

        local ContentProvider =
            game:GetService("ContentProvider")

        ContentProvider:PreloadAsync({
            sound
        })

    end)

    if not preloadOk then

        warn(
            "⚠️ PreloadAsync ошибка:",
            tostring(preloadError)
        )

    end

    -- =====================================================
    -- PLAY
    -- =====================================================

    local playOk, playError = pcall(function()

        sound:Play()

    end)

    if not playOk then

        warn(
            "❌ Ошибка Play():",
            tostring(playError)
        )

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
-- ПОЛУЧЕНИЕ ATTRIBUTE / VALUE
-- =========================================================

local function getGameValue(obj, name)

    if not obj then
        return nil
    end

    -- Attribute
    local attr

    local attrOk = pcall(function()

        attr = obj:GetAttribute(name)

    end)

    if attrOk and attr ~= nil then

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

    -- =====================================================
    -- TEAM
    -- =====================================================

    local teamName = ""

    if p.Team then

        teamName = string.lower(
            tostring(p.Team.Name)
        )

    end

    local isKillerTeam =
        teamName:find("killer", 1, true)
        or teamName:find("murderer", 1, true)
        or teamName:find("slasher", 1, true)

    if not isKillerTeam then

        return false
    end

    -- =====================================================
    -- SELECTED KILLER
    -- =====================================================

    local selectedKiller =
        getGameValue(p, "SelectedKiller")

    if selectedKiller ~= nil then

        local killerName =
            string.lower(
                tostring(selectedKiller)
            )

        if killerName == "stalker"
            or killerName == "slasher" then

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

    for _, p in ipairs(
        Players:GetPlayers()
    ) do

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

    return character:FindFirstChild(
        "HumanoidRootPart"
    )
end

-- =========================================================
-- ПОЛУЧЕНИЕ ДИСТАНЦИИ
-- =========================================================

local function getDistance(target)

    if not target then
        return nil
    end

    local character =
        player.Character

    if not character then
        return nil
    end

    local myRoot =
        getRoot(character)

    if not myRoot then
        return nil
    end

    local targetRoot =
        getRoot(target.Character)

    if not targetRoot then
        return nil
    end

    return (
        myRoot.Position
        - targetRoot.Position
    ).Magnitude
end

-- =========================================================
-- ВЫБОР ЗОНЫ
-- =========================================================

local function getZoneForDistance(dist)

    if not dist then
        return nil
    end

    for _, zone in ipairs(zones) do

        if dist >= zone.minDist
            and dist < zone.maxDist then

            return zone

        end
    end

    return nil
end

-- =========================================================
-- ОСНОВНОЙ ЦИКЛ
-- =========================================================

local elapsed = 0

RunService.Heartbeat:Connect(function(deltaTime)

    elapsed = elapsed + deltaTime

    -- Не нужно проверять всё 60+ раз в секунду.
    if elapsed < UPDATE_INTERVAL then
        return
    end

    elapsed = 0

    -- =====================================================
    -- ПОИСК STALKER
    -- =====================================================

    local stalker = getStalker()

    -- Нет Stalker
    if not stalker then

        if currentSound then
            stopCurrentSound()
        end

        currentTarget = nil

        return
    end

    -- =====================================================
    -- ПОЛУЧЕНИЕ ДИСТАНЦИИ
    -- =====================================================

    local dist =
        getDistance(stalker)

    if dist == nil then

        if currentSound then
            stopCurrentSound()
        end

        currentTarget = nil

        return
    end

    -- =====================================================
    -- ЕСЛИ STALKER СМЕНИЛСЯ
    -- =====================================================

    if stalker ~= currentTarget then

        stopCurrentSound()

        currentTarget = stalker

        print(
            "🎯 Найден Stalker:",
            stalker.Name
        )

    end

    -- =====================================================
    -- ВЫБОР ЗОНЫ
    -- =====================================================

    local targetZone =
        getZoneForDistance(dist)

    local targetFile =
        targetZone
        and targetZone.file
        or nil

    -- =====================================================
    -- DEBUG
    -- =====================================================

    -- Если хочешь видеть дистанцию,
    -- раскомментируй:
    --
    -- print(
    --     "Stalker:",
    --     stalker.Name,
    --     "Distance:",
    --     math.floor(dist),
    --     "m"
    -- )

    -- =====================================================
    -- ПРОИГРЫВАНИЕ
    -- =====================================================

    if targetFile then

        if targetFile ~= currentFile then

            print(
                "📏 Дистанция:",
                math.floor(dist),
                "m"
            )

            print(
                "🎵 Зона:",
                targetZone.name
            )

            playSoundFile(targetFile)

        end

    else

        -- Дальше 96 метров
        -- или звук для зоны отсутствует.
        if currentSound then

            print(
                "🔇 Stalker слишком далеко:",
                math.floor(dist),
                "m"
            )

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