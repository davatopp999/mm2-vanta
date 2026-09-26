-- language: Lua (Roblox), env: Delta APK, game: Ride a Pet
-- KV1ZZ HUB — ride a pet edition

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace        = game:GetService("Workspace")
local TweenService     = game:GetService("TweenService")
local StarterGui       = game:GetService("StarterGui")
local LocalPlayer      = Players.LocalPlayer
local Camera           = Workspace.CurrentCamera

local CFG = {
    ESP = { Enabled=true, Coins=true, Eggs=true, Pets=true, Shops=true, Players=false,
            Names=true, Distance=true, MaxDist=1500 },
    Farm = { AutoCollect=false, CollectRange=30, AutoHatch=false, HatchRange=40, TPOnClick=true },
    Move = { Speed=false, SpeedValue=60, Jump=false, JumpPower=100,
             Fly=false, FlySpeed=80 },
    Misc = { AntiAFK=true, Fullbright=true },
    Colors = {
        Accent = Color3.fromRGB(120, 220, 255),
        Accent2= Color3.fromRGB(255, 170, 80),
        Coin   = Color3.fromRGB(255, 215, 0),
        Pet    = Color3.fromRGB(120, 255, 140),
        Shop   = Color3.fromRGB(180, 140, 255),
        Egg    = Color3.fromRGB(255, 220, 140),
        Player = Color3.fromRGB(255, 120, 120),
        Bg     = Color3.fromRGB(12, 10, 18),
        Bg2    = Color3.fromRGB(22, 18, 30),
        Line   = Color3.fromRGB(48, 42, 62),
        Text   = Color3.fromRGB(230, 225, 245),
        TextDim= Color3.fromRGB(150, 145, 170),
    }
}

local espCache = {}
local flyConn, flyBodyVel, flyBodyGyro
local mainFrame, toggleBtn, toggleBtnInner, list, statusLabel
local coins, eggs, pets, shops = {}, {}, {}, {}
local lastScan = 0

local function getRoot(plr)
    local c = plr.Character; return c and c:FindFirstChild("HumanoidRootPart")
end
local function notify(t, x, d)
    pcall(function() StarterGui:SetCore("SendNotification",
        {Title=t or "KV1ZZ", Text=x or "", Duration=d or 3}) end)
end
local function isCurrency(nm)
    local n = nm:lower()
    return n:find("coin") or n:find("cash") or n:find("money")
        or n:find("dollar") or n:find("bonus") or n:find("золот")
        or n:find("валют") or n:find("reward")
end
local function isEgg(nm)
    local n = nm:lower()
    return n:find("egg") or n:find("яйц") or n:find("crate")
        or n:find("capsule") or n:find("gacha")
end
local function isPet(nm)
    local n = nm:lower()
    return n:find("pet") or n:find("питом") or n:find("animal")
        or n:find("mount") or n:find("creature")
end
local function isShop(nm)
    local n = nm:lower()
    return n:find("shop") or n:find("магаз") or n:find("store")
        or n:find("trail") or n:find("трасс")
end

local function scanWorld()
    if os.clock() - lastScan < 1.5 then return end
    lastScan = os.clock()
    coins, eggs, pets, shops = {}, {}, {}, {}
    pcall(function()
        for _, obj in ipairs(Workspace:GetDescendants()) do
            local nm = obj.Name
            if obj:IsA("BasePart") then
                if isCurrency(nm) then table.insert(coins, obj)
                elseif isEgg(nm) then table.insert(eggs, obj)
                elseif isShop(nm) then table.insert(shops, obj) end
            elseif obj:IsA("Model") then
                if isPet(nm) then
                    local p = obj:FindFirstChild("HumanoidRootPart")
                        or obj:FindFirstChildWhichIsA("BasePart")
                    if p then table.insert(pets, p) end
                elseif isEgg(nm) then
                    local p = obj:FindFirstChildWhichIsA("BasePart")
                    if p then table.insert(eggs, p) end
                end
            end
        end
    end)
end

-- ESP
local function makeESP(key)
    if espCache[key] then return espCache[key] end
    local t = {}
    t.box = Drawing.new("Square"); t.box.Thickness=1; t.box.Filled=false; t.box.Transparency=1
    t.name = Drawing.new("Text"); t.name.Size=14; t.name.Center=true; t.name.Outline=true
    t.dist = Drawing.new("Text"); t.dist.Size=12; t.dist.Center=true; t.dist.Outline=true
    espCache[key] = t
    return t
end
local function hide(t)
    t.box.Visible=false; t.name.Visible=false; t.dist.Visible=false
end
local function drawOne(part, label, color, key)
    local t = makeESP(key)
    local pos = part.Position
    local dv = (pos - Camera.CFrame.Position).Magnitude
    if dv > CFG.ESP.MaxDist then hide(t); return end
    local sp, on = Camera:WorldToViewportPoint(pos)
    if not on then hide(t); return end
    t.box.Size = Vector2.new(44, 44)
    t.box.Position = Vector2.new(sp.X - 22, sp.Y - 22)
    t.box.Color = color; t.box.Visible = true
    if CFG.ESP.Names then
        t.name.Text = label
        t.name.Position = Vector2.new(sp.X, sp.Y - 36)
        t.name.Color = color; t.name.Visible = true
    end
    if CFG.ESP.Distance then
        t.dist.Text = string.format("[%d]", math.floor(dv))
        t.dist.Position = Vector2.new(sp.X, sp.Y + 24)
        t.dist.Color = color; t.dist.Visible = true
    end
end
local function updateESP()
    for _, t in pairs(espCache) do hide(t) end
    if not CFG.ESP.Enabled then return end
    scanWorld()
    if CFG.ESP.Coins then
        for _, c in ipairs(coins) do drawOne(c, "coin", CFG.Colors.Coin, c) end
    end
    if CFG.ESP.Eggs then
        for _, e in ipairs(eggs) do drawOne(e, "egg", CFG.Colors.Egg, e) end
    end
    if CFG.ESP.Pets then
        for _, p in ipairs(pets) do drawOne(p, "pet", CFG.Colors.Pet, p) end
    end
    if CFG.ESP.Shops then
        for _, s in ipairs(shops) do drawOne(s, "shop", CFG.Colors.Shop, s) end
    end
    if CFG.ESP.Players then
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr == LocalPlayer then continue end
            local root = getRoot(plr); if not root then continue end
            drawOne(root, plr.Name, CFG.Colors.Player, plr)
        end
    end
end

-- Fly
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
    flyBodyVel.Name="KV1ZZ_Fly"; flyBodyVel.MaxForce=Vector3.new(1e5,1e5,1e5)
    flyBodyVel.Velocity=Vector3.zero; flyBodyVel.Parent=root
    flyBodyGyro = Instance.new("BodyGyro")
    flyBodyGyro.Name="KV1ZZ_Fly"; flyBodyGyro.MaxTorque=Vector3.new(1e5,1e5,1e5)
    flyBodyGyro.P=1000; flyBodyGyro.Parent=root
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
        else
            if flyConn then stopFly() end
        end
    end
end)

-- Auto collect coins
task.spawn(function()
    while task.wait(0.4) do
        if not CFG.Farm.AutoCollect then continue end
        local root = getRoot(LocalPlayer); if not root then continue end
        scanWorld()
        for _, c in ipairs(coins) do
            if (c.Position - root.Position).Magnitude < CFG.Farm.CollectRange then
                pcall(function()
                    firetouchinterest(root, c, 0)
                    task.wait(0.03)
                    firetouchinterest(root, c, 1)
                end)
            end
        end
    end
end)

-- Auto hatch
task.spawn(function()
    while task.wait(0.8) do
        if not CFG.Farm.AutoHatch then continue end
        local root = getRoot(LocalPlayer); if not root then continue end
        scanWorld()
        for _, e in ipairs(eggs) do
            if (e.Position - root.Position).Magnitude < CFG.Farm.HatchRange then
                pcall(function()
                    local m = e
                    if m.Parent and m.Parent:IsA("Model") then m = m.Parent end
                    for _, d in ipairs(m:GetDescendants()) do
                        if d:IsA("ProximityPrompt") then fireproximityprompt(d) end
                        if d:IsA("ClickDetector") then fireclickdetector(d) end
                    end
                end)
            end
        end
    end
end)

-- Anti-AFK + Fullbright
if CFG.Misc.Fullbright then
    pcall(function()
        local L = game:GetService("Lighting")
        L.Ambient = Color3.fromRGB(180,180,180)
        L.Brightness = 2; L.ClockTime = 14
        L.FogEnd = 1e6; L.GlobalShadows = false
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

-- Tap to TP
UserInputService.InputBegan:Connect(function(i, gpe)
    if gpe or not CFG.Farm.TPOnClick then return end
    if i.UserInputType ~= Enum.UserInputType.Touch
    and i.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
    local pos = i.Position
    local root = getRoot(LocalPlayer); if not root then return end
    scanWorld()
    local best, bd = nil, 80
    for _, obj in ipairs(coins) do
        local sp, on = Camera:WorldToViewportPoint(obj.Position)
        if on then
            local d = (Vector2.new(sp.X, sp.Y) - Vector2.new(pos.X, pos.Y)).Magnitude
            if d < bd then best, bd = obj, d end
        end
    end
    for _, obj in ipairs(eggs) do
        local sp, on = Camera:WorldToViewportPoint(obj.Position)
        if on then
            local d = (Vector2.new(sp.X, sp.Y) - Vector2.new(pos.X, pos.Y)).Magnitude
            if d < bd then best, bd = obj, d end
        end
    end
    for _, obj in ipairs(pets) do
        local sp, on = Camera:WorldToViewportPoint(obj.Position)
        if on then
            local d = (Vector2.new(sp.X, sp.Y) - Vector2.new(pos.X, pos.Y)).Magnitude
            if d < bd then best, bd = obj, d end
        end
    end
    if best then
        root.CFrame = CFrame.new(best.Position + Vector3.new(0, 3, 0))
    end
end)

-- UI
local function guiParent()
    local ok, cg = pcall(function() return game:GetService("CoreGui") end)
    if ok and cg then return cg end
    return LocalPlayer:WaitForChild("PlayerGui")
end
local function corner(p, r)
    local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, r or 8)
    c.Parent = p; return c
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
    Name="KV1ZZ_RidePet", ResetOnSpawn=false,
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
    Size=UDim2.fromOffset(310, 460),
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
    BackgroundTransparency=1, Text="KV1ZZ HUB",
    TextColor3=CFG.Colors.Accent, TextSize=16, Font=Enum.Font.GothamBlack,
    TextXAlignment=Enum.TextXAlignment.Left, Parent=header,
})
statusLabel = new("TextLabel", {
    Size=UDim2.new(1,-70,0,14), Position=UDim2.new(0,14,0,26),
    BackgroundTransparency=1, Text="ride a pet edition",
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

section("Visuals")
toggleRow("ESP enabled", function() return CFG.ESP.Enabled end, function(v) CFG.ESP.Enabled=v end)
toggleRow("Coins",       function() return CFG.ESP.Coins end, function(v) CFG.ESP.Coins=v end)
toggleRow("Eggs",        function() return CFG.ESP.Eggs end, function(v) CFG.ESP.Eggs=v end)
toggleRow("Pets",        function() return CFG.ESP.Pets end, function(v) CFG.ESP.Pets=v end)
toggleRow("Shops",       function() return CFG.ESP.Shops end, function(v) CFG.ESP.Shops=v end)
toggleRow("Players",     function() return CFG.ESP.Players end, function(v) CFG.ESP.Players=v end)
toggleRow("Names",       function() return CFG.ESP.Names end, function(v) CFG.ESP.Names=v end)
toggleRow("Distance",    function() return CFG.ESP.Distance end, function(v) CFG.ESP.Distance=v end)

section("Farm")
toggleRow("Auto collect coins", function() return CFG.Farm.AutoCollect end, function(v) CFG.Farm.AutoCollect=v end)
toggleRow("Auto hatch eggs",    function() return CFG.Farm.AutoHatch end, function(v) CFG.Farm.AutoHatch=v end)
toggleRow("Tap to TP",          function() return CFG.Farm.TPOnClick end, function(v) CFG.Farm.TPOnClick=v end)
sliderRow("Collect range", 5, 100, function() return CFG.Farm.CollectRange end, function(v) CFG.Farm.CollectRange=v end)
sliderRow("Hatch range", 5, 100, function() return CFG.Farm.HatchRange end, function(v) CFG.Farm.HatchRange=v end)

section("Movement")
toggleRow("Speed", function() return CFG.Move.Speed end, function(v) CFG.Move.Speed=v end)
toggleRow("Jump",  function() return CFG.Move.Jump end, function(v) CFG.Move.Jump=v end)
toggleRow("Fly",   function() return CFG.Move.Fly end, function(v) CFG.Move.Fly=v end)
sliderRow("WalkSpeed", 16, 200, function() return CFG.Move.SpeedValue end, function(v) CFG.Move.SpeedValue=v end)
sliderRow("JumpPower", 50, 300, function() return CFG.Move.JumpPower end, function(v) CFG.Move.JumpPower=v end)
sliderRow("FlySpeed", 10, 250, function() return CFG.Move.FlySpeed end, function(v) CFG.Move.FlySpeed=v end)

section("Misc")
toggleRow("Anti-AFK",  function() return CFG.Misc.AntiAFK end, function(v) CFG.Misc.AntiAFK=v end)
toggleRow("Fullbright",function() return CFG.Misc.Fullbright end, function(v) CFG.Misc.Fullbright=v end)

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
            statusLabel.Text = string.format("coins %d · eggs %d · pets %d",
                #coins, #eggs, #pets)
        end
    end
end)

notify("KV1ZZ HUB", "Ride a Pet loaded — tap K", 3)
