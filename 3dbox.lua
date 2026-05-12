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
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local BoxESP = {
    TeamCheck = true,
    SelfEsp = true
}

BoxESP.__index = BoxESP

local EDGES = {
	{1,2}, {2,3}, {3,4}, {4,1},
	{5,6}, {6,7}, {7,8}, {8,5},
	{1,5}, {2,6}, {3,7}, {4,8}
}

local function getCornersFromCF(cf, size)
	local h = size / 2

	return {
		(cf * CFrame.new(-h.X, -h.Y, -h.Z)).Position,
		(cf * CFrame.new( h.X, -h.Y, -h.Z)).Position,
		(cf * CFrame.new( h.X,  h.Y, -h.Z)).Position,
		(cf * CFrame.new(-h.X,  h.Y, -h.Z)).Position,

		(cf * CFrame.new(-h.X, -h.Y,  h.Z)).Position,
		(cf * CFrame.new( h.X, -h.Y,  h.Z)).Position,
		(cf * CFrame.new( h.X,  h.Y,  h.Z)).Position,
		(cf * CFrame.new(-h.X,  h.Y,  h.Z)).Position,
	}
end

local function project(worldPos)
	local v, visible = Camera:WorldToViewportPoint(worldPos)
	return Vector2.new(v.X, v.Y), visible, v.Z
end

function BoxESP:ShouldRender()
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

function BoxESP.new(target, Drawing, player)
	local self = setmetatable({}, BoxESP)

	self.Target = target
	self.Player = player
	self.Drawing = Drawing
	self.Color = Color3.fromRGB(255, 255, 255)
	self.Thickness = 1
	self.Enabled = false
	self.Connection = nil
	self.Lines = {}

	for i = 1, 12 do
		local line = Drawing.new("Line")
		line.Visible = false
		line.Color = self.Color
		line.Thickness = self.Thickness
		self.Lines[i] = line
	end

	return self
end

function BoxESP:SetColor(color)
	self.Color = color
	for _, line in ipairs(self.Lines) do
		line.Color = color
	end
end

function BoxESP:SetThickness(thickness)
	self.Thickness = thickness
	for _, line in ipairs(self.Lines) do
		line.Thickness = thickness
	end
end

function BoxESP:GetBounds()
	if not self.Target or not self.Target.Parent then
		return nil
	end

	if self.Target:IsA("Model") then
		return self.Target:GetBoundingBox()
	elseif self.Target:IsA("BasePart") then
		return self.Target.CFrame, self.Target.Size
	end

	return nil
end

function BoxESP:Hide()
	for _, line in ipairs(self.Lines) do
		line.Visible = false
	end
end

function BoxESP:Update()
	if not self:ShouldRender() then
		self:Hide()
		return
	end

	local cf, size = self:GetBounds()
	if not cf then
		self:Hide()
		return
	end

	local corners = getCornersFromCF(cf, size)
	local screenCorners = {}
	local anyVisible = false

	for i = 1, 8 do
		local pos2d, visible, depth = project(corners[i])
		screenCorners[i] = {
			pos = pos2d,
			visible = visible and depth > 0
		}
		if screenCorners[i].visible then
			anyVisible = true
		end
	end

	if not anyVisible then
		self:Hide()
		return
	end

	for i, edge in ipairs(EDGES) do
		local a = screenCorners[edge[1]]
		local b = screenCorners[edge[2]]
		local line = self.Lines[i]

		if a.visible and b.visible then
			line.From = a.pos
			line.To = b.pos
			line.Visible = true
		else
			line.Visible = false
		end
	end
end

function BoxESP:Start()
	if self.Connection then return end

	self.Enabled = true
	self.Connection = RunService.RenderStepped:Connect(function()
		if self.Enabled then
			self:Update()
		end
	end)
end

function BoxESP:Stop()
	self.Enabled = false
	self:Hide()

	if self.Connection then
		self.Connection:Disconnect()
		self.Connection = nil
	end
end

function BoxESP:Destroy()
	self:Stop()

	for _, line in ipairs(self.Lines) do
		line:Remove()
	end

	table.clear(self.Lines)
end

function BoxESP:SetTeamCheck(state)
	self.TeamCheck = state and true or false
end

function BoxESP:SetSelfESP(state)
	self.SelfEsp = state and true or false
end

return BoxESP
