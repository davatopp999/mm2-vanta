-- language: Lua (Roblox), env: Delta APK, game: Realistic Street Soccer
-- KV1ZZ HUB — RSS edition

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace        = game:GetService("Workspace")
local TweenService     = game:GetService("TweenService")
local StarterGui       = game:GetService("StarterGui")
local LocalPlayer      = Players.LocalPlayer
local Camera           = Workspace.CurrentCamera

local CFG = {
    ESP = { Enabled=true, Ball=true, Players=true, Names=true, Distance=true, MaxDist=800 },
    GK = { AutoSave=false, AutoDive=false, SaveRange=50, ReactionTime=0.2 },
    Player = { AutoDribble=false, AutoShoot=false, InfiniteStamina=false, MagnetRange=8 },
    Move = { Speed=false, SpeedValue=40, Jump=false, JumpPower=90, InfJump=false },
    Misc = { AntiAFK=true, Fullbright=true },
    Colors = {
        Accent = Color3.fromRGB(120, 220, 255),
        Accent2= Color3.fromRGB(120, 255, 140),
        Ball   = Color3.fromRGB(255, 255, 255),
        Player = Color3.fromRGB(255, 120, 120),
        Bg     = Color3.fromRGB(12, 10, 18),
        Bg2    = Color3.fromRGB(22, 18, 30),
        Line   = Color3.fromRGB(48, 42, 62),
        Text   = Color3.fromRGB(230, 225, 245),
        TextDim= Color3.fromRGB(150, 145, 170),
    }
}

local espCache = {}
local mainFrame, toggleBtn, toggleBtnInner, list, statusLabel
local ball, lastBallPos = nil, nil
local ballVel = Vector3.zero

local function getRoot(plr)
    local c = plr.Character; return c and c:FindFirstChild("HumanoidRootPart")
end
local function notify(t, x, d)
    pcall(function() StarterGui:SetCore("SendNotification",
        {Title=t or "KV1ZZ", Text=x or "", Duration=d or 3}) end)
end
local function findBall()
    if ball and ball.Parent then return ball end
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") and obj.Name:lower():find("ball") then
            ball = obj; return ball
        end
    end
    return nil
end
local function isAlive(plr)
    local c = plr.Character; if not c then return false end
    local h = c:FindFirstChildOfClass("Humanoid")
    return h and h.Health > 0
end
local function worldToScreen(pos)
    local sp, on = Camera:WorldToViewportPoint(pos)
    if not on then return nil end
    return Vector2.new(sp.X, sp.Y)
end

-- ==== GK AUTO-SAVE ====
-- Предикт траектории мяча: считаем, куда он полетит через ReactionTime
task.spawn(function()
    while task.wait(0.05) do
        local b = findBall()
        if b then
            if lastBallPos then
                local d = b.Position - lastBallPos
                ballVel = ballVel:Lerp(d / 0.05, 0.5)
            end
            lastBallPos = b.Position
        end
    end
end)

task.spawn(function()
    while task.wait(0.1) do
        if not CFG.GK.AutoSave and not CFG.GK.AutoDive then continue end
        local b = findBall(); if not b then continue end
        local root = getRoot(LocalPlayer); if not root then continue end
        local speed = ballVel.Magnitude
        if speed < 15 then continue end
        local dv = (b.Position - root.Position).Magnitude
        if dv > CFG.GK.SaveRange then continue end

        -- предикт позиции мяча
        local predicted = b.Position + ballVel * CFG.GK.ReactionTime
        local dir = (predicted - root.Position)

        -- прыжок в сторону мяча (свайп по экрану = движение)
        local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then
            -- толкаем персонажа в сторону предсказанной точки
            pcall(function()
                root.CFrame = root.CFrame + Vector3.new(dir.X, 0, dir.Z).Unit * 2
            end)
            -- прыжок
            if CFG.GK.AutoDive then
                pcall(function() hum:ChangeState(Enum.HumanoidStateType.Jumping) end)
            end
        end
    end
end)

-- ==== AUTO-DRIBBLE (Ball Magnet) ====
task.spawn(function()
    while task.wait(0.05) do
        if not CFG.Player.AutoDribble then continue end
        local b = findBall(); if not b then continue end
        local root = getRoot(LocalPlayer); if not root then continue end
        local dv = (b.Position - root.Position).Magnitude
        if dv < CFG.Player.MagnetRange then
            pcall(function()
                -- подтягиваем мяч к ногам
                local target = root.CFrame * CFrame.new(0, -1.5, -2)
                b.CFrame = b.CFrame:Lerp(CFrame.new(target.Position), 0.3)
            end)
        end
    end
end)

-- ==== AUTO-SHOOT ====
task.spawn(function()
    while task.wait(0.3) do
        if not CFG.Player.AutoShoot then continue end
        local b = findBall(); if not b then continue end
        local root = getRoot(LocalPlayer); if not root then continue end
        if (b.Position - root.Position).Magnitude < CFG.Player.MagnetRange + 2 then
            pcall(function()
                local goal = Workspace:FindFirstChild("Goal") or Workspace:FindFirstChildWhichIsA("Goal")
                if goal then
                    local dir = (goal.Position - b.Position).Unit
                    b.Velocity = dir * 150
                else
                    -- если ворот нет, бьём вперёд
                    local look = root.CFrame.LookVector
                    b.Velocity = look * 150
                end
            end)
        end
    end
end)

-- ==== INFINITE STAMINA ====
task.spawn(function()
    while task.wait(0.5) do
        if not CFG.Player.InfiniteStamina then continue end
        local c = LocalPlayer.Character; if not c then continue end
        for _, v in ipairs(c:GetDescendants()) do
            if v:IsA("NumberValue") and (v.Name:lower():find("stamina") or v.Name:lower():find("energy")) then
                v.Value = 100
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
local function hide(t)
    t.box.Visible=false; t.name.Visible=false; t.dist.Visible=false
end
local function updateESP()
    for _, t in pairs(espCache) do hide(t) end
    if not CFG.ESP.Enabled then return end

    -- Ball
    if CFG.ESP.Ball then
        local b = findBall()
        if b then
            local dv = (b.Position - Camera.CFrame.Position).Magnitude
            if dv < CFG.ESP.MaxDist then
                local sp, on = Camera:WorldToViewportPoint(b.Position)
                if on then
                    local t = makeESP(b)
                    t.box.Size = Vector2.new(20, 20)
                    t.box.Position = Vector2.new(sp.X - 10, sp.Y - 10)
                    t.box.Color = CFG.Colors.Ball; t.box.Visible = true
                    if CFG.ESP.Distance then
                        t.dist.Text = string.format("[%d]", math.floor(dv))
                        t.dist.Position = Vector2.new(sp.X, sp.Y + 14)
                        t.dist.Color = CFG.Colors.Ball; t.dist.Visible = true
                    end
                end
            end
        end
    end

    -- Players
    if CFG.ESP.Players then
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr == LocalPlayer or not isAlive(plr) then continue end
            local root = getRoot(plr); if not root then continue end
            local dv = (root.Position - Camera.CFrame.Position).Magnitude
            if dv > CFG.ESP.MaxDist then continue end
            local sp, on = Camera:WorldToViewportPoint(root.Position)
            if not on then continue end
            local t = makeESP(plr)
            t.box.Size = Vector2.new(36, 54)
            t.box.Position = Vector2.new(sp.X - 18, sp.Y - 45)
            t.box.Color = CFG.Colors.Player; t.box.Visible = true
            if CFG.ESP.Names then
                t.name.Text = plr.Name
                t.name.Position = Vector2.new(sp.X, sp.Y - 62)
                t.name.Color = CFG.Colors.Player; t.name.Visible = true
            end
            if CFG.ESP.Distance then
                t.dist.Text = string.format("[%d]", math.floor(dv))
                t.dist.Position = Vector2.new(sp.X, sp.Y + 14)
                t.dist.Color = CFG.Colors.Player; t.dist.Visible = true
            end
        end
    end
end

-- ==== MOVEMENT ====
task.spawn(function()
    while task.wait(0.3) do
        local c = LocalPlayer.Character
        if c then
            local hum = c:FindFirstChildOfClass("Humanoid")
            if hum then
                hum.WalkSpeed = CFG.Move.Speed and CFG.Move.SpeedValue or 16
                hum.JumpPower = CFG.Move.Jump and CFG.Move.JumpPower or 50
                hum.UseJumpPower = true
            end
        end
    end
end)
UserInputService.JumpRequest:Connect(function()
    if CFG.Move.InfJump and LocalPlayer.Character then
        local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end)

-- ==== MISC ====
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

-- ==== UI ====
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
    Name="KV1ZZ_RSS", ResetOnSpawn=false,
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
    BackgroundTransparency=1, Text="rss edition",
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
toggleRow("Ball",        function() return CFG.ESP.Ball end, function(v) CFG.ESP.Ball=v end)
toggleRow("Players",     function() return CFG.ESP.Players end, function(v) CFG.ESP.Players=v end)
toggleRow("Names",       function() return CFG.ESP.Names end, function(v) CFG.ESP.Names=v end)
toggleRow("Distance",    function() return CFG.ESP.Distance end, function(v) CFG.ESP.Distance=v end)

section("Goalkeeper")
toggleRow("Auto save",     function() return CFG.GK.AutoSave end, function(v) CFG.GK.AutoSave=v end)
toggleRow("Auto dive",     function() return CFG.GK.AutoDive end, function(v) CFG.GK.AutoDive=v end)
sliderRow("Save range", 10, 100, function() return CFG.GK.SaveRange end, function(v) CFG.GK.SaveRange=v end)
sliderRow("Reaction x100", 5, 50, function() return math.floor(CFG.GK.ReactionTime*100) end,
    function(v) CFG.GK.ReactionTime = v/100 end)

section("Player")
toggleRow("Auto dribble",    function() return CFG.Player.AutoDribble end, function(v) CFG.Player.AutoDribble=v end)
toggleRow("Auto shoot",      function() return CFG.Player.AutoShoot end, function(v) CFG.Player.AutoShoot=v end)
toggleRow("Infinite stamina",function() return CFG.Player.InfiniteStamina end, function(v) CFG.Player.InfiniteStamina=v end)
sliderRow("Magnet range", 3, 20, function() return CFG.Player.MagnetRange end, function(v) CFG.Player.MagnetRange=v end)

section("Movement")
toggleRow("Speed",         function() return CFG.Move.Speed end, function(v) CFG.Move.Speed=v end)
toggleRow("Jump",          function() return CFG.Move.Jump end, function(v) CFG.Move.Jump=v end)
toggleRow("Infinite jump", function() return CFG.Move.InfJump end, function(v) CFG.Move.InfJump=v end)
sliderRow("WalkSpeed", 16, 100, function() return CFG.Move.SpeedValue end, function(v) CFG.Move.SpeedValue=v end)
sliderRow("JumpPower", 50, 200, function() return CFG.Move.JumpPower end, function(v) CFG.Move.JumpPower=v end)

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
            statusLabel.Text = string.format("GK %s · dribble %s",
                CFG.GK.AutoSave and "on" or "off",
                CFG.Player.AutoDribble and "on" or "off")
        end
    end
end)

notify("KV1ZZ HUB", "RSS loaded — tap K", 3)
