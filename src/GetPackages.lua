local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = script.Parent.Parent

if Packages.Name ~= "Packages" then
	Packages = ReplicatedStorage:WaitForChild("Packages")
end

return function()
	return Packages
end
