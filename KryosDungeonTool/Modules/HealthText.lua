-- Kryos Dungeon Tool
-- Modules/HealthText.lua - Custom health text display on unit frames
-- Ported from EnhanceQoL/Submodules/HealthText.lua

local _, KDT = ...

local HealthText = KDT.HealthText or {}
KDT.HealthText = HealthText

HealthText.modes = HealthText.modes or { boss = "OFF", target = "OFF", player = "OFF" }
HealthText.frame = HealthText.frame or CreateFrame("Frame")
HealthText.hooked = HealthText.hooked or {}
HealthText._valueHooked = HealthText._valueHooked or false

---------------------------------------------------------------------------
-- HEALTH PERCENT: Use WoW 12.0 UnitHealthPercent API (returns real number)
-- Falls back to cur/max*100 + AbbreviateNumbers for secret safety
---------------------------------------------------------------------------
local function safeUnitHealthPercent(unit)
    if not UnitHealthPercent or not unit then return nil end
    -- Try with predicted health and ScaleTo100 curve first
    local curve = CurveConstants and CurveConstants.ScaleTo100
    if curve then
        local ok, pct = pcall(UnitHealthPercent, unit, true, curve)
        if ok and pct ~= nil then return pct end
    end
    local ok, pct = pcall(UnitHealthPercent, unit, true)
    if ok and pct ~= nil then return pct end
    return nil
end

local function getHealthPercent(unit, cur, max)
    if not unit then return 0 end
    local pct = safeUnitHealthPercent(unit)
    if pct ~= nil then return pct end
    cur = cur or (UnitHealth and UnitHealth(unit)) or 0
    max = max or (UnitHealthMax and UnitHealthMax(unit)) or 0
    if max > 0 then return (cur / max) * 100 end
    return 0
end

---------------------------------------------------------------------------
-- FORMAT: Uses AbbreviateNumbers on everything (handles secrets natively)
---------------------------------------------------------------------------
local function fmt(mode, cur, max, unit)
    if not unit then return "" end
    cur = cur or 0
    max = max or 0
    if mode == "PERCENT" then
        return string.format("%s%%", AbbreviateNumbers(getHealthPercent(unit, cur, max)))
    elseif mode == "ABS" then
        return AbbreviateNumbers(cur)
    elseif mode == "BOTH" then
        local pct = getHealthPercent(unit, cur, max)
        return string.format("%s%% (%s)", AbbreviateNumbers(pct), AbbreviateNumbers(cur))
    elseif mode == "CURMAX" then
        return string.format("%s / %s", AbbreviateNumbers(cur), AbbreviateNumbers(max))
    elseif mode == "CURMAXPERCENT" then
        local pct = getHealthPercent(unit, cur, max)
        return string.format("%s / %s (%s%%)", AbbreviateNumbers(cur), AbbreviateNumbers(max), AbbreviateNumbers(pct))
    else
        return ""
    end
end

---------------------------------------------------------------------------
-- APPLY TEXT to health bar's TextString
---------------------------------------------------------------------------
local function applyText(hb, text)
    if not hb or not text then return end
    local t = hb.TextString or hb.HealthBarText
    if not t then return end
    if hb.LeftText then hb.LeftText:Hide() end
    if hb.RightText then hb.RightText:Hide() end
    t:SetText(text)
    t:Show()
end

---------------------------------------------------------------------------
-- FRAME ACCESS (WoW 12.0 hierarchy)
---------------------------------------------------------------------------
local function getBossHB(i)
    local f = _G[("Boss%dTargetFrame"):format(i)]
    if not f or not f.TargetFrameContent then return end
    local main = f.TargetFrameContent.TargetFrameContentMain
    return main and main.HealthBarsContainer and main.HealthBarsContainer.HealthBar
end

local function getTargetHB()
    local tf = _G.TargetFrame
    if not tf or not tf.TargetFrameContent then return end
    local main = tf.TargetFrameContent.TargetFrameContentMain
    return main and main.HealthBarsContainer and main.HealthBarsContainer.HealthBar
end

local function getPlayerHB()
    local pf = _G.PlayerFrame
    if not pf or not pf.PlayerFrameContent then return end
    local main = pf.PlayerFrameContent.PlayerFrameContentMain
    return main and main.HealthBarsContainer and main.HealthBarsContainer.HealthBar
end

local function shouldApply(kind)
    return (HealthText.modes[kind] or "OFF") ~= "OFF"
end

local function unitFor(kind, idx)
    if kind == "player" then return "player" end
    if kind == "target" then return "target" end
    if kind == "boss" and idx then return ("boss%d"):format(idx) end
end

---------------------------------------------------------------------------
-- UPDATE
---------------------------------------------------------------------------
function HealthText:Update(kind, idx)
    if not shouldApply(kind) then return end
    local hb
    if kind == "player" then hb = getPlayerHB()
    elseif kind == "target" then hb = getTargetHB()
    elseif kind == "boss" and idx then hb = getBossHB(idx)
    end
    if not hb then return end
    local unit = unitFor(kind, idx)
    if unit and not UnitExists(unit) and kind ~= "player" then return end
    if UnitIsDead(unit) then
        applyText(hb, "")
        return
    end
    applyText(hb, fmt(self.modes[kind], UnitHealth(unit), UnitHealthMax(unit), unit))
end

function HealthText:UpdateAll()
    if shouldApply("player") then self:Update("player") end
    if shouldApply("target") then self:Update("target") end
    if shouldApply("boss") then
        for i = 1, (_G.MAX_BOSS_FRAMES or 5) do
            self:Update("boss", i)
        end
    end
end

function HealthText:HideAll() end

---------------------------------------------------------------------------
-- HOOKS: Intercept Blizzard text updates (exact same approach as original)
---------------------------------------------------------------------------
local function ensureBarHook(hb, ctx)
    if not hb or HealthText.hooked[hb] then return end
    HealthText.hooked[hb] = ctx or true

    if hb.UpdateTextStringWithValues then
        hooksecurefunc(hb, "UpdateTextStringWithValues", function(bar, textString, value, min, max)
            if not KDT or not KDT.HealthText then return end
            local kind, idx = ctx.kind, ctx.idx
            if not shouldApply(kind) then return end
            if not textString then return end
            local unit = unitFor(kind, idx)
            if unit ~= "player" and not UnitExists(unit) then return end
            if UnitIsDead(unit) then
                textString:SetText("")
                return
            end
            textString:SetText(fmt(KDT.HealthText.modes[kind], UnitHealth(unit), UnitHealthMax(unit), unit))
            textString:Show()
            if bar.LeftText then bar.LeftText:Hide() end
            if bar.RightText then bar.RightText:Hide() end
        end)
    else
        hooksecurefunc("TextStatusBar_UpdateTextStringWithValues", function(statusBar, textString, value, min, max)
            if statusBar ~= hb or not textString then return end
            if not KDT or not KDT.HealthText then return end
            local kind, idx = ctx.kind, ctx.idx
            if not shouldApply(kind) then return end
            local unit = unitFor(kind, idx)
            if unit ~= "player" and not UnitExists(unit) then return end
            if UnitIsDead(unit) then
                textString:SetText("")
                return
            end
            textString:SetText(fmt(KDT.HealthText.modes[kind], UnitHealth(unit), UnitHealthMax(unit), unit))
            textString:Show()
            if statusBar.LeftText then statusBar.LeftText:Hide() end
            if statusBar.RightText then statusBar.RightText:Hide() end
        end)
    end
end

function HealthText:HookBars()
    local hb = getPlayerHB()
    if hb then ensureBarHook(hb, { kind = "player" }) end
    hb = getTargetHB()
    if hb then ensureBarHook(hb, { kind = "target" }) end
    for i = 1, (_G.MAX_BOSS_FRAMES or 5) do
        hb = getBossHB(i)
        if hb then ensureBarHook(hb, { kind = "boss", idx = i }) end
    end

    if not self._valueHooked and TargetFrameHealthBarMixin then
        hooksecurefunc(TargetFrameHealthBarMixin, "OnValueChanged", function(bar)
            if not KDT or not KDT.HealthText then return end
            local ht = KDT.HealthText
            local p = bar
            for _ = 1, 8 do
                if not p then break end
                local name = p.GetName and p:GetName()
                if name == "PlayerFrame" then
                    if shouldApply("player") then ht:Update("player") end
                    return
                elseif name == "TargetFrame" then
                    if shouldApply("target") and UnitExists("target") then ht:Update("target") end
                    return
                elseif name then
                    local i = tonumber(name:match("^Boss(%d)TargetFrame$"))
                    if i then
                        if shouldApply("boss") then ht:Update("boss", i) end
                        return
                    end
                end
                p = p.GetParent and p:GetParent() or nil
            end
        end)
        self._valueHooked = true
    end
end

---------------------------------------------------------------------------
-- EVENT REGISTRATION
---------------------------------------------------------------------------
local function anyEnabled()
    for _, v in pairs(HealthText.modes) do
        if v and v ~= "OFF" then return true end
    end
end

local function updateEventRegistration()
    if anyEnabled() then
        HealthText.frame:RegisterEvent("PLAYER_LOGIN")
        HealthText.frame:RegisterEvent("INSTANCE_ENCOUNTER_ENGAGE_UNIT")
        HealthText.frame:RegisterEvent("UNIT_HEALTH")
        HealthText.frame:RegisterEvent("UNIT_MAXHEALTH")
        HealthText.frame:RegisterEvent("PLAYER_TARGET_CHANGED")
        HealthText.frame:RegisterEvent("CVAR_UPDATE")
    else
        HealthText.frame:UnregisterEvent("PLAYER_LOGIN")
        HealthText.frame:UnregisterEvent("INSTANCE_ENCOUNTER_ENGAGE_UNIT")
        HealthText.frame:UnregisterEvent("UNIT_HEALTH")
        HealthText.frame:UnregisterEvent("UNIT_MAXHEALTH")
        HealthText.frame:UnregisterEvent("PLAYER_TARGET_CHANGED")
        HealthText.frame:UnregisterEvent("CVAR_UPDATE")
        HealthText:HideAll()
    end
end

function HealthText:SetMode(kind, mode)
    if not kind then return end
    self.modes[kind] = mode or "OFF"
    updateEventRegistration()
    self:HookBars()
    self:UpdateAll()
end

---------------------------------------------------------------------------
-- EVENT HANDLER
---------------------------------------------------------------------------
HealthText.frame:SetScript("OnEvent", function(_, event, arg1)
    if not KDT or not KDT.HealthText then return end
    if not anyEnabled() then return end

    if event == "PLAYER_LOGIN" or event == "INSTANCE_ENCOUNTER_ENGAGE_UNIT" then
        KDT.HealthText:HookBars()
        KDT.HealthText:UpdateAll()
    elseif event == "PLAYER_TARGET_CHANGED" then
        KDT.HealthText:Update("target")
    elseif event == "UNIT_HEALTH" or event == "UNIT_MAXHEALTH" then
        local unit = tostring(arg1 or "")
        if unit == "player" then
            KDT.HealthText:Update("player")
        elseif unit == "target" then
            KDT.HealthText:Update("target")
        else
            local i = tonumber(unit:match("^boss(%d)$"))
            if i then KDT.HealthText:Update("boss", i) end
        end
    elseif event == "CVAR_UPDATE" then
        KDT.HealthText:UpdateAll()
    end
end)

---------------------------------------------------------------------------
-- INIT (called from QoL.lua)
---------------------------------------------------------------------------
function KDT:InitHealthText()
    local qol = self.DB and self.DB.qol
    if not qol then return end
    HealthText:SetMode("player", qol.healthTextPlayer or "OFF")
    HealthText:SetMode("target", qol.healthTextTarget or "OFF")
    HealthText:SetMode("boss", qol.healthTextBoss or "OFF")
end
