local function clone(s)
    local fn = cloneref
    if fn then
        return fn(game:GetService(s))
    else
        return game:GetService(s)
    end
end

local RunService = clone("RunService")
local Players = clone("Players")
local Camera = workspace.CurrentCamera

local Skeletons = {}

local skelHidden = false

local SkeletonESP = {
    TeamCheck = true,
    SelfEsp = true
}

SkeletonESP.__index = SkeletonESP

local R15_CONNECTIONS = {
	{"Head", "UpperTorso"},
	{"UpperTorso", "LeftUpperArm"},
	{"LeftUpperArm", "LeftLowerArm"},
	{"LeftLowerArm", "LeftHand"},
	{"UpperTorso", "RightUpperArm"},
	{"RightUpperArm", "RightLowerArm"},
	{"RightLowerArm", "RightHand"},
	{"UpperTorso", "LowerTorso"},
	{"LowerTorso", "LeftUpperLeg"},
	{"LeftUpperLeg", "LeftLowerLeg"},
	{"LeftLowerLeg", "LeftFoot"},
	{"LowerTorso", "RightUpperLeg"},
	{"RightUpperLeg", "RightLowerLeg"},
	{"RightLowerLeg", "RightFoot"},
}

local R6_CONNECTIONS = {
	{"Head", "Torso"},
	{"Torso", "Left Arm"},
	{"Torso", "Right Arm"},
	{"Torso", "Left Leg"},
	{"Torso", "Right Leg"},
}

local function createSkeletonForPlayer(player)
	local char = player.Character
	if not char then return end

	local skel = SkeletonESP.new(player, char, Drawing)
	Skeletons[player] = skel
end

function SkeletonESP.new(player, character, Drawing)
	local self = setmetatable({}, SkeletonESP)

	self.Player = player
	self.Character = character
	self.Drawing = Drawing
	self.Lines = {}
	self.Connection = nil
	self.Color = Color3.fromRGB(255,255,255)
	self.Thickness = 1

	self.TeamCheck = true
	self.SelfEsp = true

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	self.IsR15 = humanoid and humanoid.RigType == Enum.HumanoidRigType.R15
	self.Connections = self.IsR15 and R15_CONNECTIONS or R6_CONNECTIONS

	for i = 1, #self.Connections do
		local line = Drawing.new("Line")
		line.Color = self.Color
		line.Thickness = self.Thickness
		line.Visible = false
		self.Lines[i] = line
	end

	return self
end

function SkeletonESP:ShouldRender()
	local Players = game:GetService("Players")
	local LocalPlayer = Players.LocalPlayer

	if not self.Player then
		return true
	end

	if not self.SelfEsp and self.Player == LocalPlayer then
		return false
	end

	if self.TeamCheck then
		if LocalPlayer.Team and self.Player.Team then
			if LocalPlayer.Team == self.Player.Team then
				return false
			end
		end
	end

	return true
end

function SkeletonESP:Project(pos)
	local v, onScreen = Camera:WorldToViewportPoint(pos)
	return Vector2.new(v.X, v.Y), onScreen, v.Z
end

function SkeletonESP:Update()
	if not self.Character or not self.Character.Parent then
		return
	end

	if not self:ShouldRender() then
		for _, line in ipairs(self.Lines) do
			line.Visible = false
		end
		return
	end

	for i, pair in ipairs(self.Connections) do
		local partA = self.Character:FindFirstChild(pair[1])
		local partB = self.Character:FindFirstChild(pair[2])
		local line = self.Lines[i]

		if partA and partB then
			local posA, visA = self:Project(partA.Position)
			local posB, visB = self:Project(partB.Position)

            if skelHidden then
                line.Visible = false
            end

			if visA and visB then
				line.From = posA
				line.To = posB
				line.Visible = true
			else
				line.Visible = false
			end
		else
			line.Visible = false
		end
	end
end

function SkeletonESP:Start()
	local Players = game:GetService("Players")

	for _, player in ipairs(Players:GetPlayers()) do
		createSkeletonForPlayer(player)
	end

	Players.PlayerAdded:Connect(function(player)
		player.CharacterAdded:Connect(function(char)
			task.wait(0.5)
			createSkeletonForPlayer(player)
		end)
	end)

	RunService.RenderStepped:Connect(function()
		for _, skel in pairs(Skeletons) do
			skel:Update()
		end
	end)
end

function SkeletonESP:Stop()
	for _, skel in pairs(Skeletons) do
		skel:Destroy()
	end
	table.clear(Skeletons)
end

function SkeletonESP:Destroy()
	if self.Connection then
		self.Connection:Disconnect()
	end

	for _, line in ipairs(self.Lines) do
		line:Remove()
	end
end

return SkeletonESP
