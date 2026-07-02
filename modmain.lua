local GLOBAL = GLOBAL

local BLUEPRINT_ONLY_TECH = (GLOBAL.TECH and GLOBAL.TECH.LOST) or { LOST = 1 }

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

local function IsBlueprintCompatible(recipe)
    if recipe.nounlock
        or recipe.builder_tag ~= nil
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

    if not IsBlueprintCompatible(recipe)
        or not RequiresTechnology(original_level) then
        RestoreRecipe(recipe)
        return
    end

    if not recipe._blueprint_only_locked then
        -- LOST tech cannot be prototyped, but learning the recipe from a
        -- blueprint still adds it to the builder's known recipe list.
        recipe._blueprint_only_original_level = recipe.level
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

AddComponentPostInit("builder", function(self)
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

    if self.inst:HasTag("player") then
        self.inst:ListenForEvent("death", function()
            LoseLearnedRecipes(self)
        end)
    end
end)

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

local function GetTumbleweedBlueprintRecipes()
    local candidates = {}

    for _, recipe in pairs(GLOBAL.AllRecipes) do
        if recipe._blueprint_only_locked and IsBlueprintCompatible(recipe) then
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

local function RepairUnknownBlueprint(blueprint)
    if blueprint.recipetouse ~= nil and blueprint.recipetouse ~= "unknown" then
        return
    end

    local candidates = GetTumbleweedBlueprintRecipes()
    if #candidates == 0 then
        for _, recipe in pairs(GLOBAL.AllRecipes) do
            if IsBlueprintCompatible(recipe) and RequiresTechnology(recipe.level) then
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

-- The vanilla random blueprint generator excludes TECH.LOST. Since this mod
-- intentionally uses LOST, replace its empty "unknown" result with our pool.
AddPrefabPostInit("blueprint", function(inst)
    if not GLOBAL.TheWorld.ismastersim then
        return
    end

    RepairUnknownBlueprint(inst)

    local old_onload = inst.OnLoad
    inst.OnLoad = function(inst, data)
        if old_onload ~= nil then
            old_onload(inst, data)
        end
        RepairUnknownBlueprint(inst)
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
