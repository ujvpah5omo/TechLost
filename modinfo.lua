name = "全科技蓝图解锁"
description = [[
所有需要科技的配方初始只能通过蓝图解锁。玩家学习蓝图后可自行制作，也可把已掌握配方带进新建科技站。

角色死亡会丢失全部已学科技。每台科技站独立保存公开配方，其他玩家可通过该站制作并学会；全部受限配方都可从风滚草获得蓝图。
]]
author = "Codex"
version = "2.5.0"

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
