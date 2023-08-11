local settings = {
    isCraftingRebalancedEnabled = true,
    itemTypeWeaponCraftingDivider = 2.0,
    itemTypeClothingCraftingDivider = 8.0,
    itemTypeWeaponUpgradingDivider = 1.0,
    itemTypeClothingUpgradingDivider = 4.0,
    itemTypeWeaponDisassemblingDivider = 4.0,
    itemTypeClothingDisassemblingDivider = 16.0,
}

local GameUI = require('GameUI')
local GameSettings = require('GameSettings')
local lang = ""

registerForEvent("onInit", function()
    lang = NameToString(GameSettings.Get("/language/OnScreen"))

    SetupLanguageListener()
    LoadSettings()
    SetupMenu()

    -- MAIN MOD SWITCH
    Override("RPGManager", "IsCraftingRebalancedEnabled;", function ()
        return settings.isCraftingRebalancedEnabled
    end)

    -- CRAFTING STUFF SECTION
    Override("RPGManager", "GetWeaponCraftingDivider;", function ()
        return settings.itemTypeWeaponCraftingDivider
    end)

    Override("RPGManager", "GetClothingCraftingDivider;", function ()
        return settings.itemTypeClothingCraftingDivider
    end)

    -- UPGRADING STUFF SECTION
    Override("RPGManager", "GetWeaponUpgradingDivider;", function ()
        return settings.itemTypeWeaponUpgradingDivider
    end)

    Override("RPGManager", "GetClothingUpgradingDivider;", function ()
        return settings.itemTypeClothingUpgradingDivider
    end)

    -- DISASSEMBLING STUFF SECTION
    Override("RPGManager", "GetWeaponDisassemblingDivider;", function ()
        return settings.itemTypeWeaponDisassemblingDivider
    end)

    Override("RPGManager", "GetClothingDisassemblingDivider;", function ()
        return settings.itemTypeClothingDisassemblingDivider
    end)

end)

function SetupLanguageListener()
    GameUI.Listen("MenuNav", function(state)
        if state.lastSubmenu ~= nil and state.lastSubmenu == "Settings" then
            local newLang = NameToString(GameSettings.Get("/language/OnScreen"))
            if lang ~= newLang then
                lang = newLang
                SetupMenu()
            end
            SaveSettings()
        end
    end)
end

function LoadSettings()
    local file = io.open('settings.json', 'r')
    if file ~= nil then
        local contents = file:read("*a")
        local validJson, savedSettings = pcall(function() return json.decode(contents) end)
        file:close()

        if validJson then
            for key, _ in pairs(settings) do
                if savedSettings[key] ~= nil then
                    settings[key] = savedSettings[key]
                end
            end
        end
    end
end

function SaveSettings()
    local validJson, contents = pcall(function() return json.encode(settings) end)

    if validJson and contents ~= nil then
        local file = io.open("settings.json", "w+")
        file:write(contents)
        file:close()
    end
end

function SetupMenu()
    local nativeSettings = GetMod("nativeSettings")

    if not nativeSettings.pathExists("/RalphMods") then
        nativeSettings.addTab("/RalphMods", "Ralph Mods")
    end

    if nativeSettings.pathExists("/RalphMods/crafting_rebalanced") then
        nativeSettings.removeSubcategory("/RalphMods/crafting_rebalanced")
    end
    nativeSettings.addSubcategory("/RalphMods/crafting_rebalanced", "Crafting Rebalanced")

    -- MAIN MOD SWITCH
    nativeSettings.addSwitch(
        "/RalphMods/crafting_rebalanced",
        "Enable/Disable this mod",
        "Returning the crafting calculation to it's original values or update them to this mod configurations",
        settings.isCraftingRebalancedEnabled,
        true,
        function(state)
            settings.isCraftingRebalancedEnabled = state
        end
    )

    -- CRAFTING STUFF SECTION
    nativeSettings.addRangeFloat(
        "/RalphMods/crafting_rebalanced",
        "Crafting: Weapon cost divider",
        "Affects the amount of components needed for crafting weapons, being: ((original components * player level) / weapon divider)",
        1,
        50,
        1,
        "%.0f",
        settings.itemTypeWeaponCraftingDivider,
        2,
        function(value)
            settings.itemTypeWeaponCraftingDivider = value
        end
    )

    nativeSettings.addRangeFloat(
        "/RalphMods/crafting_rebalanced",
        "Crafting: Clothing cost divider",
        "Affects the amount of components needed for crafting clothes, being: ((original components * player level) / clothes divider)",
        1,
        50,
        1,
        "%.0f",
        settings.itemTypeClothingCraftingDivider,
        8,
        function(value)
            settings.itemTypeClothingCraftingDivider = value
        end
    )

    -- Parameters: path, label, desc, min, max, step, format, currentValue, defaultValue, callback
    -- UPGRADING STUFF SECTION
    nativeSettings.addRangeFloat(
        "/RalphMods/crafting_rebalanced",
        "Upgrading: Weapon cost divider",
        "Affects the amount of components needed for upgrading weapons, being: ((original components * item level) / weapon divider)",
        1,
        50,
        1,
        "%.0f",
        settings.itemTypeWeaponUpgradingDivider,
        1,
        function(value)
            settings.itemTypeWeaponUpgradingDivider = value
        end
    )

    nativeSettings.addRangeFloat(
        "/RalphMods/crafting_rebalanced",
        "Upgrading: Clothing cost divider",
        "Affects the amount of components needed for upgrading clothes, being: ((original components * item level) / clothes divider)",
        1,
        50,
        1,
        "%.0f",
        settings.itemTypeClothingUpgradingDivider,
        4,
        function(value)
            settings.itemTypeClothingUpgradingDivider = value
        end
    )

    -- DISASSEMBLING STUFF SECTION
    nativeSettings.addRangeFloat(
        "/RalphMods/crafting_rebalanced",
        "Disassembling: Weapon reward divider",
        "Affects the amount of components rewarded for disassembling weapons, being: ((original components * item level) / weapon divider)",
        1,
        50,
        1,
        "%.0f",
        settings.itemTypeWeaponDisassemblingDivider,
        4,
        function(value)
            settings.itemTypeWeaponDisassemblingDivider = value
        end
    )

    nativeSettings.addRangeFloat(
        "/RalphMods/crafting_rebalanced",
        "Disassembling: Clothing reward divider",
        "Affects the amount of components rewarded for disassembling clothes, being: ((original components * item level) / clothes divider)",
        1,
        50,
        1,
        "%.0f",
        settings.itemTypeClothingDisassemblingDivider,
        16,
        function(value)
            settings.itemTypeClothingDisassemblingDivider = value
        end
    )

    nativeSettings.refresh()
end
