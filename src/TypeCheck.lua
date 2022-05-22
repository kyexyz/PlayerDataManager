local TypeCheck = {}

function TypeCheck:Value(key, value)
	local Configuration = _G.PLAYERDATAMANAGER_CONFIGURATION

	for k, v in next, Configuration.DEFAULT_DATA do
		if k == key then
			if typeof(v) == "table" and v.type then
				if typeof(value) ~= v.type then
					if not v.optional and value ~= nil then
						error("Value of key " .. key .. " is not of type " .. v.type)
					end
				end
			end
		end
	end
	return true
end

function TypeCheck:Data(data)
	for k, v in next, data do
		self:Value(k, v.value)
	end
end

return TypeCheck
