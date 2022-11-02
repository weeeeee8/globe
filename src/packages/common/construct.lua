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
    return math.floor(n / snapFactor) * snapFactor
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

        moveScale = 5,--per stud
        sizeScale = 5,--per stud
        rotationScale = 45,--to be converted to radians

        states = {},
    }, construct)

    self.maid:GiveTask(self.simulationMaid)
    self.states.handleType = Subscription.new("move", self.maid)
    self.states.objectSpace = Subscription.new("world", self.maid)

    self.maid:GiveTask(Players.LocalPlayer.Chatted:Connect(function(msg: string?)
        if #msg <= 0 then return end
        if msg:sub(1, 2):lower() == "/e" then msg = msg:sub(4, #msg) end
        if msg:lower():sub(1, #self.prefix) == self.prefix then
            if not self.active then return end
            local part = Instance.new("Part")
            part.Name = "clientpart#"..tostring(self.partindex)
            self.partindex+=1
            part.CFrame = CFrame.new(getMouseWorldPosition() + Vector3.new(0, 1, 0))
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
    local tempPart = Instance.new("Part")
    tempPart.Name = "Hitbox"
    tempPart.CanCollide = false
    tempPart.CanQuery = false
    tempPart.CanTouch = false
    tempPart.CastShadow = false
    tempPart.Transparency = 1
    tempPart.Anchored = true
    tempPart.Size = part.Size
    tempPart.CFrame = if self.states.objectSpace:get() == "world" then CFrame.new(part.Position) else part.CFrame
    self.simulationMaid:GiveTask(self.states.objectSpace:subscribe(function(typ)
        tempPart.CFrame = if typ == "world" then CFrame.new(part.Position) else part.CFrame
    end))
    tempPart.Parent = workspace.CurrentCamera
    self.simulationMaid:GiveTask(tempPart)

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
    handles.Style = if self.states.handleType:get() == "move" then Enum.HandlesStyle.Movement else Enum.HandlesStyle.Resize
    self.simulationMaid:GiveTask(self.states.handleType:subscribe(function(handleType)
        handles.Style = if handleType == "move" then Enum.HandlesStyle.Movement else Enum.HandlesStyle.Resize
    end))

    local originalSize = part.Size
    local originalCFrame = part.CFrame
    self.simulationMaid:GiveTask(handles.MouseDrag:Connect(function(face, dist)
        if self.states.handleType:get() == "move" then
            if self.states.objectSpace:get() == "world" then
                part.Position = originalCFrame.Position + Vector3.fromNormalId(face) * snap(dist, self.moveScale)
            else
                part.CFrame = originalCFrame:ToWorldSpace(CFrame.new(Vector3.fromNormalId(face) * snap(dist, self.moveScale)))
            end

            tempPart.CFrame = if self.states.objectSpace:get() == "world" then CFrame.new(part.Position) else part.CFrame
        else
            local fixedFace = Vector3.fromNormalId(face)
            fixedFace = Vector3.new(
                math.abs(fixedFace.X),
                math.abs(fixedFace.Y),
                math.abs(fixedFace.Z)
            )
            local goalSize = originalSize + fixedFace * snap(dist, self.sizeScale)
            goalSize = Vector3.new(
                math.max(goalSize.X, 0.001),
                math.max(goalSize.Y, 0.001),
                math.max(goalSize.Z, 0.001)
            )
            part.Size = goalSize
            part.CFrame = originalCFrame:ToWorldSpace(CFrame.new(Vector3.fromNormalId(face) * snap(dist, self.moveScale) / 2))

            tempPart.Size = part.Size
            tempPart.CFrame = part.CFrame
        end
    end))
    self.simulationMaid:GiveTask(handles.MouseButton1Down:Connect(function(face)
        originalCFrame = part.CFrame
        originalSize = part.Size
        handles.Faces = Faces.new(face)
    end))
    self.simulationMaid:GiveTask(handles.MouseButton1Up:Connect(function()
        originalCFrame = part.CFrame
        originalSize = part.Size
        handles.Faces = ALL_FACES
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