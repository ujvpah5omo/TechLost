name = "全科技蓝图解锁"
description = [[
符合条件的普通科技配方初始只能通过蓝图解锁。原生稀有蓝图保留 Boss、任务及商店等专属获取途径。

角色死亡可配置为丢失全部已学科技。每台科技站独立保存公开配方；由本 Mod 新锁定的普通配方可从风滚草和海盗猴获得蓝图。角色相关蓝图不进入普通蓝图池，沉底宝箱会按开启者角色筛选角色相关奖励，海盗宝藏会按挖开者角色筛选角色相关奖励。技能树可配置为需要技能许可点才能点亮节点；技能许可点蓝图不进入普通蓝图池，只由海盗猴首领大副按击杀者角色掉落，且不会回退为其他角色许可。月后影后模式下，可提前获得许可点但双裂隙开启前不能点亮技能，节点自身月亮/暗影裂隙条件仍保留。未使用许可点在换角色时会重置，点亮技能消耗的许可点不会返还。本 Mod 蓝图池生成的地面蓝图可配置为经过数次下雨后消失。
]]
author = "Codex"
version = "2.10.10"

api_version = 10
dst_compatible = true
dont_starve_compatible = false
reign_of_giants_compatible = false
shipwrecked_compatible = false

all_clients_require_mod = true
client_only_mod = false
server_only_mod = false

configuration_options =
{
    {
        name = "include_skill_tree_recipes",
        label = "技能树配方蓝图",
        hover = "开启后，纯技能树配方会进入高级蓝图池；沉底宝箱按开启者角色筛选，海盗宝藏按挖开者角色筛选，月亮/暗影线技能蓝图需要对应裂隙开启。技能树+科技站配方保留原版方式。",
        options =
        {
            { description = "关闭", data = false },
            { description = "开启", data = true },
        },
        default = false,
    },
    {
        name = "include_skill_tree_node_blueprints",
        label = "技能树许可蓝图",
        hover = "开启后，技能树节点需要消耗技能许可点，再按原版技能点和前置条件手动点亮；许可点蓝图不进入普通蓝图池，只由海盗猴首领大副按击杀者角色掉落，不回退其他角色，可重复掉落保存。月后影后模式下，可提前获得许可点但双裂隙前不能点亮。换角色会重置未使用许可点，点亮消耗不返还。",
        options =
        {
            { description = "关闭", data = false },
            { description = "开启", data = "enabled" },
            { description = "月后影后", data = "after_both_rifts" },
        },
        default = false,
    },
    {
        name = "include_character_tag_recipes",
        label = "角色专属科技蓝图",
        hover = "开启后，非技能树且需要科技站的角色专属配方会进入高级蓝图池；沉底宝箱按开启者角色筛选，海盗宝藏按挖开者角色筛选。只有对应角色能学习，禁用角色的配方不会进入蓝图池。",
        options =
        {
            { description = "关闭", data = false },
            { description = "开启", data = true },
        },
        default = false,
    },
    {
        name = "include_ancient_tech",
        label = "远古塔科技蓝图",
        hover = "开启后，远古伪科学站配方会进入蓝图池；学习蓝图后仍需靠近对应远古塔制作。关闭时保留原版方式。",
        options =
        {
            { description = "关闭", data = false },
            { description = "开启", data = true },
        },
        default = false,
    },
    {
        name = "include_lunar_forge_tech",
        label = "辉煌铁匠铺科技蓝图",
        hover = "开启后，月亮裂隙开启后辉煌铁匠铺配方才会进入蓝图池；学习蓝图后仍需靠近辉煌铁匠铺制作。",
        options =
        {
            { description = "关闭", data = false },
            { description = "开启", data = true },
        },
        default = false,
    },
    {
        name = "include_shadow_forge_tech",
        label = "暗影操纵基座科技蓝图",
        hover = "开启后，暗影裂隙开启后暗影操纵基座配方才会进入蓝图池；学习蓝图后仍需靠近暗影操纵基座制作。",
        options =
        {
            { description = "关闭", data = false },
            { description = "开启", data = true },
        },
        default = false,
    },
    {
        name = "sunken_treasure_advanced_blueprints",
        label = "沉底宝箱高级蓝图",
        hover = "开启后，沉底宝箱会在首次打开时按类型和奖励内容额外产出高级科技蓝图；角色相关奖励按开启者角色筛选，稀有箱稳定给图，普通箱按概率给图。",
        options =
        {
            { description = "关闭", data = 0 },
            { description = "保守 10%", data = 0.10 },
            { description = "推荐 20%", data = 0.20 },
            { description = "慷慨 30%", data = 0.30 },
        },
        default = 0,
    },
    {
        name = "pirate_treasure_advanced_blueprints",
        label = "海盗宝藏高级蓝图",
        hover = "开启后，含沉底宝箱内容的海盗宝藏必定额外给 1 张高级蓝图；普通海盗宝藏按配置概率给图。角色相关奖励按挖开者角色筛选。",
        options =
        {
            { description = "关闭", data = 0 },
            { description = "保守 10%", data = 0.10 },
            { description = "推荐 20%", data = 0.20 },
            { description = "慷慨 30%", data = 0.30 },
        },
        default = 0,
    },
    {
        name = "lose_tech_on_death",
        label = "死亡丢失科技",
        hover = "开启后，角色死亡会清空全部已学习配方；科技站公开进度不受影响。",
        options =
        {
            { description = "开启", data = true },
            { description = "关闭", data = false },
        },
        default = false,
    },
    {
        name = "include_powder_monkey_blueprints",
        label = "海盗猴蓝图掉落",
        hover = "开启后，普通海盗猴死亡时会按风滚草蓝图概率掉落普通蓝图池的蓝图，不包含角色相关奖励和技能许可蓝图。",
        options =
        {
            { description = "开启", data = true },
            { description = "关闭", data = false },
        },
        default = true,
    },
    {
        name = "ground_blueprint_rain_washes",
        label = "地面蓝图雨水冲刷",
        hover = "本 Mod 蓝图池生成的蓝图丢在地上时，每次开始下雨计数一次；达到次数后消失。放进背包或箱子会暂停计数，原生蓝图不受影响。",
        options =
        {
            { description = "关闭", data = 0 },
            { description = "1 次雨", data = 1 },
            { description = "2 次雨", data = 2 },
            { description = "3 次雨", data = 3 },
            { description = "5 次雨", data = 5 },
        },
        default = 3,
    },
    {
        name = "tumbleweed_blueprint_chance",
        label = "风滚草蓝图概率",
        hover = "每株风滚草额外掉落一张受限科技蓝图的概率。",
        options =
        {
            { description = "1%", data = 0.01 },
            { description = "2%", data = 0.02 },
            { description = "5%", data = 0.05 },
            { description = "10%", data = 0.10 },
            { description = "20%", data = 0.20 },
            { description = "50%", data = 0.50 },
            { description = "必出", data = 1 },
        },
        default = 0.05,
    },
}
