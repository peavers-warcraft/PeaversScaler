--------------------------------------------------------------------------------
-- PeaversScaler Configuration
-- Account-wide by design: UI scale is a property of the monitor, not the
-- character, so this uses the flat (non-profile) ConfigManager variant.
--------------------------------------------------------------------------------

local addonName, PS = ...

local PeaversCommons = _G.PeaversCommons
local ConfigManager = PeaversCommons.ConfigManager

PS.name = PS.name or addonName

local PS_DEFAULTS = {
    -- Master toggle: the addon never touches scale until the user opts in
    enabled = false,
    -- "pixelPerfect" | "custom" | "1080p" | "1440p" | "4k"
    -- pixelPerfect is a mode, not a frozen number, so it recomputes when the
    -- resolution changes; presets and the slider store fixed values
    scaleMode = "pixelPerfect",
    -- Used when scaleMode == "custom"
    scale = 1.0,
    -- Pixel-perfect multiplier: 0 = auto (smallest pixel-aligned multiple
    -- that's comfortably readable), 1+ = force that multiple
    ppMultiplier = 0,
    -- Blizzard CVar state captured on first Enable, restored on Disable
    -- (original = nil until then; Save() persists ad-hoc keys)
    debugMode = false,
    DEBUG_ENABLED = false,
}

PS.Config = ConfigManager:New(PS, PS_DEFAULTS, {
    savedVariablesName = "PeaversScalerDB",
})

return PS.Config
