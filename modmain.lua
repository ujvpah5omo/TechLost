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
local include_character_tag_recipes =
    GetModConfigData("include_character_tag_recipes") == true
local lose_tech_on_death = GetModConfigData("lose_tech_on_death") == true

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

-- Keep a non-zero floor so every restricted recipe remains obtainable even
-- when upgrading a world whose old configuration had drops disabled.
local tumbleweed_blueprint_chance = math.max(
    GetModConfigData("tumbleweed_blueprint_chance") or 0.05,
    0.01
)

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
        if recipe._blueprint_only_locked and IsBlueprintPoolRecipe(recipe) then
            candidates[#candidates + 1] = recipe
        end
    end

    return candidates
end

local function ConfigureBlueprint(blueprint, recipe)
    if blueprint == nil or recipe == nil or blueprint.components.teacher == nil then
        return false
    end

    blueprint.recipetouse = recipe.name
    blueprint.components.teacher:SetRecipe(recipe.name)

    local product_name = GLOBAL.STRINGS.NAMES[string.upper(recipe.name)]
    local blueprint_name = GLOBAL.STRINGS.NAMES.BLUEPRINT
    if product_name ~= nil and blueprint_name ~= nil and blueprint.components.named ~= nil then
        blueprint.components.named:SetName(product_name .. " " .. blueprint_name)
    end

    return true
end

local function RepairInvalidBlueprint(blueprint)
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

    local recipe = candidates[math.random(#candidates)]
    ConfigureBlueprint(blueprint, recipe)
end

-- Vanilla random blueprints exclude TECH.LOST but do not exclude builder_skill.
-- Replace unknown or configuration-excluded results with our filtered pool.
AddPrefabPostInit("blueprint", function(inst)
    if not GLOBAL.TheWorld.ismastersim then
        return
    end

    RepairInvalidBlueprint(inst)

    local old_onload = inst.OnLoad
    inst.OnLoad = function(inst, data)
        if old_onload ~= nil then
            old_onload(inst, data)
        end
        RepairInvalidBlueprint(inst)
    end
end)

local function DropTumbleweedBlueprint(inst)
    local candidates = GetTumbleweedBlueprintRecipes()
    if #candidates == 0 then
        return
    end

    local recipe = candidates[math.random(#candidates)]
    local blueprint = GLOBAL.SpawnPrefab("blueprint")
    if blueprint == nil then
        return
    end

    ConfigureBlueprint(blueprint, recipe)
    blueprint.Transform:SetPosition(inst.Transform:GetWorldPosition())
end

AddPrefabPostInit("tumbleweed", function(inst)
    if not GLOBAL.TheWorld.ismastersim
        or inst.components.pickable == nil then
        return
    end

    local old_onpickedfn = inst.components.pickable.onpickedfn
    inst.components.pickable.onpickedfn = function(inst, picker, ...)
        if math.random() < tumbleweed_blueprint_chance then
            DropTumbleweedBlueprint(inst)
        end

        if old_onpickedfn ~= nil then
            old_onpickedfn(inst, picker, ...)
        end
    end
end)
