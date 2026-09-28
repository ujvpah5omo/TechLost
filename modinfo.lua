local _locale = locale or "en"
local _is_zh =
    _locale == "zh"
    or _locale == "zhr"
    or _locale == "zht"
    or _locale == "chs"
    or _locale == "cht"
    or _locale == "sc"
    or _locale == "tc"
    or _locale == "zh_CN"
    or _locale == "zh_TW"
    or _locale == "zh-CN"
    or _locale == "zh-TW"
    or _locale == "chinese"
    or _locale == "schinese"
    or _locale == "tchinese"

local function T(zh, en)
    return _is_zh and zh or en
end

name = T("全科技蓝图解锁", "Tech Lost")
description = T([[
配方不能直接通过科技站解锁，蓝图才是知识来源。每台科技站独立保存公开配方。

普通蓝图来自风滚草和普通海盗猴，默认 50%。普通池约 304 张：基础约 100、进阶约 151、高级约 53；按 35% / 55% / 10% 分层抽取。默认 50% 掉图时，指定单张约为基础 0.175%、进阶 0.182%、高级 0.094%。

高级蓝图来自沉底宝箱和海盗宝藏。高级池为公共高级科技 + 触发者角色自己的专属科技，等概率随机。公共高级约 39 张；沉底宝箱和宝藏推荐概率 20%。

支持远古塔、辉煌铁匠铺、暗影操纵基座、角色专属科技、技能树制作配方、技能许可点、死亡丢失科技、地面蓝图雨水冲刷等可配置规则。
]], [[
Recipes cannot be unlocked directly by tech stations. Blueprints are the source of knowledge. Each tech station stores its own shared recipes.

Normal blueprints come from tumbleweeds and Powder Monkey deaths. Default chance: 50%. The normal pool has about 304 recipes: Basic about 100, Intermediate about 151, Advanced about 53; tier weights are 35% / 55% / 10%. At 50% drop chance, a specific recipe is about Basic 0.175%, Intermediate 0.182%, Advanced 0.094%.

Advanced blueprints come from Sunken Chests and Pirate Treasure. The pool is public advanced tech plus the reward character's own character tech, selected evenly. Public advanced recipes: about 39. Recommended chest/treasure chance: 20%.

Configurable rules include Ancient tech, Brightsmithy tech, Shadowcraft Plinth tech, character-specific tech, skill-tree crafting recipes, skill permits, losing learned tech on death, and rain-washing ground blueprints.
]])
author = "Codex"
version = "2.10.29"
forumthread = "https://steamcommunity.com/sharedfiles/filedetails/?id=3748878775"

api_version = 10
api_version_dst = 10
dst_compatible = true
dont_starve_compatible = false
reign_of_giants_compatible = false
shipwrecked_compatible = false

all_clients_require_mod = true
client_only_mod = false
server_only_mod = false
priority = 0
server_filter_tags = { "blueprint", "tech", "progression" }

local OFF = T("关闭", "Off")
local ON = T("开启", "On")
local RECOMMENDED = T("推荐", "Recommended")

configuration_options =
{
    {
        name = "include_skill_tree_recipes",
        label = T("技能树配方蓝图", "Skill-Tree Recipe Blueprints"),
        hover = T(
            "开启后，技能树制作配方会进入高级蓝图池，包括需要科技站的技能树配方；按触发者角色筛选，月亮/暗影线需要对应裂隙。若技能许可蓝图为月后影后，则这类蓝图也需双裂隙后出现。",
            "If enabled, skill-tree crafting recipes enter the advanced blueprint pool, including station-bound skill recipes. They are filtered by reward character and rift progress. In after-both-rifts mode, these recipes also wait for both rifts."
        ),
        options =
        {
            {
                description = OFF,
                data = false,
                hover = T("技能树制作配方按原版方式使用，不额外加入蓝图池。", "Skill-tree crafting recipes use vanilla rules and are not added to the blueprint pool."),
            },
            {
                description = ON,
                data = true,
                hover = T("技能树制作配方需要先学习蓝图；角色相关奖励按触发者角色筛选。", "Skill-tree crafting recipes require blueprints first; character-related rewards are filtered by the triggering character."),
            },
        },
        default = false,
    },
    {
        name = "include_skill_tree_node_blueprints",
        label = T("技能树许可蓝图", "Skill Permit Blueprints"),
        hover = T(
            "开启后，技能树节点需要消耗技能许可点，再按原版技能点和前置条件手动点亮；许可点蓝图只由海盗猴首领大副按相关击杀角色掉落。禁用技能树会移除全部技能树定义。",
            "If enabled, controlled skill nodes require skill permit points, then still follow vanilla skill points and prerequisites. Permit blueprints only drop from Prime Mate for the related attacker character. Disable Skill Tree removes skill-tree definitions."
        ),
        options =
        {
            {
                description = OFF,
                data = false,
                hover = T("技能树节点按原版方式点亮，不需要技能许可点。", "Skill nodes use vanilla activation and do not require permit points."),
            },
            {
                description = ON,
                data = "enabled",
                hover = T("技能树节点需要技能许可点；许可点蓝图只由海盗猴首领大副掉落。", "Skill nodes require permit points; permit blueprints only drop from Prime Mate."),
            },
            {
                description = T("月后影后", "After Both Rifts"),
                data = "after_both_rifts",
                hover = T(
                    "许可点蓝图可提前掉落；月亮裂隙和暗影裂隙都开启后，才允许点亮受控技能，并允许技能树制作配方蓝图出现。",
                    "Permit blueprints can drop early, but controlled skills and skill-tree recipe blueprints unlock only after both Lunar and Shadow Rifts are enabled."
                ),
            },
            {
                description = T("禁用技能树", "Disable Skill Tree"),
                data = "disable_skill_tree",
                hover = T(
                    "移除技能树定义，停止获得技能经验，清理已点亮技能；技能树配方和许可蓝图均不可用。",
                    "Removes skill-tree definitions, stops skill XP, and clears activated skills. Skill-tree recipes and permit blueprints become unavailable."
                ),
            },
        },
        default = false,
    },
    {
        name = "include_character_tag_recipes",
        label = T("角色专属科技蓝图", "Character Tech Blueprints"),
        hover = T(
            "开启后，需要科技站的角色专属配方会进入高级蓝图池；沉底宝箱按开启者角色筛选，海盗宝藏按挖开者角色筛选。只有对应角色能学习。",
            "If enabled, character-specific recipes that require tech enter the advanced pool. Sunken Chests use the opener character; Pirate Treasure uses the digger character. Only the matching character can learn them."
        ),
        options =
        {
            {
                description = OFF,
                data = false,
                hover = T("需要科技站的角色专属配方按原版方式使用。", "Character-specific station recipes use vanilla rules."),
            },
            {
                description = ON,
                data = true,
                hover = T("需要科技站的角色专属配方进入高级蓝图池，并按触发者角色筛选。", "Character-specific station recipes enter the advanced pool and are filtered by triggering character."),
            },
        },
        default = false,
    },
    {
        name = "include_ancient_tech",
        label = T("远古塔科技蓝图", "Ancient Tech Blueprints"),
        hover = T("开启后，远古伪科学站配方会进入蓝图池；学习蓝图后仍需靠近对应远古塔制作。", "If enabled, Ancient Pseudoscience recipes enter the blueprint pool. Their original station is still required after learning."),
        options =
        {
            { description = OFF, data = false },
            { description = ON, data = true },
        },
        default = false,
    },
    {
        name = "include_lunar_forge_tech",
        label = T("辉煌铁匠铺科技蓝图", "Brightsmithy Blueprints"),
        hover = T("开启后，月亮裂隙开启后辉煌铁匠铺配方才会进入蓝图池；学习蓝图后仍需靠近辉煌铁匠铺制作。", "If enabled, Brightsmithy recipes enter the pool after Lunar Rifts are enabled. The Brightsmithy is still required after learning."),
        options =
        {
            { description = OFF, data = false },
            { description = ON, data = true },
        },
        default = false,
    },
    {
        name = "include_shadow_forge_tech",
        label = T("暗影操纵基座科技蓝图", "Shadowcraft Plinth Blueprints"),
        hover = T("开启后，暗影裂隙开启后暗影操纵基座配方才会进入蓝图池；学习蓝图后仍需靠近暗影操纵基座制作。", "If enabled, Shadowcraft Plinth recipes enter the pool after Shadow Rifts are enabled. The Shadowcraft Plinth is still required after learning."),
        options =
        {
            { description = OFF, data = false },
            { description = ON, data = true },
        },
        default = false,
    },
    {
        name = "sunken_treasure_advanced_blueprints",
        label = T("沉底宝箱高级蓝图", "Sunken Chest Advanced Blueprints"),
        hover = T(
            "沉底宝箱首次打开时按类型和内容额外产出高级蓝图；角色奖励按开启者角色筛选。稀有箱稳定给图，普通箱按概率给图。",
            "When first opened, Sunken Chests can add advanced blueprints based on type and loot. Character rewards use the opener character. Rare chests are guaranteed; normal chests use chance."
        ),
        options =
        {
            { description = OFF, data = 0 },
            { description = T("保守 10%", "Conservative 10%"), data = 0.10 },
            { description = RECOMMENDED .. " 20%", data = 0.20 },
            { description = T("慷慨 30%", "Generous 30%"), data = 0.30 },
            { description = "50%", data = 0.50 },
            { description = T("极高 75%", "Very High 75%"), data = 0.75 },
        },
        default = 0.20,
    },
    {
        name = "pirate_treasure_advanced_blueprints",
        label = T("海盗宝藏高级蓝图", "Pirate Treasure Advanced Blueprints"),
        hover = T(
            "含沉底宝箱内容的海盗宝藏必定额外给 1 张高级蓝图；普通海盗宝藏按配置概率给图。角色奖励按挖开者角色筛选。",
            "Pirate Treasure containing Sunken Chest loot always adds 1 advanced blueprint. Normal Pirate Treasure uses the configured chance. Character rewards use the digger character."
        ),
        options =
        {
            { description = OFF, data = 0 },
            { description = T("保守 10%", "Conservative 10%"), data = 0.10 },
            { description = RECOMMENDED .. " 20%", data = 0.20 },
            { description = T("慷慨 30%", "Generous 30%"), data = 0.30 },
            { description = "50%", data = 0.50 },
            { description = T("极高 75%", "Very High 75%"), data = 0.75 },
        },
        default = 0.20,
    },
    {
        name = "lose_tech_on_death",
        label = T("死亡丢失科技", "Lose Tech on Death"),
        hover = T("开启后，角色死亡会清空全部已学习配方；科技站公开进度不受影响。", "If enabled, death clears all learned recipes for that player. Tech station shared progress is not affected."),
        options =
        {
            { description = ON, data = true },
            { description = OFF, data = false },
        },
        default = false,
    },
    {
        name = "include_powder_monkey_blueprints",
        label = T("海盗猴蓝图掉落", "Powder Monkey Blueprint Drops"),
        hover = T("开启后，普通海盗猴死亡时会按风滚草蓝图概率掉落普通蓝图池的蓝图，不包含角色奖励和技能许可蓝图。", "If enabled, Powder Monkey deaths use the tumbleweed chance to drop normal-pool blueprints. Does not include character rewards or skill permits."),
        options =
        {
            { description = ON, data = true },
            { description = OFF, data = false },
        },
        default = true,
    },
    {
        name = "ground_blueprint_rain_washes",
        label = T("地面蓝图雨水冲刷", "Ground Blueprint Rain Wash"),
        hover = T("本 Mod 蓝图池生成的蓝图丢在地上时，每次开始下雨计数一次；达到次数后消失。放进背包或箱子会暂停计数，原生蓝图不受影响。", "Blueprints generated by this mod count rain starts while on the ground and disappear after the set count. Inventories and containers pause counting. Native blueprints are not affected."),
        options =
        {
            { description = OFF, data = 0 },
            { description = T("1 次雨", "1 Rain"), data = 1 },
            { description = T("2 次雨", "2 Rains"), data = 2 },
            { description = T("3 次雨", "3 Rains"), data = 3 },
            { description = T("5 次雨", "5 Rains"), data = 5 },
        },
        default = 3,
    },
    {
        name = "tumbleweed_blueprint_chance",
        label = T("风滚草蓝图概率", "Tumbleweed Blueprint Chance"),
        hover = T(
            "每株风滚草额外掉落一张普通蓝图池蓝图的概率；普通海盗猴也使用这个概率。普通池约 304 张：基础约 100、进阶约 151、高级约 53；按 35% / 55% / 10% 分层抽取。",
            "Chance for each tumbleweed to add one normal-pool blueprint. Powder Monkeys also use this chance. Normal pool has about 304 recipes: Basic about 100, Intermediate about 151, Advanced about 53; tier weights are 35% / 55% / 10%."
        ),
        options =
        {
            { description = "1%", data = 0.01 },
            { description = "2%", data = 0.02 },
            { description = "5%", data = 0.05 },
            { description = "10%", data = 0.10 },
            { description = "20%", data = 0.20 },
            { description = RECOMMENDED .. " 50%", data = 0.50 },
            { description = "75%", data = 0.75 },
            { description = T("必出", "Always"), data = 1 },
        },
        default = 0.50,
    },
}
