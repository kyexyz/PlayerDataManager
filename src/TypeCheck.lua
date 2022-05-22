local TypeCheck = {}

local PlayerDataManager

function TypeCheck:Value(key, value)
	if not PlayerDataManager then
		PlayerDataManager = require(script.Parent)
	end

	local Configuration = _G.PLAYERDATAMANAGER_CONFIGURATION

	for k, v in next, Configuration.DEFAULT_DATA do
		if k == key then
			if typeof(v) == "table" and v.type then
				if typeof(value) ~= v.type then
					print(typeof(value), value)
					if value == nil and v.optional then
						continue
					end
					error("Value of key " .. key .. " is not of type " .. v.type)
				end
			end
		end
	end
	return true
end

function TypeCheck:Data(data)
	for k, v in next, data do
		if typeof(v) == "table" and v.type then
			self:Value(k, v.value)
		end
	end
end

return TypeCheck
