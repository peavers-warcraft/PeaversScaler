--------------------------------------------------------------------------------
-- PeaversScaler scaling engine
--
-- WoW's virtual UI is 768 units tall; pixel perfect means one UI unit maps to
-- whole pixels: scale = 768 / physical screen height. The uiScale CVar is
-- clamped to [0.64, 1.15], which cannot express pixel perfect at 1440p
-- (0.5333) or 4K (0.3556), so like classic ElvUI we write the clamped CVar
-- (keeps Blizzard's Settings panel honest, and any Blizzard reset lands near
-- our value instead of at 1.0) and then call UIParent:SetScale with the real
-- value, re-applying whenever something resets it.
--------------------------------------------------------------------------------

local addonName, PS = ...

local PeaversCommons = _G.PeaversCommons
local Utils = PeaversCommons.Utils

local Scaler = {}
PS.Scaler = Scaler

local UI_HEIGHT = 768
local CVAR_MIN, CVAR_MAX = 0.64, 1.15
local SCALE_MIN, SCALE_MAX = 0.25, 1.25 -- floor leaves room for 5K (768/2880)
local EPSILON = 0.001

Scaler.SCALE_MIN = SCALE_MIN
Scaler.SCALE_MAX = SCALE_MAX

Scaler.PRESETS = {
    { key = "1080p", label = "1080p", scale = UI_HEIGHT / 1080 },
    { key = "1440p", label = "1440p", scale = UI_HEIGHT / 1440 },
    { key = "4k",    label = "4K",    scale = UI_HEIGHT / 2160 },
}

local applying = false      -- our own writes; event handlers and hook ignore them
local reapplyQueued = false -- coalesce all re-apply triggers to next frame
local pendingCombat = false -- apply deferred until PLAYER_REGEN_ENABLED
local pendingRestore = nil  -- { clear = bool }: restore deferred until combat ends
local warnedOverride = false
local suppressWarnUntil = 0

local function Clamp(value, lo, hi)
    if value < lo then return lo end
    if value > hi then return hi end
    return value
end

function Scaler:GetPixelPerfectScale()
    local _, physicalHeight = GetPhysicalScreenSize()
    if not physicalHeight or physicalHeight <= 0 then
        return 1.0
    end
    return UI_HEIGHT / physicalHeight
end

function Scaler:GetConfiguredScale()
    local mode = PS.Config.scaleMode
    if mode == "pixelPerfect" then
        return self:GetPixelPerfectScale()
    end
    for _, preset in ipairs(self.PRESETS) do
        if preset.key == mode then
            return preset.scale
        end
    end
    return PS.Config.scale or 1.0
end

function Scaler:GetCurrentScale()
    return UIParent:GetScale()
end

-- The only function that writes scale; first line is the opt-in gate
local function applyNow()
    if not PS.Config.enabled then return end
    if InCombatLockdown() then
        pendingCombat = true
        return
    end

    local target = Clamp(Scaler:GetConfiguredScale(), SCALE_MIN, SCALE_MAX)

    applying = true
    SetCVar("useUiScale", 1)
    SetCVar("uiScale", Clamp(target, CVAR_MIN, CVAR_MAX))
    -- SetCVar above already made Blizzard call UIParent:SetScale(clamped);
    -- this overrides it with the true value, including below the CVar floor
    UIParent:SetScale(target)
    -- UI_SCALE_CHANGED fires synchronously from SetCVar; clearing next frame
    -- also swallows any same-frame Blizzard follow-up work
    C_Timer.After(0, function() applying = false end)
end

local function restoreNow(clearOriginal)
    if InCombatLockdown() then
        pendingRestore = { clear = clearOriginal }
        Utils.Print(PS, "Your original UI scale will be restored when combat ends.")
        return
    end

    local original = PS.Config.original
    applying = true
    if original and original.useUiScale ~= "0" then
        SetCVar("useUiScale", original.useUiScale or "1")
        SetCVar("uiScale", original.uiScale or "1")
        UIParent:SetScale(tonumber(original.uiScale) or 1)
        Utils.Print(PS, "Original UI scale restored.")
    else
        -- With useUiScale off Blizzard auto-scales; that exact state can't be
        -- reconstructed from addon code, so approximate and suggest /reload
        SetCVar("useUiScale", 0)
        UIParent:SetScale(math.max(CVAR_MIN, Scaler:GetPixelPerfectScale()))
        Utils.Print(PS, "UI scale restored (approximately). /reload restores Blizzard's exact scale.")
    end
    if clearOriginal then
        PS.Config.original = nil
        PS.Config:Save()
    end
    C_Timer.After(0, function() applying = false end)
end

local function noteExternalChange()
    if warnedOverride or GetTime() < suppressWarnUntil then return end
    warnedOverride = true
    Utils.Print(PS, "Re-applied your configured UI scale after something else changed it. Use /pscaler to adjust or disable.")
end

function Scaler:QueueReapply()
    if reapplyQueued then return end
    reapplyQueued = true
    C_Timer.After(0, function()
        reapplyQueued = false
        applyNow()
    end)
end

function Scaler:Apply()
    applyNow()
end

function Scaler:ApplyScale(value)
    value = Clamp(tonumber(value) or 1.0, SCALE_MIN, SCALE_MAX)
    PS.Config.scaleMode = "custom"
    PS.Config.scale = value
    PS.Config:Save()
    applyNow()
end

function Scaler:SetMode(mode)
    PS.Config.scaleMode = mode
    PS.Config:Save()
    applyNow()
end

function Scaler:Enable()
    if not PS.Config.original then
        -- Capture Blizzard's state before the first-ever apply so Disable can
        -- always hand back what the user had
        PS.Config.original = {
            useUiScale = GetCVar("useUiScale"),
            uiScale = GetCVar("uiScale"),
        }
    end
    PS.Config.enabled = true
    PS.Config:Save()
    applyNow()
end

function Scaler:Disable()
    PS.Config.enabled = false
    PS.Config:Save()
    pendingCombat = false
    restoreNow(false)
end

-- Full undo: restore everything to before PeaversScaler ever changed it, turn
-- scaling off, and forget the snapshot (the next Enable captures a fresh one)
function Scaler:RestoreOriginal()
    if not PS.Config.original then
        Utils.Print(PS, "Nothing to restore - PeaversScaler hasn't changed anything yet.")
        return false
    end
    PS.Config.enabled = false
    PS.Config:Save()
    pendingCombat = false
    restoreNow(true)
    return true
end

function Scaler:HasOriginal()
    return PS.Config.original ~= nil
end

-- Delay external-change warnings during login, when Blizzard applies its own
-- scale late and we silently re-apply over it
function Scaler:SuppressWarnings(seconds)
    suppressWarnUntil = GetTime() + seconds
end

function Scaler:PrintInfo()
    local width, height = GetPhysicalScreenSize()
    Utils.Print(PS, "Scale diagnostics:")
    print(string.format("  Physical screen: %dx%d", width or 0, height or 0))
    print(string.format("  Pixel perfect scale: %.4f", self:GetPixelPerfectScale()))
    print(string.format("  Mode: %s | Configured scale: %.4f", tostring(PS.Config.scaleMode), self:GetConfiguredScale()))
    print(string.format("  UIParent scale: %.4f | Effective scale: %.4f", UIParent:GetScale(), UIParent:GetEffectiveScale()))
    print(string.format("  Enabled: %s | uiScale CVar: %s | useUiScale: %s",
        tostring(PS.Config.enabled), tostring(GetCVar("uiScale")), tostring(GetCVar("useUiScale"))))
end

function Scaler:Initialize()
    local Events = PeaversCommons.Events

    local function onExternalScaleChange()
        if applying or not PS.Config.enabled then return end
        noteExternalChange()
        Scaler:QueueReapply()
    end

    Events:RegisterEvent("UI_SCALE_CHANGED", onExternalScaleChange)

    -- Resolution/monitor change: in pixelPerfect mode the target itself
    -- changes, so re-apply recomputes from the new physical size
    Events:RegisterEvent("DISPLAY_SIZE_CHANGED", function()
        if applying or not PS.Config.enabled then return end
        Scaler:QueueReapply()
    end)

    -- Cinematics can leave UIParent scale altered
    Events:RegisterEvent("CINEMATIC_STOP", function()
        if not PS.Config.enabled then return end
        Scaler:QueueReapply()
    end)
    Events:RegisterEvent("STOP_MOVIE", function()
        if not PS.Config.enabled then return end
        Scaler:QueueReapply()
    end)

    Events:RegisterEvent("PLAYER_REGEN_ENABLED", function()
        if pendingRestore then
            local clear = pendingRestore.clear
            pendingRestore = nil
            restoreNow(clear)
            return
        end
        if pendingCombat and PS.Config.enabled then
            pendingCombat = false
            Scaler:QueueReapply()
        end
    end)

    -- Catches resets that fire no event. hooksecurefunc is a taint-free
    -- post-hook and can't be removed, so the disabled gate lives inside it
    hooksecurefunc(UIParent, "SetScale", function(_, newScale)
        if applying or not PS.Config.enabled then return end
        if math.abs((newScale or 0) - Scaler:GetConfiguredScale()) < EPSILON then return end
        noteExternalChange()
        Scaler:QueueReapply()
    end)
end

return Scaler
