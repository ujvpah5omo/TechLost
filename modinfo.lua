name = "全科技蓝图解锁"
description = [[
所有需要科技的配方初始只能通过蓝图解锁。任意玩家学习蓝图后，该配方会向整个世界公开。

其他玩家随后可在原本对应的科技站制作；全部受限配方都可从风滚草获得蓝图。
]]
author = "Codex"
version = "2.1.2"

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
