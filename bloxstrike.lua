-- language: Lua (Roblox), env: Delta APK, game: Bloxstrike
-- KV1ZZ HUB — Bloxstrike edition

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace        = game:GetService("Workspace")
local TweenService     = game:GetService("TweenService")
local StarterGui       = game:GetService("StarterGui")
local VirtualInputManager = game:GetService("VirtualInputManager")
local LocalPlayer      = Players.LocalPlayer
local Camera           = Workspace.CurrentCamera

local CFG = {
    Aim = { Enabled=true, FOV=140, Smooth=0.35, WallCheck=true, TeamCheck=true,
            Part="Head", DrawFOV=true, AutoFire=false, TriggerBot=false },
    Silent = { Enabled=true, FOV=220, Part="Head", WallCheck=false },
    Recoil = { NoRecoil=true, NoSpread=true },
    ESP = { Enabled=true, Enemies=true, Allies=false, Names=true, Distance=true,
            Health=true, Tracers=false, MaxDist=800 },
    Move = { Speed=false, SpeedValue=26, Jump=false, JumpPower=60 },
    Misc = { HitboxExpand=false, HitboxSize=3, Fullbright=true },
    Colors = {
        Accent = Color3.fromRGB(255, 170, 80),
        Accent2= Color3.fromRGB(120, 220, 255),
        Enemy  = Color3.fromRGB(255, 90, 120),
        Ally   = Color3.fromRGB(120, 255, 140),
        Bg     = Color3.fromRGB(12, 10, 16),
        Bg2    = Color3.fromRGB(22, 18, 28),
        Line   = Color3.fromRGB(48, 42, 58),
        Text   = Color3.fromRGB(230, 225, 240),
        TextDim= Color3.fromRGB(150, 145, 165),
    }
}

local espCache = {}
local currentTarget = nil
local mainFrame, toggleBtn, toggleBtnInner, list, statusLabel, fovCircle

local function getRoot(plr)
    local c = plr.Character; return c and c:FindFirstChild("HumanoidRootPart")
end
local function isAlive(plr)
    local c = plr.Character; if not c then return false end
    local h = c:FindFirstChildOfClass("Humanoid")
    return h and h.Health > 0
end
local function isTeammate(plr)
    if not CFG.Aim.TeamCheck then return false end
    return plr.Team ~= nil and plr.Team == LocalPlayer.Team
end
local function worldToScreen(pos)
    local sp, on = Camera:WorldToViewportPoint(pos)
    if not on then return nil end
    return Vector2.new(sp.X, sp.Y)
end
local function notify(t, x, d)
    pcall(function() StarterGui:SetCore("SendNotification",
        {Title=t or "KV1ZZ", Text=x or "", Duration=d or 3}) end)
end
local function hasLOS(a, b)
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {LocalPlayer.Character}
    local hit = Workspace:Raycast(a.Position, b.Position - a.Position, params)
    return hit == nil or hit.Instance:IsDescendantOf(b.Parent)
end

local function getClosest(fov, part, wallCheck, teamCheck)
    local best, bd = nil, math.huge
    local center = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr == LocalPlayer or not isAlive(plr) then continue end
        if teamCheck and isTeammate(plr) then continue end
        local char = plr.Character; if not char then continue end
        local target = char:FindFirstChild(part) or char:FindFirstChild("HumanoidRootPart")
        if not target then continue end
        if wallCheck then
            local myRoot = getRoot(LocalPlayer)
            if myRoot and not hasLOS(myRoot, target) then continue end
        end
        local sp, on = Camera:WorldToViewportPoint(target.Position)
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
    if not CFG.Aim.Enabled then currentTarget = nil; return end
    if not aimHeld and not UserInputService.TouchEnabled then return end
    local t = getClosest(CFG.Aim.FOV, CFG.Aim.Part, CFG.Aim.WallCheck, CFG.Aim.TeamCheck)
    currentTarget = t
    if not t or not t.Character then return end
    local part = t.Character:FindFirstChild(CFG.Aim.Part) or t.Character:FindFirstChild("HumanoidRootPart")
    if not part then return end
    local desired = CFrame.lookAt(Camera.CFrame.Position, part.Position)
    if CFG.Aim.Smooth <= 0 then Camera.CFrame = desired
    else Camera.CFrame = Camera.CFrame:Lerp(desired, 1 - CFG.Aim.Smooth) end
end)

-- FOV circle
do
    local sg = Instance.new("ScreenGui")
    sg.Name = "KV1ZZ_FOV"; sg.ResetOnSpawn=false; sg.IgnoreGuiInset=true
    sg.Parent = (function()
        local ok, cg = pcall(function() return game:GetService("CoreGui") end)
        if ok and cg then return cg end
        return LocalPlayer:WaitForChild("PlayerGui")
    end)()
    fovCircle = Instance.new("Frame")
    fovCircle.BackgroundTransparency = 1
    fovCircle.AnchorPoint = Vector2.new(0.5, 0.5)
    fovCircle.Position = UDim2.new(0.5, 0, 0.5, 0)
    fovCircle.Parent = sg
    local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(1,0); c.Parent = fovCircle
    local s = Instance.new("UIStroke"); s.Color = CFG.Colors.Accent
    s.Thickness = 1; s.Transparency = 0.4; s.Parent = fovCircle
end
RunService.RenderStepped:Connect(function()
    if not fovCircle then return end
    if CFG.Aim.DrawFOV and CFG.Aim.Enabled then
        fovCircle.Size = UDim2.fromOffset(CFG.Aim.FOV*2, CFG.Aim.FOV*2)
        fovCircle.Visible = true
    else
        fovCircle.Visible = false
    end
end)

-- Silent aim
pcall(function()
    if hookmetamethod and getnamecallmethod then
        local old
        old = hookmetamethod(game, "__namecall", function(self, ...)
            if CFG.Silent.Enabled and getnamecallmethod() == "Raycast" and self == Workspace then
                local origin = ...
                local t = getClosest(CFG.Silent.FOV, CFG.Silent.Part, CFG.Silent.WallCheck, CFG.Aim.TeamCheck)
                if t and t.Character then
                    local part = t.Character:FindFirstChild(CFG.Silent.Part) or t.Character:FindFirstChild("HumanoidRootPart")
                    if part then return old(self, origin, part.Position - origin, ...) end
                end
            end
            return old(self, ...)
        end)
    end
end)

-- No-recoil / no-spread
RunService.Heartbeat:Connect(function()
    if not LocalPlayer.Character then return end
    local tool = LocalPlayer.Character:FindFirstChildOfClass("Tool")
    if not tool then return end
    if CFG.Recoil.NoRecoil then
        for _, v in ipairs(tool:GetDescendants()) do
            if v:IsA("Vector3Value") and v.Name:lower():find("recoil") then v.Value = Vector3.zero end
        end
    end
    if CFG.Recoil.NoSpread then
        for _, v in ipairs(tool:GetDescendants()) do
            if v:IsA("NumberValue")
            and (v.Name:lower():find("spread") or v.Name:lower():find("inaccuracy")) then
                v.Value = 0
            end
        end
    end
end)

-- Trigger bot
RunService.Heartbeat:Connect(function()
    if not CFG.Aim.TriggerBot then return end
    local t = getClosest(30, CFG.Aim.Part, false, CFG.Aim.TeamCheck)
    if t then
        pcall(function()
            VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 1)
            task.wait(0.02)
            VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 1)
        end)
    end
end)

-- Auto fire
RunService.Heartbeat:Connect(function()
    if not CFG.Aim.AutoFire or not currentTarget then return end
    pcall(function()
        VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 1)
        task.wait(0.05)
        VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 1)
    end)
end)

-- ESP
local function makeESP(key)
    if espCache[key] then return espCache[key] end
    local t = {}
    t.box = Drawing.new("Square"); t.box.Thickness=1; t.box.Filled=false; t.box.Transparency=1
    t.name = Drawing.new("Text"); t.name.Size=14; t.name.Center=true; t.name.Outline=true
    t.dist = Drawing.new("Text"); t.dist.Size=12; t.dist.Center=true; t.dist.Outline=true
    t.tracer = Drawing.new("Line"); t.tracer.Thickness=1; t.tracer.Transparency=0.6
    t.hpBg = Drawing.new("Line"); t.hpBg.Thickness=3; t.hpBg.Transparency=0.7
    t.hpFg = Drawing.new("Line"); t.hpFg.Thickness=3; t.hpFg.Transparency=1
    espCache[key] = t
    return t
end
local function hide(t)
    for _, d in pairs(t) do d.Visible = false end
end
local function updateESP()
    for _, t in pairs(espCache) do hide(t) end
    if not CFG.ESP.Enabled then return end
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr == LocalPlayer or not isAlive(plr) then continue end
        local ally = isTeammate(plr)
        if ally and not CFG.ESP.Allies then continue end
        if not ally and not CFG.ESP.Enemies then continue end
        local char = plr.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        local head = char and char:FindFirstChild("Head")
        local hum  = char and char:FindFirstChildOfClass("Humanoid")
        if not root or not head or not hum then continue end
        local dv = (root.Position - Camera.CFrame.Position).Magnitude
        if dv > CFG.ESP.MaxDist then continue end
        local top = worldToScreen(head.Position + Vector3.new(0, 1.2, 0))
        local bot = worldToScreen(root.Position - Vector3.new(0, 3, 0))
        if not top or not bot then continue end
        local t = makeESP(plr)
        local col = ally and CFG.Colors.Ally or CFG.Colors.Enemy
        local h = bot.Y - top.Y; local w = h * 0.55
        t.box.Size = Vector2.new(w, h); t.box.Position = Vector2.new(top.X - w/2, top.Y)
        t.box.Color = col; t.box.Visible = true
        if CFG.ESP.Names then
            t.name.Text = plr.Name
            t.name.Position = Vector2.new(top.X, top.Y - 18)
            t.name.Color = col; t.name.Visible = true
        end
        if CFG.ESP.Distance then
            t.dist.Text = string.format("[%d]", math.floor(dv))
            t.dist.Position = Vector2.new(top.X, bot.Y + 2)
            t.dist.Color = col; t.dist.Visible = true
        end
        if CFG.ESP.Tracers then
            t.tracer.From = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y)
            t.tracer.To = Vector2.new(top.X, bot.Y)
            t.tracer.Color = col; t.tracer.Visible = true
        end
        if CFG.ESP.Health then
            local ratio = math.clamp(hum.Health / math.max(hum.MaxHealth, 1), 0, 1)
            local x = top.X - w/2 - 6
            t.hpBg.From = Vector2.new(x, top.Y); t.hpBg.To = Vector2.new(x, bot.Y)
            t.hpBg.Color = Color3.fromRGB(60,60,70); t.hpBg.Visible = true
            t.hpFg.From = Vector2.new(x, bot.Y - h*ratio); t.hpFg.To = Vector2.new(x, bot.Y)
            t.hpFg.Color = Color3.fromRGB(90,220,120); t.hpFg.Visible = true
        end
    end
end

-- Movement (без ломающих фич)
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

-- Hitbox expand
task.spawn(function()
    while task.wait(1) do
        if not CFG.Misc.HitboxExpand then continue end
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr == LocalPlayer or not plr.Character or isTeammate(plr) then continue end
            local hum = plr.Character:FindFirstChildOfClass("Humanoid")
            if hum then pcall(function() hum.HipHeight = CFG.Misc.HitboxSize end) end
        end
    end
end)

-- Fullbright
if CFG.Misc.Fullbright then
    pcall(function()
        local L = game:GetService("Lighting")
        L.Ambient = Color3.fromRGB(180,180,180)
        L.Brightness = 2; L.ClockTime = 14
        L.FogEnd = 1e6; L.GlobalShadows = false
    end)
end

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
    Name="KV1ZZ_Bloxstrike", ResetOnSpawn=false,
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
    BackgroundColor3=CFG.Colors.Bg, BorderSizePixel=0,
    Visible=false, Parent=gui,
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
    BackgroundTransparency=1, Text="bloxstrike edition",
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

section("Aimbot")
toggleRow("Aimbot enabled", function() return CFG.Aim.Enabled end, function(v) CFG.Aim.Enabled=v end)
toggleRow("Wall check",     function() return CFG.Aim.WallCheck end, function(v) CFG.Aim.WallCheck=v end)
toggleRow("Team check",     function() return CFG.Aim.TeamCheck end, function(v) CFG.Aim.TeamCheck=v end)
toggleRow("Draw FOV",       function() return CFG.Aim.DrawFOV end, function(v) CFG.Aim.DrawFOV=v end)
toggleRow("Trigger bot",    function() return CFG.Aim.TriggerBot end, function(v) CFG.Aim.TriggerBot=v end)
toggleRow("Auto fire",      function() return CFG.Aim.AutoFire end, function(v) CFG.Aim.AutoFire=v end)
sliderRow("FOV", 20, 400, function() return CFG.Aim.FOV end, function(v) CFG.Aim.FOV=v end)
sliderRow("Smooth x100", 0, 100, function() return math.floor(CFG.Aim.Smooth*100) end,
    function(v) CFG.Aim.Smooth = v/100 end)

section("Silent Aim")
toggleRow("Silent enabled",    function() return CFG.Silent.Enabled end, function(v) CFG.Silent.Enabled=v end)
toggleRow("Silent wall check", function() return CFG.Silent.WallCheck end, function(v) CFG.Silent.WallCheck=v end)
sliderRow("Silent FOV", 20, 500, function() return CFG.Silent.FOV end, function(v) CFG.Silent.FOV=v end)

section("Recoil")
toggleRow("No recoil", function() return CFG.Recoil.NoRecoil end, function(v) CFG.Recoil.NoRecoil=v end)
toggleRow("No spread", function() return CFG.Recoil.NoSpread end, function(v) CFG.Recoil.NoSpread=v end)

section("ESP")
toggleRow("ESP enabled", function() return CFG.ESP.Enabled end, function(v) CFG.ESP.Enabled=v end)
toggleRow("Enemies",     function() return CFG.ESP.Enemies end, function(v) CFG.ESP.Enemies=v end)
toggleRow("Allies",      function() return CFG.ESP.Allies end, function(v) CFG.ESP.Allies=v end)
toggleRow("Names",       function() return CFG.ESP.Names end, function(v) CFG.ESP.Names=v end)
toggleRow("Distance",    function() return CFG.ESP.Distance end, function(v) CFG.ESP.Distance=v end)
toggleRow("Health bar",  function() return CFG.ESP.Health end, function(v) CFG.ESP.Health=v end)
toggleRow("Tracers",     function() return CFG.ESP.Tracers end, function(v) CFG.ESP.Tracers=v end)

section("Movement")
toggleRow("Speed", function() return CFG.Move.Speed end, function(v) CFG.Move.Speed=v end)
toggleRow("Jump",  function() return CFG.Move.Jump end, function(v) CFG.Move.Jump=v end)
sliderRow("WalkSpeed", 16, 40, function() return CFG.Move.SpeedValue end, function(v) CFG.Move.SpeedValue=v end)
sliderRow("JumpPower", 50, 120, function() return CFG.Move.JumpPower end, function(v) CFG.Move.JumpPower=v end)

section("Misc")
toggleRow("Hitbox expand (RISK)", function() return CFG.Misc.HitboxExpand end,
    function(v) CFG.Misc.HitboxExpand=v end)
sliderRow("Hitbox size", 2, 10, function() return CFG.Misc.HitboxSize end, function(v) CFG.Misc.HitboxSize=v end)

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
            statusLabel.Text = string.format("%d players · silent %s",
                #Players:GetPlayers(), CFG.Silent.Enabled and "on" or "off")
        end
    end
end)

notify("KV1ZZ HUB", "Bloxstrike loaded — tap K", 3)
