-- language: Lua (Roblox), env: Delta APK, game: Murder Mystery 2
-- VANTA MM2 v3

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
    ESP = { Enabled=true, Boxes=true, Names=true, Roles=true, Distance=true, Tracers=true,
            MaxDist=500, Highlight=false, HealthBar=true },
    Aimbot = { Enabled=true, FOV=120, Smooth=0.25, WallCheck=true },
    SilentAim = { Enabled=true, FOV=200, WallCheck=false },
    Movement = { Fly=false, FlySpeed=60, Speed=false, SpeedValue=35,
                 Jump=false, JumpPower=80, NoClip=false, InfJump=false, AntiFling=false },
    Auto = { AutoKnife=true, AutoShoot=true, AutoPickup=true, AutoDodge=false, BringGun=false },
    Misc = { Fullbright=true, RoleAlert=true, JoinLeave=true, ClickTP=false },
    Colors = {
        Murderer = Color3.fromRGB(255, 70, 70),
        Sheriff  = Color3.fromRGB(70, 150, 255),
        Innocent = Color3.fromRGB(80, 230, 120),
        Unknown  = Color3.fromRGB(200, 200, 200),
        Accent   = Color3.fromRGB(120, 220, 255),
        Bg       = Color3.fromRGB(14, 14, 20),
        Bg2      = Color3.fromRGB(22, 22, 30),
        Line     = Color3.fromRGB(45, 45, 58),
        Text     = Color3.fromRGB(225, 228, 240),
        TextDim  = Color3.fromRGB(150, 155, 175),
    }
}

local espCache, highlightCache = {}, {}
local currentTarget = nil
local flyConn, flyBodyVel, flyBodyGyro
local mainFrame, toggleBtn, toggleBtnInner, statusLabel

local function isAlive(plr)
    local c = plr.Character; if not c then return false end
    local h = c:FindFirstChildOfClass("Humanoid")
    return h and h.Health > 0
end
local function getRoot(plr)
    local c = plr.Character; return c and c:FindFirstChild("HumanoidRootPart")
end
local function worldToScreen(pos)
    local sp, on = Camera:WorldToViewportPoint(pos)
    if not on then return nil end
    return Vector2.new(sp.X, sp.Y)
end
local function getRole(plr)
    local c = plr.Character; if not c then return "Unknown" end
    for _, t in ipairs(c:GetChildren()) do
        if t:IsA("Tool") then
            local n = t.Name:lower()
            if n:find("knife") then return "Murderer" end
            if n:find("gun") or n:find("revolver") then return "Sheriff" end
        end
    end
    local tag = c:FindFirstChild("Role") or plr:FindFirstChild("Role")
    if tag then return tag.Value or tag.Name end
    return "Innocent"
end
local function roleColor(r) return CFG.Colors[r] or CFG.Colors.Unknown end
local function hasLOS(a, b)
    local p = RaycastParams.new()
    p.FilterType = Enum.RaycastFilterType.Exclude
    p.FilterDescendantsInstances = {LocalPlayer.Character}
    local hit = Workspace:Raycast(a.Position, b.Position - a.Position, p)
    return hit == nil or hit.Instance:IsDescendantOf(b.Parent)
end
local function notify(title, text, dur)
    pcall(function()
        StarterGui:SetCore("SendNotification",
            {Title = title or "VANTA MM2", Text = text or "", Duration = dur or 3})
    end)
end

-- ESP
local function makeESP(plr)
    if espCache[plr] then return espCache[plr] end
    local t = {}
    t.box = Drawing.new("Square"); t.box.Thickness=1; t.box.Filled=false; t.box.Transparency=1
    t.name = Drawing.new("Text"); t.name.Size=14; t.name.Center=true; t.name.Outline=true
    t.dist = Drawing.new("Text"); t.dist.Size=12; t.dist.Center=true; t.dist.Outline=true
    t.role = Drawing.new("Text"); t.role.Size=13; t.role.Center=true; t.role.Outline=true
    t.tracer = Drawing.new("Line"); t.tracer.Thickness=1; t.tracer.Transparency=0.6
    t.hpBg = Drawing.new("Line"); t.hpBg.Thickness=3; t.hpBg.Transparency=0.7
    t.hpFg = Drawing.new("Line"); t.hpFg.Thickness=3; t.hpFg.Transparency=1
    espCache[plr] = t
    return t
end
local function removeESP(plr)
    local t = espCache[plr]
    if t then
        for _, d in pairs(t) do pcall(function() d:Remove() end) end
        espCache[plr] = nil
    end
end
local function setESPVisible(t, v)
    for _, d in pairs(t) do pcall(function() d.Visible = v end) end
end
local function updateESP()
    for plr, t in pairs(espCache) do
        if plr == LocalPlayer or not isAlive(plr) or not CFG.ESP.Enabled then
            setESPVisible(t, false); continue
        end
        local char = plr.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        local head = char and char:FindFirstChild("Head")
        local hum  = char and char:FindFirstChildOfClass("Humanoid")
        if not root or not head or not hum then setESPVisible(t, false); continue end
        local dv = (root.Position - Camera.CFrame.Position).Magnitude
        if dv > CFG.ESP.MaxDist then setESPVisible(t, false); continue end
        local top = worldToScreen(head.Position + Vector3.new(0, 1.5, 0))
        local bot = worldToScreen(root.Position - Vector3.new(0, 3, 0))
        if not top or not bot then setESPVisible(t, false); continue end
        local r = getRole(plr); local col = roleColor(r)
        if CFG.ESP.Boxes then
            local h = bot.Y - top.Y; local w = h * 0.6
            t.box.Size = Vector2.new(w, h); t.box.Position = Vector2.new(top.X - w/2, top.Y)
            t.box.Color = col; t.box.Visible = true
        else t.box.Visible = false end
        if CFG.ESP.Names then
            t.name.Text = plr.Name
            t.name.Position = Vector2.new(top.X, top.Y - 18)
            t.name.Color = col; t.name.Visible = true
        else t.name.Visible = false end
        if CFG.ESP.Roles then
            t.role.Text = r; t.role.Position = Vector2.new(top.X, bot.Y + 2)
            t.role.Color = col; t.role.Visible = true
        else t.role.Visible = false end
        if CFG.ESP.Distance then
            t.dist.Text = string.format("[%d]", math.floor(dv))
            t.dist.Position = Vector2.new(top.X, bot.Y + 16)
            t.dist.Color = col; t.dist.Visible = true
        else t.dist.Visible = false end
        if CFG.ESP.Tracers then
            t.tracer.From = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y)
            t.tracer.To = Vector2.new(top.X, bot.Y)
            t.tracer.Color = col; t.tracer.Visible = true
        else t.tracer.Visible = false end
        if CFG.ESP.HealthBar then
            local h = bot.Y - top.Y
            local ratio = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
            local x = top.X - (h*0.6)/2 - 6
            t.hpBg.From = Vector2.new(x, top.Y); t.hpBg.To = Vector2.new(x, bot.Y)
            t.hpBg.Color = Color3.fromRGB(60,60,70); t.hpBg.Visible = true
            t.hpFg.From = Vector2.new(x, bot.Y - h*ratio); t.hpFg.To = Vector2.new(x, bot.Y)
            t.hpFg.Color = Color3.fromRGB(90,220,120); t.hpFg.Visible = true
        else t.hpBg.Visible = false; t.hpFg.Visible = false end
    end
end

-- Aimbot
local function getClosestTarget(fov, wallCheck)
    local best, bd = nil, math.huge
    local center = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
    local myRoot = getRoot(LocalPlayer); if not myRoot then return nil end
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr == LocalPlayer or not isAlive(plr) then continue end
        local char = plr.Character; if not char then continue end
        local part = char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart")
        if not part then continue end
        if wallCheck and not hasLOS(myRoot, part) then continue end
        local sp, on = Camera:WorldToViewportPoint(part.Position)
        if not on then continue end
        local d = (Vector2.new(sp.X, sp.Y) - center).Magnitude
        if d < fov and d < bd then best, bd = plr, d end
    end
    return best
end
local aimHeld = false
UserInputService.InputBegan:Connect(function(i, gpe)
    if gpe then return end
    if i.UserInputType == Enum.UserInputType.Touch
    or i.UserInputType == Enum.UserInputType.MouseButton2 then aimHeld = true end
end)
UserInputService.InputEnded:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.Touch
    or i.UserInputType == Enum.UserInputType.MouseButton2 then aimHeld = false end
end)
RunService.RenderStepped:Connect(function()
    if not CFG.Aimbot.Enabled then currentTarget = nil; return end
    if not aimHeld and not UserInputService.TouchEnabled then return end
    local t = getClosestTarget(CFG.Aimbot.FOV, CFG.Aimbot.WallCheck)
    currentTarget = t
    if not t or not t.Character then return end
    local part = t.Character:FindFirstChild("Head") or t.Character:FindFirstChild("HumanoidRootPart")
    if not part then return end
    local desired = CFrame.lookAt(Camera.CFrame.Position, part.Position)
    if CFG.Aimbot.Smooth <= 0 then Camera.CFrame = desired
    else Camera.CFrame = Camera.CFrame:Lerp(desired, 1 - CFG.Aimbot.Smooth) end
end)

-- Silent Aim
pcall(function()
    if hookmetamethod and getnamecallmethod then
        local old
        old = hookmetamethod(game, "__namecall", function(self, ...)
            if CFG.SilentAim.Enabled and getnamecallmethod() == "Raycast" and self == Workspace then
                local origin = ...
                local t = getClosestTarget(CFG.SilentAim.FOV, CFG.SilentAim.WallCheck)
                if t and t.Character then
                    local part = t.Character:FindFirstChild("Head") or t.Character:FindFirstChild("HumanoidRootPart")
                    if part then return old(self, origin, part.Position - origin, ...) end
                end
            end
            return old(self, ...)
        end)
    end
end)

-- Movement
local function stopFly()
    if flyConn then flyConn:Disconnect(); flyConn = nil end
    if flyBodyVel then flyBodyVel:Destroy(); flyBodyVel = nil end
    if flyBodyGyro then flyBodyGyro:Destroy(); flyBodyGyro = nil end
end
local function startFly()
    local c = LocalPlayer.Character; if not c then return end
    local root = c:FindFirstChild("HumanoidRootPart"); if not root then return end
    stopFly()
    flyBodyVel = Instance.new("BodyVelocity")
    flyBodyVel.Name = "VANTA_Fly"
    flyBodyVel.MaxForce = Vector3.new(1e5,1e5,1e5)
    flyBodyVel.Velocity = Vector3.zero; flyBodyVel.Parent = root
    flyBodyGyro = Instance.new("BodyGyro")
    flyBodyGyro.Name = "VANTA_Fly"
    flyBodyGyro.MaxTorque = Vector3.new(1e5,1e5,1e5)
    flyBodyGyro.P = 1000; flyBodyGyro.Parent = root
    flyConn = RunService.RenderStepped:Connect(function()
        local hum = c:FindFirstChildOfClass("Humanoid"); if not hum then return end
        local move = hum.MoveDirection
        local cam = Camera.CFrame
        flyBodyVel.Velocity = (cam.LookVector * -move.Z + cam.RightVector * move.X) * CFG.Movement.FlySpeed
        flyBodyGyro.CFrame = cam
    end)
end
task.spawn(function()
    while task.wait(0.3) do
        local c = LocalPlayer.Character
        if c then
            if CFG.Movement.Fly then
                if not flyConn then startFly() end
            else
                if flyConn then stopFly() end
            end
            local hum = c:FindFirstChildOfClass("Humanoid")
            if hum then
                hum.WalkSpeed = CFG.Movement.Speed and CFG.Movement.SpeedValue or 16
                hum.JumpPower = CFG.Movement.Jump and CFG.Movement.JumpPower or 50
                hum.UseJumpPower = true
            end
        else
            if flyConn then stopFly() end
        end
    end
end)
task.spawn(function()
    while task.wait(0.2) do
        if CFG.Movement.NoClip and LocalPlayer.Character then
            for _, p in ipairs(LocalPlayer.Character:GetDescendants()) do
                if p:IsA("BasePart") and p.CanCollide then p.CanCollide = false end
            end
        end
    end
end)
UserInputService.JumpRequest:Connect(function()
    if CFG.Movement.InfJump and LocalPlayer.Character then
        local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end)
RunService.Heartbeat:Connect(function()
    if not CFG.Movement.AntiFling then return end
    local c = LocalPlayer.Character; if not c then return end
    local root = c:FindFirstChild("HumanoidRootPart"); if not root then return end
    for _, v in ipairs(root:GetChildren()) do
        if v:IsA("BodyAngularVelocity") or v:IsA("BodyVelocity") or v:IsA("BodyForce") then
            if v.Name ~= "VANTA_Fly" then pcall(function() v:Destroy() end) end
        end
    end
end)

-- Auto
local function nearestInRange(r)
    local myRoot = getRoot(LocalPlayer); if not myRoot then return nil end
    local best, bd = nil, r
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr == LocalPlayer or not isAlive(plr) then continue end
        local rr = getRoot(plr)
        if rr then
            local d = (rr.Position - myRoot.Position).Magnitude
            if d < bd then best, bd = plr, d end
        end
    end
    return best
end
local function getMyTool()
    local c = LocalPlayer.Character; if not c then return nil end
    return c:FindFirstChildOfClass("Tool")
end
task.spawn(function()
    while task.wait(0.15) do
        local c = LocalPlayer.Character; if not c then continue end
        local myRoot = c:FindFirstChild("HumanoidRootPart"); if not myRoot then continue end
        if CFG.Auto.AutoKnife then
            local tool = getMyTool()
            if tool and tool.Name:lower():find("knife") and nearestInRange(8) then
                pcall(function() tool:Activate() end)
            end
        end
        if CFG.Auto.AutoShoot and currentTarget then
            local tool = getMyTool()
            if tool and (tool.Name:lower():find("gun") or tool.Name:lower():find("revolver")) then
                pcall(function() tool:Activate() end)
            end
        end
        if CFG.Auto.AutoPickup or CFG.Auto.BringGun then
            for _, obj in ipairs(Workspace:GetChildren()) do
                if obj:IsA("Tool") and not obj:IsDescendantOf(c) then
                    local h = obj:FindFirstChild("Handle")
                    if h then
                        local d = (h.Position - myRoot.Position).Magnitude
                        if CFG.Auto.AutoPickup and d < 10 then
                            pcall(function()
                                firetouchinterest(myRoot, h, 0)
                                task.wait(0.05)
                                firetouchinterest(myRoot, h, 1)
                            end)
                        elseif CFG.Auto.BringGun and d < 200 then
                            pcall(function() h.CFrame = myRoot.CFrame end)
                        end
                    end
                end
            end
        end
        if CFG.Auto.AutoDodge then
            local t = nearestInRange(12)
            if t and t.Character and getRole(t) == "Murderer" then
                local tRoot = getRoot(t)
                if tRoot then
                    local dir = (myRoot.Position - tRoot.Position).Unit
                    myRoot.CFrame = myRoot.CFrame + dir * 4
                end
            end
        end
    end
end)

-- Misc
if CFG.Misc.Fullbright then
    pcall(function()
        Lighting.Ambient = Color3.fromRGB(180,180,180)
        Lighting.Brightness = 2; Lighting.ClockTime = 14
        Lighting.FogEnd = 1e6; Lighting.GlobalShadows = false
    end)
end
task.spawn(function()
    local last
    while task.wait(0.5) do
        if not CFG.Misc.RoleAlert then continue end
        local r = getRole(LocalPlayer)
        if r ~= last then last = r; notify("VANTA MM2", "Роль: " .. r, 3) end
    end
end)
Players.PlayerAdded:Connect(function(plr)
    if CFG.Misc.JoinLeave then notify("+", plr.Name, 2) end
    if plr ~= LocalPlayer then makeESP(plr) end
end)
Players.PlayerRemoving:Connect(function(plr)
    if CFG.Misc.JoinLeave then notify("-", plr.Name, 2) end
    removeESP(plr)
end)
UserInputService.InputBegan:Connect(function(i, gpe)
    if gpe or not CFG.Misc.ClickTP then return end
    if i.UserInputType ~= Enum.UserInputType.Touch
    and i.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
    local mouse = LocalPlayer:GetMouse()
    if not mouse or not mouse.Target then return end
    local root = getRoot(LocalPlayer)
    if root then pcall(function()
        root.CFrame = CFrame.new(mouse.Hit.Position + Vector3.new(0, 3, 0))
    end) end
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
    Name = "VANTA_MM2", ResetOnSpawn = false,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 999,
    IgnoreGuiInset = true,
})
gui.Parent = guiParent()

toggleBtn = new("TextButton", {
    Name = "VANTA_Toggle", Size = UDim2.fromOffset(52, 52),
    Position = UDim2.new(0, 20, 0.4, 0),
    BackgroundColor3 = CFG.Colors.Bg, Text = "",
    AutoButtonColor = false, Parent = gui,
})
corner(toggleBtn, 26); stroke(toggleBtn, CFG.Colors.Accent, 2)
toggleBtnInner = new("TextLabel", {
    Size = UDim2.fromScale(1,1), BackgroundTransparency = 1,
    Text = "V", TextColor3 = CFG.Colors.Accent,
    TextSize = 24, Font = Enum.Font.GothamBold, Parent = toggleBtn,
})
task.spawn(function()
    while gui.Parent do
        tween(toggleBtnInner, 1.2, {TextTransparency = 0.35},
            Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
        task.wait(1.2)
        tween(toggleBtnInner, 1.2, {TextTransparency = 0},
            Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
        task.wait(1.2)
    end
end)

mainFrame = new("Frame", {
    Name = "VANTA_Menu", Size = UDim2.fromOffset(300, 430),
    Position = UDim2.new(0, 80, 0.15, 0),
    BackgroundColor3 = CFG.Colors.Bg, BorderSizePixel = 0,
    Visible = false, Parent = gui,
})
corner(mainFrame, 12); stroke(mainFrame, CFG.Colors.Line, 1)

local header = new("Frame", {
    Size = UDim2.new(1, 0, 0, 44),
    BackgroundColor3 = CFG.Colors.Bg2, BorderSizePixel = 0, Parent = mainFrame,
})
corner(header, 12)
new("Frame", {
    Size = UDim2.new(1, 0, 0, 12), Position = UDim2.new(0, 0, 1, -12),
    BackgroundColor3 = CFG.Colors.Bg2, BorderSizePixel = 0, Parent = header,
})
new("TextLabel", {
    Size = UDim2.new(1, -70, 0, 18), Position = UDim2.new(0, 14, 0, 6),
    BackgroundTransparency = 1, Text = "VANTA · MM2",
    TextColor3 = CFG.Colors.Text, TextSize = 15, Font = Enum.Font.GothamBold,
    TextXAlignment = Enum.TextXAlignment.Left, Parent = header,
})
statusLabel = new("TextLabel", {
    Size = UDim2.new(1, -70, 0, 14), Position = UDim2.new(0, 14, 0, 24),
    BackgroundTransparency = 1, Text = "ready",
    TextColor3 = CFG.Colors.TextDim, TextSize = 11, Font = Enum.Font.Gotham,
    TextXAlignment = Enum.TextXAlignment.Left, Parent = header,
})
local hideBtn = new("TextButton", {
    Size = UDim2.fromOffset(28, 28), Position = UDim2.new(1, -36, 0, 8),
    BackgroundColor3 = CFG.Colors.Line, Text = "×",
    TextColor3 = CFG.Colors.Text, TextSize = 18,
    Font = Enum.Font.GothamBold, Parent = header,
})
corner(hideBtn, 8)
hideBtn.MouseButton1Click:Connect(function()
    tween(mainFrame, 0.18, {BackgroundTransparency = 1})
    mainFrame.Visible = false
    mainFrame.BackgroundTransparency = 0
end)

local list = new("ScrollingFrame", {
    Size = UDim2.new(1, -16, 1, -60),
    Position = UDim2.new(0, 8, 0, 52),
    BackgroundTransparency = 1, BorderSizePixel = 0,
    ScrollBarThickness = 3, ScrollBarImageColor3 = CFG.Colors.Line,
    CanvasSize = UDim2.new(0, 0, 0, 0), Parent = mainFrame,
})
local ll = new("UIListLayout", {
    Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder, Parent = list,
})
ll:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    list.CanvasSize = UDim2.new(0, 0, 0, ll.AbsoluteContentSize.Y + 12)
end)

local function section(text)
    new("TextLabel", {
        Size = UDim2.new(1, 0, 0, 22), BackgroundTransparency = 1,
        Text = "▸ " .. text, TextColor3 = CFG.Colors.Accent,
        TextSize = 12, Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left, Parent = list,
    })
end

local function toggleRow(label, get, set)
    local row = new("TextButton", {
        Size = UDim2.new(1, 0, 0, 32),
        BackgroundColor3 = CFG.Colors.Bg2, Text = "",
        AutoButtonColor = false, Parent = list,
    })
    corner(row, 8); stroke(row, CFG.Colors.Line, 1)
    new("TextLabel", {
        Size = UDim2.new(1, -70, 1, 0), Position = UDim2.new(0, 12, 0, 0),
        BackgroundTransparency = 1, Text = label,
        TextColor3 = CFG.Colors.Text, TextSize = 13,
        Font = Enum.Font.Gotham, TextXAlignment = Enum.TextXAlignment.Left, Parent = row,
    })
    local box = new("Frame", {
        Size = UDim2.fromOffset(38, 22), Position = UDim2.new(1, -50, 0.5, -11),
        BackgroundColor3 = get() and Color3.fromRGB(80,200,140) or CFG.Colors.Line,
        Parent = row,
    })
    corner(box, 11)
    local knob = new("Frame", {
        Size = UDim2.fromOffset(16, 16),
        Position = get() and UDim2.new(1, -18, 0, 3) or UDim2.new(0, 3, 0, 3),
        BackgroundColor3 = Color3.fromRGB(240,240,240), Parent = box,
    })
    corner(knob, 8)
    row.MouseButton1Click:Connect(function()
        local v = not get(); set(v)
        tween(box, 0.18, {BackgroundColor3 = v and Color3.fromRGB(80,200,140) or CFG.Colors.Line})
        tween(knob, 0.18, {
            Position = v and UDim2.new(1, -18, 0, 3) or UDim2.new(0, 3, 0, 3)
        })
    end)
end

local function sliderRow(label, min, max, get, set)
    local row = new("Frame", {
        Size = UDim2.new(1, 0, 0, 46),
        BackgroundColor3 = CFG.Colors.Bg2, Parent = list,
    })
    corner(row, 8); stroke(row, CFG.Colors.Line, 1)
    local lbl = new("TextLabel", {
        Size = UDim2.new(1, -20, 0, 18), Position = UDim2.new(0, 12, 0, 4),
        BackgroundTransparency = 1, Text = label .. ": " .. tostring(get()),
        TextColor3 = CFG.Colors.Text, TextSize = 13, Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left, Parent = row,
    })
    local bar = new("TextButton", {
        Size = UDim2.new(1, -24, 0, 12), Position = UDim2.new(0, 12, 0, 26),
        BackgroundColor3 = CFG.Colors.Line, Text = "",
        AutoButtonColor = false, Parent = row,
    })
    corner(bar, 6)
    local fill = new("Frame", {
        Size = UDim2.new((get()-min)/(max-min), 0, 1, 0),
        BackgroundColor3 = CFG.Colors.Accent, Parent = bar,
    })
    corner(fill, 6)
    local dragging = false
    local function apply(x)
        local rel = math.clamp((x - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
        local val = math.floor(min + (max-min)*rel + 0.5)
        set(val)
        lbl.Text = label .. ": " .. tostring(val)
        fill.Size = UDim2.new(rel, 0, 1, 0)
    end
    bar.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.Touch
        or i.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true; apply(i.Position.X)
        end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if not dragging then return end
        if i.UserInputType == Enum.UserInputType.Touch
        or i.UserInputType == Enum.UserInputType.MouseMovement then apply(i.Position.X) end
    end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.Touch
        or i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end)
end

section("ESP")
toggleRow("ESP enabled", function() return CFG.ESP.Enabled end, function(v) CFG.ESP.Enabled = v end)
toggleRow("Boxes",     function() return CFG.ESP.Boxes end,    function(v) CFG.ESP.Boxes = v end)
toggleRow("Names",     function() return CFG.ESP.Names end,    function(v) CFG.ESP.Names = v end)
toggleRow("Roles",     function() return CFG.ESP.Roles end,    function(v) CFG.ESP.Roles = v end)
toggleRow("Distance",  function() return CFG.ESP.Distance end, function(v) CFG.ESP.Distance = v end)
toggleRow("Tracers",   function() return CFG.ESP.Tracers end,  function(v) CFG.ESP.Tracers = v end)
toggleRow("Health bar",function() return CFG.ESP.HealthBar end,function(v) CFG.ESP.HealthBar = v end)

section("Aimbot")
toggleRow("Aimbot enabled", function() return CFG.Aimbot.Enabled end, function(v) CFG.Aimbot.Enabled = v end)
toggleRow("Wall check",     function() return CFG.Aimbot.WallCheck end, function(v) CFG.Aimbot.WallCheck = v end)
sliderRow("FOV", 20, 400, function() return CFG.Aimbot.FOV end, function(v) CFG.Aimbot.FOV = v end)
sliderRow("Smooth x100", 0, 100, function() return math.floor(CFG.Aimbot.Smooth*100) end,
    function(v) CFG.Aimbot.Smooth = v/100 end)

section("Silent Aim")
toggleRow("Silent enabled", function() return CFG.SilentAim.Enabled end, function(v) CFG.SilentAim.Enabled = v end)
sliderRow("Silent FOV", 20, 500, function() return CFG.SilentAim.FOV end, function(v) CFG.SilentAim.FOV = v end)

section("Movement")
toggleRow("Fly",         function() return CFG.Movement.Fly end,      function(v) CFG.Movement.Fly = v end)
toggleRow("Speed",       function() return CFG.Movement.Speed end,    function(v) CFG.Movement.Speed = v end)
toggleRow("Jump",        function() return CFG.Movement.Jump end,     function(v) CFG.Movement.Jump = v end)
toggleRow("NoClip",      function() return CFG.Movement.NoClip end,   function(v) CFG.Movement.NoClip = v end)
toggleRow("Infinite jump",function() return CFG.Movement.InfJump end, function(v) CFG.Movement.InfJump = v end)
toggleRow("Anti-fling",  function() return CFG.Movement.AntiFling end,function(v) CFG.Movement.AntiFling = v end)
sliderRow("FlySpeed", 10, 200, function() return CFG.Movement.FlySpeed end, function(v) CFG.Movement.FlySpeed = v end)
sliderRow("WalkSpeed",16, 200, function() return CFG.Movement.SpeedValue end, function(v) CFG.Movement.SpeedValue = v end)

section("Auto")
toggleRow("AutoKnife",  function() return CFG.Auto.AutoKnife end,  function(v) CFG.Auto.AutoKnife = v end)
toggleRow("AutoShoot",  function() return CFG.Auto.AutoShoot end,  function(v) CFG.Auto.AutoShoot = v end)
toggleRow("AutoPickup", function() return CFG.Auto.AutoPickup end, function(v) CFG.Auto.AutoPickup = v end)
toggleRow("AutoDodge",  function() return CFG.Auto.AutoDodge end,  function(v) CFG.Auto.AutoDodge = v end)
toggleRow("Bring guns", function() return CFG.Auto.BringGun end,  function(v) CFG.Auto.BringGun = v end)

section("Misc")
toggleRow("Fullbright",  function() return CFG.Misc.Fullbright end, function(v)
    CFG.Misc.Fullbright = v
    if v then pcall(function()
        Lighting.Ambient = Color3.fromRGB(180,180,180)
        Lighting.Brightness = 2; Lighting.ClockTime = 14
        Lighting.FogEnd = 1e6; Lighting.GlobalShadows = false
    end) end
end)
toggleRow("Role alert",  function() return CFG.Misc.RoleAlert end, function(v) CFG.Misc.RoleAlert = v end)
toggleRow("Join/Leave",  function() return CFG.Misc.JoinLeave end, function(v) CFG.Misc.JoinLeave = v end)
toggleRow("Click TP",    function() return CFG.Misc.ClickTP end,   function(v) CFG.Misc.ClickTP = v end)

-- toggle opens
local openTween
toggleBtn.MouseButton1Click:Connect(function()
    if openTween then pcall(function() openTween:Cancel() end) end
    if not mainFrame.Visible then
        mainFrame.Visible = true
        mainFrame.Size = UDim2.fromOffset(280, 400)
        mainFrame.BackgroundTransparency = 1
        openTween = tween(mainFrame, 0.22, {
            Size = UDim2.fromOffset(300, 430),
            BackgroundTransparency = 0,
        })
    else
        openTween = tween(mainFrame, 0.18, {BackgroundTransparency = 1})
        task.delay(0.18, function() mainFrame.Visible = false; mainFrame.BackgroundTransparency = 0 end)
    end
end)

-- drag by header
do
    local dragging, dragStart, startPos
    header.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.Touch
        or i.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true; dragStart = i.Position; startPos = mainFrame.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if not dragging then return end
        if i.UserInputType == Enum.UserInputType.Touch
        or i.UserInputType == Enum.UserInputType.MouseMovement then
            local d = i.Position - dragStart
            mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset+d.X,
                                           startPos.Y.Scale, startPos.Y.Offset+d.Y)
        end
    end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.Touch
        or i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end)
end

-- status bar
task.spawn(function()
    while gui.Parent do
        task.wait(1)
        if statusLabel then
            local ping = "—"
            pcall(function()
                ping = tostring(math.floor(LocalPlayer:GetNetworkPing() * 1000)) .. "ms"
            end)
            statusLabel.Text = string.format("%d online · %s", #Players:GetPlayers(), ping)
        end
    end
end)

-- init
for _, plr in ipairs(Players:GetPlayers()) do
    if plr ~= LocalPlayer then makeESP(plr) end
end
LocalPlayer.CharacterAdded:Connect(function()
    task.wait(1)
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then makeESP(plr) end
    end
end)
RunService.RenderStepped:Connect(updateESP)

notify("VANTA MM2", "v3 loaded — tap V", 3)
