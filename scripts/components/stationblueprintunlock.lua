local StationBlueprintUnlock = Class(function(self, inst)
    self.inst = inst
    self.unlocked_recipes = {}
end)

function StationBlueprintUnlock:IsUnlocked(recipe_name)
    return self.unlocked_recipes[recipe_name] == true
end

function StationBlueprintUnlock:UnlockRecipe(recipe_name)
    if recipe_name == nil or self.unlocked_recipes[recipe_name] then
        return false
    end

    self.unlocked_recipes[recipe_name] = true
    return true
end

function StationBlueprintUnlock:GetUnlockedRecipes()
    local recipes = {}
    for recipe_name in pairs(self.unlocked_recipes) do
        recipes[#recipes + 1] = recipe_name
    end
    table.sort(recipes)
    return recipes
end

function StationBlueprintUnlock:OnSave()
    return { unlocked_recipes = self:GetUnlockedRecipes() }
end

function StationBlueprintUnlock:OnLoad(data)
    if data == nil or data.unlocked_recipes == nil then
        return
    end

    for _, recipe_name in ipairs(data.unlocked_recipes) do
        self.unlocked_recipes[recipe_name] = true
    end
end

return StationBlueprintUnlock
