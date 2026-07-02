name = "全科技蓝图解锁"
description = [[
所有需要科技的配方初始只能通过蓝图解锁。玩家学习蓝图后可自行制作，也可把已掌握配方带进新建科技站。

角色死亡可配置为丢失全部已学科技。每台科技站独立保存公开配方，其他玩家可通过该站制作并学会；全部受限配方都可从风滚草获得蓝图。
]]
author = "Codex"
version = "2.7.0"

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
        hover = "开启后，辉煌铁匠铺配方会进入蓝图池；学习蓝图后仍需靠近辉煌铁匠铺制作。",
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
        hover = "开启后，暗影操纵基座配方会进入蓝图池；学习蓝图后仍需靠近暗影操纵基座制作。",
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
