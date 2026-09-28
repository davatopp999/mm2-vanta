-- language: Lua (Roblox), env: Delta APK, game: Drive a Kukirin
-- KV1ZZ HUB — kukirin wheelie edition

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace        = game:GetService("Workspace")
local Lighting         = game:GetService("Lighting")
local TweenService     = game:GetService("TweenService")
local StarterGui       = game:GetService("StarterGui")
local LocalPlayer      = Players.LocalPlayer
local Camera           = Workspace.CurrentCamera

local CFG = {
    ESP = { Enabled=true, Money=true, Names=true, Distance=true, MaxDist=1000 },
    Stunt = { NoFall=true, AutoStabilize=true, AutoWheelie=true, BalanceLock=false,
              Multiplier=true, AutoRecover=true, WheelieAngle=30 },
    Auto = { CollectMoney=false, CollectRange=25 },
    Move = { Speed=false, SpeedValue=80, Fly=false, FlySpeed=70, Jump=false, JumpPower=80 },
    Misc = { Fullbright=true, AntiAFK=true },
    Colors = {
        Accent = Color3.fromRGB(120, 220, 255),
        Accent2= Color3.fromRGB(120, 255, 140),
        Money  = Color3.fromRGB(120, 255, 120),
        Object = Color3.fromRGB(255, 200, 80),
        Bg     = Color3.fromRGB(12, 10, 18),
        Bg2    = Color3.fromRGB(22, 18, 30),
        Line   = Color3.fromRGB(48, 42, 62),
        Text   = Color3.fromRGB(230, 225, 245),
        TextDim= Color3.fromRGB(150, 145, 170),
    }
}

local espCache = {}
local wheelieGyro, wheelieAV
local flyConn, flyBodyVel, flyBodyGyro
local mainFrame, toggleBtn, toggleBtnInner, list, statusLabel

local function notify(t, x, d)
    pcall(function() StarterGui:SetCore("SendNotification",
        {Title=t or "KV1ZZ", Text=x or "", Duration=d or 3}) end)
end

local function getVehicle()
    local c = LocalPlayer.Character; if not c then return nil end
    local hum = c:FindFirstChildOfClass("Humanoid")
    if hum and hum.SeatPart then
        local v = hum.SeatPart:FindFirstAncestorOfClass("Model")
        if v then return v end
    end
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("VehicleSeat") then
            local occ = obj.Occupant
            if occ and occ.Parent == c then
                return obj:FindFirstAncestorOfClass("Model") or obj.Parent
            end
        end
    end
    return nil
end

local function getVehicleRoot(veh)
    if not veh then return nil end
    return veh:FindFirstChild("HumanoidRootPart")
        or veh:FindFirstChild("Chassis")
        or veh:FindFirstChild("Root")
        or veh.PrimaryPart
        or veh:FindFirstChildWhichIsA("BasePart")
end

-- ==== WHEELIE ENGINE ====
local function stopWheelie()
    if wheelieGyro then wheelieGyro:Destroy(); wheelieGyro = nil end
    if wheelieAV then wheelieAV:Destroy(); wheelieAV = nil end
end

local function startWheelie(root)
    if not root then return end
    if not wheelieGyro then
        wheelieGyro = Instance.new("BodyGyro")
        wheelieGyro.Name = "KV1ZZ_Wheelie"
        wheelieGyro.MaxTorque = Vector3.new(1e5, 0, 1e5)
        wheelieGyro.P = 5000
        wheelieGyro.D = 500
        wheelieGyro.Parent = root
    end
    if not wheelieAV then
        wheelieAV = Instance.new("BodyAngularVelocity")
        wheelieAV.Name = "KV1ZZ_Wheelie"
        wheelieAV.MaxTorque = Vector3.new(1e5, 0, 1e5)
        wheelieAV.AngularVelocity = Vector3.zero
        wheelieAV.P = 1e4
        wheelieAV.Parent = root
    end
end

RunService.Heartbeat:Connect(function()
    if not CFG.Stunt.AutoWheelie then stopWheelie(); return end
    local veh = getVehicle(); if not veh then stopWheelie(); return end
    local root = getVehicleRoot(veh); if not root then return end
    startWheelie(root)
    pcall(function()
        local yaw = select(2, root.CFrame:ToOrientation())
        local targetCF = CFrame.new(root.Position)
            * CFrame.Angles(0, yaw, 0)
            * CFrame.Angles(math.rad(-CFG.Stunt.WheelieAngle), 0, 0)
        wheelieGyro.CFrame = targetCF
    end)
end)

-- No-Fall / BalanceLock (не активны когда wheelie on)
RunService.Heartbeat:Connect(function()
    if CFG.Stunt.AutoWheelie then return end
    if not CFG.Stunt.NoFall and not CFG.Stunt.BalanceLock then return end
    local veh = getVehicle(); if not veh then return end
    local root = getVehicleRoot(veh); if not root then return end
    pcall(function()
        local x, y, z = root.CFrame:ToOrientation()
        if CFG.Stunt.BalanceLock then x, z = 0, 0
        elseif CFG.Stunt.NoFall then
            x = math.clamp(x, math.rad(-30), math.rad(30))
            z = math.clamp(z, math.rad(-30), math.rad(30))
        end
        root.CFrame = CFrame.new(root.Position) * CFrame.Angles(x, y, z)
    end)
end)

-- Auto-Recover
RunService.Heartbeat:Connect(function()
    if not CFG.Stunt.AutoRecover then return end
    local veh = getVehicle(); if not veh then return end
    local root = getVehicleRoot(veh); if not root then return end
    local x, y = root.CFrame:ToOrientation()
    if math.abs(x) > math.rad(80) then
        root.CFrame = CFrame.new(root.Position + Vector3.new(0,2,0)) * CFrame.Angles(0, y, 0)
    end
end)

-- Side stabilize
RunService.Heartbeat:Connect(function()
    if not CFG.Stunt.AutoStabilize then return end
    local veh = getVehicle(); if not veh then return end
    local root = getVehicleRoot(veh); if not root then return end
    pcall(function()
        local av = root:FindFirstChild("KV1ZZ_SideAV")
        if not av then
            av = Instance.new("BodyAngularVelocity")
            av.Name = "KV1ZZ_SideAV"
            av.MaxTorque = Vector3.new(0, 1e5, 0)
            av.AngularVelocity = Vector3.zero
            av.P = 1e4
            av.Parent = root
        end
    end)
end)

-- ==== AUTO COLLECT ====
task.spawn(function()
    while task.wait(0.4) do
        if not CFG.Auto.CollectMoney then continue end
        local char = LocalPlayer.Character; if not char then continue end
        local root = char:FindFirstChild("HumanoidRootPart"); if not root then continue end
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj:IsA("BasePart") then
                local n = obj.Name:lower()
                if n:find("cash") or n:find("money") or n:find("dollar")
                or n:find("coin") or n:find("bonus") or n:find("%$") then
                    if (obj.Position - root.Position).Magnitude < CFG.Auto.CollectRange then
                        pcall(function()
                            firetouchinterest(root, obj, 0)
                            task.wait(0.03)
                            firetouchinterest(root, obj, 1)
                        end)
                    end
                end
            end
        end
    end
end)

-- ==== ESP ====
local function makeESP(key)
    if espCache[key] then return espCache[key] end
    local t = {}
    t.box = Drawing.new("Square"); t.box.Thickness=1; t.box.Filled=false; t.box.Transparency=1
    t.name = Drawing.new("Text"); t.name.Size=13; t.name.Center=true; t.name.Outline=true
    t.dist = Drawing.new("Text"); t.dist.Size=11; t.dist.Center=true; t.dist.Outline=true
    espCache[key] = t
    return t
end
local function hideESP(t)
    for _, d in pairs(t) do d.Visible = false end
end
local function drawOne(part, label, col, key)
    local t = makeESP(key)
    local dv = (part.Position - Camera.CFrame.Position).Magnitude
    if dv > CFG.ESP.MaxDist then hideESP(t); return end
    local sp, on = Camera:WorldToViewportPoint(part.Position)
    if not on then hideESP(t); return end
    t.box.Size = Vector2.new(36, 36)
    t.box.Position = Vector2.new(sp.X - 18, sp.Y - 18)
    t.box.Color = col; t.box.Visible = true
    if CFG.ESP.Names then
        t.name.Text = label; t.name.Position = Vector2.new(sp.X, sp.Y - 30)
        t.name.Color = col; t.name.Visible = true
    end
    if CFG.ESP.Distance then
        t.dist.Text = string.format("[%d]", math.floor(dv))
        t.dist.Position = Vector2.new(sp.X, sp.Y + 20)
        t.dist.Color = col; t.dist.Visible = true
    end
end
local function updateESP()
    for _, t in pairs(espCache) do hideESP(t) end
    if not CFG.ESP.Enabled then return end
    local cnt = 0
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if cnt > 200 then break end
        if obj:IsA("BasePart") then
            local n = obj.Name:lower()
            if CFG.ESP.Money and (n:find("cash") or n:find("money")
                or n:find("dollar") or n:find("coin")) then
                drawOne(obj, "money", CFG.Colors.Money, obj); cnt = cnt + 1
            end
        end
    end
end

-- ==== SPEED / FLY ====
local function stopFly()
    if flyConn then flyConn:Disconnect(); flyConn=nil end
    if flyBodyVel then flyBodyVel:Destroy(); flyBodyVel=nil end
    if flyBodyGyro then flyBodyGyro:Destroy(); flyBodyGyro=nil end
end
local function startFly()
    local c = LocalPlayer.Character; if not c then return end
    local root = c:FindFirstChild("HumanoidRootPart"); if not root then return end
    stopFly()
    flyBodyVel = Instance.new("BodyVelocity")
    flyBodyVel.MaxForce = Vector3.new(1e5,1e5,1e5)
    flyBodyVel.Velocity = Vector3.zero; flyBodyVel.Parent = root
    flyBodyGyro = Instance.new("BodyGyro")
    flyBodyGyro.MaxTorque = Vector3.new(1e5,1e5,1e5)
    flyBodyGyro.P = 1000; flyBodyGyro.Parent = root
    flyConn = RunService.RenderStepped:Connect(function()
        local hum = c:FindFirstChildOfClass("Humanoid"); if not hum then return end
        local mv = hum.MoveDirection
        local cam = Camera.CFrame
        flyBodyVel.Velocity = (cam.LookVector * -mv.Z + cam.RightVector * mv.X) * CFG.Move.FlySpeed
        flyBodyGyro.CFrame = cam
    end)
end

task.spawn(function()
    while task.wait(0.3) do
        local c = LocalPlayer.Character
        if c then
            if CFG.Move.Fly then
                if not flyConn then startFly() end
            else
                if flyConn then stopFly() end
            end
            local hum = c:FindFirstChildOfClass("Humanoid")
            if hum then
                hum.WalkSpeed = CFG.Move.Speed and CFG.Move.SpeedValue or 16
                hum.JumpPower = CFG.Move.Jump and CFG.Move.JumpPower or 50
                hum.UseJumpPower = true
            end
            if CFG.Move.Speed then
                local veh = getVehicle()
                if veh then
                    for _, d in ipairs(veh:GetDescendants()) do
                        if d:IsA("VehicleSeat") then
                            pcall(function() d.MaxSpeed = CFG.Move.SpeedValue end)
                            pcall(function() d.Torque = CFG.Move.SpeedValue * 100 end)
                        end
                    end
                end
            end
        else
            if flyConn then stopFly() end
        end
    end
end)

if CFG.Misc.Fullbright then
    pcall(function()
        Lighting.Ambient = Color3.fromRGB(180,180,180)
        Lighting.Brightness = 2; Lighting.ClockTime = 14
        Lighting.FogEnd = 1e6; Lighting.GlobalShadows = false
    end)
end
task.spawn(function()
    while task.wait(30) do
        if CFG.Misc.AntiAFK then
            pcall(function()
                local VU = game:GetService("VirtualUser")
                VU:CaptureController(); VU:ClickButton2(Vector2.new())
            end)
        end
    end
end)

-- ==== UI ====
local function guiParent()
    local ok, cg = pcall(function() return game:GetService("CoreGui") end)
    if ok and cg then return cg end
    return LocalPlayer:WaitForChild("PlayerGui")
end
local function corner(p, r)
    local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, r or 8); c.Parent = p; return c
end
local function stroke(p, col, th)
    local s = Instance.new("UIStroke"); s.Color = col or CFG.Colors.Line
    s.Thickness = th or 1; s.Parent = p; return s
end
local function new(cls, props)
    local i = Instance.new(cls)
    for k, v in pairs(props or {}) do i[k] = v end
    return i
end
local function tween(obj, t, goal, style, dir)
    local tw = TweenService:Create(obj,
        TweenInfo.new(t, style or Enum.EasingStyle.Quart, dir or Enum.EasingDirection.Out), goal)
    tw:Play(); return tw
end

local gui = new("ScreenGui", {
    Name="KV1ZZ_Kukirin", ResetOnSpawn=false,
    ZIndexBehavior=Enum.ZIndexBehavior.Sibling, DisplayOrder=999, IgnoreGuiInset=true,
})
gui.Parent = guiParent()

toggleBtn = new("TextButton", {
    Size=UDim2.fromOffset(54,54), Position=UDim2.new(0,20,0.4,0),
    BackgroundColor3=CFG.Colors.Bg, Text="", AutoButtonColor=false, Parent=gui,
})
corner(toggleBtn, 27); stroke(toggleBtn, CFG.Colors.Accent, 2)
toggleBtnInner = new("TextLabel", {
    Size=UDim2.fromScale(1,1), BackgroundTransparency=1,
    Text="K", TextColor3=CFG.Colors.Accent,
    TextSize=24, Font=Enum.Font.GothamBlack, Parent=toggleBtn,
})
task.spawn(function()
    while gui.Parent do
        tween(toggleBtnInner, 1.2, {TextTransparency=0.35}, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
        task.wait(1.2)
        tween(toggleBtnInner, 1.2, {TextTransparency=0}, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
        task.wait(1.2)
    end
end)

mainFrame = new("Frame", {
    Size=UDim2.fromOffset(310, 440),
    Position=UDim2.new(0, 80, 0.12, 0),
    BackgroundColor3=CFG.Colors.Bg, BorderSizePixel=0, Visible=false, Parent=gui,
})
corner(mainFrame, 14); stroke(mainFrame, CFG.Colors.Accent, 1)

local header = new("Frame", {
    Size=UDim2.new(1,0,0,46),
    BackgroundColor3=CFG.Colors.Bg2, BorderSizePixel=0, Parent=mainFrame,
})
corner(header, 14)
new("Frame", {
    Size=UDim2.new(1,0,0,14), Position=UDim2.new(0,0,1,-14),
    BackgroundColor3=CFG.Colors.Bg2, BorderSizePixel=0, Parent=header,
})
new("TextLabel", {
    Size=UDim2.new(1,-70,0,20), Position=UDim2.new(0,14,0,6),
    BackgroundTransparency=1, Text="KV1ZZ · KUKIRIN",
    TextColor3=CFG.Colors.Accent, TextSize=16, Font=Enum.Font.GothamBlack,
    TextXAlignment=Enum.TextXAlignment.Left, Parent=header,
})
statusLabel = new("TextLabel", {
    Size=UDim2.new(1,-70,0,14), Position=UDim2.new(0,14,0,26),
    BackgroundTransparency=1, Text="wheelie edition",
    TextColor3=CFG.Colors.TextDim, TextSize=11, Font=Enum.Font.Gotham,
    TextXAlignment=Enum.TextXAlignment.Left, Parent=header,
})
local hideBtn = new("TextButton", {
    Size=UDim2.fromOffset(28,28), Position=UDim2.new(1,-36,0,9),
    BackgroundColor3=CFG.Colors.Line, Text="×",
    TextColor3=CFG.Colors.Text, TextSize=18, Font=Enum.Font.GothamBold, Parent=header,
})
corner(hideBtn, 8)
hideBtn.MouseButton1Click:Connect(function() mainFrame.Visible=false end)

list = new("ScrollingFrame", {
    Size=UDim2.new(1,-16,1,-62), Position=UDim2.new(0,8,0,54),
    BackgroundTransparency=1, BorderSizePixel=0,
    ScrollBarThickness=3, ScrollBarImageColor3=CFG.Colors.Line,
    CanvasSize=UDim2.new(0,0,0,0), Parent=mainFrame,
})
local ll = new("UIListLayout", {
    Padding=UDim.new(0,6), SortOrder=Enum.SortOrder.LayoutOrder, Parent=list,
})
ll:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    list.CanvasSize = UDim2.new(0,0,0, ll.AbsoluteContentSize.Y + 12)
end)

local function section(text)
    new("TextLabel", {
        Size=UDim2.new(1,0,0,22), BackgroundTransparency=1,
        Text="▸ " .. text, TextColor3=CFG.Colors.Accent2,
        TextSize=12, Font=Enum.Font.GothamBold,
        TextXAlignment=Enum.TextXAlignment.Left, Parent=list,
    })
end
local function toggleRow(label, get, set)
    local row = new("TextButton", {
        Size=UDim2.new(1,0,0,32), BackgroundColor3=CFG.Colors.Bg2,
        Text="", AutoButtonColor=false, Parent=list,
    })
    corner(row, 8); stroke(row, CFG.Colors.Line, 1)
    new("TextLabel", {
        Size=UDim2.new(1,-70,1,0), Position=UDim2.new(0,12,0,0),
        BackgroundTransparency=1, Text=label,
        TextColor3=CFG.Colors.Text, TextSize=13, Font=Enum.Font.Gotham,
        TextXAlignment=Enum.TextXAlignment.Left, Parent=row,
    })
    local box = new("Frame", {
        Size=UDim2.fromOffset(38,22), Position=UDim2.new(1,-50,0.5,-11),
        BackgroundColor3=get() and CFG.Colors.Accent or CFG.Colors.Line, Parent=row,
    })
    corner(box, 11)
    local knob = new("Frame", {
        Size=UDim2.fromOffset(16,16),
        Position=get() and UDim2.new(1,-18,0,3) or UDim2.new(0,3,0,3),
        BackgroundColor3=Color3.fromRGB(240,240,240), Parent=box,
    })
    corner(knob, 8)
    row.MouseButton1Click:Connect(function()
        local v = not get(); set(v)
        tween(box, 0.18, {BackgroundColor3=v and CFG.Colors.Accent or CFG.Colors.Line})
        tween(knob, 0.18, {Position=v and UDim2.new(1,-18,0,3) or UDim2.new(0,3,0,3)})
    end)
end
local function sliderRow(label, min, max, get, set)
    local row = new("Frame", {
        Size=UDim2.new(1,0,0,46), BackgroundColor3=CFG.Colors.Bg2, Parent=list,
    })
    corner(row, 8); stroke(row, CFG.Colors.Line, 1)
    local lbl = new("TextLabel", {
        Size=UDim2.new(1,-20,0,18), Position=UDim2.new(0,12,0,4),
        BackgroundTransparency=1, Text=label .. ": " .. tostring(get()),
        TextColor3=CFG.Colors.Text, TextSize=13, Font=Enum.Font.Gotham,
        TextXAlignment=Enum.TextXAlignment.Left, Parent=row,
    })
    local bar = new("TextButton", {
        Size=UDim2.new(1,-24,0,12), Position=UDim2.new(0,12,0,26),
        BackgroundColor3=CFG.Colors.Line, Text="", AutoButtonColor=false, Parent=row,
    })
    corner(bar, 6)
    local fill = new("Frame", {
        Size=UDim2.new((get()-min)/(max-min),0,1,0),
        BackgroundColor3=CFG.Colors.Accent, Parent=bar,
    })
    corner(fill, 6)
    local dragging = false
    local function apply(x)
        local rel = math.clamp((x - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
        local val = math.floor(min + (max-min)*rel + 0.5)
        set(val); lbl.Text = label .. ": " .. tostring(val)
        fill.Size = UDim2.new(rel,0,1,0)
    end
    bar.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.Touch
        or i.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging=true; apply(i.Position.X)
        end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if not dragging then return end
        if i.UserInputType == Enum.UserInputType.Touch
        or i.UserInputType == Enum.UserInputType.MouseMovement then apply(i.Position.X) end
    end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.Touch
        or i.UserInputType == Enum.UserInputType.MouseButton1 then dragging=false end
    end)
end

section("Stunt (Wheelie)")
toggleRow("Auto wheelie",    function() return CFG.Stunt.AutoWheelie end,    function(v) CFG.Stunt.AutoWheelie=v end)
sliderRow("Wheelie angle", 10, 60, function() return CFG.Stunt.WheelieAngle end,
    function(v) CFG.Stunt.WheelieAngle = v end)
toggleRow("No fall",         function() return CFG.Stunt.NoFall end,         function(v) CFG.Stunt.NoFall=v end)
toggleRow("Balance lock",    function() return CFG.Stunt.BalanceLock end,    function(v) CFG.Stunt.BalanceLock=v end)
toggleRow("Auto stabilize",  function() return CFG.Stunt.AutoStabilize end,  function(v) CFG.Stunt.AutoStabilize=v end)
toggleRow("Auto recover",    function() return CFG.Stunt.AutoRecover end,    function(v) CFG.Stunt.AutoRecover=v end)

section("Money")
toggleRow("Auto collect", function() return CFG.Auto.CollectMoney end, function(v) CFG.Auto.CollectMoney=v end)
sliderRow("Collect range", 5, 80, function() return CFG.Auto.CollectRange end, function(v) CFG.Auto.CollectRange=v end)

section("ESP")
toggleRow("ESP enabled", function() return CFG.ESP.Enabled end, function(v) CFG.ESP.Enabled=v end)
toggleRow("Money",       function() return CFG.ESP.Money end,   function(v) CFG.ESP.Money=v end)
toggleRow("Names",       function() return CFG.ESP.Names end,   function(v) CFG.ESP.Names=v end)
toggleRow("Distance",    function() return CFG.ESP.Distance end,function(v) CFG.ESP.Distance=v end)

section("Movement")
toggleRow("Speed", function() return CFG.Move.Speed end, function(v) CFG.Move.Speed=v end)
toggleRow("Fly",   function() return CFG.Move.Fly end,   function(v) CFG.Move.Fly=v end)
sliderRow("Speed value", 20, 500, function() return CFG.Move.SpeedValue end, function(v) CFG.Move.SpeedValue=v end)
sliderRow("Fly speed", 10, 200, function() return CFG.Move.FlySpeed end, function(v) CFG.Move.FlySpeed=v end)

section("Misc")
toggleRow("Fullbright", function() return CFG.Misc.Fullbright end, function(v) CFG.Misc.Fullbright=v end)
toggleRow("Anti-AFK",   function() return CFG.Misc.AntiAFK end,   function(v) CFG.Misc.AntiAFK=v end)

toggleBtn.MouseButton1Click:Connect(function()
    mainFrame.Visible = not mainFrame.Visible
end)

do
    local drag, ds, sp
    header.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.Touch
        or i.UserInputType==Enum.UserInputType.MouseButton1 then
            drag=true; ds=i.Position; sp=mainFrame.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if not drag then return end
        if i.UserInputType==Enum.UserInputType.Touch
        or i.UserInputType==Enum.UserInputType.MouseMovement then
            local d = i.Position - ds
            mainFrame.Position = UDim2.new(sp.X.Scale, sp.X.Offset+d.X, sp.Y.Scale, sp.Y.Offset+d.Y)
        end
    end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.Touch
        or i.UserInputType==Enum.UserInputType.MouseButton1 then drag=false end
    end)
end

RunService.RenderStepped:Connect(updateESP)
task.spawn(function()
    while gui.Parent do
        task.wait(1)
        if statusLabel then
            local v = getVehicle()
            statusLabel.Text = v and "on bike · wheelie " .. CFG.Stunt.WheelieAngle .. "°" or "on foot"
        end
    end
end)

notify("KV1ZZ KUKIRIN", "wheelie loaded — tap K", 3)
