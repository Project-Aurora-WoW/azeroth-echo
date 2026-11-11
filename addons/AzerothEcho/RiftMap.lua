-- ============================================================
-- AzerothEcho — RiftMap.lua (WoW 3.3.5a)
-- Карта разломов Пустоты: пины на карте Northrend
-- с тултипами и уровнями опасности.
-- Лор-обоснование: docs/lore/universe.md (раздел «Ключевые локации»).
-- Открытие: /ae rifts или кнопка «Карта разломов» на панели.
-- ============================================================

local AE = AzerothEcho
local C = AE.COLOR

-- Разломы Пустоты (проценты от площади карты Northrend).
-- mapID 571 = Northrend в Map.dbc, но SetMapByID принимает НЕ его,
-- а areaID из WorldMapArea.dbc: для всего Нортренда это 485.
local NORTHREND_MAP_AREA_ID = 485

local RIFTS = {
    { name = "Драконий Погост — эпицентр", x = 66.8, y = 68.5, danger = 3, desc = "Осколок Трона. Главные разломы." },
    { name = "Зул'Драк — Храм Шёпота",     x = 74.5, y = 22.5, danger = 2, desc = "Алтари Культа Усмешки Бездны." },
    { name = "Бесплодные земли — перевал", x = 47.0, y = 39.0, danger = 1, desc = "Перевалочный пункт Культа." },
}

local RIFT_PIN_COLORS = {
    [1] = { r = 0.4,  g = 0.7,  b = 1.0 },   -- низкая опасность: голубой
    [2] = { r = 1.0,  g = 0.6,  b = 0.1 },   -- средняя: оранжевый
    [3] = { r = 1.0,  g = 0.15, b = 0.15 },  -- высокая: красный
}

local RIFT_DANGER_COLORS = { C.blue, C.orange, C.red }
local RIFT_DANGER_NAMES  = { "низкая", "средняя", "высокая" }

-- ============================================================
-- Пины
-- ============================================================

local riftPins = {}

-- Полотно карты: WorldMapButton — именно та область, по которой считаются
-- проценты. WorldMapFrame включает заголовок и рамки, из-за чего пины,
-- привязанные к нему, уезжали за пределы видимой карты.
local function GetMapCanvas()
    if WorldMapButton then return WorldMapButton end
    if WorldMapDetailFrame then return WorldMapDetailFrame end
    return WorldMapFrame
end

local function PositionPins()
    local canvas = GetMapCanvas()
    if not canvas then return end
    local w, h = canvas:GetWidth(), canvas:GetHeight()
    if not w or not h or w <= 1 or h <= 1 then return end

    for i, pin in ipairs(riftPins) do
        local rift = RIFTS[i]
        if rift then
            pin:ClearAllPoints()
            pin:SetPoint("CENTER", canvas, "TOPLEFT",
                (rift.x / 100) * w,
                -(rift.y / 100) * h)
        end
    end
end

local function CreateRiftPin(index, rift)
    local canvas = GetMapCanvas()
    local pin = CreateFrame("Frame", "AzerothEchoRiftPin" .. index, canvas)
    pin:SetWidth(20)
    pin:SetHeight(20)
    pin:SetFrameStrata("TOOLTIP")
    pin:SetFrameLevel((canvas:GetFrameLevel() or 1) + 10)

    local tex = pin:CreateTexture(nil, "OVERLAY")
    tex:SetAllPoints(pin)
    tex:SetTexture("Interface\\Minimap\\Ping")
    local color = RIFT_PIN_COLORS[rift.danger] or RIFT_PIN_COLORS[1]
    tex:SetVertexColor(color.r, color.g, color.b)

    pin:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText((RIFT_DANGER_COLORS[rift.danger] or C.blue) .. rift.name .. "|r")
        GameTooltip:AddLine(rift.desc, 0.8, 0.8, 0.8, true)
        GameTooltip:AddLine("Опасность: " .. RIFT_DANGER_NAMES[rift.danger] ..
            " (" .. string.rep("*", rift.danger) .. ")", 1, 1, 0.4)
        GameTooltip:Show()
    end)
    pin:SetScript("OnLeave", function() GameTooltip:Hide() end)

    return pin
end

local function ClearRiftPins()
    for _, pin in ipairs(riftPins) do
        pin:Hide()
        pin:SetParent(nil)
    end
    riftPins = {}
end

-- Пересчёт позиций, пока карта открыта: SetMapByID меняет размер полотна,
-- и фиксированная привязка после смены карты становится неверной.
-- Хуки ставятся один раз, иначе они накапливались бы при каждом открытии.
local hooksInstalled = false

local function EnsureHooks()
    if hooksInstalled or not WorldMapFrame then return end
    hooksInstalled = true

    local acc = 0
    WorldMapFrame:HookScript("OnUpdate", function(_, elapsed)
        acc = acc + elapsed
        if acc < 0.2 then return end
        acc = 0
        if WorldMapFrame:IsShown() and #riftPins > 0 then
            PositionPins()
        end
    end)

    WorldMapFrame:HookScript("OnShow", function()
        for _, pin in ipairs(riftPins) do pin:Show() end
        PositionPins()
    end)

    WorldMapFrame:HookScript("OnHide", function()
        for _, pin in ipairs(riftPins) do pin:Hide() end
    end)
end

-- ============================================================
-- Публичный API
-- ============================================================

function AE.ShowRiftMap()
    if not WorldMapFrame then
        DEFAULT_CHAT_FRAME:AddMessage(AE.TAG .. " Карта мира недоступна в этом клиенте.")
        return
    end

    WorldMapFrame:Show()

    -- SetMapByID ожидает areaID из WorldMapArea.dbc (485 = весь Нортренд),
    -- а не mapID 571 из Map.dbc. Без pcall неверный id может выбросить ошибку.
    local switched = false
    if SetMapByID then
        switched = pcall(SetMapByID, NORTHREND_MAP_AREA_ID)
    end
    if not switched and SetMapToCurrentZone then
        pcall(SetMapToCurrentZone)
    end

    ClearRiftPins()
    for i, rift in ipairs(RIFTS) do
        local pin = CreateRiftPin(i, rift)
        pin:Show()
        table.insert(riftPins, pin)
    end

    EnsureHooks()
    PositionPins()

    DEFAULT_CHAT_FRAME:AddMessage(
        AE.TAG .. " Карта разломов Пустоты открыта (" .. #RIFTS .. " разлома)."
    )
end

-- Подключение кнопки панели к карте
AE.SetRiftsHandler(AE.ShowRiftMap)
