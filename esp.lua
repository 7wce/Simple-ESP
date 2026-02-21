-- This does have some bugs so please contact me if you encounter one!!
-- Discord: 1ivt

local ESPModule = {}

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera

local settings = {
    BoxThickness = 2,
    BoxTransparency = 1,
    RainbowSpeed = 0.5,
    ShowNames = true,
    TeamEsp = true,
    SelfEsp = false
}

local playerBoxes = {}
local playerNames = {}
local playerBoxSizes = {}
local hue = 0
local enabled = false
local connection = nil

local function calculatePlayerSize(player)
    local character = player.Character
    if not character then return nil end
    
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local head = character:FindFirstChild("Head")
    local humanRootPart = character:FindFirstChild("HumanoidRootPart")
    
    if not (humanoid and head and humanRootPart) then return nil end

    local highestPoint = head.Position.Y + (head.Size.Y / 2)
    
    local lowestPoint = humanRootPart.Position.Y - (humanoid.HipHeight * 2)
    
    local leftFoot = character:FindFirstChild("LeftFoot")
    local rightFoot = character:FindFirstChild("RightFoot")
    local leftLowerLeg = character:FindFirstChild("LeftLowerLeg")
    local rightLowerLeg = character:FindFirstChild("RightLowerLeg")
    
    if leftFoot and rightFoot then
        lowestPoint = math.min(
            leftFoot.Position.Y - (leftFoot.Size.Y / 2),
            rightFoot.Position.Y - (rightFoot.Size.Y / 2)
        )
    elseif leftLowerLeg and rightLowerLeg then
        lowestPoint = math.min(
            leftLowerLeg.Position.Y - (leftLowerLeg.Size.Y / 2),
            rightLowerLeg.Position.Y - (rightLowerLeg.Size.Y / 2)
        )
    else
        lowestPoint = humanRootPart.Position.Y - (humanoid.HipHeight * 2.5)
    end
    
    local leftExtent = humanRootPart.Position.X - 1.5
    local rightExtent = humanRootPart.Position.X + 1.5
    
    local leftHand = character:FindFirstChild("LeftHand")
    local rightHand = character:FindFirstChild("RightHand")
    local leftUpperArm = character:FindFirstChild("LeftUpperArm")
    local rightUpperArm = character:FindFirstChild("RightUpperArm")
    
    if leftHand and rightHand then
        leftExtent = math.min(leftExtent, leftHand.Position.X - (leftHand.Size.X / 2))
        rightExtent = math.max(rightExtent, rightHand.Position.X + (rightHand.Size.X / 2))
    end
    
    if leftUpperArm and rightUpperArm then
        leftExtent = math.min(leftExtent, leftUpperArm.Position.X - (leftUpperArm.Size.X / 2))
        rightExtent = math.max(rightExtent, rightUpperArm.Position.X + (rightUpperArm.Size.X / 2))
    end
    
    local height = math.abs(highestPoint - lowestPoint)
    local width = math.abs(rightExtent - leftExtent)
    
    local padding = 10
    height = height + (padding * 2)
    width = width + (padding * 2)
    
    width = math.max(width, 30)
    height = math.max(height, 50)
    
    return {
        Width = width,
        Height = height,
        Padding = padding
    }
end

local function createESP(player)
    local box = Drawing.new("Square")
    box.Color = Color3.fromHSV(hue, 1, 1)
    box.Thickness = settings.BoxThickness
    box.Transparency = settings.BoxTransparency
    box.Visible = false
    box.ZIndex = 10

    local nameTag = Drawing.new("Text")
    nameTag.Color = Color3.fromHSV(hue, 1, 1)
    nameTag.Size = 13
    nameTag.Center = true
    nameTag.Outline = true
    nameTag.OutlineColor = Color3.new(0, 0, 0)
    nameTag.Visible = false
    nameTag.ZIndex = 10

    playerBoxes[player] = box
    playerNames[player] = nameTag
    
    if player.Character then
        local size = calculatePlayerSize(player)
        if size then
            playerBoxSizes[player] = size
        end
    end
end

local function removeESP(player)
    if playerBoxes[player] then
        playerBoxes[player]:Remove()
        playerBoxes[player] = nil
    end
    if playerNames[player] then
        playerNames[player]:Remove()
        playerNames[player] = nil
    end
    playerBoxSizes[player] = nil
end

local function hideAllESP()
    for player, box in pairs(playerBoxes) do
        if box then
            box.Visible = false
        end
    end
    for player, nameTag in pairs(playerNames) do
        if nameTag then
            nameTag.Visible = false
        end
    end
end

local function updateESP()
    if not enabled then return end
    
    hue = (hue + settings.RainbowSpeed * task.wait()) % 1
    local currentColor = Color3.fromHSV(hue, 1, 1)
    
    for _, player in pairs(Players:GetPlayers()) do
        local character = player.Character
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        local box = playerBoxes[player]
        local nameTag = playerNames[player]

        if settings.TeamEsp == false then
            if player.Team == LocalPlayer.Team then
                box.Visible = false
                nameTag.Visible = false
                continue
            end
        end

        if settings.SelfEsp == false then
            if player == LocalPlayer then
                box.Visible = false
                nameTag.Visible = false
                continue
            end
        end

        if box then
            box.Color = currentColor
        end

        if nameTag then
            nameTag.Color = currentColor
        end

        if character and humanoid and humanoid.Health > 0 and box and nameTag then
            local head = character:FindFirstChild("Head")
            local humanRootPart = character:FindFirstChild("HumanoidRootPart")

            if head and humanRootPart then
                local lowestPart = humanRootPart
                local lowestPosition = lowestPart.Position.Y
                
                local leftFoot = character:FindFirstChild("LeftFoot")
                local rightFoot = character:FindFirstChild("RightFoot")
                
                if leftFoot and rightFoot then
                    lowestPosition = math.min(leftFoot.Position.Y, rightFoot.Position.Y)
                else
                    lowestPosition = humanRootPart.Position.Y - 5
                end
                
                local headPos, onScreenHead = Camera:WorldToViewportPoint(head.Position)
                local feetPos = Vector3.new(humanRootPart.Position.X, lowestPosition, humanRootPart.Position.Z)
                local feetPos2D, onScreenFeet = Camera:WorldToViewportPoint(feetPos)

                if onScreenHead and onScreenFeet then
                    local boxTop = headPos.Y
                    local boxBottom = feetPos2D.Y
                    local height = math.abs(boxBottom - boxTop)
                    local width = height * 0.6

                    local rootPos2D, _ = Camera:WorldToViewportPoint(humanRootPart.Position)
                    local boxX = rootPos2D.X
                    local boxY = boxTop

                    box.Size = Vector2.new(width, height)
                    box.Position = Vector2.new(boxX - width / 2, boxY)
                    box.Visible = true

                    if settings.ShowNames then
                        nameTag.Text = player.Name
                        nameTag.Position = Vector2.new(boxX, boxTop - 20)
                        nameTag.Visible = true
                    else
                        nameTag.Visible = false
                    end
                else
                    box.Visible = false
                    nameTag.Visible = false
                end
            else
                box.Visible = false
                nameTag.Visible = false
            end
        else
            if box then box.Visible = false end
            if nameTag then nameTag.Visible = false end
        end
    end
end

local function recalculateSize(player)
    if player and player.Character then
        playerBoxSizes[player] = calculatePlayerSize(player)
    end
end

local function setupESP()
    for _, player in pairs(Players:GetPlayers()) do
        createESP(player)
    end

    Players.PlayerAdded:Connect(createESP)
    Players.PlayerRemoving:Connect(removeESP)

    for _, player in pairs(Players:GetPlayers()) do
        player.CharacterAdded:Connect(function()
            task.wait(0.5)
            recalculateSize(player)
        end)
    end

    Players.PlayerAdded:Connect(function(player)
        player.CharacterAdded:Connect(function()
            task.wait(0.5)
            recalculateSize(player)
        end)
    end)
end

function ESPModule:espToggle(state)
    state = state or false
    
    if state == enabled then
        return
    end
    
    enabled = state
    
    if enabled then
        if not connection then
            setupESP()
            connection = RunService.RenderStepped:Connect(updateESP)
        end
    else
        hideAllESP()
    end
end

function ESPModule:updateSettings(newSettings, value)
    settings[newSettings] = value
end

function ESPModule:getSettings()
    return settings
end

function ESPModule:isEnabled()
    return enabled
end

function ESPModule:refreshAllSizes()
    for _, player in pairs(Players:GetPlayers()) do
        recalculateSize(player)
    end
end

function ESPModule:cleanup()
    if connection then
        connection:Disconnect()
        connection = nil
    end
    
    for player, box in pairs(playerBoxes) do
        if box then
            box:Remove()
        end
    end
    for player, nameTag in pairs(playerNames) do
        if nameTag then
            nameTag:Remove()
        end
    end
    
    playerBoxes = {}
    playerNames = {}
    playerBoxSizes = {}
    enabled = false
end

ESPModule:espToggle(true)

return ESPModule
