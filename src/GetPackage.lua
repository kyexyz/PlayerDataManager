local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = script.Parent.Parent

if Packages.Name ~= "Packages" then
	Packages = ReplicatedStorage:WaitForChild("Packages")
end

return function(packageName: string)
	local package = (Packages:FindFirstChild(packageName))

	if package then
		return package
	else
		package = script.Parent.Parent:FindFirstChild(packageName)
		return package
	end
end
