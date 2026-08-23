-- =========================================================
-- STALKER + MASKED + KILLER CUSTOM CHASE MUSIC
-- =========================================================
--
-- 1. Блокирует стандартную музыку Killer (ChaseMusic)
-- 2. Находит Stalker
-- 3. Проигрывает собственные WAV по дистанции
--
-- Дистанции:
-- 0-15m   -> chase_m.wav
-- 15-24m  -> 8m.wav
-- 24-36m  -> 12m.wav
-- 36-72m  -> 24m.wav
-- 72-96m  -> 32m.wav
-- >96m    -> тишина
-- =========================================================


-- =========================================================
-- SERVICES
-- =========================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local UserInputService = game:GetService("UserInputService")
local ContentProvider = game:GetService("ContentProvider")

local player = Players.LocalPlayer


-- =========================================================
-- НАСТРОЙКИ
-- =========================================================

local SOUND_VOLUME = 0.5

-- На телефонах слишком частые проверки и переключения
-- могут давать лишние микрофризы.
local IS_MOBILE =
    UserInputService.TouchEnabled
    and not UserInputService.KeyboardEnabled

local UPDATE_INTERVAL =
    IS_MOBILE
    and 0.10
    or 0.05

-- Версия кэша.
-- Используется новое имя, чтобы старые битые WAV
-- не использовались повторно.
local CACHE_VERSION = "v2"


-- =========================================================
-- STALKER WAV
-- =========================================================

local zoneConfigs = {

    {
        name = "32M_MM",

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
-- MASKED WAV
-- =========================================================
-- 0-24m   -> chase_m.wav
-- 24-48m  -> 8m.wav
-- 48-72m  -> 16m.wav
-- 72-96m  -> 32m.wav
-- =========================================================

local maskedZoneConfigs = {

    {
        name = "32M_MASKED",
        url = "https://raw.githubusercontent.com/Soekki/Violence-District-Soekki-Addon/main/Sounds/Masked/32m.wav",
        minDist = 72,
        maxDist = 96
    },

    {
        name = "16M_MASKED",
        url = "https://raw.githubusercontent.com/Soekki/Violence-District-Soekki-Addon/main/Sounds/Masked/16m.wav",
        minDist = 48,
        maxDist = 72
    },

    {
        name = "8M_MASKED",
        url = "https://raw.githubusercontent.com/Soekki/Violence-District-Soekki-Addon/main/Sounds/Masked/8m.wav",
        minDist = 24,
        maxDist = 48
    },

    {
        name = "CHASE_MASKED",
        url = "https://raw.githubusercontent.com/Soekki/Violence-District-Soekki-Addon/main/Sounds/Masked/chase_m.wav",
        minDist = 0,
        maxDist = 24
    }
}


-- =========================================================
-- KILLER WAV
-- =========================================================
-- 0-15m    -> chase_k.wav
-- 15-24m   -> 8m.wav
-- 24-36m   -> 16m.wav
-- 36-72m   -> 24m.wav
-- 72-96m   -> 32m.wav
-- 96-128m  -> 64m.wav
-- >128m    -> тишина
-- =========================================================

local killerZoneConfigs = {

    {
        name = "64M_KILLER",
        url = "https://raw.githubusercontent.com/Soekki/Violence-District-Soekki-Addon/main/Sounds/Killer/64m.wav",
        minDist = 96,
        maxDist = 128
    },

    {
        name = "32M_KILLER",
        url = "https://raw.githubusercontent.com/Soekki/Violence-District-Soekki-Addon/main/Sounds/Killer/32m.wav",
        minDist = 72,
        maxDist = 96
    },

    {
        name = "24M_KILLER",
        url = "https://raw.githubusercontent.com/Soekki/Violence-District-Soekki-Addon/main/Sounds/Killer/24m.wav",
        minDist = 36,
        maxDist = 72
    },

    {
        name = "16M_KILLER",
        url = "https://raw.githubusercontent.com/Soekki/Violence-District-Soekki-Addon/main/Sounds/Killer/16m.wav",
        minDist = 24,
        maxDist = 36
    },

    {
        name = "8M_KILLER",
        url = "https://raw.githubusercontent.com/Soekki/Violence-District-Soekki-Addon/main/Sounds/Killer/8m.wav",
        minDist = 15,
        maxDist = 24
    },

    {
        name = "CHASE_KILLER",
        url = "https://raw.githubusercontent.com/Soekki/Violence-District-Soekki-Addon/main/Sounds/Killer/chase_k.wav",
        minDist = 0,
        maxDist = 15
    }
}


-- =========================================================
-- БЛОКИРОВКА ОРИГИНАЛЬНОЙ МУЗЫКИ KILLER
-- =========================================================
--
-- В игре стандартный звук называется "ChaseMusic".
-- Мы удаляем именно его.
--
-- Наш собственный звук называется "StalkerAudio",
-- поэтому он не затрагивается.
-- =========================================================

local function blockKillerMusic()

    for _, obj in ipairs(SoundService:GetChildren()) do

        if obj:IsA("Sound")
            and obj.Name == "ChaseMusic" then

            pcall(function()
                obj.Volume = 0
                obj:Stop()
                obj:Destroy()
            end)

        end
    end
end


-- =========================================================
-- ОТСЛЕЖИВАНИЕ СОЗДАНИЯ ChaseMusic
-- =========================================================
--
-- Игра может создать ChaseMusic уже после запуска
-- нашего скрипта.
--
-- Поэтому следим за SoundService.ChildAdded.
-- =========================================================

SoundService.ChildAdded:Connect(function(obj)

    if not obj:IsA("Sound") then
        return
    end

    if obj.Name ~= "ChaseMusic" then
        return
    end

    task.defer(function()

        if not obj then
            return
        end

        if not obj.Parent then
            return
        end

        pcall(function()
            obj.Volume = 0
            obj:Stop()
            obj:Destroy()
        end)

    end)

end)


-- Удаляем ChaseMusic, если он уже существует.
blockKillerMusic()


-- =========================================================
-- ПРОВЕРКА XENO API
-- =========================================================

print("========================================")
print("   STALKER + MASKED + KILLER AUDIO / XENO")
print("========================================")

print("writefile:", type(writefile))
print("isfile:", type(isfile))
print("readfile:", type(readfile))
print("getcustomasset:", type(getcustomasset))
print("getsynasset:", type(getsynasset))
print("📱 Mobile mode:", IS_MOBILE)


if type(writefile) ~= "function" then

    warn("❌ writefile недоступен!")
    warn("❌ Невозможно сохранить WAV.")

    return
end


if type(getcustomasset) ~= "function"
    and type(getsynasset) ~= "function" then

    warn("❌ getcustomasset/getsynasset недоступен!")

    return
end


-- =========================================================
-- ПРОВЕРКА WAV
-- =========================================================

local function isValidWav(data)

    if type(data) ~= "string" then
        return false
    end

    if #data < 12 then
        return false
    end

    local riff = string.sub(data, 1, 4)
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
-- GET LOCAL ASSET
-- =========================================================

local function getLocalAsset(filename)

    if type(getcustomasset) == "function" then

        local ok, result = pcall(function()

            return getcustomasset(filename)

        end)

        if ok and result then
            return result
        end
    end


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
-- CACHE FILENAME
-- =========================================================

local function getCacheFilename(prefix, index)

    return prefix
        .. "_"
        .. CACHE_VERSION
        .. "_"
        .. index
        .. ".wav"

end


-- =========================================================
-- ПРОВЕРКА КЭША
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


    if type(readfile) == "function" then

        local readOk, data = pcall(function()

            return readfile(filename)

        end)


        if not readOk then
            return false
        end


        return isValidWav(data)

    end


    return true
end


-- =========================================================
-- DOWNLOAD WAV
-- =========================================================

local function downloadSound(config, filename)

    print("")
    print("⬇️ Скачивание:", config.name)
    print("🔗 URL:", config.url)


    local success, data = pcall(function()

        return game:HttpGet(config.url)

    end)


    if not success then

        warn("❌ HttpGet ошибка:")
        warn(tostring(data))

        return false
    end


    if type(data) ~= "string" then

        warn("❌ GitHub вернул неизвестный тип данных.")

        return false
    end


    if #data == 0 then

        warn("❌ GitHub вернул пустой ответ.")

        return false
    end


    -- Проверяем настоящий WAV,
    -- чтобы HTML/ошибка GitHub не сохранились
    -- под расширением .wav.
    if not isValidWav(data) then

        warn("❌ Ответ НЕ является WAV!")
        warn("❌ Файл не сохранён.")

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


    -- Дополнительная проверка после записи.
    if type(readfile) == "function" then

        local checkOk, savedData = pcall(function()

            return readfile(filename)

        end)


        if not checkOk
            or not isValidWav(savedData) then

            warn("❌ Записанный файл повреждён!")

            return false
        end
    end


    print("✅ Сохранено:", filename)

    return true
end


-- =========================================================
-- ЗАГРУЗКА ВСЕХ STALKER WAV
-- =========================================================

print("")
print("========================================")
print("   ПРОВЕРКА STALKER WAV")
print("========================================")


local zones = {}


for i, config in ipairs(zoneConfigs) do

    local filename =
        getCacheFilename("stalker", i)


    local downloaded = false


    if isCachedWavValid(filename) then

        print(
            "📁 Уже есть корректный WAV:",
            filename
        )

        downloaded = true

    else

        print(
            "🔄 Файл отсутствует или повреждён:",
            filename
        )

        downloaded =
            downloadSound(
                config,
                filename
            )

    end


    zones[#zones + 1] = {

        name = config.name,

        file =
            downloaded
            and filename
            or nil,

        minDist = config.minDist,

        maxDist = config.maxDist

    }


    if downloaded then

        print(
            "✅",
            config.name,
            "|",
            config.minDist
                .. "-"
                .. config.maxDist
                .. "m",
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
-- ЗАГРУЗКА MASKED WAV
-- =========================================================

local maskedZones = {}

for i, config in ipairs(maskedZoneConfigs) do

    local filename =
        getCacheFilename("masked", i)

    local downloaded = false

    if isCachedWavValid(filename) then

        print(
            "📁 Уже есть корректный MASKED WAV:",
            filename
        )

        downloaded = true

    else

        print(
            "🔄 MASKED файл отсутствует или повреждён:",
            filename
        )

        downloaded =
            downloadSound(
                config,
                filename
            )

    end

    maskedZones[#maskedZones + 1] = {

        name = config.name,

        file =
            downloaded
            and filename
            or nil,

        minDist = config.minDist,

        maxDist = config.maxDist

    }

end


-- =========================================================
-- ЗАГРУЗКА KILLER WAV
-- =========================================================

local killerZones = {}

for i, config in ipairs(killerZoneConfigs) do

    local filename =
        getCacheFilename("killer", i)

    local downloaded = false

    if isCachedWavValid(filename) then

        print(
            "📁 Уже есть корректный KILLER WAV:",
            filename
        )

        downloaded = true

    else

        print(
            "🔄 KILLER файл отсутствует или повреждён:",
            filename
        )

        downloaded =
            downloadSound(
                config,
                filename
            )

    end

    killerZones[#killerZones + 1] = {

        name = config.name,

        file =
            downloaded
            and filename
            or nil,

        minDist = config.minDist,

        maxDist = config.maxDist

    }

end



-- =========================================================
-- ТЕКУЩИЙ STALKER SOUND
-- =========================================================

local currentSound = nil
local currentFile = nil
local currentTarget = nil
local currentKillerType = nil


-- =========================================================
-- STOP CURRENT SOUND
-- =========================================================

local function stopCurrentSound()

    if currentSound then

        pcall(function()

            currentSound:Stop()

        end)

    end


    currentSound = nil
    currentFile = nil

end


-- =========================================================
-- КЭШ CUSTOM SOUNDS
-- =========================================================
--
-- Раньше при каждой смене дистанционной зоны создавался
-- новый Sound и снова вызывался PreloadAsync().
--
-- На мобильных это может вызывать микрофризы и треск/заикание.
-- Теперь Sound создаётся один раз и переиспользуется.
-- =========================================================

local soundCache = {}


local function destroyCachedSounds()

    for _, sound in pairs(soundCache) do

        pcall(function()
            sound:Stop()
            sound:Destroy()
        end)

    end

    table.clear(soundCache)

end


local function createCachedSound(filename)

    if not filename then
        return nil
    end

    if soundCache[filename] then
        return soundCache[filename]
    end


    local assetUrl =
        getLocalAsset(filename)


    if not assetUrl then

        warn(
            "❌ Не удалось получить asset:",
            filename
        )

        return nil
    end


    local sound =
        Instance.new("Sound")


    sound.Name =
        "KillerCustomAudio_" .. filename


    sound.SoundId =
        assetUrl


    sound.Volume =
        SOUND_VOLUME


    sound.Looped =
        true


    sound.Parent =
        SoundService


    soundCache[filename] =
        sound


    return sound
end


local function preloadDownloadedSounds(zoneLists)

    local soundsToPreload = {}

    for _, zoneList in ipairs(zoneLists) do

        for _, zone in ipairs(zoneList) do

            if zone.file then

                local sound =
                    createCachedSound(
                        zone.file
                    )

                if sound then

                    soundsToPreload[
                        #soundsToPreload + 1
                    ] = sound

                end

            end

        end

    end


    if #soundsToPreload == 0 then
        return
    end


    print("")
    print("========================================")
    print("   ПОДГОТОВКА AUDIO CACHE")
    print("========================================")


    local ok, err =
        pcall(function()

            ContentProvider:PreloadAsync(
                soundsToPreload
            )

        end)


    if ok then

        print(
            "✅ Audio cache готов:",
            #soundsToPreload,
            "звуков"
        )

    else

        warn(
            "⚠️ Audio preload:",
            tostring(err)
        )

    end

end


local function playSoundFile(filename)

    if not filename then

        stopCurrentSound()

        return
    end


    -- Уже играет нужный звук.
    if currentFile == filename
        and currentSound then

        return
    end


    stopCurrentSound()


    print("")
    print("🔊 Переключение:", filename)


    local sound =
        createCachedSound(filename)


    if not sound then

        warn(
            "❌ Не удалось создать Sound:",
            filename
        )

        return
    end


    currentSound =
        sound

    currentFile =
        filename


    local playOk,
        playError =
        pcall(function()

            sound:Play()

        end)


    if not playOk then

        warn(
            "❌ Play() ошибка:",
            tostring(playError)
        )

        currentSound = nil
        currentFile = nil

        return
    end


    print(
        "🎵 Играет:",
        filename
    )

end


-- =========================================================
-- ПРЕДЗАГРУЗКА AUDIO
-- =========================================================
--
-- ВАЖНО: вызываем после объявления preloadDownloadedSounds().
-- =========================================================

preloadDownloadedSounds({
    zones,
    maskedZones,
    killerZones
})


-- =========================================================
-- ПОЛУЧЕНИЕ ATTRIBUTE / VALUE
-- =========================================================

local function getGameValue(obj, name)

    if not obj then
        return nil
    end


    -- Attribute
    local attr


    local attrOk =
        pcall(function()

            attr =
                obj:GetAttribute(name)

        end)


    if attrOk
        and attr ~= nil then

        return attr

    end


    -- Value object
    local child =
        obj:FindFirstChild(name)


    if child then

        local ok,
            value =
            pcall(function()

                return child.Value

            end)


        if ok then

            return value

        end

    end


    return nil

end


-- =========================================================
-- ПРОВЕРКА KILLER
-- =========================================================

local function getKillerType(p)

    if not p
        or p == player then

        return nil
    end

    local teamName = ""

    if p.Team then

        teamName =
            string.lower(
                tostring(
                    p.Team.Name
                )
            )
    end

    local isKillerTeam =
        teamName:find("killer", 1, true)
        or teamName:find("murderer", 1, true)
        or teamName:find("slasher", 1, true)

    if not isKillerTeam then
        return nil
    end

    local selectedKiller =
        getGameValue(
            p,
            "SelectedKiller"
        )

    if selectedKiller ~= nil then

        local killerName =
            string.lower(
                tostring(
                    selectedKiller
                )
            )

        if killerName == "masked" then
            return "Masked"
        end

        if killerName == "killer" then
            return "Killer"
        end

        if killerName == "stalker"
            or killerName == "slasher" then
            return "Stalker"
        end

        return nil
    end

    return nil
end


-- =========================================================
-- ПОИСК KILLER
-- =========================================================

local function getKiller()

    for _, p in ipairs(
        Players:GetPlayers()
    ) do

        local killerType =
            getKillerType(p)

        if killerType then
            return p, killerType
        end
    end

    return nil, nil
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
-- DISTANCE
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
        getRoot(
            target.Character
        )


    if not targetRoot then
        return nil
    end


    return (
        myRoot.Position
        - targetRoot.Position
    ).Magnitude

end


-- =========================================================
-- GET ZONE
-- =========================================================

local function getZoneForDistance(dist, zoneList)

    if not dist then
        return nil
    end


    for _, zone in ipairs(zoneList) do

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

RunService.Heartbeat:Connect(
    function(deltaTime)

        elapsed =
            elapsed
            + deltaTime

        if elapsed <
            UPDATE_INTERVAL then
            return
        end

        elapsed = 0

        blockKillerMusic()

        -- Ищем Stalker или Masked.
        local killer, killerType =
            getKiller()

        if not killer then

            if currentSound then
                stopCurrentSound()
            end

            currentTarget = nil
            currentKillerType = nil

            return
        end

        local activeZones

        if killerType == "Masked" then
            activeZones = maskedZones
        elseif killerType == "Killer" then
            activeZones = killerZones
        else
            activeZones = zones
        end

        local dist =
            getDistance(
                killer
            )

        if dist == nil then

            if currentSound then
                stopCurrentSound()
            end

            currentTarget = nil
            currentKillerType = nil

            return
        end

        -- Killer или его тип сменился.
        if killer ~= currentTarget
            or killerType ~= currentKillerType then

            stopCurrentSound()

            currentTarget = killer
            currentKillerType = killerType

            print(
                "🎯 Найден " .. killerType .. ":",
                killer.Name
            )
        end

        local targetZone =
            getZoneForDistance(
                dist,
                activeZones
            )

        local targetFile =
            targetZone
            and targetZone.file
            or nil

        if targetFile then

            if targetFile ~= currentFile then

                print(
                    "📏 " .. killerType .. " дистанция:",
                    math.floor(dist),
                    "m"
                )

                print(
                    "🎵 Зона:",
                    targetZone.name
                )

                playSoundFile(
                    targetFile
                )
            end

        else

            -- Stalker/Masked: максимум 96m.
            -- Killer: максимум 128m.
            if currentSound then

                print(
                    "🔇 " .. killerType .. " далеко:",
                    math.floor(dist),
                    "m"
                )

                stopCurrentSound()
            end
        end
    end
)


-- =========================================================
-- ГОТОВО
-- =========================================================

print("")
print("========================================")
print("✅ STALKER + MASKED + KILLER AUDIO ЗАПУЩЕН")
print("🚫 KILLER CHASE MUSIC ЗАБЛОКИРОВАНА")
print("🎵 Ожидание Stalker / Masked / Killer...")
print("📱 Mobile audio optimization:", IS_MOBILE)
print("========================================")