local class = require "class"
local huPaiConfig = require "hupai_config"

MASK_VALUE = 0x0F
MASK_COLOR = 0xF0

CARD_DEFINE = {
	0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, -- 万
    0x11, 0x12, 0x13, 0x14, 0x15, 0x16, 0x17, 0x18, 0x19, -- 筒
    0x21, 0x22, 0x23, 0x24, 0x25, 0x26, 0x27, 0x28, 0x29, -- 条
    0x31, 0x32, 0x33, 0x34, 0x35, 0x36, 0x37,             -- 东南西北中发白
    0x41, 0x42, 0x43, 0x44, 0x45, 0x46, 0x47, 0x48,       -- 春夏秋冬梅兰竹菊
}

CARD_COLOR = {
	WAN  = 0,
	TONG = 1,
	TIAO = 2,
	ZI   = 3,
	HUA  = 4,
}


local MjLogic = class()
function MjLogic:_init()

end

function MjLogic:GetCardColor(card)
	return card & MASK_VALUE
end

function MjLogic:GetCardValue(card)
	return (card & MASK_COLOR) >> 4
end

function MjLogic:GetIndexColor(index)
	return math.ceil(index / 9) - 1
end

function MjLogic:GetIndexValue(index)
	return (index-1) % 9 + 1
end

function MjLogic:Index2Card(index)
	return (self:GetIndexColor(index) << 4) | self:GetIndexValue(index)
end

function MjLogic:Card2Index(card)
	return self:GetCardColor(card) * 9 + self:GetCardValue(card)
end

function MjLogic:IsChiColor(color)
	return color < CARD_COLOR.ZI
end

function MjLogic:CanPeng(indexMap, index)
	return indexMap[index] >= 2
end

function MjLogic:CanAnGang(indexMap, index)
	return indexMap[index] == 4
end

function MjLogic:CanMingGang(indexMap, index)
	return indexMap[index] == 3
end

function MjLogic:CanGongGang(indexMap, index)
	return indexMap[index] == 1
end

function MjLogic:_canChi(indexMap, index1, index2)
	if not indexMap[index1] or not indexMap[index2] then
		return false
	end

	if indexMap[index1] == 0 or indexMap[index2] == 0 then
		return false
	end

	local color1 = self:GetIndexColor(index1)
	local color2 = self:GetIndexColor(index2)

	if color1 ~= color2 then
		return false
	end

	return self:IsChiColor(index1)
end

function MjLogic:CanLeftChi(indexMap, index)
	return self:_canChi(indexMap, index+1, index+2)
end

function MjLogic:CanMiddleChi(indexMap, index)
	return self:_canChi(indexMap, index-1, index+1)
end

function MjLogic:CanRightChi(indexMap, index)
	return self:_canChi(indexMap, index-2, index-1)
end

return MjLogic