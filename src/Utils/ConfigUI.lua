local addonName, PS = ...

local ConfigUI = {}
PS.ConfigUI = ConfigUI

local PeaversCommons = _G.PeaversCommons
if not PeaversCommons then
    print("|cffff0000Error:|r PeaversCommons not found.")
    return
end

local W = PeaversCommons.Widgets

local function ResolveWidth(parentFrame, indent)
    local parentWidth = parentFrame:GetWidth() or 0
    if parentWidth > 100 then
        return parentWidth - (indent * 2) - 10
    end
    return 360
end

function ConfigUI:BuildGeneralPage(parentFrame)
    local y = -10
    local indent = 25
    local width = ResolveWidth(parentFrame, indent)

    local Scaler = PS.Scaler
    local controls = {}       -- widgets grayed out while the master toggle is off
    local updatingUI = false  -- guard: programmatic slider updates must not write config
    local slider

    local function SetControlsEnabled(enabled)
        local alpha = enabled and 1 or 0.4
        for _, control in ipairs(controls) do
            control:SetAlpha(alpha)
        end
    end

    local function RefreshSlider()
        if not slider then return end
        updatingUI = true
        slider:SetValue(Scaler:GetConfiguredScale())
        updatingUI = false
    end

    local _, newY = W:CreateSectionHeader(parentFrame, "UI Scaling", indent, y)
    y = newY - 8

    local screenWidth, screenHeight = GetPhysicalScreenSize()
    local screenInfo = W:CreateLabel(parentFrame,
        string.format("Your screen is %dx%d — pixel perfect scale is %.4f",
            screenWidth or 0, screenHeight or 0, Scaler:GetPixelPerfectScale()),
        { font = "GameFontNormalSmall", color = { 0.7, 0.7, 0.7 } })
    screenInfo:SetPoint("TOPLEFT", indent, y)
    y = y - 26

    local toggle = W:CreateToggle(parentFrame, "Enable UI scaling", {
        checked = PS.Config.enabled == true,
        width = width,
        onChange = function(checked)
            if checked then
                Scaler:Enable()
            else
                Scaler:Disable()
            end
            SetControlsEnabled(checked)
            RefreshSlider()
        end,
    })
    toggle:SetPoint("TOPLEFT", indent, y)
    y = y - 34

    slider = W:CreateSlider(parentFrame, "UI Scale", {
        min = Scaler.SCALE_MIN,
        max = Scaler.SCALE_MAX,
        step = 0.01,
        value = Scaler:GetConfiguredScale(),
        width = width,
        onChange = function(value)
            if updatingUI then return end
            if not PS.Config.enabled then
                -- Snap the thumb back so a disabled drag doesn't desync the display
                C_Timer.After(0, RefreshSlider)
                return
            end
            Scaler:ApplyScale(value)
        end,
    })
    slider:SetPoint("TOPLEFT", indent, y)
    y = y - 56
    table.insert(controls, slider)

    local presetLabel = W:CreateLabel(parentFrame, "Presets (pixel perfect for that resolution)",
        { font = "GameFontNormalSmall", color = { 0.7, 0.7, 0.7 } })
    presetLabel:SetPoint("TOPLEFT", indent, y)
    y = y - 20
    table.insert(controls, presetLabel)

    local gap = 8
    local btnWidth = (width - gap * 2) / 3
    for i, preset in ipairs(Scaler.PRESETS) do
        local btn = W:CreateButton(parentFrame, preset.label, {
            width = btnWidth,
            onClick = function()
                if not PS.Config.enabled then return end
                Scaler:SetMode(preset.key)
                RefreshSlider()
            end,
        })
        btn:SetPoint("TOPLEFT", indent + (i - 1) * (btnWidth + gap), y)
        table.insert(controls, btn)
    end
    y = y - 34

    local ppButton = W:CreateButton(parentFrame, "Set Pixel Perfect", {
        width = width,
        variant = "primary",
        onClick = function()
            if not PS.Config.enabled then return end
            Scaler:SetMode("pixelPerfect")
            RefreshSlider()
        end,
    })
    ppButton:SetPoint("TOPLEFT", indent, y)
    y = y - 34
    table.insert(controls, ppButton)

    local note = W:CreateLabel(parentFrame,
        "Tip: 1.0 is the largest UI, not the default — lower values give a smaller, sharper UI.",
        { font = "GameFontNormalSmall", color = { 0.6, 0.6, 0.6 } })
    note:SetPoint("TOPLEFT", indent, y)
    y = y - 22

    SetControlsEnabled(PS.Config.enabled == true)
    RefreshSlider()

    parentFrame:SetHeight(math.abs(y) + 30)
end

function ConfigUI:GetPages()
    return {
        { key = "general", label = "General", builder = function(f) ConfigUI:BuildGeneralPage(f) end },
    }
end

function ConfigUI:BuildIntoFrame(parentFrame)
    self:BuildGeneralPage(parentFrame)
    return parentFrame
end

function ConfigUI:OpenOptions()
    if _G.PeaversConfig and _G.PeaversConfig.MainFrame then
        _G.PeaversConfig.MainFrame:Show()
        _G.PeaversConfig.MainFrame:SelectAddon("PeaversScaler")
        return
    end

    if Settings and Settings.OpenToCategory then
        if PS.directSettingsCategoryID then
            local success = pcall(Settings.OpenToCategory, PS.directSettingsCategoryID)
            if success then return end
        end
        if PS.directCategoryID then
            local success = pcall(Settings.OpenToCategory, PS.directCategoryID)
            if success then return end
        end
    end

    if SettingsPanel then
        SettingsPanel:Open()
    end
end

function ConfigUI:Initialize()
end

return ConfigUI
