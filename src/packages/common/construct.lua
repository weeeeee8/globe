local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")

local env = assert(getgenv, "[GLOBE] getgenv cannot be found, executor might not be supported")()

local Maid = import('lib/maid')
local Subscription = import('lib/subscription')

local ALL_FACES = Faces.new(Enum.NormalId.Front, Enum.NormalId.Back, Enum.NormalId.Left, Enum.NormalId.Right, Enum.NormalId.Top, Enum.NormalId.Bottom)

local function project()
    local pos = UserInputService.GetMouseLocation(UserInputService)
    local ray = workspace.CurrentCamera.ViewportPointToRay(workspace.CurrentCamera, pos.X, pos.Y)
    return ray
end

local function getMouseWorldPosition()
    local ray = project()
    local result = workspace.Raycast(workspace, ray.Origin, ray.Direction * 2000)
    return if result then result.Position else ray.Origin + (ray.Direction * 2000)
end

local function getMouseHit()
    local ray = project()
    local result = workspace.Raycast(workspace, ray.Origin, ray.Direction * 2000)
    return if result then result.Instance else nil
end

local function snap(n, snapFactor)
    return math.clamp(math.floor(n / snapFactor) * snapFactor, 0, math.huge)
end

local construct = {}
construct.__index = construct

function construct.newTool()
    local self = setmetatable({
        maid = Maid.new(),
        simulationMaid = Maid.new(),
        prefix = "!cpart",
        partindex = 0,
        active = false,
        activelySimulating = false,

        moveScale = 1,--per stud
        sizeScale = 1,--per stud
        rotationScale = 45,--to be converted to radians

        states = {},
    }, construct)

    self.maid:GiveTask(self.simulationMaid)
    self.states.handleType = Subscription.new("move", self.maid)

    self.maid:GiveTask(Players.LocalPlayer.Chatted:Connect(function(msg: string?)
        if #msg > 0 then return end
        if msg:lower() == self.prefix then
            if not self.active then return end
            local part = Instance.new("Part")
            part.Name = "clientpart#"..tostring(self.partindex)
            self.partindex+=1
            part.CFrame = CFrame.new(getMouseWorldPosition())
            part.Anchored = true
            part.Parent = workspace

            if self.activelySimulating then
                self:deselect()
            end
            self:select(part)
        end
    end))
    
    self.maid:GiveTask(UserInputService.InputBegan:Connect(function(i, g)
        if g then return end
        if self.active then
            if i.UserInputType == Enum.UserInputType.MouseButton1 then
                local part = getMouseHit()
                if part then
                    if self.activelySimulating then
                        self:deselect()
                    else
                        self:select(part)
                    end
                end
            end
        end
    end))

    return self
end

function construct:Enable(enabled)
    self.active = enabled
    if not enabled then
        self:deselect()
    end
end

function construct:deselect()
    self.simulationMaid:DoCleaning()
    self.activelySimulating = false
end

function construct:select(part)
    if not part:IsA("BasePart") then return end
    local selectionBox = Instance.new("SelectionBox")
    selectionBox.LineThickness = 0.5
    selectionBox.Color3 = Color3.fromRGB(0, 255, 255)
    selectionBox.Visible = true
    selectionBox.Adornee = part
    selectionBox.Name = "ConstructSelectionBox"
    selectionBox.Parent = CoreGui
    self.simulationMaid:GiveTask(selectionBox)

    local handles = Instance.new("Handles")
    handles.Color3 = Color3.fromRGB(248, 149, 0)
    handles.Faces = ALL_FACES
    handles.Style = Enum.HandlesStyle.Movement
    handles.Adornee = part
    handles.Parent = CoreGui
    self.simulationMaid:GiveTask(self.states.handleType:subscribe(function(handleType)
        handles.Style = if handleType == "move" then Enum.HandlesStyle.Movement else Enum.HandlesStyle.Resize
    end))

    local lastSizeVector, lastPosVector = part.Size, part.Position
    self.simulationMaid:GiveTask(handles.MouseDrag:Connect(function(face, dist)
        if self.states.handleType:get() == "move" then
            local vector = Vector3.fromNormalId(face) * snap(dist, self.moveScale) + part.Position
            if lastPosVector ~= vector then
                part.Position = vector
                lastPosVector = vector
            end
        else
            local vector = Vector3.fromNormalId(face) * snap(dist, self.sizeScale) + part.Size
            if lastSizeVector ~= vector then
                part.Size = vector
                lastSizeVector = vector
            end
        end
    end))
    self.simulationMaid:GiveTask(handles)
    
    self.activelySimulating = true
end

function construct:Destroy()
    self.maid:Destroy()
    table.clear(self)
    setmetatable(self, nil)
end

return construct