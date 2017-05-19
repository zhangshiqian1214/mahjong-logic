local class    = require "class"
local configDb = require "config_db"
-- require "utils"

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

CARD_COLOR_SPLIT = {
	[CARD_COLOR.WAN]  = {min = 1,  max = 9,  chi = true },
	[CARD_COLOR.TONG] = {min = 10, max = 18, chi = true },
	[CARD_COLOR.TIAO] = {min = 19, max = 27, chi = true },
	[CARD_COLOR.ZI]   = {min = 28, max = 34, chi = false},
	[CARD_COLOR.HUA]  = {min = 37, max = 44, chi = false},
}

local MjLogic = class()
function MjLogic:_init(configName)
	self._hupai_config = require(configName) -- configDb[configName]
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

function MjLogic:GetColorConfig(color)
	if color <= 3 then
		return CARD_COLOR_SPLIT[color]
	end
	return nil
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

--能否胡牌
function MjLogic:CanHuPai(indexMap, guiIndex)
	local tmpIndexMap = {
		0,0,0, 0,0,0, 0,0,0, --万
        0,0,0, 0,0,0, 0,0,0, --筒
        0,0,0, 0,0,0, 0,0,0, --条
        0,0,0, 0,0,0, 0,0,0, --东南西北中发白
        0,0,0, 0,0,0, 0,0,   --春夏秋冬梅兰竹菊
	}

	for i, v in pairs(indexMap) do
		tmpIndexMap[i] = v
	end
	local guiNum = 0
	if guiIndex then
		guiNum = tmpIndexMap[guiIndex]
		tmpIndexMap[guiIndex] = 0
	end

	--按花色切分
	local splitedResult = self:splitIndexMap(tmpIndexMap, guiNum)
	if not splitedResult then
		return false
	end
	
	--切分的结果效验
	return self:CheckProbability(splitedResult, guiNum)
end

--分割手牌
function MjLogic:splitIndexMap(indexMap, guiNum)
	local ret = {}
	for _, color in pairs(CARD_COLOR) do
		local config = self:GetColorConfig(color)
		repeat
			if not config then break end
			local key = 0
			local num = 0
			for i=config.min, config.max do
				key = key * 10 + indexMap[i]
				num = num + indexMap[i]
			end
			if num > 0 then
				local list = self:ListProbability(guiNum, num, key, config.chi)
				if #list == 0 then
					return false
				end
				table.insert(ret, list)
			end
		until(true)
	end
	return ret
end

--列出所有可能组合
function MjLogic:ListProbability(guiNum, cardNum, key, chi)
	local list = {}
	for i=0, guiNum do
		local remainder = (cardNum + i) % 3
		if remainder == 0 then
			if self:CompareConfigWithKey(key, i, false, chi) then
				table.insert(list, {eye = false, guiNum=i})
			end
		elseif remainder == 2 then
			if self:CompareConfigWithKey(key, i, true) then
				table.insert(list, {eye = true, guiNum=i})
			end
		end
	end
	return list
end

--对比配置表与手牌生成的key
function MjLogic:CompareConfigWithKey(key, guiNum, eye, chi)
	local config
	if chi then
		if eye then 
			config = self._hupai_config["check_eye_table"][guiNum]
		else
			config = self._hupai_config["check_table"][guiNum]
		end
	else
		if eye then	
			config = self._hupai_config["check_feng_eye_table"][guiNum]
		else
			config = self._hupai_config["check_feng_table"][guiNum]
		end
	end

	if config then
		return config[key]
	end
	return nil
end

--效验按花色切分出来的结果
function MjLogic:CheckProbability(splitedResult, guiNum)
	local count = #splitedResult
	--全是鬼牌
	if count == 0 then
		return true
	end

	if count == 1 then
		return true
	end

	for i, v in pairs(splitedResult[1]) do
		local info = {
			eye = v.eye,
			guiNum = guiNum - v.guiNum,
			count = count,
		}
		local ret = self:CheckProbabilitySub(splitedResult, info, 2)
		if ret then
			return true
		end
	end
	return false
end

--可能性子检查
function MjLogic:CheckProbabilitySub(splitedResult, info, level)
	for _, v in pairs(splitedResult[level]) do
		repeat
			if info.eye and v.eye then
				break
			end

			if info.guiNum < v.guiNum then
				break
			end

			if level < info.count then
				info.guiNum = info.guiNum - v.guiNum
				local oldEye = info.eye
				info.eye = oldEye or v.eye
				if self:CheckProbabilitySub(splitedResult, info, level + 1) then
					return true
				end
				info.eye = oldEye
				info.guiNum = info.guiNum + v.guiNum
				break
			end

			if not info.eye and not v.eye and info.guiNum < 2 then
				break
			end

			return true
		until(true)
	end
	return false
end

return MjLogic