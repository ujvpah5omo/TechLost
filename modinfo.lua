name = "全科技蓝图解锁"
description = [[
符合条件的普通科技配方初始只能通过蓝图解锁。原生稀有蓝图保留 Boss、任务及商店等专属获取途径。

角色死亡可配置为丢失全部已学科技。每台科技站独立保存公开配方；由本 Mod 新锁定的配方可从风滚草获得蓝图。
]]
author = "Codex"
version = "2.9.5"

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
        hover = "开启后，纯技能树配方会进入蓝图池；月亮/暗影线技能蓝图需要对应裂隙开启。技能树+科技站配方保留原版方式。",
        options =
        {
            { description = "关闭", data = false },
            { description = "开启", data = true },
        },
        default = false,
    },
    {
        name = "include_character_tag_recipes",
        label = "角色专属科技蓝图",
        hover = "开启后，非技能树且需要科技站的角色专属配方会进入蓝图池；只有对应角色能学习，禁用角色的配方不会进入蓝图池。",
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
