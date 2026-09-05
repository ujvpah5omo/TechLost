local GLOBAL = GLOBAL

local BLUEPRINT_ONLY_TECH = (GLOBAL.TECH and GLOBAL.TECH.LOST) or { LOST = 1 }
local skilltree_defs = GLOBAL.require ~= nil
    and GLOBAL.require("prefabs/skilltree_defs")
    or nil
local include_ancient_tech = GetModConfigData("include_ancient_tech") == true
local include_lunar_forge_tech = GetModConfigData("include_lunar_forge_tech") == true
local include_shadow_forge_tech = GetModConfigData("include_shadow_forge_tech") == true
local include_skill_tree_recipes =
    GetModConfigData("include_skill_tree_recipes") == true
local skill_tree_node_blueprint_mode =
    GetModConfigData("include_skill_tree_node_blueprints")
local include_skill_tree_node_blueprints =
    skill_tree_node_blueprint_mode == true
    or skill_tree_node_blueprint_mode == "enabled"
    or skill_tree_node_blueprint_mode == "after_both_rifts"
local include_character_tag_recipes =
    GetModConfigData("include_character_tag_recipes") == true
local include_powder_monkey_blueprints =
    GetModConfigData("include_powder_monkey_blueprints") ~= false
local lose_tech_on_death = GetModConfigData("lose_tech_on_death") == true
local ground_blueprint_rain_washes =
    GetModConfigData("ground_blueprint_rain_washes") or 3
local sunken_treasure_advanced_blueprint_chance =
    GetModConfigData("sunken_treasure_advanced_blueprints") or 0
local pirate_treasure_advanced_blueprint_chance =
    GetModConfigData("pirate_treasure_advanced_blueprints") or 0

local SKILL_TREE_BLUEPRINT_REQUIRED_MESSAGE = "需要先学习技能许可蓝图"
local SKILL_TREE_RIFT_REQUIRED_MESSAGE = "需要月亮裂隙和暗影裂隙都开启"
local SKILL_TREE_BLUEPRINT_REMOVED_MESSAGE = "未满足许可条件的技能已被取消"

local CHARACTER_RECIPE_TAG_OWNERS = {
    pyromaniac = "willow",
    masterchef = "warly",
    professionalchef = "warly",
    merm_builder = "wurt",
    ghostlyfriend = "wendy",
    elixirbrewer = "wendy",
    werehuman = "woodie",
    valkyrie = "wathgrithr",
    battlesinger = "wathgrithr",
    pebblemaker = "walter",
    pinetreepioneer = "walter",
    strongman = "wolfgang",
    bookbuilder = "wickerbottom",
    shadowmagic = "waxwell",
    handyperson = "winona",
    portableengineer = "winona",
    spiderwhisperer = "webber",
    plantkin = "wormwood",
    clockmaker = "wanda",
    balloonomancer = "wes",
    upgrademoduleowner = "wx78",
}

local SUNKEN_TREASURE_HIGH_GEMS = {
    greengem = true,
    yellowgem = true,
}

local SUNKEN_TREASURE_SPLUNKER_ITEMS = {
    armorruins = true,
    multitool_axe_pickaxe = true,
}

local SUNKEN_TREASURE_TRAVELER_ITEMS = {
    cane = true,
    gnarwail_horn = true,
}

local SUNKEN_TREASURE_MINER_ITEMS = {
    goldenpickaxe = true,
    moonglass = true,
    moonrocknugget = true,
}

local SUNKEN_TREASURE_MARKER_ITEMS = {
    boatpatch = true,
    cookiecuttershell = true,
    saltrock = true,
    cane = true,
    papyrus = true,
    gnarwail_horn = true,
    malbatross_feather = true,
    oceanfishingrod = true,
    boat_ancient_item = true,
    goldenpickaxe = true,
    moonglass = true,
    moonrocknugget = true,
    armorruins = true,
    multitool_axe_pickaxe = true,
    thulecite = true,
}

-- Keep a non-zero floor so every restricted recipe remains obtainable even
-- when upgrading a world whose old configuration had drops disabled.
local tumbleweed_blueprint_chance = math.max(
    GetModConfigData("tumbleweed_blueprint_chance") or 0.05,
    0.01
)

local BLUEPRINT_TIER_BASIC = "basic"
local BLUEPRINT_TIER_INTERMEDIATE = "intermediate"
local BLUEPRINT_TIER_ADVANCED = "advanced"

local TUMBLEWEED_BLUEPRINT_TIER_WEIGHTS = {
    { tier = BLUEPRINT_TIER_BASIC, weight = 0.42 },
    { tier = BLUEPRINT_TIER_INTERMEDIATE, weight = 0.48 },
    { tier = BLUEPRINT_TIER_ADVANCED, weight = 0.10 },
}

local function RequiresTechnology(level)
    if level == nil then
        return false
    end

    for _, required_level in pairs(level) do
        if type(required_level) == "number" and required_level > 0 then
            return true
        end
    end

    return false
end

local function IsNativeLostTechnology(level)
    return level == BLUEPRINT_ONLY_TECH
        or (level ~= nil
            and level.SCIENCE == 10
            and level.MAGIC == 10
            and level.ANCIENT == 10)
end

local function RequiresBlueprintLearning(recipe, level)
    return not IsNativeLostTechnology(level)
        and (RequiresTechnology(level)
            or (include_skill_tree_recipes and recipe.builder_skill ~= nil))
end

local function IsSkillTreeTechnologyRecipe(recipe, level)
    return recipe ~= nil
        and recipe.builder_skill ~= nil
        and RequiresTechnology(level)
        and not IsNativeLostTechnology(level)
end

local function IsSelectableCharacter(character)
    if type(character) ~= "string" then
        return false
    end

    local selectable_characters = GLOBAL.GetSelectableCharacterList ~= nil
        and GLOBAL.GetSelectableCharacterList()
        or nil
    if selectable_characters ~= nil then
        return table.contains(selectable_characters, character)
    end

    return (GLOBAL.DST_CHARACTERLIST ~= nil
            and table.contains(GLOBAL.DST_CHARACTERLIST, character))
        or (GLOBAL.MODCHARACTERLIST ~= nil
            and table.contains(GLOBAL.MODCHARACTERLIST, character))
end

local function GetSkillOwnerCharacter(skill)
    local skill_defs = skilltree_defs ~= nil
        and skilltree_defs.SKILLTREE_DEFS
        or nil
    if type(skill) ~= "string" or skill_defs == nil then
        return nil
    end

    for character, skills in pairs(skill_defs) do
        if type(skills) == "table"
            and skills[skill] ~= nil
            and IsSelectableCharacter(character) then
            return character
        end
    end

    return nil
end

local function GetRecipeOwnerCharacter(recipe)
    if recipe == nil then
        return nil
    end

    if recipe.builder_tag ~= nil then
        local character = CHARACTER_RECIPE_TAG_OWNERS[recipe.builder_tag]
        if character ~= nil then
            return character
        end
    end

    if recipe.builder_skill ~= nil then
        return GetSkillOwnerCharacter(recipe.builder_skill)
    end

    return nil
end

local function GetCharacterDisplayName(character)
    local character_names = GLOBAL.STRINGS.CHARACTER_NAMES
    local name = character_names ~= nil
        and (character_names[character]
            or character_names[string.upper(character)])
        or nil
    if name ~= nil then
        return name
    end

    name = GLOBAL.STRINGS.NAMES[string.upper(character)]
    return name ~= nil and name or character
end

local function IsRecipeActiveForBlueprintPool(recipe)
    return GetRecipeOwnerCharacter(recipe) == nil
end

local function IsRecipeAllowedForRewardCharacter(recipe, character)
    local owner = GetRecipeOwnerCharacter(recipe)
    return owner == nil or owner == character
end

local function GetRewardCharacter(player)
    if player == nil
        or type(player.prefab) ~= "string"
        or not IsSelectableCharacter(player.prefab) then
        return nil
    end

    return player.prefab
end

local function IsCharacterTagRecipeEnabled(recipe, level)
    if not include_character_tag_recipes
        or recipe == nil
        or recipe.builder_tag == nil
        or recipe.builder_skill ~= nil
        or not RequiresTechnology(level)
        or IsNativeLostTechnology(level) then
        return false
    end

    return IsSelectableCharacter(
        CHARACTER_RECIPE_TAG_OWNERS[recipe.builder_tag]
    )
end

local function GetOptionalStationTechnologyEnabled(level)
    if level == nil then
        return nil
    -- TECH.LOST uses level 10 (including ANCIENT = 10), so only treat
    -- attainable station levels below 10 as optional station technology.
    elseif type(level.ANCIENT) == "number"
        and level.ANCIENT > 0
        and level.ANCIENT < 10 then
        return include_ancient_tech
    elseif type(level.LUNARFORGING) == "number"
        and level.LUNARFORGING > 0
        and level.LUNARFORGING < 10 then
        return include_lunar_forge_tech
    elseif type(level.SHADOWFORGING) == "number"
        and level.SHADOWFORGING > 0
        and level.SHADOWFORGING < 10 then
        return include_shadow_forge_tech
    end

    return nil
end

local function IsLunarForgeTechnology(level)
    return level ~= nil
        and type(level.LUNARFORGING) == "number"
        and level.LUNARFORGING > 0
        and level.LUNARFORGING < 10
end

local function IsShadowForgeTechnology(level)
    return level ~= nil
        and type(level.SHADOWFORGING) == "number"
        and level.SHADOWFORGING > 0
        and level.SHADOWFORGING < 10
end

local function GetRiftSpawner()
    return GLOBAL.TheWorld ~= nil
        and GLOBAL.TheWorld.components ~= nil
        and GLOBAL.TheWorld.components.riftspawner
        or nil
end

local function IsLunarRiftEnabled()
    local riftspawner = GetRiftSpawner()
    return riftspawner ~= nil
        and riftspawner.GetLunarRiftsEnabled ~= nil
        and riftspawner:GetLunarRiftsEnabled()
end

local function IsShadowRiftEnabled()
    local riftspawner = GetRiftSpawner()
    return riftspawner ~= nil
        and riftspawner.GetShadowRiftsEnabled ~= nil
        and riftspawner:GetShadowRiftsEnabled()
end

local function IsSkillTreeNodeBlueprintControlEnabled()
    return include_skill_tree_node_blueprints
end

local function IsSkillTreeNodeBlueprintActivationProgressAllowed()
    if skill_tree_node_blueprint_mode == "after_both_rifts" then
        return IsLunarRiftEnabled() and IsShadowRiftEnabled()
    end

    return true
end

local function IsForgeTechnologyAvailableForBlueprintPool(level)
    if IsLunarForgeTechnology(level) then
        return IsLunarRiftEnabled()
    elseif IsShadowForgeTechnology(level) then
        return IsShadowRiftEnabled()
    end

    return true
end

local function SkillHasTag(skill, tag)
    if type(skill) ~= "string"
        or skilltree_defs == nil
        or skilltree_defs.SKILLTREE_DEFS == nil then
        return false
    end

    for _, skills in pairs(skilltree_defs.SKILLTREE_DEFS) do
        local skill_data = skills[skill]
        if skill_data ~= nil and skill_data.tags ~= nil then
            for _, skill_tag in ipairs(skill_data.tags) do
                if skill_tag == tag then
                    return true
                end
            end
        end
    end

    return false
end

local function SkillDataHasTag(skill_data, tag)
    if skill_data == nil or skill_data.tags == nil then
        return false
    end

    for _, skill_tag in ipairs(skill_data.tags) do
        if skill_tag == tag then
            return true
        end
    end

    return false
end

local function IsLunarSkill(character, skill, skill_data)
    return type(skill) == "string"
        and (SkillDataHasTag(skill_data, "lunar_favor")
            or SkillDataHasTag(skill_data, "lunar")
            or string.find(skill, "lunar", 1, true) ~= nil)
end

local function IsShadowSkill(character, skill, skill_data)
    return type(skill) == "string"
        and (SkillDataHasTag(skill_data, "shadow_favor")
            or SkillDataHasTag(skill_data, "shadow")
            or string.find(skill, "shadow", 1, true) ~= nil)
end

local function IsLunarSkillTreeRecipe(recipe)
    return recipe ~= nil
        and type(recipe.builder_skill) == "string"
        and (SkillHasTag(recipe.builder_skill, "lunar_favor")
            or SkillHasTag(recipe.builder_skill, "lunar")
            or string.find(recipe.builder_skill, "lunar", 1, true) ~= nil)
end

local function IsShadowSkillTreeRecipe(recipe)
    return recipe ~= nil
        and type(recipe.builder_skill) == "string"
        and (SkillHasTag(recipe.builder_skill, "shadow_favor")
            or SkillHasTag(recipe.builder_skill, "shadow")
            or string.find(recipe.builder_skill, "shadow", 1, true) ~= nil)
end

local function IsSkillTreeRecipeAvailableForBlueprintPool(recipe)
    if IsLunarSkillTreeRecipe(recipe) then
        return IsLunarRiftEnabled()
    elseif IsShadowSkillTreeRecipe(recipe) then
        return IsShadowRiftEnabled()
    end

    return true
end

local function IsSkillTreeNodeAvailableForBlueprintPool(character, skill, skill_data)
    if IsLunarSkill(character, skill, skill_data) then
        return IsLunarRiftEnabled()
    elseif IsShadowSkill(character, skill, skill_data) then
        return IsShadowRiftEnabled()
    end

    return true
end

local function IsRiftTechnologyAvailableForBlueprintPool(recipe, level)
    return IsForgeTechnologyAvailableForBlueprintPool(level)
        and IsSkillTreeRecipeAvailableForBlueprintPool(recipe)
end

local function IsInactiveSpecialEventTechnology(level)
    if level == nil
        or GLOBAL.SPECIAL_EVENTS == nil
        or GLOBAL.TECH == nil then
        return false
    end

    for event_key, event_name in pairs(GLOBAL.SPECIAL_EVENTS) do
        if event_name ~= GLOBAL.SPECIAL_EVENTS.NONE
            and GLOBAL.TECH[event_key] == level then
            return GLOBAL.IsSpecialEventActive == nil
                or not GLOBAL.IsSpecialEventActive(event_name)
        end
    end

    return false
end

local function IsProgressionStationKitRecipe(recipe)
    return recipe ~= nil and recipe.name == "shadow_forge_kit"
end

local function IsBlueprintCompatible(recipe, original_level)
    local recipe_level = original_level
        or recipe._blueprint_only_original_level
        or recipe.level
    local optional_station_tech_enabled =
        GetOptionalStationTechnologyEnabled(recipe_level)
    local skill_tree_technology_recipe =
        IsSkillTreeTechnologyRecipe(recipe, recipe_level)
    local skill_tree_recipe_enabled =
        include_skill_tree_recipes
        and recipe.builder_skill ~= nil
        and not skill_tree_technology_recipe
    local skill_tree_technology_recipe_enabled =
        not include_skill_tree_recipes and skill_tree_technology_recipe
    local character_tag_recipe_enabled =
        IsCharacterTagRecipeEnabled(recipe, recipe_level)

    if IsProgressionStationKitRecipe(recipe)
        or IsInactiveSpecialEventTechnology(recipe_level)
        or optional_station_tech_enabled == false
        or (recipe.nounlock
            and optional_station_tech_enabled ~= true
            and not skill_tree_recipe_enabled
            and not skill_tree_technology_recipe_enabled
            and not character_tag_recipe_enabled)
        or (recipe.builder_tag ~= nil and not character_tag_recipe_enabled)
        or (recipe.builder_skill ~= nil
            and not skill_tree_recipe_enabled
            and not skill_tree_technology_recipe_enabled)
        or recipe.noblueprint
        or recipe.no_blueprint
        or type(recipe.name) ~= "string" then
        return false
    end

    if GLOBAL.IsRecipeValid ~= nil and not GLOBAL.IsRecipeValid(recipe.name) then
        return false
    end

    return GLOBAL.STRINGS.NAMES[string.upper(recipe.name)] ~= nil
end

local function RestoreRecipe(recipe)
    if recipe._blueprint_only_locked then
        recipe.level = recipe._blueprint_only_original_level
        if recipe._blueprint_only_original_nounlock ~= nil then
            recipe.nounlock = recipe._blueprint_only_original_nounlock
            recipe._blueprint_only_original_nounlock = nil
        end
        recipe._blueprint_only_original_level = nil
        recipe._blueprint_only_locked = nil
    end
end

local function BuilderKnowsRecipe(builder, recipe_name)
    if builder == nil or builder.recipes == nil then
        return false
    end

    for _, known_recipe_name in ipairs(builder.recipes) do
        if known_recipe_name == recipe_name then
            return true
        end
    end

    return false
end

local function GetReplicaBuilder(builder)
    return builder ~= nil
        and builder.inst ~= nil
        and builder.inst.replica ~= nil
        and builder.inst.replica.builder
        or nil
end

local function CanPrototypeWithTrees(recipe_level, tech_trees)
    if recipe_level == nil or tech_trees == nil then
        return false
    end

    if GLOBAL.CanPrototypeRecipe ~= nil then
        return GLOBAL.CanPrototypeRecipe(recipe_level, tech_trees)
    end

    for tech_name, required_level in pairs(recipe_level) do
        if type(required_level) == "number"
            and required_level > (tech_trees[tech_name] or 0) then
            return false
        end
    end

    return true
end

local function IsStationBoundBlueprintRecipe(recipe)
    return recipe ~= nil
        and recipe._blueprint_only_locked
        and GetOptionalStationTechnologyEnabled(
            recipe._blueprint_only_original_level
        ) ~= nil
end

local function ResolveRecipe(recipe)
    if type(recipe) == "string" then
        return GLOBAL.AllRecipes[recipe]
    end

    return recipe
end

local function IsAtOriginalTechStation(builder, recipe)
    local prototyper = builder ~= nil and builder.current_prototyper or nil
    if prototyper == nil
        or not prototyper:IsValid()
        or prototyper.components.prototyper == nil then
        return false
    end

    return CanPrototypeWithTrees(
        recipe._blueprint_only_original_level,
        prototyper.components.prototyper.trees
    )
end

local function IsReplicaAtOriginalTechStation(builder, recipe)
    local server_builder = builder ~= nil
        and builder.inst ~= nil
        and builder.inst.components ~= nil
        and builder.inst.components.builder
        or nil
    if server_builder ~= nil then
        return IsAtOriginalTechStation(server_builder, recipe)
    end

    local prototyper = builder ~= nil
        and builder.GetCurrentPrototyper ~= nil
        and builder:GetCurrentPrototyper()
        or nil
    return prototyper ~= nil
        and prototyper:IsValid()
        and builder.GetTechTrees ~= nil
        and CanPrototypeWithTrees(
            recipe._blueprint_only_original_level,
            builder:GetTechTrees()
        )
end

local function ShouldUnlockStationRecipe(builder, recipe)
    return recipe ~= nil
        and recipe._blueprint_only_locked
        and BuilderKnowsRecipe(builder, recipe.name)
        and IsAtOriginalTechStation(builder, recipe)
end

local function GetStationUnlockComponent(station, create)
    if station == nil or station.components == nil then
        return nil
    end

    if station.components.stationblueprintunlock == nil and create then
        station:AddComponent("stationblueprintunlock")
    end

    return station.components.stationblueprintunlock
end

local function MakeRecipeBlueprintOnly(recipe)
    if recipe == nil or recipe.level == nil then
        return
    end

    local original_level = recipe._blueprint_only_locked
        and recipe._blueprint_only_original_level
        or recipe.level

    if not IsBlueprintCompatible(recipe, original_level)
        or not RequiresBlueprintLearning(recipe, original_level) then
        RestoreRecipe(recipe)
        return
    end

    if not recipe._blueprint_only_locked then
        -- LOST tech cannot be prototyped, but learning the recipe from a
        -- blueprint still adds it to the builder's known recipe list.
        recipe._blueprint_only_original_level = recipe.level
        if recipe.nounlock
            and (GetOptionalStationTechnologyEnabled(recipe.level) == true
                or (include_skill_tree_recipes
                    and recipe.builder_skill ~= nil
                    and not IsSkillTreeTechnologyRecipe(recipe, recipe.level))
                or (not include_skill_tree_recipes
                    and IsSkillTreeTechnologyRecipe(recipe, recipe.level))
                or IsCharacterTagRecipeEnabled(recipe, recipe.level)) then
            recipe._blueprint_only_original_nounlock = recipe.nounlock
            recipe.nounlock = false
        end
    end

    recipe.level = BLUEPRINT_ONLY_TECH
    recipe._blueprint_only_locked = true
end

local function ClearStationUnlockedRecipes(builder)
    if builder._blueprint_only_station_recipes == nil then
        return
    end

    for recipe_name in pairs(builder._blueprint_only_station_recipes) do
        if builder.station_recipes ~= nil then
            builder.station_recipes[recipe_name] = nil
        end
        if not BuilderKnowsRecipe(builder, recipe_name) then
            local replica_builder = GetReplicaBuilder(builder)
            if replica_builder ~= nil then
                replica_builder:RemoveRecipe(recipe_name)
            end
        end
    end

    builder._blueprint_only_station_recipes = nil
end

local function ApplyStationUnlockedRecipes(builder)
    ClearStationUnlockedRecipes(builder)

    local station = builder ~= nil and builder.current_prototyper or nil
    local prototyper = station ~= nil and station.components.prototyper or nil
    local component = GetStationUnlockComponent(station, false)
    if component == nil or prototyper == nil then
        return
    end

    local added = false
    for _, recipe_name in ipairs(component:GetUnlockedRecipes()) do
        local recipe = GLOBAL.AllRecipes[recipe_name]
        if recipe ~= nil
            and recipe._blueprint_only_locked
            and not BuilderKnowsRecipe(builder, recipe_name)
            and CanPrototypeWithTrees(recipe._blueprint_only_original_level, prototyper.trees) then
            builder.station_recipes[recipe_name] = true
            builder._blueprint_only_station_recipes = builder._blueprint_only_station_recipes or {}
            builder._blueprint_only_station_recipes[recipe_name] = true
            local replica_builder = GetReplicaBuilder(builder)
            if replica_builder ~= nil then
                replica_builder:AddRecipe(recipe_name)
            end
            added = true
        end
    end

    if added then
        builder.inst:PushEvent("techtreechange", { level = builder.accessible_tech_trees })
    end
end

local function RefreshPlayersUsingStation(station)
    for _, player in ipairs(GLOBAL.AllPlayers) do
        local builder = player.components.builder
        if builder ~= nil and builder.current_prototyper == station then
            ApplyStationUnlockedRecipes(builder)
        end
    end
end

local function MarkRecipeUnlockedForStation(station, recipe_name)
    local component = GetStationUnlockComponent(station, true)
    if component ~= nil and component:UnlockRecipe(recipe_name) then
        RefreshPlayersUsingStation(station)
    end
end

local function SeedStationFromBuilder(builder, station)
    local prototyper = station ~= nil and station.components.prototyper or nil
    local component = GetStationUnlockComponent(station, prototyper ~= nil)
    if builder == nil
        or builder.recipes == nil
        or prototyper == nil
        or component == nil then
        return
    end

    local unlocked = false
    for _, recipe_name in ipairs(builder.recipes) do
        local recipe = GLOBAL.AllRecipes[recipe_name]
        if recipe ~= nil
            and recipe._blueprint_only_locked
            and CanPrototypeWithTrees(recipe._blueprint_only_original_level, prototyper.trees)
            and component:UnlockRecipe(recipe_name) then
            unlocked = true
        end
    end

    if unlocked then
        RefreshPlayersUsingStation(station)
    end
end

local function LoseLearnedRecipes(builder)
    if builder == nil or builder.recipes == nil or #builder.recipes == 0 then
        return
    end

    -- Remove recipes through the component API so the replica is updated too.
    -- Copy first because RemoveRecipe mutates builder.recipes.
    local learned_recipes = {}
    for i, recipe_name in ipairs(builder.recipes) do
        learned_recipes[i] = recipe_name
    end

    for _, recipe_name in ipairs(learned_recipes) do
        builder:RemoveRecipe(recipe_name)
    end

    -- A nearby station may still publicly provide some of the lost recipes.
    ApplyStationUnlockedRecipes(builder)
end

local function GetSkillTreeUpdater(target)
    return target ~= nil
        and target.components ~= nil
        and target.components.skilltreeupdater
        or nil
end

local function GetSkillData(character, skill)
    return skilltree_defs ~= nil
        and skilltree_defs.SKILLTREE_DEFS ~= nil
        and skilltree_defs.SKILLTREE_DEFS[character] ~= nil
        and skilltree_defs.SKILLTREE_DEFS[character][skill]
        or nil
end

local function IsSkillTreeNodeBlueprintControlled(character, skill, skill_data)
    return IsSkillTreeNodeBlueprintControlEnabled()
        and type(character) == "string"
        and type(skill) == "string"
        and type(skill_data) == "table"
        and IsSelectableCharacter(character)
        and skill_data.rpc_id ~= nil
        and skill_data.infographic == nil
end

local function IsSkillTreeNodeBlueprintUnlocked(updater, character, skill)
    return updater ~= nil
        and updater._techlost_blueprint_skill_unlocks ~= nil
        and updater._techlost_blueprint_skill_unlocks[character] ~= nil
        and updater._techlost_blueprint_skill_unlocks[character][skill] == true
end

local function GetSkillTreePermitPoints(updater, character)
    return updater ~= nil
        and updater._techlost_skill_permit_points ~= nil
        and updater._techlost_skill_permit_points[character]
        or 0
end

local function SetSkillTreePermitPoints(updater, character, points)
    if updater == nil or type(character) ~= "string" then
        return
    end

    updater._techlost_skill_permit_points =
        updater._techlost_skill_permit_points or {}
    if points > 0 then
        updater._techlost_skill_permit_points[character] = points
    else
        updater._techlost_skill_permit_points[character] = nil
        if GLOBAL.next(updater._techlost_skill_permit_points) == nil then
            updater._techlost_skill_permit_points = nil
        end
    end
end

local function AddSkillTreePermitPoint(updater, character)
    SetSkillTreePermitPoints(
        updater,
        character,
        GetSkillTreePermitPoints(updater, character) + 1
    )
end

local function ConsumeSkillTreePermitPoint(updater, character)
    local points = GetSkillTreePermitPoints(updater, character)
    if points <= 0 then
        return false
    end

    SetSkillTreePermitPoints(updater, character, points - 1)
    return true
end

local function GetSkillTreePermitCapacity(character)
    local skills = skilltree_defs ~= nil
        and skilltree_defs.SKILLTREE_DEFS ~= nil
        and skilltree_defs.SKILLTREE_DEFS[character]
        or nil
    if type(skills) ~= "table" then
        return 0
    end

    local capacity = 0
    for skill, skill_data in pairs(skills) do
        if IsSkillTreeNodeBlueprintControlled(character, skill, skill_data) then
            capacity = capacity + 1
        end
    end

    return capacity
end

local function CountBlueprintSkillUnlocks(updater, character)
    local unlocks = updater ~= nil
        and updater._techlost_blueprint_skill_unlocks ~= nil
        and updater._techlost_blueprint_skill_unlocks[character]
        or nil
    if type(unlocks) ~= "table" then
        return 0
    end

    local count = 0
    for skill, unlocked in pairs(unlocks) do
        if unlocked == true
            and IsSkillTreeNodeBlueprintControlled(
                character,
                skill,
                GetSkillData(character, skill)
            ) then
            count = count + 1
        end
    end

    return count
end

local function GetSkillTreePermitRoom(updater, character)
    return math.max(
        0,
        GetSkillTreePermitCapacity(character)
            - CountBlueprintSkillUnlocks(updater, character)
            - GetSkillTreePermitPoints(updater, character)
    )
end

local function SayWithCooldown(inst, message, cooldown_key)
    if inst ~= nil
        and inst.components ~= nil
        and inst.components.talker ~= nil then
        local now = GLOBAL.GetTime ~= nil and GLOBAL.GetTime() or 0
        if inst[cooldown_key] ~= nil and now - inst[cooldown_key] < 2 then
            return
        end

        inst[cooldown_key] = now
        inst.components.talker:Say(message)
    end
end

local function SaySkillTreeBlueprintRequired(inst)
    SayWithCooldown(
        inst,
        SKILL_TREE_BLUEPRINT_REQUIRED_MESSAGE,
        "_techlost_last_skill_blueprint_hint_time"
    )
end

local function SaySkillTreeRiftRequired(inst)
    SayWithCooldown(
        inst,
        SKILL_TREE_RIFT_REQUIRED_MESSAGE,
        "_techlost_last_skill_rift_hint_time"
    )
end

local function SayUnauthorizedSkillTreeNodesRemoved(inst)
    SayWithCooldown(
        inst,
        SKILL_TREE_BLUEPRINT_REMOVED_MESSAGE,
        "_techlost_last_skill_blueprint_removed_time"
    )
end

local function CanLearnSkillTreeBlueprint(target, character)
    local updater = GetSkillTreeUpdater(target)
    if updater == nil
        or target.prefab ~= character
        or not IsSkillTreeNodeBlueprintControlEnabled()
        or not IsSelectableCharacter(character) then
        return false, "CANTLEARN"
    end

    if GetSkillTreePermitRoom(updater, character) <= 0 then
        return false, "KNOWN"
    end

    return true
end

local function RememberBlueprintSkillUnlock(updater, character, skill)
    updater._techlost_blueprint_skill_unlocks =
        updater._techlost_blueprint_skill_unlocks or {}
    updater._techlost_blueprint_skill_unlocks[character] =
        updater._techlost_blueprint_skill_unlocks[character] or {}
    updater._techlost_blueprint_skill_unlocks[character][skill] = true
end

local function UnlockSkillFromBlueprint(target, character)
    local can_learn, reason = CanLearnSkillTreeBlueprint(target, character)
    if not can_learn then
        return false, reason
    end

    local updater = target.components.skilltreeupdater
    AddSkillTreePermitPoint(updater, character)
    return true
end

AddComponentPostInit("prototyper", function(self)
    if GLOBAL.TheWorld ~= nil
        and GLOBAL.TheWorld.ismastersim
        and self.inst.components.stationblueprintunlock == nil then
        self.inst:AddComponent("stationblueprintunlock")
    end
end)

AddComponentPostInit("teacher", function(self)
    local old_teach = self.Teach
    self.Teach = function(self, target, ...)
        if self.inst ~= nil and self.inst._techlost_skill_blueprint then
            local success, reason = UnlockSkillFromBlueprint(
                target,
                self.inst._techlost_skill_blueprint_character
            )
            if success then
                self.inst:Remove()
            end
            return success, reason
        end

        local recipe = self.recipe ~= nil and GLOBAL.AllRecipes[self.recipe] or nil
        local builder = target ~= nil
            and target.components ~= nil
            and target.components.builder
            or nil
        if IsStationBoundBlueprintRecipe(recipe)
            and BuilderKnowsRecipe(builder, recipe.name) then
            return false, "KNOWN"
        end

        return old_teach(self, target, ...)
    end
end)

AddComponentPostInit("builder", function(self)
    local old_knows_recipe = self.KnowsRecipe
    self.KnowsRecipe = function(self, recipe, ...)
        local recipe_data = ResolveRecipe(recipe)
        if IsStationBoundBlueprintRecipe(recipe_data)
            and not IsAtOriginalTechStation(self, recipe_data) then
            return false
        end

        return old_knows_recipe(self, recipe, ...)
    end

    local old_evaluate_tech_trees = self.EvaluateTechTrees
    self.EvaluateTechTrees = function(self, ...)
        ClearStationUnlockedRecipes(self)
        local result = old_evaluate_tech_trees(self, ...)
        ApplyStationUnlockedRecipes(self)
        return result
    end

    local old_do_build = self.DoBuild
    self.DoBuild = function(self, recname, ...)
        local recipe = recname ~= nil and GLOBAL.AllRecipes[recname] or nil
        if IsStationBoundBlueprintRecipe(recipe)
            and not self:IsBuildBuffered(recname)
            and not IsAtOriginalTechStation(self, recipe) then
            return false
        end

        local station = self.current_prototyper
        local should_unlock_station = ShouldUnlockStationRecipe(self, recipe)
        local result, reason = old_do_build(self, recname, ...)

        if result and should_unlock_station then
            MarkRecipeUnlockedForStation(station, recname)
        end

        return result, reason
    end

    local old_buffer_build = self.BufferBuild
    self.BufferBuild = function(self, recname, ...)
        local recipe = recname ~= nil and GLOBAL.AllRecipes[recname] or nil
        local station = self.current_prototyper
        local should_unlock_station = ShouldUnlockStationRecipe(self, recipe)
        local was_buffered = self:IsBuildBuffered(recname)
        local result = old_buffer_build(self, recname, ...)

        if should_unlock_station and not was_buffered and self:IsBuildBuffered(recname) then
            MarkRecipeUnlockedForStation(station, recname)
        end

        return result
    end

    self.inst:ListenForEvent("builditem", function(inst, data)
        SeedStationFromBuilder(self, data ~= nil and data.item or nil)
    end)

    self.inst:ListenForEvent("buildstructure", function(inst, data)
        SeedStationFromBuilder(self, data ~= nil and data.item or nil)
    end)

    if lose_tech_on_death and self.inst:HasTag("player") then
        self.inst:ListenForEvent("death", function()
            LoseLearnedRecipes(self)
        end)
    end
end)

local function CopyBlueprintSkillUnlocks(skill_unlocks)
    if type(skill_unlocks) ~= "table" then
        return nil
    end

    local copy = {}
    for character, skills in pairs(skill_unlocks) do
        if type(character) == "string" and type(skills) == "table" then
            for skill, unlocked in pairs(skills) do
                if type(skill) == "string" and unlocked == true then
                    copy[character] = copy[character] or {}
                    copy[character][skill] = true
                end
            end
        end
    end

    return GLOBAL.next(copy) ~= nil and copy or nil
end

local function MergeBlueprintSkillUnlocks(first_skill_unlocks, second_skill_unlocks)
    local copy = {}

    local function Merge(skill_unlocks)
        if type(skill_unlocks) == "table" then
            for character, skills in pairs(skill_unlocks) do
                if type(character) == "string" and type(skills) == "table" then
                    for skill, unlocked in pairs(skills) do
                        if type(skill) == "string" and unlocked == true then
                            copy[character] = copy[character] or {}
                            copy[character][skill] = true
                        end
                    end
                end
            end
        end
    end

    Merge(first_skill_unlocks)
    Merge(second_skill_unlocks)

    return GLOBAL.next(copy) ~= nil and copy or nil
end

local function CopySkillTreePermitPoints(permit_points)
    if type(permit_points) ~= "table" then
        return nil
    end

    local copy = {}
    for character, points in pairs(permit_points) do
        if type(character) == "string"
            and type(points) == "number"
            and points > 0 then
            local safe_points = math.floor(points)
            if safe_points > 0 then
                copy[character] = safe_points
            end
        end
    end

    return GLOBAL.next(copy) ~= nil and copy or nil
end

local function GetSkillTreeNodeActivationBlockReason(
    updater,
    character,
    skill
)
    local skill_data = GetSkillData(character, skill)
    if not IsSkillTreeNodeBlueprintControlled(character, skill, skill_data) then
        return nil
    end

    if IsSkillTreeNodeBlueprintUnlocked(updater, character, skill) then
        if not IsSkillTreeNodeAvailableForBlueprintPool(
            character,
            skill,
            skill_data
        ) or not IsSkillTreeNodeBlueprintActivationProgressAllowed() then
            return "RIFT"
        end

        return nil
    end

    if GetSkillTreePermitPoints(updater, character) <= 0 then
        return "BLUEPRINT"
    end

    if not IsSkillTreeNodeAvailableForBlueprintPool(
        character,
        skill,
        skill_data
    ) or not IsSkillTreeNodeBlueprintActivationProgressAllowed() then
        return "RIFT"
    end

    return nil
end

local function GetExistingSkillTreeNodeActivationBlockReason(
    updater,
    character,
    skill
)
    local skill_data = GetSkillData(character, skill)
    if not IsSkillTreeNodeBlueprintControlled(character, skill, skill_data) then
        return nil
    end

    if not IsSkillTreeNodeBlueprintUnlocked(updater, character, skill) then
        if updater._techlost_pending_skill_permit_activation == skill
            and GetSkillTreePermitPoints(updater, character) > 0 then
            if not IsSkillTreeNodeAvailableForBlueprintPool(
                character,
                skill,
                skill_data
            ) or not IsSkillTreeNodeBlueprintActivationProgressAllowed() then
                return "RIFT"
            end

            return nil
        end

        return "BLUEPRINT"
    end

    if not IsSkillTreeNodeAvailableForBlueprintPool(
        character,
        skill,
        skill_data
    ) or not IsSkillTreeNodeBlueprintActivationProgressAllowed() then
        return "RIFT"
    end

    return nil
end

local function IsSkillTreeNodeActivationAllowed(
    updater,
    character,
    skill
)
    return GetSkillTreeNodeActivationBlockReason(
        updater,
        character,
        skill
    ) == nil
end

local function GetBlockedSkillTreeNodeActivation(
    updater,
    character,
    activated_skills
)
    if not IsSkillTreeNodeBlueprintControlEnabled()
        or activated_skills == nil then
        return nil
    end

    for skill in pairs(activated_skills) do
        local reason = GetExistingSkillTreeNodeActivationBlockReason(
            updater,
            character,
            skill
        )
        if reason ~= nil then
            return skill, reason
        end
    end

    return nil
end

local function ValidateCharacterDataWithBlueprintSkillUnlocks(
    updater,
    character,
    activated_skills
)
    local blocked_skill, reason = GetBlockedSkillTreeNodeActivation(
        updater,
        character,
        activated_skills
    )
    if blocked_skill ~= nil then
        if not updater._techlost_suppress_skill_blueprint_hint then
            if reason == "RIFT" then
                SaySkillTreeRiftRequired(updater.inst)
            else
                SaySkillTreeBlueprintRequired(updater.inst)
            end
        end
        return false
    end

    return true
end

local function RemoveUnauthorizedSkillTreeNodeActivations(updater)
    if not IsSkillTreeNodeBlueprintControlEnabled()
        or updater == nil
        or updater.GetActivatedSkills == nil then
        return false
    end

    local character = updater.inst.prefab
    local activated_skills = updater:GetActivatedSkills()
    if activated_skills == nil then
        return false
    end

    local removed_skills = {}
    for skill in pairs(activated_skills) do
        if GetExistingSkillTreeNodeActivationBlockReason(
            updater,
            character,
            skill
        ) ~= nil then
            removed_skills[#removed_skills + 1] = skill
        end
    end

    if #removed_skills <= 0 then
        return false
    end

    for _, skill in ipairs(removed_skills) do
        if updater.DeactivateSkill ~= nil then
            updater._techlost_suppress_skill_blueprint_hint = true
            updater:DeactivateSkill(skill)
            updater._techlost_suppress_skill_blueprint_hint = nil
        end

        local character_skills = updater.skilltree ~= nil
            and updater.skilltree.activatedskills ~= nil
            and updater.skilltree.activatedskills[character]
            or nil
        if character_skills ~= nil then
            character_skills[skill] = nil
        end
    end

    SayUnauthorizedSkillTreeNodesRemoved(updater.inst)
    return true
end

local function DoStrictSkillTreeBlueprintCheck(updater)
    if updater == nil or updater.inst == nil then
        return
    end

    updater.inst:DoTaskInTime(0, function()
        if updater.inst.components ~= nil
            and updater.inst.components.skilltreeupdater == updater then
            RemoveUnauthorizedSkillTreeNodeActivations(updater)
        end
    end)
end

AddComponentPostInit("skilltreeupdater", function(self)
    if self.skilltree ~= nil then
        local old_validate_character_data = self.skilltree.ValidateCharacterData
        self.skilltree.ValidateCharacterData = function(skilltree, character, activated_skills, skill_xp, ...)
            if not ValidateCharacterDataWithBlueprintSkillUnlocks(
                self,
                character,
                activated_skills
            ) then
                return false
            end

            return old_validate_character_data ~= nil
                and old_validate_character_data(
                    skilltree,
                    character,
                    activated_skills,
                    skill_xp,
                    ...
                )
                or false
        end
    end

    local old_activate_skill = self.ActivateSkill
    self.ActivateSkill = function(self, skill, ...)
        local character = self.inst.prefab
        local should_consume_permit =
            IsSkillTreeNodeBlueprintControlled(
                character,
                skill,
                GetSkillData(character, skill)
            )
            and not IsSkillTreeNodeBlueprintUnlocked(self, character, skill)
        local reason = GetSkillTreeNodeActivationBlockReason(
            self,
            character,
            skill
        )
        if reason ~= nil then
            if reason == "RIFT" then
                SaySkillTreeRiftRequired(self.inst)
            else
                SaySkillTreeBlueprintRequired(self.inst)
            end
            return false
        end

        if should_consume_permit then
            self._techlost_pending_skill_permit_activation = skill
        end

        local result, activate_reason = nil, nil
        if old_activate_skill ~= nil then
            result, activate_reason = old_activate_skill(self, skill, ...)
        end
        self._techlost_pending_skill_permit_activation = nil

        if result and should_consume_permit then
            ConsumeSkillTreePermitPoint(self, character)
            RememberBlueprintSkillUnlock(self, character, skill)
        end

        return result, activate_reason
    end

    local old_onsave = self.OnSave
    self.OnSave = function(self, ...)
        local data = old_onsave ~= nil and old_onsave(self, ...) or nil
        local skill_unlocks =
            CopyBlueprintSkillUnlocks(self._techlost_blueprint_skill_unlocks)
        if skill_unlocks ~= nil then
            data = data or {}
            data.techlost_blueprint_skill_unlocks = skill_unlocks
        end
        local permit_points =
            CopySkillTreePermitPoints(self._techlost_skill_permit_points)
        if permit_points ~= nil then
            data = data or {}
            data.techlost_skill_permit_points = permit_points
        end

        return data
    end

    local old_onload = self.OnLoad
    self.OnLoad = function(self, data, ...)
        if old_onload ~= nil then
            old_onload(self, data, ...)
        end
        self._techlost_blueprint_skill_unlocks = data ~= nil
            and MergeBlueprintSkillUnlocks(
                data.techlost_blueprint_skill_unlocks,
                data.techlost_blueprint_skills
            )
            or nil
        self._techlost_skill_permit_points = data ~= nil
            and CopySkillTreePermitPoints(data.techlost_skill_permit_points)
            or nil

        DoStrictSkillTreeBlueprintCheck(self)
    end

    local old_transfer_component = self.TransferComponent
    self.TransferComponent = function(self, newinst, ...)
        if old_transfer_component ~= nil then
            old_transfer_component(self, newinst, ...)
        end
        if newinst ~= nil
            and newinst.components ~= nil
            and newinst.components.skilltreeupdater ~= nil then
            local new_updater = newinst.components.skilltreeupdater
            new_updater._techlost_blueprint_skill_unlocks =
                CopyBlueprintSkillUnlocks(
                    self._techlost_blueprint_skill_unlocks
                )
            new_updater._techlost_skill_permit_points =
                newinst.prefab == self.inst.prefab
                and CopySkillTreePermitPoints(
                    self._techlost_skill_permit_points
                )
                or nil
            DoStrictSkillTreeBlueprintCheck(new_updater)
        end
    end
end)

if AddClassPostConstruct ~= nil then
    AddClassPostConstruct("components/builder_replica", function(self)
        local old_knows_recipe = self.KnowsRecipe
        self.KnowsRecipe = function(self, recipe, ...)
            local recipe_data = ResolveRecipe(recipe)
            if IsStationBoundBlueprintRecipe(recipe_data)
                and not IsReplicaAtOriginalTechStation(self, recipe_data) then
                return false
            end

            return old_knows_recipe(self, recipe, ...)
        end
    end)
end

-- Cover recipes registered after this mod, including recipes from other mods.
if AddRecipePostInitAny ~= nil then
    AddRecipePostInitAny(MakeRecipeBlueprintOnly)
end

-- Cover all recipes that already exist once every mod has finished loading.
AddSimPostInit(function()
    for _, recipe in pairs(GLOBAL.AllRecipes) do
        MakeRecipeBlueprintOnly(recipe)
    end
end)

local function IsBlueprintPoolRecipe(recipe)
    if recipe == nil then
        return false
    end

    local original_level = recipe._blueprint_only_locked
        and recipe._blueprint_only_original_level
        or recipe.level
    return IsBlueprintCompatible(recipe, original_level)
        and RequiresBlueprintLearning(recipe, original_level)
        and IsRiftTechnologyAvailableForBlueprintPool(recipe, original_level)
end

local function GetTumbleweedBlueprintRecipes()
    local candidates = {}

    for _, recipe in pairs(GLOBAL.AllRecipes) do
        if recipe._blueprint_only_locked
            and IsBlueprintPoolRecipe(recipe)
            and IsRecipeActiveForBlueprintPool(recipe) then
            candidates[#candidates + 1] = recipe
        end
    end

    return candidates
end

local function GetMaximumTechnologyLevel(level)
    local max_level = 0

    if level ~= nil then
        for _, required_level in pairs(level) do
            if type(required_level) == "number"
                and required_level > max_level
                and required_level < 10 then
                max_level = required_level
            end
        end
    end

    return max_level
end

local function GetBlueprintPoolTier(recipe)
    local original_level = recipe ~= nil
        and (recipe._blueprint_only_locked
            and recipe._blueprint_only_original_level
            or recipe.level)
        or nil

    if GetOptionalStationTechnologyEnabled(original_level) ~= nil then
        return BLUEPRINT_TIER_ADVANCED
    end

    local max_level = GetMaximumTechnologyLevel(original_level)
    if max_level <= 1 then
        return BLUEPRINT_TIER_BASIC
    elseif max_level == 2 then
        return BLUEPRINT_TIER_INTERMEDIATE
    end

    return BLUEPRINT_TIER_ADVANCED
end

local function SelectTieredBlueprintRecipe(candidates)
    if candidates == nil or #candidates == 0 then
        return nil
    end

    local tiered_candidates = {
        [BLUEPRINT_TIER_BASIC] = {},
        [BLUEPRINT_TIER_INTERMEDIATE] = {},
        [BLUEPRINT_TIER_ADVANCED] = {},
    }

    for _, recipe in ipairs(candidates) do
        local tier = GetBlueprintPoolTier(recipe)
        tiered_candidates[tier][#tiered_candidates[tier] + 1] = recipe
    end

    local available_tiers = {}
    local total_weight = 0
    for _, tier_data in ipairs(TUMBLEWEED_BLUEPRINT_TIER_WEIGHTS) do
        if #tiered_candidates[tier_data.tier] > 0 then
            available_tiers[#available_tiers + 1] = tier_data
            total_weight = total_weight + tier_data.weight
        end
    end

    if total_weight <= 0 then
        return candidates[math.random(#candidates)]
    end

    local roll = math.random() * total_weight
    for _, tier_data in ipairs(available_tiers) do
        roll = roll - tier_data.weight
        if roll <= 0 then
            local tier_candidates = tiered_candidates[tier_data.tier]
            return tier_candidates[math.random(#tier_candidates)]
        end
    end

    local fallback_candidates =
        tiered_candidates[available_tiers[#available_tiers].tier]
    return fallback_candidates[math.random(#fallback_candidates)]
end

local function SelectTumbleweedBlueprintRecipe()
    return SelectTieredBlueprintRecipe(GetTumbleweedBlueprintRecipes())
end

local function IsAdvancedBlueprintPoolRecipe(recipe)
    if recipe == nil then
        return false
    end

    local original_level = recipe._blueprint_only_locked
        and recipe._blueprint_only_original_level
        or recipe.level
    return IsBlueprintPoolRecipe(recipe)
        and (GetOptionalStationTechnologyEnabled(original_level) ~= nil
            or IsCharacterTagRecipeEnabled(recipe, original_level)
            or IsSkillTreeTechnologyRecipe(recipe, original_level))
end

local function GetAdvancedBlueprintRecipes(character)
    local candidates = {}

    for _, recipe in pairs(GLOBAL.AllRecipes) do
        if recipe._blueprint_only_locked
            and IsAdvancedBlueprintPoolRecipe(recipe)
            and IsRecipeAllowedForRewardCharacter(recipe, character) then
            candidates[#candidates + 1] = recipe
        end
    end

    return candidates
end

local function IsSkillTreeNodeBlueprintCandidate(
    character,
    skill,
    skill_data,
    character_filter
)
    local character_allowed = false
    if character_filter ~= nil then
        character_allowed = character_filter(character)
    else
        character_allowed = IsSelectableCharacter(character)
    end

    return IsSkillTreeNodeBlueprintControlled(character, skill, skill_data)
        and character_allowed
        and IsSkillTreeNodeAvailableForBlueprintPool(character, skill, skill_data)
end

local function GetSkillTreeNodeBlueprintCandidates(character_filter)
    local candidates = {}
    local skill_defs = skilltree_defs ~= nil
        and skilltree_defs.SKILLTREE_DEFS
        or nil
    if skill_defs == nil then
        return candidates
    end

    for character, skills in pairs(skill_defs) do
        if IsSelectableCharacter(character) then
            for skill, skill_data in pairs(skills) do
                if IsSkillTreeNodeBlueprintCandidate(
                    character,
                    skill,
                    skill_data,
                    character_filter
                ) then
                    candidates[#candidates + 1] = {
                        character = character,
                    }
                    break
                end
            end
        end
    end

    return candidates
end

local function GetWorldRainWashCount()
    return GLOBAL.TheWorld ~= nil
        and GLOBAL.TheWorld._techlost_rain_wash_count
        or 0
end

local function OnWorldRainChanged(world, israining)
    if not israining then
        world._techlost_was_raining = false
        return
    end

    if world._techlost_was_raining then
        return
    end

    world._techlost_was_raining = true
    world._techlost_rain_wash_count =
        (world._techlost_rain_wash_count or 0) + 1
end

local function InitWorldRainWashCounter(inst)
    if inst._techlost_rain_wash_initialized then
        return
    end

    inst._techlost_rain_wash_initialized = true

    if not inst.ismastersim then
        return
    end

    inst._techlost_rain_wash_count = inst._techlost_rain_wash_count or 0
    inst._techlost_was_raining =
        inst.state ~= nil
        and inst.state.israining == true

    inst:WatchWorldState("israining", OnWorldRainChanged)

    local old_onsave = inst.OnSave
    inst.OnSave = function(inst, data)
        if old_onsave ~= nil then
            old_onsave(inst, data)
        end
        if data ~= nil then
            data.techlost_rain_wash_count =
                inst._techlost_rain_wash_count or nil
        end
    end

    local old_onload = inst.OnLoad
    inst.OnLoad = function(inst, data)
        if old_onload ~= nil then
            old_onload(inst, data)
        end
        if data ~= nil then
            inst._techlost_rain_wash_count =
                data.techlost_rain_wash_count or 0
        end
        inst._techlost_was_raining =
            inst.state ~= nil
            and inst.state.israining == true
    end
end

AddPrefabPostInit("world", InitWorldRainWashCounter)
AddPrefabPostInit("forest", InitWorldRainWashCounter)
AddPrefabPostInit("cave", InitWorldRainWashCounter)

if AddPlayerPostInit ~= nil then
    AddPlayerPostInit(function(inst)
        if GLOBAL.TheWorld ~= nil and GLOBAL.TheWorld.ismastersim then
            if inst.components ~= nil
                and inst.components.skilltreeupdater ~= nil then
                DoStrictSkillTreeBlueprintCheck(
                    inst.components.skilltreeupdater
                )
            end
        end
    end)
end

local function ConfigureBlueprint(blueprint, recipe)
    if blueprint == nil or recipe == nil or blueprint.components.teacher == nil then
        return false
    end

    blueprint.recipetouse = recipe.name
    blueprint.components.teacher:SetRecipe(recipe.name)

    local product_name =
        GLOBAL.STRINGS.NAMES[string.upper(recipe.name)] or recipe.name
    local blueprint_name = GLOBAL.STRINGS.NAMES.BLUEPRINT or "Blueprint"
    if blueprint.components.named ~= nil then
        local name = product_name .. " " .. blueprint_name
        local owner = GetRecipeOwnerCharacter(recipe)
        if owner ~= nil then
            name = GetCharacterDisplayName(owner) .. " - " .. name
        end
        blueprint.components.named:SetName(name)
    end

    if IsBlueprintPoolRecipe(recipe) then
        blueprint._techlost_blueprint_pool_generated = true
        blueprint._techlost_last_rain_wash_count = GetWorldRainWashCount()
    end

    return true
end

local function GetSkillTreeNodeBlueprintName(character)
    local blueprint_name = GLOBAL.STRINGS.NAMES.BLUEPRINT or "Blueprint"

    return GetCharacterDisplayName(character)
        .. " - "
        .. "技能许可"
        .. blueprint_name
end

local function ConfigureSkillTreeNodeBlueprint(blueprint, candidate)
    if blueprint == nil
        or candidate == nil
        or blueprint.components == nil
        or blueprint.components.teacher == nil then
        return false
    end

    blueprint.recipetouse = nil
    blueprint.components.teacher:SetRecipe(nil)
    blueprint._techlost_skill_blueprint = true
    blueprint._techlost_skill_blueprint_character = candidate.character
    blueprint._techlost_skill_blueprint_skill = nil
    blueprint._techlost_blueprint_pool_generated = true
    blueprint._techlost_last_rain_wash_count = GetWorldRainWashCount()

    if blueprint.components.named ~= nil then
        blueprint.components.named:SetName(GetSkillTreeNodeBlueprintName(
            candidate.character
        ))
    end

    return true
end

local function GiveAdvancedBlueprint(container_owner, reward_player)
    local candidates =
        GetAdvancedBlueprintRecipes(GetRewardCharacter(reward_player))
    if #candidates == 0 then
        return false
    end

    local blueprint = GLOBAL.SpawnPrefab("blueprint")
    if blueprint == nil
        or not ConfigureBlueprint(blueprint, candidates[math.random(#candidates)]) then
        if blueprint ~= nil then
            blueprint:Remove()
        end
        return false
    end

    local container = container_owner ~= nil
        and container_owner.components ~= nil
        and container_owner.components.container
        or nil
    if container ~= nil then
        if container:IsFull() then
            blueprint:Remove()
            return false
        end
        if container:GiveItem(blueprint) ~= nil then
            return true
        end
        blueprint:Remove()
        return false
    end

    local inventory = container_owner ~= nil
        and container_owner.components ~= nil
        and container_owner.components.inventory
        or nil
    if inventory ~= nil then
        local item_count = GetTableSize(inventory.itemslots)
        if inventory.maxslots ~= nil and item_count >= inventory.maxslots then
            blueprint:Remove()
            return false
        end
        if inventory:GiveItem(blueprint) ~= nil then
            return true
        end
        blueprint:Remove()
        return false
    end

    blueprint:Remove()
    return false
end

local function ForEachStoredItem(container_owner, fn)
    if container_owner == nil
        or container_owner.components == nil
        or fn == nil then
        return
    end

    local container = container_owner.components.container
    if container ~= nil and container.slots ~= nil then
        for _, item in pairs(container.slots) do
            fn(item)
        end
    end

    local inventory = container_owner.components.inventory
    if inventory ~= nil and inventory.itemslots ~= nil then
        for _, item in pairs(inventory.itemslots) do
            fn(item)
        end
    end
end

local function StoredItemMatches(container_owner, prefabs)
    local matched = false
    ForEachStoredItem(container_owner, function(item)
        if item ~= nil and prefabs[item.prefab] then
            matched = true
        end
    end)
    return matched
end

local function HasSunkenTreasureMarker(container_owner)
    return StoredItemMatches(container_owner, SUNKEN_TREASURE_MARKER_ITEMS)
end

local function GetSunkenTreasureAdvancedBlueprintCount(sunken_chest)
    if sunken_treasure_advanced_blueprint_chance <= 0 then
        return 0
    end

    local is_splunker =
        StoredItemMatches(sunken_chest, SUNKEN_TREASURE_SPLUNKER_ITEMS)
    local is_traveler =
        StoredItemMatches(sunken_chest, SUNKEN_TREASURE_TRAVELER_ITEMS)
    local is_miner =
        StoredItemMatches(sunken_chest, SUNKEN_TREASURE_MINER_ITEMS)
    local has_high_gem =
        StoredItemMatches(sunken_chest, SUNKEN_TREASURE_HIGH_GEMS)

    if is_splunker then
        return has_high_gem and 2 or 1
    elseif is_traveler then
        return 1
    elseif is_miner and has_high_gem then
        return 1
    end

    return math.random() < sunken_treasure_advanced_blueprint_chance and 1 or 0
end

local function AddSunkenTreasureAdvancedBlueprints(sunken_chest, opener)
    if sunken_treasure_advanced_blueprint_chance <= 0
        or sunken_chest == nil
        or sunken_chest._techlost_advanced_blueprints_checked
        or (sunken_chest.GetCurrentPlatform ~= nil
            and sunken_chest:GetCurrentPlatform() ~= nil) then
        return
    end

    if GetRewardCharacter(opener) == nil then
        return
    end

    sunken_chest._techlost_advanced_blueprints_checked = true

    local count = GetSunkenTreasureAdvancedBlueprintCount(sunken_chest)
    for _ = 1, count do
        if not GiveAdvancedBlueprint(sunken_chest, opener) then
            return
        end
    end
end

local function AddPirateTreasureAdvancedBlueprint(stash, worker)
    if pirate_treasure_advanced_blueprint_chance <= 0
        or stash == nil
        or stash._techlost_advanced_blueprints_checked then
        return
    end

    if GetRewardCharacter(worker) == nil then
        return
    end

    stash._techlost_advanced_blueprints_checked = true

    if stash._techlost_has_sunken_treasure
        or math.random() < pirate_treasure_advanced_blueprint_chance then
        GiveAdvancedBlueprint(stash, worker)
    end
end

local function RepairInvalidBlueprint(blueprint)
    if blueprint._techlost_skill_blueprint then
        return
    end

    local current_recipe = blueprint.recipetouse ~= nil
        and GLOBAL.AllRecipes[blueprint.recipetouse]
        or nil
    local current_original_level = current_recipe ~= nil
        and current_recipe._blueprint_only_locked
        and current_recipe._blueprint_only_original_level
        or (current_recipe ~= nil and current_recipe.level or nil)

    -- Specific rare blueprint prefabs also identify themselves as "blueprint".
    -- Preserve native TECH.LOST rewards such as Antlion's fixed blueprints.
    if blueprint.is_rare
        and IsNativeLostTechnology(current_original_level) then
        return
    end

    if blueprint.recipetouse ~= "unknown"
        and IsBlueprintPoolRecipe(current_recipe) then
        return
    end

    local candidates = GetTumbleweedBlueprintRecipes()
    if #candidates == 0 then
        for _, recipe in pairs(GLOBAL.AllRecipes) do
            if IsBlueprintPoolRecipe(recipe) then
                candidates[#candidates + 1] = recipe
            end
        end
    end

    if #candidates == 0 then
        return
    end

    local recipe = SelectTieredBlueprintRecipe(candidates)
    ConfigureBlueprint(blueprint, recipe)
end

local function IsGroundBlueprint(blueprint)
    return blueprint ~= nil
        and blueprint._techlost_blueprint_pool_generated
        and blueprint.components ~= nil
        and blueprint.components.inventoryitem ~= nil
        and blueprint.components.inventoryitem.owner == nil
        and not blueprint:HasTag("INLIMBO")
        and not blueprint.is_rare
end

local function ReconcileBlueprintRainWashes(blueprint)
    if ground_blueprint_rain_washes <= 0
        or blueprint == nil
        or blueprint.is_rare
        or not blueprint._techlost_blueprint_pool_generated then
        return
    end

    local current_rain_wash_count = GetWorldRainWashCount()
    local last_rain_wash_count = blueprint._techlost_last_rain_wash_count
    blueprint._techlost_last_rain_wash_count = current_rain_wash_count

    if last_rain_wash_count == nil
        or current_rain_wash_count <= last_rain_wash_count
        or not IsGroundBlueprint(blueprint) then
        return
    end

    blueprint._techlost_rain_washes =
        (blueprint._techlost_rain_washes or 0)
        + current_rain_wash_count
        - last_rain_wash_count

    if blueprint._techlost_rain_washes >= ground_blueprint_rain_washes then
        blueprint:Remove()
    end
end

local function OnBlueprintRainChanged(blueprint, israining)
    if not israining then
        blueprint._techlost_was_raining = false
        return
    end

    -- WatchWorldState may fire immediately when registered. Track the current
    -- rain state so newly spawned or loaded blueprints are only counted by the
    -- next real rain start.
    if blueprint._techlost_was_raining then
        return
    end

    blueprint._techlost_was_raining = true
    blueprint:DoTaskInTime(0, ReconcileBlueprintRainWashes)
end

-- Vanilla random blueprints exclude TECH.LOST but do not exclude builder_skill.
-- Replace unknown or configuration-excluded results with our filtered pool.
AddPrefabPostInit("blueprint", function(inst)
    if not GLOBAL.TheWorld.ismastersim then
        return
    end

    RepairInvalidBlueprint(inst)

    if ground_blueprint_rain_washes > 0 and not inst.is_rare then
        inst._techlost_was_raining =
            GLOBAL.TheWorld ~= nil
            and GLOBAL.TheWorld.state ~= nil
            and GLOBAL.TheWorld.state.israining == true
        inst:WatchWorldState("israining", OnBlueprintRainChanged)
    end

    local old_onsave = inst.OnSave
    inst.OnSave = function(inst, data)
        if old_onsave ~= nil then
            old_onsave(inst, data)
        end
        if data ~= nil then
            data.techlost_rain_washes = inst._techlost_rain_washes or nil
            data.techlost_blueprint_pool_generated =
                inst._techlost_blueprint_pool_generated or nil
            data.techlost_last_rain_wash_count =
                inst._techlost_last_rain_wash_count or nil
            data.techlost_skill_blueprint =
                inst._techlost_skill_blueprint or nil
            data.techlost_skill_blueprint_character =
                inst._techlost_skill_blueprint_character or nil
            data.techlost_skill_blueprint_skill =
                inst._techlost_skill_blueprint_skill or nil
        end
    end

    local old_onload = inst.OnLoad
    inst.OnLoad = function(inst, data)
        if old_onload ~= nil then
            old_onload(inst, data)
        end
        if data ~= nil then
            inst._techlost_rain_washes = data.techlost_rain_washes or nil
            inst._techlost_blueprint_pool_generated =
                data.techlost_blueprint_pool_generated or nil
            inst._techlost_last_rain_wash_count =
                data.techlost_last_rain_wash_count or nil
            inst._techlost_skill_blueprint =
                data.techlost_skill_blueprint or nil
            inst._techlost_skill_blueprint_character =
                data.techlost_skill_blueprint_character or nil
            inst._techlost_skill_blueprint_skill =
                data.techlost_skill_blueprint_skill or nil
            if inst._techlost_skill_blueprint then
                inst.recipetouse = nil
                if inst.components.teacher ~= nil then
                    inst.components.teacher:SetRecipe(nil)
                end
                if inst.components.named ~= nil then
                    inst.components.named:SetName(GetSkillTreeNodeBlueprintName(
                        inst._techlost_skill_blueprint_character
                    ))
                end
            end
        end
        RepairInvalidBlueprint(inst)
        inst:DoTaskInTime(0, ReconcileBlueprintRainWashes)
    end
end)

AddPrefabPostInit("sunkenchest", function(inst)
    if not GLOBAL.TheWorld.ismastersim then
        return
    end

    local old_onsave = inst.OnSave
    inst.OnSave = function(inst, data)
        if old_onsave ~= nil then
            old_onsave(inst, data)
        end
        data.techlost_advanced_blueprints_checked =
            inst._techlost_advanced_blueprints_checked or nil
    end

    local old_onload = inst.OnLoad
    inst.OnLoad = function(inst, data)
        if old_onload ~= nil then
            old_onload(inst, data)
        end
        if data ~= nil then
            inst._techlost_advanced_blueprints_checked =
                data.techlost_advanced_blueprints_checked or nil
        end
    end

    inst:ListenForEvent("onopen", function(inst, data)
        AddSunkenTreasureAdvancedBlueprints(
            inst,
            data ~= nil and (data.doer or data.opener or data.player) or nil
        )
    end)

    if inst.components.container ~= nil then
        local old_onopenfn = inst.components.container.onopenfn
        inst.components.container.onopenfn = function(inst, ...)
            AddSunkenTreasureAdvancedBlueprints(inst, select(1, ...))
            if old_onopenfn ~= nil then
                return old_onopenfn(inst, ...)
            end
        end
    end
end)

AddPrefabPostInit("pirate_stash", function(inst)
    if not GLOBAL.TheWorld.ismastersim then
        return
    end

    inst:ListenForEvent("itemget", function(inst, data)
        local item = data ~= nil and data.item or nil
        if item ~= nil and SUNKEN_TREASURE_MARKER_ITEMS[item.prefab] then
            inst._techlost_has_sunken_treasure = true
        end
    end)

    inst:DoTaskInTime(0, function(inst)
        if HasSunkenTreasureMarker(inst) then
            inst._techlost_has_sunken_treasure = true
        end
    end)

    if inst.components.workable ~= nil then
        local old_onfinish = inst.components.workable.onfinish
        inst.components.workable:SetOnFinishCallback(function(inst, worker, ...)
            AddPirateTreasureAdvancedBlueprint(inst, worker)
            if old_onfinish ~= nil then
                return old_onfinish(inst, worker, ...)
            end
        end)
    end
end)

local function DropRandomBlueprint(inst)
    local recipe = SelectTumbleweedBlueprintRecipe()
    if recipe == nil then
        return
    end

    local blueprint = GLOBAL.SpawnPrefab("blueprint")
    if blueprint == nil then
        return
    end

    ConfigureBlueprint(blueprint, recipe)
    blueprint.Transform:SetPosition(inst.Transform:GetWorldPosition())
end

local function DropRandomSkillTreeNodeBlueprint(inst, character_filter)
    local candidates = GetSkillTreeNodeBlueprintCandidates(character_filter)
    if #candidates == 0 then
        return
    end

    local blueprint = GLOBAL.SpawnPrefab("blueprint")
    if blueprint == nil then
        return
    end

    if not ConfigureSkillTreeNodeBlueprint(
        blueprint,
        candidates[math.random(#candidates)]
    ) then
        blueprint:Remove()
        return
    end

    blueprint.Transform:SetPosition(inst.Transform:GetWorldPosition())
end

local function GetPlayerFromBlueprintDropSource(source)
    if source == nil then
        return nil
    end

    if source.HasTag ~= nil and source:HasTag("player") then
        return source
    end

    local inventory_owner = source.components ~= nil
        and source.components.inventoryitem ~= nil
        and source.components.inventoryitem.owner
        or nil
    if inventory_owner ~= nil
        and inventory_owner.HasTag ~= nil
        and inventory_owner:HasTag("player") then
        return inventory_owner
    end

    local leader = source.components ~= nil
        and source.components.follower ~= nil
        and source.components.follower.GetLeader ~= nil
        and source.components.follower:GetLeader()
        or nil
    if leader ~= nil
        and leader.HasTag ~= nil
        and leader:HasTag("player") then
        return leader
    end

    local owner = source.owner
    if owner ~= nil
        and owner.HasTag ~= nil
        and owner:HasTag("player") then
        return owner
    end

    return nil
end

local function GetPrimeMateBlueprintDropPlayer(inst, data)
    local player = data ~= nil
        and GetPlayerFromBlueprintDropSource(data.afflicter)
        or nil

    if player == nil then
        player = inst.components ~= nil
            and inst.components.combat ~= nil
            and GetPlayerFromBlueprintDropSource(inst.components.combat.lastattacker)
            or nil
    end

    return player
end

local function MakeCharacterBlueprintFilter(character)
    return function(candidate_character)
        return candidate_character == character
    end
end

local function DropPrimeMateSkillTreeNodeBlueprint(inst, data)
    local player = GetPrimeMateBlueprintDropPlayer(inst, data)
    if player == nil then
        return
    end

    DropRandomSkillTreeNodeBlueprint(
        inst,
        MakeCharacterBlueprintFilter(player.prefab)
    )
end

local function TryDropRandomBlueprints(inst)
    if math.random() < tumbleweed_blueprint_chance then
        DropRandomBlueprint(inst)
    end
end

AddPrefabPostInit("powder_monkey", function(inst)
    if not GLOBAL.TheWorld.ismastersim
        or not include_powder_monkey_blueprints then
        return
    end

    inst:ListenForEvent("death", function(inst)
        TryDropRandomBlueprints(inst)
    end)
end)

AddPrefabPostInit("prime_mate", function(inst)
    if not GLOBAL.TheWorld.ismastersim then
        return
    end

    inst:ListenForEvent("death", function(inst, data)
        DropPrimeMateSkillTreeNodeBlueprint(inst, data)
    end)
end)

AddPrefabPostInit("tumbleweed", function(inst)
    if not GLOBAL.TheWorld.ismastersim
        or inst.components.pickable == nil then
        return
    end

    local old_onpickedfn = inst.components.pickable.onpickedfn
    inst.components.pickable.onpickedfn = function(inst, picker, ...)
        TryDropRandomBlueprints(inst)

        if old_onpickedfn ~= nil then
            old_onpickedfn(inst, picker, ...)
        end
    end
end)
