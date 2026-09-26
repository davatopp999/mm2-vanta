-- language: Lua (Roblox), env: Delta APK, game: Murder Mystery 2
-- VANTA MM2 — loader with in-game menu (Instance/ScreenGui based)

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace        = game:GetService("Workspace")
local Lighting         = game:GetService("Lighting")
local TweenService     = game:GetService("TweenService")
local LocalPlayer      = Players.LocalPlayer
local Camera           = Workspace.CurrentCamera

-- ============ CONFIG ============
local CFG = {
    ESP = { Enabled=true, Boxes=true, Names=true, Roles=true, Distance=true, Tracers=true, MaxDist=500 },
    Aimbot = { Enabled=true, FOV=120, Smooth=0.25, WallCheck=true },
    SilentAim = { Enabled=true, FOV=200, WallCheck=false },
    Movement = { Fly=false, FlySpeed=60, Speed=false, SpeedValue=35, Jump=false, JumpPower=80 },
    Auto = { AutoKnife=true, AutoShoot=true, AutoPickup=true },
    Misc = { Fullbright=true, RoleAlert=true },
    Colors = {
        Murderer = Color3.fromRGB(255,60,60),
        Sheriff  = Color3.fromRGB(60,140,255),
        Innocent = Color3.fromRGB(60,255,120),
        Unknown  = Color3.fromRGB(200,200,200),
    }
}

local espCache, currentTarget = {}, nil
local flyConn, flyBodyVel, flyBodyGyro
local mainFrame, toggleBtn

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

-- ESP
local function makeESP(plr)
    if espCache[plr] then return espCache[plr] end
    local box = Drawing.new("Square"); box.Thickness=1; box.Filled=false; box.Transparency=1
    local name = Drawing.new("Text"); name.Size=14; name.Center=true; name.Outline=true
    local dist = Drawing.new("Text"); dist.Size=12; dist.Center=true; dist.Outline=true
    local role = Drawing.new("Text"); role.Size=13; role.Center=true; role.Outline=true
    local tracer = Drawing.new("Line"); tracer.Thickness=1; tracer.Transparency=0.6
    espCache[plr] = {box=box,name=name,dist=dist,role=role,tracer=tracer}
    return espCache[plr]
end
local function removeESP(plr)
    local e = espCache[plr]; if not e then return end
    for _, d in pairs(e) do pcall(function() d:Remove() end) end
    espCache[plr] = nil
end
local function updateESP()
    for plr, e in pairs(espCache) do
        if plr == LocalPlayer or not isAlive(plr) or not CFG.ESP.Enabled then
            for _, d in pairs(e) do d.Visible = false end; continue
        end
        local root = getRoot(plr); local head = plr.Character:FindFirstChild("Head")
        if not root or not head then
            for _, d in pairs(e) do d.Visible = false end; continue
        end
        local dv = (root.Position - Camera.CFrame.Position).Magnitude
        if dv > CFG.ESP.MaxDist then
            for _, d in pairs(e) do d.Visible = false end; continue
        end
        local top = worldToScreen(head.Position + Vector3.new(0,1.5,0))
        local bot = worldToScreen(root.Position - Vector3.new(0,3,0))
        if not top or not bot then
            for _, d in pairs(e) do d.Visible = false end; continue
        end
        local r = getRole(plr); local col = roleColor(r)
        if CFG.ESP.Boxes then
            local h = bot.Y - top.Y; local w = h*0.6
            e.box.Size = Vector2.new(w,h); e.box.Position = Vector2.new(top.X-w/2, top.Y)
            e.box.Color = col; e.box.Visible = true
        else e.box.Visible = false end
        if CFG.ESP.Names then
            e.name.Text = plr.Name; e.name.Position = Vector2.new(top.X, top.Y-18)
            e.name.Color = col; e.name.Visible = true
        else e.name.Visible = false end
        if CFG.ESP.Roles then
            e.role.Text = r; e.role.Position = Vector2.new(top.X, bot.Y+2)
            e.role.Color = col; e.role.Visible = true
        else e.role.Visible = false end
        if CFG.ESP.Distance then
            e.dist.Text = string.format("[%d]", math.floor(dv))
            e.dist.Position = Vector2.new(top.X, bot.Y+16); e.dist.Color = col; e.dist.Visible = true
        else e.dist.Visible = false end
        if CFG.ESP.Tracers then
            e.tracer.From = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y)
            e.tracer.To = Vector2.new(top.X, bot.Y); e.tracer.Color = col; e.tracer.Visible = true
        else e.tracer.Visible = false end
    end
end

-- Aimbot
local function getClosestTarget(fov, wallCheck)
    local best, bd = nil, math.huge
    local center = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
    local myRoot = getRoot(LocalPlayer); if not myRoot then return nil end
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr == LocalPlayer or not isAlive(plr) then continue end
        local part = plr.Character:FindFirstChild("Head") or plr.Character:FindFirstChild("HumanoidRootPart")
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
    if not CFG.Aimbot.Enabled then return end
    if not aimHeld and not UserInputService.TouchEnabled then return end
    local t = getClosestTarget(CFG.Aimbot.FOV, CFG.Aimbot.WallCheck)
    currentTarget = t
    if not t then return end
    local part = t.Character:FindFirstChild("Head") or t.Character:FindFirstChild("HumanoidRootPart")
    if not part then return end
    local desired = CFrame.lookAt(Camera.CFrame.Position, part.Position)
    if CFG.Aimbot.Smooth <= 0 then Camera.CFrame = desired
    else Camera.CFrame = Camera.CFrame:Lerp(desired, 1 - CFG.Aimbot.Smooth) end
end)

-- Silent Aim
if hookmetamethod then
    local old
    old = hookmetamethod(game, "__namecall", function(self, ...)
        if CFG.SilentAim.Enabled and getnamecallmethod() == "Raycast" and self == Workspace then
            local origin, dir = ...
            local t = getClosestTarget(CFG.SilentAim.FOV, CFG.SilentAim.WallCheck)
            if t then
                local part = t.Character:FindFirstChild("Head") or t.Character:FindFirstChild("HumanoidRootPart")
                if part then return old(self, origin, part.Position - origin, ...) end
            end
        end
        return old(self, ...)
    end)
end

-- Fly / Speed
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
    flyBodyVel.MaxForce = Vector3.new(1e5,1e5,1e5)
    flyBodyVel.Velocity = Vector3.zero; flyBodyVel.Parent = root
    flyBodyGyro = Instance.new("BodyGyro")
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
        if CFG.Movement.Fly and LocalPlayer.Character then
            if not flyConn then startFly() end
        else
            if flyConn then stopFly() end
        end
        local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then
            hum.WalkSpeed = CFG.Movement.Speed and CFG.Movement.SpeedValue or 16
            hum.JumpPower = CFG.Movement.Jump and CFG.Movement.JumpPower or 50
            hum.UseJumpPower = true
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
        if not LocalPlayer.Character then continue end
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
        if CFG.Auto.AutoPickup then
            local myRoot = getRoot(LocalPlayer)
            if myRoot then
                for _, obj in ipairs(Workspace:GetChildren()) do
                    if obj:IsA("Tool") and not obj:IsDescendantOf(LocalPlayer.Character) then
                        local h = obj:FindFirstChild("Handle")
                        if h and (h.Position - myRoot.Position).Magnitude < 10 then
                            pcall(function()
                                firetouchinterest(myRoot, h, 0)
                                task.wait(0.05)
                                firetouchinterest(myRoot, h, 1)
                            end)
                        end
                    end
                end
            end
        end
    end
end)

-- Misc
if CFG.Misc.Fullbright then
    pcall(function()
        Lighting.Ambient = Color3.fromRGB(180,180,180)
        Lighting.Brightness = 2
        Lighting.ClockTime = 14
        Lighting.FogEnd = 1e6
        Lighting.GlobalShadows = false
    end)
end
if CFG.Misc.RoleAlert then
    task.spawn(function()
        local last
        while task.wait(0.5) do
            local r = getRole(LocalPlayer)
            if r ~= last then
                last = r
                pcall(function()
                    game:GetService("StarterGui"):SetCore("SendNotification",
                        {Title="VANTA MM2", Text="Роль: "..r, Duration=3})
                end)
            end
        end
    end)
end

-- ============ MENU ============
local function guiParent()
    local ok, pg = pcall(function() return game:GetService("CoreGui") end)
    if ok and pg then return pg end
    return LocalPlayer:WaitForChild("PlayerGui")
end
local function corner(parent, r)
    local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, r or 8); c.Parent = parent; return c
end
local function stroke(parent, col, th)
    local s = Instance.new("UIStroke"); s.Color = col or Color3.fromRGB(60,60,70)
    s.Thickness = th or 1; s.Parent = parent; return s
end
local function pad(parent, p)
    local u = Instance.new("UIPadding")
    u.PaddingTop = UDim.new(0,p); u.PaddingBottom = UDim.new(0,p)
    u.PaddingLeft = UDim.new(0,p); u.PaddingRight = UDim.new(0,p)
    u.Parent = parent; return u
end
local function new(cls, props)
    local i = Instance.new(cls)
    for k, v in pairs(props or {}) do i[k] = v end
    return i
end

local gui = new("ScreenGui", {
    Name = "VANTA_MM2", ResetOnSpawn = false,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 999,
})
gui.Parent = guiParent()

toggleBtn = new("TextButton", {
    Name = "VANTA_Toggle", Size = UDim2.fromOffset(48,48),
    Position = UDim2.new(0,20,0.4,0),
    BackgroundColor3 = Color3.fromRGB(20,20,26),
    Text = "V", TextColor3 = Color3.fromRGB(120,220,255),
    TextSize = 22, Font = Enum.Font.GothamBold,
    AutoButtonColor = false, Parent = gui,
})
corner(toggleBtn, 24); stroke(toggleBtn, Color3.fromRGB(80,140,200), 2)

mainFrame = new("Frame", {
    Name = "VANTA_Menu", Size = UDim2.fromOffset(280,360),
    Position = UDim2.new(0,80,0.2,0),
    BackgroundColor3 = Color3.fromRGB(16,16,22),
    BorderSizePixel = 0, Visible = false, Parent = gui,
})
corner(mainFrame, 10); stroke(mainFrame, Color3.fromRGB(60,60,80), 1); pad(mainFrame, 10)

local title = new("TextLabel", {
    Size = UDim2.new(1,0,0,26), BackgroundTransparency = 1,
    Text = "VANTA · MM2", TextColor3 = Color3.fromRGB(200,220,255),
    TextSize = 16, Font = Enum.Font.GothamBold,
    TextXAlignment = Enum.TextXAlignment.Left, Parent = mainFrame,
})
local hideBtn = new("TextButton", {
    Size = UDim2.fromOffset(26,26), Position = UDim2.new(1,-26,0,0),
    BackgroundColor3 = Color3.fromRGB(40,40,50),
    Text = "×", TextColor3 = Color3.fromRGB(220,220,220),
    TextSize = 16, Font = Enum.Font.GothamBold, Parent = mainFrame,
})
corner(hideBtn, 6)
hideBtn.MouseButton1Click:Connect(function() mainFrame.Visible = false end)

local list = new("ScrollingFrame", {
    Size = UDim2.new(1,0,1,-34), Position = UDim2.new(0,0,0,34),
    BackgroundTransparency = 1, BorderSizePixel = 0,
    ScrollBarThickness = 4, CanvasSize = UDim2.new(0,0,0,0),
    Parent = mainFrame,
})
local ll = new("UIListLayout", {
    Padding = UDim.new(0,6), SortOrder = Enum.SortOrder.LayoutOrder, Parent = list,
})
ll:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    list.CanvasSize = UDim2.new(0,0,0, ll.AbsoluteContentSize.Y + 10)
end)

local function section(text)
    new("TextLabel", {
        Size = UDim2.new(1,0,0,22), BackgroundTransparency = 1,
        Text = text, TextColor3 = Color3.fromRGB(120,220,255),
        TextSize = 13, Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left, Parent = list,
    })
end

local function toggle(label, get, set)
    local row = new("TextButton", {
        Size = UDim2.new(1,0,0,30),
        BackgroundColor3 = Color3.fromRGB(24,24,32),
        Text = "", AutoButtonColor = false, Parent = list,
    })
    corner(row, 6); stroke(row, Color3.fromRGB(50,50,62), 1)
    new("TextLabel", {
        Size = UDim2.new(1,-60,1,0), Position = UDim2.new(0,10,0,0),
        BackgroundTransparency = 1, Text = label,
        TextColor3 = Color3.fromRGB(220,220,230), TextSize = 14,
        Font = Enum.Font.Gotham, TextXAlignment = Enum.TextXAlignment.Left, Parent = row,
    })
    local box = new("Frame", {
        Size = UDim2.fromOffset(36,20), Position = UDim2.new(1,-46,0.5,-10),
        BackgroundColor3 = get() and Color3.fromRGB(60,180,120) or Color3.fromRGB(50,50,60),
        Parent = row,
    })
    corner(box, 10)
    local knob = new("Frame", {
        Size = UDim2.fromOffset(16,16),
        Position = get() and UDim2.new(1,-18,0,2) or UDim2.new(0,2,0,2),
        BackgroundColor3 = Color3.fromRGB(240,240,240), Parent = box,
    })
    corner(knob, 8)
    row.MouseButton1Click:Connect(function()
        local v = not get()
        set(v)
        box.BackgroundColor3 = v and Color3.fromRGB(60,180,120) or Color3.fromRGB(50,50,60)
        TweenService:Create(knob, TweenInfo.new(0.15), {
            Position = v and UDim2.new(1,-18,0,2) or UDim2.new(0,2,0,2)
        }):Play()
    end)
end

local function slider(label, min, max, get, set)
    local row = new("Frame", {
        Size = UDim2.new(1,0,0,44),
        BackgroundColor3 = Color3.fromRGB(24,24,32), Parent = list,
    })
    corner(row, 6); stroke(row, Color3.fromRGB(50,50,62), 1)
    local lbl = new("TextLabel", {
        Size = UDim2.new(1,-20,0,20), Position = UDim2.new(0,10,0,2),
        BackgroundTransparency = 1, Text = label .. ": " .. tostring(get()),
        TextColor3 = Color3.fromRGB(220,220,230), TextSize = 13,
        Font = Enum.Font.Gotham, TextXAlignment = Enum.TextXAlignment.Left, Parent = row,
    })
    local bar = new("TextButton", {
        Size = UDim2.new(1,-20,0,10), Position = UDim2.new(0,10,0,26),
        BackgroundColor3 = Color3.fromRGB(50,50,62),
        Text = "", AutoButtonColor = false, Parent = row,
    })
    corner(bar, 5)
    local fill = new("Frame", {
        Size = UDim2.new((get()-min)/(max-min), 0, 1, 0),
        BackgroundColor3 = Color3.fromRGB(120,200,255), Parent = bar,
    })
    corner(fill, 5)
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
toggle("ESP enabled", function() return CFG.ESP.Enabled end, function(v) CFG.ESP.Enabled = v end)
toggle("Boxes",   function() return CFG.ESP.Boxes end,   function(v) CFG.ESP.Boxes = v end)
toggle("Names",   function() return CFG.ESP.Names end,   function(v) CFG.ESP.Names = v end)
toggle("Roles",   function() return CFG.ESP.Roles end,   function(v) CFG.ESP.Roles = v end)
toggle("Distance",function() return CFG.ESP.Distance end,function(v) CFG.ESP.Distance = v end)
toggle("Tracers", function() return CFG.ESP.Tracers end, function(v) CFG.ESP.Tracers = v end)

section("Aimbot")
toggle("Aimbot enabled", function() return CFG.Aimbot.Enabled end, function(v) CFG.Aimbot.Enabled = v end)
toggle("Wall check",     function() return CFG.Aimbot.WallCheck end, function(v) CFG.Aimbot.WallCheck = v end)
slider("FOV", 20, 400, function() return CFG.Aimbot.FOV end, function(v) CFG.Aimbot.FOV = v end)
slider("Smooth x100", 0, 100, function() return math.floor(CFG.Aimbot.Smooth*100) end,
    function(v) CFG.Aimbot.Smooth = v/100 end)

section("Silent Aim")
toggle("Silent enabled", function() return CFG.SilentAim.Enabled end, function(v) CFG.SilentAim.Enabled = v end)
slider("Silent FOV", 20, 500, function() return CFG.SilentAim.FOV end, function(v) CFG.SilentAim.FOV = v end)

section("Movement")
toggle("Fly",   function() return CFG.Movement.Fly end,   function(v) CFG.Movement.Fly = v end)
toggle("Speed", function() return CFG.Movement.Speed end, function(v) CFG.Movement.Speed = v end)
toggle("Jump",  function() return CFG.Movement.Jump end,  function(v) CFG.Movement.Jump = v end)
slider("FlySpeed", 10, 200, function() return CFG.Movement.FlySpeed end, function(v) CFG.Movement.FlySpeed = v end)
slider("WalkSpeed", 16, 200, function() return CFG.Movement.SpeedValue end, function(v) CFG.Movement.SpeedValue = v end)

section("Auto")
toggle("AutoKnife",  function() return CFG.Auto.AutoKnife end,  function(v) CFG.Auto.AutoKnife = v end)
toggle("AutoShoot",  function() return CFG.Auto.AutoShoot end,  function(v) CFG.Auto.AutoShoot = v end)
toggle("AutoPickup", function() return CFG.Auto.AutoPickup end, function(v) CFG.Auto.AutoPickup = v end)

section("Misc")
toggle("Fullbright", function() return CFG.Misc.Fullbright end, function(v)
    CFG.Misc.Fullbright = v
    if v then pcall(function()
        Lighting.Ambient = Color3.fromRGB(180,180,180)
        Lighting.Brightness = 2; Lighting.ClockTime = 14
        Lighting.FogEnd = 1e6; Lighting.GlobalShadows = false
    end) end
end)
toggle("Role alert", function() return CFG.Misc.RoleAlert end, function(v) CFG.Misc.RoleAlert = v end)

toggleBtn.MouseButton1Click:Connect(function()
    mainFrame.Visible = not mainFrame.Visible
end)

do
    local dragging, dragStart, startPos
    title.InputBegan:Connect(function(i)
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

-- init
Players.PlayerRemoving:Connect(removeESP)
for _, plr in ipairs(Players:GetPlayers()) do
    if plr ~= LocalPlayer then makeESP(plr) end
end
Players.PlayerAdded:Connect(function(plr) if plr ~= LocalPlayer then makeESP(plr) end end)
LocalPlayer.CharacterAdded:Connect(function()
    task.wait(1)
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then makeESP(plr) end
    end
end)
RunService.RenderStepped:Connect(updateESP)

print("[VANTA] MM2 loaded — menu ready. Tap V.")
