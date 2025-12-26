if getgenv().SKIBIDI_LOADED then return end
getgenv().SKIBIDI_LOADED = true

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Player = Players.LocalPlayer

-- ===== CONFIG =====
local SPEED_REQUIRE = 33
local JUMP_DELAY = 0.02
local RAY_DISTANCE = 3.2
local TOGGLE_KEY = Enum.KeyCode.Z

-- ===== STATE =====
local ENABLED = true
local canJump = true
local toggleCooldown = false

local keysHeld = {
	[Enum.KeyCode.W] = false,
	[Enum.KeyCode.A] = false,
	[Enum.KeyCode.D] = false,
}

-- ===== CHARACTER =====
local Character, Humanoid, Root

local function SetupCharacter(char)
	Character = char
	Humanoid = char:WaitForChild("Humanoid")
	Root = char:WaitForChild("HumanoidRootPart")
end

SetupCharacter(Player.Character or Player.CharacterAdded:Wait())
Player.CharacterAdded:Connect(SetupCharacter)

-- ===== GUI =====
local gui = Instance.new("ScreenGui")
gui.Name = "SkibidiJumpGUI"
gui.ResetOnSpawn = false
gui.Parent = Player:WaitForChild("PlayerGui")

local frame = Instance.new("Frame")
frame.Size = UDim2.fromOffset(170, 60)
frame.Position = UDim2.fromScale(0.05, 0.6)
frame.BackgroundColor3 = Color3.fromRGB(30,30,30)
frame.BorderSizePixel = 0
frame.Active = true
frame.Draggable = true
frame.Parent = gui

local button = Instance.new("TextButton")
button.Size = UDim2.fromScale(1,1)
button.Font = Enum.Font.GothamBold
button.TextScaled = true
button.TextColor3 = Color3.new(1,1,1)
button.Parent = frame

local function UpdateGUI()
	if ENABLED then
		button.Text = "SKIBIDI JUMP : ON"
		button.BackgroundColor3 = Color3.fromRGB(0,170,0)
	else
		button.Text = "SKIBIDI JUMP : OFF"
		button.BackgroundColor3 = Color3.fromRGB(170,0,0)
	end
end

local function Toggle()
	if toggleCooldown then return end
	toggleCooldown = true
	ENABLED = not ENABLED
	UpdateGUI()
	task.delay(0.25, function()
		toggleCooldown = false
	end)
end

UpdateGUI()
button.MouseButton1Click:Connect(Toggle)

-- ===== INPUT =====
UserInputService.InputBegan:Connect(function(input, gpe)
	if gpe then return end
	if input.KeyCode == TOGGLE_KEY then
		Toggle()
	end
	if keysHeld[input.KeyCode] ~= nil then
		keysHeld[input.KeyCode] = true
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if keysHeld[input.KeyCode] ~= nil then
		keysHeld[input.KeyCode] = false
	end
end)

local function IsAnyKeyHeld()
	for _,v in pairs(keysHeld) do
		if v then return true end
	end
	return false
end

-- ===== GROUND CHECK =====
local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Blacklist
rayParams.IgnoreWater = true

local function IsOnGround()
	if not Root then return false end
	rayParams.FilterDescendantsInstances = {Character}
	return Workspace:Raycast(
		Root.Position,
		Vector3.new(0,-RAY_DISTANCE,0),
		rayParams
	) ~= nil
end

-- ===== AUTO JUMP CORE (FIX JUMPPOWER EVADE) =====
RunService.Heartbeat:Connect(function()
	if not ENABLED then return end
	if not IsAnyKeyHeld() then return end
	if not Humanoid or Humanoid.Health <= 0 then return end
	if not Root then return end

	local speed = Root.AssemblyLinearVelocity.Magnitude
	if speed < SPEED_REQUIRE then
		canJump = true
		return
	end

	if IsOnGround() and canJump then
		canJump = false
		task.delay(JUMP_DELAY, function()
			if Humanoid and Humanoid.Health > 0 then
				Humanoid.Jump = true -- FIX: giữ JumpPower của Evade
			end
			canJump = true
		end)
	end
end)
