local GlobalBlueprintUnlock = Class(function(self, inst)
    self.inst = inst
    self.unlocked_recipes = {}
    self.onunlockfn = nil
end)

function GlobalBlueprintUnlock:IsUnlocked(recipe_name)
    return self.unlocked_recipes[recipe_name] == true
end

function GlobalBlueprintUnlock:UnlockRecipe(recipe_name)
    if recipe_name == nil or self.unlocked_recipes[recipe_name] then
        return
    end

    self.unlocked_recipes[recipe_name] = true
    if self.onunlockfn ~= nil then
        self.onunlockfn(recipe_name)
    end
end

function GlobalBlueprintUnlock:GetUnlockedRecipes()
    local recipes = {}
    for recipe_name in pairs(self.unlocked_recipes) do
        recipes[#recipes + 1] = recipe_name
    end
    table.sort(recipes)
    return recipes
end

function GlobalBlueprintUnlock:OnSave()
    return { unlocked_recipes = self:GetUnlockedRecipes() }
end

function GlobalBlueprintUnlock:OnLoad(data)
    if data == nil or data.unlocked_recipes == nil then
        return
    end

    for _, recipe_name in ipairs(data.unlocked_recipes) do
        self.unlocked_recipes[recipe_name] = true
    end

    self.inst:DoTaskInTime(0, function()
        if self.onunlockfn ~= nil then
            for _, recipe_name in ipairs(self:GetUnlockedRecipes()) do
                self.onunlockfn(recipe_name)
            end
        end
    end)
end

return GlobalBlueprintUnlock
