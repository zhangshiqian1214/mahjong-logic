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
	self.config = {}
	self.config.weave_base     = {}
	self.config.weave_eye_base = {}

	--万筒条的鬼表
	self.config.weave_0_gui          = {} --无鬼
	self.config.weave_1_gui          = {} --一鬼
	self.config.weave_2_gui          = {} --二鬼
	self.config.weave_3_gui          = {} --三鬼
	self.config.weave_4_gui          = {} --四鬼

	--带将的万筒条鬼表
	self.config.weave_0_gui_eye      = {} --带眼牌无鬼
	self.config.weave_1_gui_eye      = {} --带眼牌一鬼
	self.config.weave_2_gui_eye      = {} --带眼牌二鬼
	self.config.weave_3_gui_eye      = {} --带眼牌三鬼
	self.config.weave_4_gui_eye      = {} --带眼牌四鬼

	--风字牌的鬼表
	self.config.weave_0_gui_feng     = {} --不带鬼的风牌
	self.config.weave_1_gui_feng     = {} --带一鬼的风牌
	self.config.weave_2_gui_feng     = {} --带二鬼的风牌
	self.config.weave_3_gui_feng     = {} --带三鬼的风牌
	self.config.weave_4_gui_feng     = {} --带四鬼的风牌

	--风字牌的鬼眼表
	self.config.weave_0_gui_feng_eye = {} --不带鬼的风牌
	self.config.weave_1_gui_feng_eye = {} --带一鬼的风牌
	self.config.weave_2_gui_feng_eye = {} --带二鬼的风牌
	self.config.weave_3_gui_feng_eye = {} --带三鬼的风牌
	self.config.weave_4_gui_feng_eye = {} --带四鬼的风牌

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
		--检查万筒条
		if config.chi and not self:CheckNumColor(tmpIndexMap, config, firstInfo) then
			return false
		--检查字牌
		elseif not config.chi and not self:CheckZiColor(tmpIndexMap, config, firstInfo) then
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
			end
			
			if count == 0 or i == config.max then
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

function HupaiGen:CalcCountListKey(countList)
	local key = 0
	for _, c in pairs(countList) do
		key = key * 10 + c
	end
	return key
end

function HupaiGen:CheckWeave(countList)
	local key = self:CalcCountListKey(countList)
	if self.config.weave_base[key] then
		return true
	end

	self.config.weave_base[key] = 1
	return true
end

function HupaiGen:CheckWeaveWithEye(countList)
	if #countList == 1 then
		return true
	end

	local key = self:CalcCountListKey(countList)
	if self.config.weave_eye_base[key] then
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

--生成基础的组合配置
function HupaiGen:GenWeaveBase()
	local testedKeyMap = {}
	
	local function calcIndexMapKey(indexMap)
		local key = 0
		for i=1, 9 do
			key = key * 10 + indexMap[i]
		end
		return key
	end

	local function checkHuPai(indexMap)
		for i=1, 18 do
			if indexMap[i] > 4 then
				return
			end
		end

		local key = calcIndexMapKey(indexMap)
		if testedKeyMap[key] then
			return
		end
		testedKeyMap[key] = true
		if not self:CanHuPai(indexMap) then
			print("测试失败")
		end
	end
	
	local function checkHuPaiSub(indexMap, num)
		for i=1, 32 do
			local index = nil
			if i <= 18 then
				indexMap[i] = indexMap[i] + 3
			elseif i <= 25 then
				index = i - 18
			else
				index = i - 16
			end
			if index then
				indexMap[index] = indexMap[index] + 1
				indexMap[index+1] = indexMap[index+1] + 1
				indexMap[index+2] = indexMap[index+2] +1
			end

			if num == 4 then
				checkHuPai(indexMap)
			else
				checkHuPaiSub(indexMap, num+1)
			end

			if i <= 18 then
				indexMap[i] = indexMap[i] - 3
			else
				indexMap[index] = indexMap[index] - 1
				indexMap[index+1] = indexMap[index+1] - 1
				indexMap[index+2] = indexMap[index+2] -1
			end
		end
	end

	local tmp = {
		0,0,0, 0,0,0, 0,0,0, --万
        0,0,0, 0,0,0, 0,0,0, --筒
        0,0,0, 0,0,0, 0,0,0, --条
        0,0,0, 0,0,0, 0,0,0, --东南西北中发白
        0,0,0, 0,0,0, 0,0,   --春夏秋冬梅兰竹菊
	}
	checkHuPaiSub(tmp, 1)
end

--生成带眼牌的组合配置
function HupaiGen:GenWeaveEyeBase()

	local function clone(object)
		local lookup_table = {}
	    local function _copy(object)
	        if type(object) ~= "table" then
	            return object
	        elseif lookup_table[object] then
	            return lookup_table[object]
	        end
	        local new_table = {}
	        lookup_table[object] = new_table
	        for key, value in pairs(object) do
	            new_table[_copy(key)] = _copy(value)
	        end
	        return setmetatable(new_table, getmetatable(object))
	    end
	    return _copy(object)
	end

	local function addWeave(indexMap)
		local key = 0
		for i,v in pairs(indexMap) do
			key = key * 10 + v
		end
		self.config.weave_eye_base[key] = 1
	end

	local function key2IndexMap(key)
		local t = {}
		while key > 0 do
			local remainder = key % 10
			key = math.floor(key / 10)
			table.insert(t, 1, remainder)
		end
		return t
	end

	for key, _ in pairs(self.config.weave_base) do
		local t = key2IndexMap(key)
		if #t < 9 then
			local tmp = clone(t)
			table.insert(tmp, 1, 2)
			addWeave(tmp)

			tmp = clone(t)
			table.insert(tmp, 2)
			addWeave(tmp)
		end

		for i, v in pairs(t) do
			if v <= 2 then
				local tmp = clone(t)
				tmp[i] = v + 2
				addWeave(tmp)
			end
		end
	end
end

--生成不带鬼的牌
function HupaiGen:GenWeave0Gui()
	local testedKeyMap = {}
	local function addWeave(indexMap)

	end

	local function parseIndexMap(indexMap)
		local count = 0
		for i=1, 9 do
			count = count + indexMap[i]
		end

		local eye = false
		if count % 3 ~= 0 then
			eye = true
		end

		if not eye then
			addWeave(indexMap)
		else
			
		end
	end

	local function checkHuPai(indexMap)
		for i=1, 34 do
			if indexMap[i] > 4 then
				return
			end
		end
		local key = 0
		for i=1, 18 do
			key = key * 10 + indexMap[i]
		end
		if testedKeyMap[key] then
			return
		end
		testedKeyMap[key] = true
		if self:CanHuPai(indexMap) then

		end
	end
end

--生成不带鬼带眼的牌
function HupaiGen:GenWeave0GuiEye()

end

--生成胡牌配置
function HupaiGen:GenHuPaiConfig(filename)
	self:GenWeaveBase()
	self:GenWeaveEyeBase()
	

end

local huPaiGen = HupaiGen()
local indexMap = {
    1,1,1,1,4,1,0,0,1,
    0,0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0,0,
  }
print(huPaiGen:CanHuPai(indexMap))



huPaiGen:GenHuPaiConfig()
local count = 0
for _, v in pairs(huPaiGen.config.weave_base) do
	count = count + 1
end
print("count=", count)

local eyeCount = 0
for _, v in pairs(huPaiGen.config.weave_eye_base) do
    eyeCount = eyeCount + 1
end
print("eyeCount=", eyeCount)


return HupaiGen

