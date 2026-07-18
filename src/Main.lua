local addonName, PS = ...

-- Access the PeaversCommons library
local PeaversCommons = _G.PeaversCommons
local Utils = PeaversCommons.Utils

-- Initialize addon namespace
PS.name = addonName
PS.version = C_AddOns.GetAddOnMetadata(addonName, "Version") or "1.0.0"

-- Register slash commands
PeaversCommons.SlashCommands:Register(addonName, "pscaler", {
    default = function()
        PS.ConfigUI:OpenOptions()
    end,
    pp = function()
        PS.Config.scaleMode = "pixelPerfect"
        PS.Config:Save()
        if not PS.Config.enabled then
            PS.Scaler:Enable()
        else
            PS.Scaler:Apply()
        end
        Utils.Print(PS, string.format("Pixel perfect scale applied (%.4f).", PS.Scaler:GetPixelPerfectScale()))
    end,
    set = function(rest)
        local value = tonumber(rest)
        if not value then
            Utils.Print(PS, string.format("Usage: /pscaler set 0.65 (%.2f-%.2f)", PS.Scaler.SCALE_MIN, PS.Scaler.SCALE_MAX))
            return
        end
        if not PS.Config.enabled then
            PS.Scaler:Enable()
        end
        PS.Scaler:ApplyScale(value)
        Utils.Print(PS, string.format("UI scale set to %.4f.", PS.Scaler:GetConfiguredScale()))
    end,
    enable = function()
        PS.Scaler:Enable()
        Utils.Print(PS, "UI scaling enabled.")
    end,
    disable = function()
        PS.Scaler:Disable()
    end,
    info = function()
        PS.Scaler:PrintInfo()
    end,
    debug = function()
        PS.Config.debugMode = not PS.Config.debugMode
        PS.Config.DEBUG_ENABLED = PS.Config.debugMode
        PS.Config:Save()
        Utils.Print(PS, "Debug mode " .. (PS.Config.debugMode and "enabled" or "disabled"))
    end,
    help = function()
        Utils.Print(PS, "Commands:")
        print("  /pscaler - Open settings")
        print("  /pscaler pp - Apply pixel-perfect scale for your screen")
        print("  /pscaler set N - Set a specific scale (e.g. 0.65)")
        print("  /pscaler enable - Enable UI scaling")
        print("  /pscaler disable - Disable and restore your original scale")
        print("  /pscaler info - Print scale diagnostics")
        print("  /pscaler config - Open settings")
    end
})

-- Initialize the addon
PeaversCommons.Events:Init(addonName, function()
    -- Initialize configuration
    PS.Config:Initialize()

    -- Initialize the scaling engine (events + UIParent hook; inert while disabled)
    PS.Scaler:Initialize()

    -- Initialize configuration UI
    if PS.ConfigUI and PS.ConfigUI.Initialize then
        PS.ConfigUI:Initialize()
    end

    -- Initialize patrons support
    if PS.Patrons and PS.Patrons.Initialize then
        PS.Patrons:Initialize()
    end

    local loginApplied = false
    PeaversCommons.Events:RegisterEvent("PLAYER_ENTERING_WORLD", function()
        -- Blizzard applies its own scale late during login on some setups;
        -- re-apply once more after a delay, and don't warn about it
        PS.Scaler:SuppressWarnings(5)
        PS.Scaler:Apply()
        if not loginApplied then
            loginApplied = true
            C_Timer.After(1, function()
                PS.Scaler:Apply()
            end)
        end
    end)

    -- Earliest moment the reported physical screen size is trustworthy on
    -- some drivers; makes pixel-perfect correct on cold start
    PeaversCommons.Events:RegisterEvent("FIRST_FRAME_RENDERED", function()
        PS.Scaler:Apply()
    end)

    -- Use the centralized SettingsUI system from PeaversCommons
    C_Timer.After(0.5, function()
        PeaversCommons.SettingsUI:CreateRedirectPage(PS, "PeaversScaler", "Peavers Scaler")
    end)

    -- Register with PeaversConfig registry
    if PeaversCommons.ConfigRegistry then
        PeaversCommons.ConfigRegistry:Register({
            name = "PeaversScaler",
            displayName = "Scaler",
            description = "Scale the entire WoW UI",
            addonRef = PS,
            config = PS.Config,
            buildPanel = function(parentFrame)
                return PS.ConfigUI:BuildIntoFrame(parentFrame)
            end,
            order = 12,
        })
    end
end, {
    suppressAnnouncement = true
})

_G.PeaversScaler = PS
