local MjLogic = require "zzmj_logic"

local mjLogic = MjLogic("sandongmj_zzmj_config")


local indexMap = {
    1,1,1,1,4,1,0,0,0,
    0,0,1,1,1,0,0,0,0,
    0,0,0,0,0,0,0,0,0,
    0,0,2,0,3,0,0,0,0,
    0,0,0,0,0,0,0,0,0,
}
print(mjLogic:CanHuPai(indexMap))
