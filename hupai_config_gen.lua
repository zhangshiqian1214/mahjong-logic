local class   = require "class"

CARD_COLOR = {
	WAN  = 0,
	TONG = 1,
	TIAO = 2,
	ZI   = 3,
	HUA  = 4,
}

local HupaiGen = class()
function HupaiGen:_init()
	--基础的刻子表
	self._weave_config       = {}
	self._weave_eye_config   = {}

	--鬼表
	self._no_gui_config      = {}
	self._one_gui_config     = {}
	self._two_gui_config     = {}
	self._three_gui_config   = {}
	self._four_gui_config    = {}

	--带将的鬼表
	self._no_gui_eye_config   = {}
	self._one_gui_eye_config  = {}
	self._two_gui_eye_config  = {}
	self._four_gui_eye_config = {} 
end

function HupaiGen:IsChiColor(color)
	return color < CARD_COLOR.ZI
end

function HupaiGen:GetColorConfig(color)
	if color < 3 then
		return { min = color*9+1, max = (color+1)*9, chi = true }
	elseif color == 3 then
		return { min = 28, max = 34, chi = false}
	else
		return { min = 37, max = 44, chi = false}
	end
end

function HupaiGen:CanHuPai(indexMap)
	local tmpIndexMap = {}
	for i, v in pairs(indexMap) do
		tmpIndexMap[i] = v
	end
	local firstInfo = {
		eye = false,
		duiArray = {},
	}
	for _, color in pairs(CARD_COLOR) do
		local config = self:GetColorConfig(color)
		--检查字牌花色
		if config.chi and not self:CheckNumColor(tmpIndexMap, config, firstInfo) then
			return false
		elseif not config.chi and not self:CheckZiColor(tmpIndexMap, config, info) then
			return false
		end
	end
	return true
end

--检查字牌
function HupaiGen:CheckZiColor(indexMap, config, info)
	for index = config.min, config.max do
		local count = indexMap[index]
		if count == 1 or count == 4 then
			return false
		end

		if count == 2 then
			if info.eye then
				return false
			end
			info.eye = true
		end
	end
	return true
end

--检查序数牌
function HupaiGen:CheckNumColor(indexMap, config, info)
	local countList = {}
	for i = config.min, config.max do
		repeat
			--连续的效验，不连续的返回
			local count = indexMap[i]
			if count > 0 then
				table.insert(countList, count)
			else
				if #countList == 0 then
					break
				end
				if not self:CheckSub(countList, info) then
					return false
				end
				countList = {}
			end
		until(true)
	end

	return true
end

function HupaiGen:CheckSub(countList, info)
	local sum = 0
	for _, v in pairs(countList) do
		sum = sum + v
	end
	local remainder = sum % 3
	if remainder == 1 then
		return false
	elseif remainder == 2 then
		if info.eye then
			return false
		end
		return self:CheckWeaveWithEye(countList)
	end
	return self:CheckWeave(countList)
end

function HupaiGen:CalcWeaveKey(countList)
	local key = 0
	for _, c in pairs(countList) do
		key = key * 10 + c
	end
	return key
end

function HupaiGen:CheckWeave(countList)
	local key = self:CalcWeaveKey(countList)
	if self._weave_config[key] then
		return true
	end
	--self._weave_config[key] = true
	return false
end

function HupaiGen:CheckWeaveWithEye(countList)
	if #countList == 1 then
		return true
	end

	local key = self:CalcWeaveKey(countList)
	if self._weave_eye_config[key] then
		return true
	end

	local len = #countList
	for i, v in pairs(countList) do
		repeat
			if v < 2 then
				break
			end

			local tmpCountList1 = {}
			local tmpCountList2 = {}
			for ii, vv in pairs(countList) do
				table.insert(tmpCountList1, vv)
			end

			if v > 2 then
				tmpCountList1[i] = v - 2
			else
				if i == 1 then
					table.remove(tmpCountList1, 1)
				elseif i == len then
					table.remove(tmpCountList1)
				else
					for ii = i + 1, len do
						table.insert(tmpCountList2, countList[ii])
					end
					tmpCountList1[i] = nil
				end
			end

			if not self:CheckWeave(tmpCountList1) then
				break
			end

			if next(tmpCountList2) then
				if not self:CheckWeave(tmpCountList2) then
					break
				end
			end
			return true
		until(true)
	end

	return false
end

function HupaiGen:GenHuPaiConfig()

end

local huPaiGen = HupaiGen()
local indexMap = {
    1,1,4,1,1,1,0,0,0,
    0,0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0,0,
  }
print(huPaiGen:CanHuPai(indexMap))

return HupaiGen

