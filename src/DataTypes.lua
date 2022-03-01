local dataTypes = {}

local function serializedValue(type, value)
   return {
      _serialized_type = type,
      value = value,
   }
end

local function parseValueForDeserialization(value)
   if typeof(value) ~= "table" then return end 
   if not value._serialized_type then return end   
   
   return value.value
end

dataTypes = {
   ["Color3"] = {
      serialize = function(value: Color3)
         return serializedValue("Color3", {value:ToHSV()})
      end,
      deserialize = function(value)
         value = parseValueForDeserialization(value)

         return Color3.fromHSV(unpack(value))
      end,
   },
   ["BrickColor"] = {
      serialize = function(value: BrickColor)
         return serializedValue("BrickColor", tostring(value))
      end,
      deserialize = function(value)
         value = parseValueForDeserialization(value)

         return BrickColor.new(value)
      end,
   },
   ["Vector3"] = {
      serialize = function(value: Vector3)
         return serializedValue("Vector3", {value.X, value.Y, value.Z})
      end,
      deserialize = function(value)
         value = parseValueForDeserialization(value)

         return Vector3.new(value.X, value.Y, value.Z)
      end,
   },
   ["Vector2"] = {
      serialize = function(value: Vector2)
         return serializedValue("Vector2", {value.X, value.Y})
      end,
      deserialize = function(value)
         value = parseValueForDeserialization(value)

         return Vector2.new(value.X, value.Y)
      end,
   },
   ["CFrame"] = {
      serialize = function(value: CFrame)
         return serializedValue("CFrame", {
            pos = dataTypes.Vector3.serialize(value.Position),
            rX = dataTypes.Vector3.serialize(value.RightVector),
            rY = dataTypes.Vector3.serialize(value.UpVector),
            rZ = dataTypes.Vector3.serialize(-value.LookVector),
         })
      end,
      deserialize = function(value)
         value = parseValueForDeserialization(value)

         return CFrame.fromMatrix(
            dataTypes.Vector3.deserialize(value.pos),
            dataTypes.Vector3.deserialize(value.rX),
            dataTypes.Vector3.deserialize(value.rY),
            dataTypes.Vector3.deserialize(value.rZ)
         )
      end,
   },
   ["EnumItem"] = {
      serialize = function(value: Enum)
         local s = string.split(tostring(value), ".")
         
         return serializedValue("EnumItem", {s[2], s[3]})
      end,
      deserialize = function(value)
         value = parseValueForDeserialization(value)

         return Enum[value[1]][value[2]]
      end,
   }
}

return dataTypes