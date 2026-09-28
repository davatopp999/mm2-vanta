-- language: Lua (Roblox), env: Delta APK, game: Murder Mystery 2
-- KV1ZZ HUB · PAID EDITION · v4

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace        = game:GetService("Workspace")
local Lighting         = game:GetService("Lighting")
local TweenService     = game:GetService("TweenService")
local StarterGui       = game:GetService("StarterGui")
local HttpService      = game:GetService("HttpService")
local LocalPlayer      = Players.LocalPlayer
local Camera           = Workspace.CurrentCamera

-- ==================== KEY SYSTEM ====================
local KEY_URL = "https://raw.githubusercontent.com/davatopp999/mm2-vanta/refs/heads/main/keys.json"
local MY_HWID = tostring(LocalPlayer.UserId)

local function isKeyValid(k)
    if not k or k == "" then return false end
    local ok, raw = pcall(function() return game:HttpGet(KEY_URL) end)
    if not ok or not raw then return false end
    local ok2, data = pcall(function() return HttpService:JSONDecode(raw) end)
    if not ok2 or type(data) ~= "table" then return false end
    for _, entry in ipairs(data.keys or {}) do
        if entry.key == k then
            if entry.banned then return false end
            if entry.hwid and entry.hwid ~= MY_HWID and entry.hwid ~= "any" then return false end
            return true
        end
    end
    return false
end

local function promptKey()
    local sg = Instance.new("ScreenGui")
    sg.Name = "KV1ZZ_KEY"
    sg.ResetOnSpawn = false
    sg.IgnoreGuiInset = true
    sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    local parent = (function()
        local ok, cg = pcall(function() return game:GetService("CoreGui") end)
        if ok and cg then return cg end
        return LocalPlayer:WaitForChild("PlayerGui")
    end)()
    sg.Parent = parent

    local bg = Instance.new("Frame")
    bg.Size = UDim2.new(1,0,1,0)
    bg.BackgroundColor3 = Color3.fromRGB(0,0,0)
    bg.BackgroundTransparency = 0.4
    bg.BorderSizePixel = 0
    bg.Parent = sg

    local box = Instance.new("Frame")
    box.Size = UDim2.fromOffset(340, 200)
    box.Position = UDim2.new(0.5,-170,0.5,-100)
    box.BackgroundColor3 = Color3.fromRGB(14,14,20)
    box.BorderSizePixel = 0
    box.Parent = sg
    local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0,14); c.Parent = box
    local st = Instance.new("UIStroke"); st.Color = Color3.fromRGB(120,220,255); st.Thickness = 1; st.Parent = box

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1,-20,0,40)
    title.Position = UDim2.new(0,10,0,10)
    title.BackgroundTransparency = 1
    title.Text = "KV1ZZ HUB · ACCESS"
    title.TextColor3 = Color3.fromRGB(120,220,255)
    title.TextSize = 18
    title.Font = Enum.Font.GothamBlack
    title.Parent = box

    local input = Instance.new("TextBox")
    input.Size = UDim2.new(1,-30,0,42)
    input.Position = UDim2.new(0,15,0,70)
    input.BackgroundColor3 = Color3.fromRGB(22,18,28)
    input.TextColor3 = Color3.fromRGB(230,225,245)
    input.PlaceholderText = "KV1ZZ-XXXX-XXXX"
    input.Text = ""
    input.TextSize = 14
    input.Font = Enum.Font.Gotham
    input.ClearTextOnFocus = false
    input.Parent = box
    local ic = Instance.new("UICorner"); ic.CornerRadius = UDim.new(0,8); ic.Parent = input

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1,-30,0,42)
    btn.Position = UDim2.new(0,15,0,124)
    btn.BackgroundColor3 = Color3.fromRGB(120,220,255)
    btn.Text = "ENTER"
    btn.TextColor3 = Color3.fromRGB(14,14,20)
    btn.TextSize = 15
    btn.Font = Enum.Font.GothamBlack
    btn.Parent = box
    local bc = Instance.new("UICorner"); bc.CornerRadius = UDim.new(0,8); bc.Parent = btn

    local status = Instance.new("TextLabel")
    status.Size = UDim2.new(1,-20,0,20)
    status.Position = UDim2.new(0,10,0,172)
    status.BackgroundTransparency = 1
    status.Text = ""
    status.TextColor3 = Color3.fromRGB(255,120,120)
    status.TextSize = 12
    status.Font = Enum.Font.Gotham
    status.Parent = box

    local done = false
    btn.MouseButton1Click:Connect(function()
        local k = input.Text:gsub("%s","")
        if isKeyValid(k) then
            done = true
            sg:Destroy()
        else
            status.Text = "Invalid key or HWID blocked"
        end
    end)

    while not done and sg.Parent do task.wait(0.1) end
    return done
end

if not promptKey() then
    return warn("[KV1ZZ] Access denied")
end

local KEY_LABEL = "PAID"

-- ==================== CONFIG ====================
local CFG = {
    ESP = { Enabled=true, Boxes=true, Names=true, Roles=true, Distance=true, Tracers=true,
            HealthBar=true, Skeleton=false, Chams=false, Offscreen=false, MaxDist=800 },
    Aim = { Enabled=true, FOV=120, Smooth=0.25, WallCheck=true, TeamCheck=true,
            Priority="Closest", Predict=0.05, Randomize=true },
    Silent = { Enabled=true, FOV=200, WallCheck=false },
    Knife = { Skin="Default", Rainbow=false, Trail=false, Effect="None" },
    Auto = { AutoKnife=true, AutoShoot=true, AutoPickup=true, AutoDodge=false,
             AutoRound=false, RoleRevealAll=false },
    Move = { Fly=false, FlySpeed=60, Speed=false, SpeedValue=35,
             Jump=false, JumpPower=80, NoClip=false, InfJump=false, AntiFling=false },
    Misc = { Fullbright=true, RoleAlert=true, JoinLeave=true, ClickTP=false, Watermark=true },
    Colors = {
        Murderer = Color3.fromRGB(255,70,70),
        Sheriff  = Color3.fromRGB(70,150,255),
        Innocent = Color3.fromRGB(80,230,120),
        Unknown  = Color3.fromRGB(200,200,200),
        Accent   = Color3.fromRGB(120,220,255),
        Accent2  = Color3.fromRGB(255,170,80),
        Bg       = Color3.fromRGB(12,10,18),
        Bg2      = Color3.fromRGB(22,18,30),
        Line     = Color3.fromRGB(48,42,62),
        Text     = Color3.fromRGB(230,225,245),
        TextDim  = Color3.fromRGB(150,145,170),
    }
}

-- ==================== STATE ====================
local espCache, chamsCache = {}, {}
local currentTarget = nil
local flyConn, flyBodyVel, flyBodyGyro
local noclipConn
local mainFrame, toggleBtn, toggleBtnInner, list, tabBar, statusLabel
local activeTab = "Main"

-- ==================== HELPERS ====================
local function isAlive(plr)
    local c = plr.Character; if not c then return false end
    local h = c:FindFirstChildOfClass("Humanoid")
    return h and h.Health > 0
end
local function getRoot(plr)
    local c = plr.Character; return c and c:FindFirstChild("HumanoidRootPart")
end
local function hasLOS(a, b)
    local p = RaycastParams.new()
    p.FilterType = Enum.RaycastFilterType.Exclude
    p.FilterDescendantsInstances = {LocalPlayer.Character}
    local hit = Workspace:Raycast(a.Position, b.Position - a.Position, p)
    return hit == nil or hit.Instance:IsDescendantOf(b.Parent)
end
local function roleOf(plr)
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
local function notify(t, x, d)
    pcall(function() StarterGui:SetCore("SendNotification",
        {Title=t or "KV1ZZ", Text=x or "", Duration=d or 3}) end)
end

-- ==================== AIM ====================
local function scoreTarget(plr, part)
    local root = getRoot(LocalPlayer); if not root then return math.huge end
    if CFG.Aim.Priority == "LowHP" then
        local h = plr.Character:FindFirstChildOfClass("Humanoid")
        return h and h.Health or math.huge
    elseif CFG.Aim.Priority == "Screen" then
        local sp, on = Camera:WorldToViewportPoint(part.Position)
        if not on then return math.huge end
        local c = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
        return (Vector2.new(sp.X, sp.Y) - c).Magnitude
    else
        return (part.Position - root.Position).Magnitude
    end
end

local function getClosest(fov, wallCheck, teamCheck)
    local best, bd = nil, math.huge
    local center = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
    local myRoot = getRoot(LocalPlayer)
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr == LocalPlayer or not isAlive(plr) then continue end
        if teamCheck and plr.Team and plr.Team == LocalPlayer.Team then continue end
        local char = plr.Character; if not char then continue end
        local part = char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart")
        if not part then continue end
        if wallCheck and myRoot and not hasLOS(myRoot, part) then continue end
        local sp, on = Camera:WorldToViewportPoint(part.Position)
        if not on then continue end
        local d = (Vector2.new(sp.X, sp.Y) - center).Magnitude
        if d < fov then
            local sc = scoreTarget(plr, part)
            if sc < bd then best, bd = plr, sc end
        end
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
    local t = getClosest(CFG.Aim.FOV, CFG.Aim.WallCheck, CFG.Aim.TeamCheck)
    currentTarget = t
    if not t or not t.Character then return end
    local part = t.Character:FindFirstChild("Head") or t.Character:FindFirstChild("HumanoidRootPart")
    if not part then return end
    local pos = part.Position
    if CFG.Aim.Predict > 0 then
        local vel = part.AssemblyLinearVelocity or Vector3.zero
        pos = pos + vel * CFG.Aim.Predict
    end
    local desired = CFrame.lookAt(Camera.CFrame.Position, pos)
    if CFG.Aim.Randomize then
        desired = desired * CFrame.Angles(
            math.rad(math.random(-10,10)/100), math.rad(math.random(-10,10)/100), 0)
    end
    if CFG.Aim.Smooth <= 0 then Camera.CFrame = desired
    else Camera.CFrame = Camera.CFrame:Lerp(desired, 1 - CFG.Aim.Smooth) end
end)

-- ==================== SILENT ====================
pcall(function()
    if hookmetamethod and getnamecallmethod then
        local old
        old = hookmetamethod(game, "__namecall", function(self, ...)
            if CFG.Silent.Enabled and getnamecallmethod() == "Raycast" and self == Workspace then
                local origin = ...
                local t = getClosest(CFG.Silent.FOV, CFG.Silent.WallCheck, CFG.Aim.TeamCheck)
                if t and t.Character then
                    local part = t.Character:FindFirstChild("Head") or t.Character:FindFirstChild("HumanoidRootPart")
                    if part then return old(self, origin, part.Position - origin, ...) end
                end
            end
            return old(self, ...)
        end)
    end
end)

-- ==================== ESP ====================
local function makeESP(key)
    if espCache[key] then return espCache[key] end
    local t = {}
    t.box = Drawing.new("Square"); t.box.Thickness=1; t.box.Filled=false; t.box.Transparency=1
    t.name = Drawing.new("Text"); t.name.Size=14; t.name.Center=true; t.name.Outline=true
    t.dist = Drawing.new("Text"); t.dist.Size=12; t.dist.Center=true; t.dist.Outline=true
    t.role = Drawing.new("Text"); t.role.Size=13; t.role.Center=true; t.role.Outline=true
    t.tracer = Drawing.new("Line"); t.tracer.Thickness=1; t.tracer.Transparency=0.6
    t.hpBg = Drawing.new("Line"); t.hpBg.Thickness=3; t.hpBg.Transparency=0.7
    t.hpFg = Drawing.new("Line"); t.hpFg.Thickness=3; t.hpFg.Transparency=1
    espCache[key] = t
    return t
end
local function hideESP(t)
    for _, d in pairs(t) do d.Visible = false end
end
local function updateESP()
    for _, t in pairs(espCache) do hideESP(t) end
    if not CFG.ESP.Enabled then return end
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr == LocalPlayer or not isAlive(plr) then continue end
        local char = plr.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        local head = char and char:FindFirstChild("Head")
        local hum  = char and char:FindFirstChildOfClass("Humanoid")
        if not root or not head or not hum then continue end
        local dv = (root.Position - Camera.CFrame.Position).Magnitude
        if dv > CFG.ESP.MaxDist then continue end
        local top, bot = worldToScreenTop(head.Position), worldToScreenBot(root.Position)
        if not top or not bot then continue end
        local t = makeESP(plr)
        local r = roleOf(plr); local col = roleColor(r)
        local h = bot.Y - top.Y; local w = h * 0.6
        if CFG.ESP.Boxes then
            t.box.Size = Vector2.new(w, h)
            t.box.Position = Vector2.new(top.X - w/2, top.Y)
            t.box.Color = col; t.box.Visible = true
        end
        if CFG.ESP.Names then
            t.name.Text = plr.Name
            t.name.Position = Vector2.new(top.X, top.Y - 18)
            t.name.Color = col; t.name.Visible = true
        end
        if CFG.ESP.Roles then
            t.role.Text = r
            t.role.Position = Vector2.new(top.X, bot.Y + 2)
            t.role.Color = col; t.role.Visible = true
        end
        if CFG.ESP.Distance then
            t.dist.Text = string.format("[%d]", math.floor(dv))
            t.dist.Position = Vector2.new(top.X, bot.Y + 16)
            t.dist.Color = col; t.dist.Visible = true
        end
        if CFG.ESP.Tracers then
            t.tracer.From = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y)
            t.tracer.To = Vector2.new(top.X, bot.Y)
            t.tracer.Color = col; t.tracer.Visible = true
        end
        if CFG.ESP.HealthBar then
            local ratio = math.clamp(hum.Health / math.max(hum.MaxHealth,1), 0, 1)
            local x = top.X - w/2 - 6
            t.hpBg.From = Vector2.new(x, top.Y); t.hpBg.To = Vector2.new(x, bot.Y)
            t.hpBg.Color = Color3.fromRGB(60,60,70); t.hpBg.Visible = true
            t.hpFg.From = Vector2.new(x, bot.Y - h*ratio); t.hpFg.To = Vector2.new(x, bot.Y)
            t.hpFg.Color = Color3.fromRGB(90,220,120); t.hpFg.Visible = true
        end
        if CFG.ESP.Chams then
            local ch = chamsCache[plr]
            if not ch then
                ch = Instance.new("Highlight")
                ch.Name = "KV1ZZ_Cham"
                ch.FillTransparency = 0.65
                ch.OutlineTransparency = 0
                ch.Adornee = char
                ch.Parent = char
                chamsCache[plr] = ch
            end
            ch.FillColor = col
        end
    end
end

function worldToScreenTop(pos)
    local sp, on = Camera:WorldToViewportPoint(pos + Vector3.new(0,1.5,0))
    if not on then return nil end
    return Vector2.new(sp.X, sp.Y)
end
function worldToScreenBot(pos)
    local sp, on = Camera:WorldToViewportPoint(pos - Vector3.new(0,3,0))
    if not on then return nil end
    return Vector2.new(sp.X, sp.Y)
end

-- ==================== KNIFE VISUALS ====================
local function applyKnifeVisuals()
    local c = LocalPlayer.Character; if not c then return end
    for _, t in ipairs(c:GetChildren()) do
        if t:IsA("Tool") and t.Name:lower():find("knife") then
            local handle = t:FindFirstChild("Handle")
            if not handle then continue end
            if CFG.Knife.Rainbow then
                local hue = (tick() * 0.5) % 1
                handle.Color = Color3.fromHSV(hue, 1, 1)
            end
            if CFG.Knife.Trail then
                if not handle:FindFirstChild("KV1ZZ_Trail") then
                    local a0 = Instance.new("Attachment", handle)
                    local a1 = Instance.new("Attachment", handle)
                    a0.Position = Vector3.new(0, -0.5, 0)
                    a1.Position = Vector3.new(0, 0.5, 0)
                    local tr = Instance.new("Trail")
                    tr.Name = "KV1ZZ_Trail"
                    tr.Attachment0 = a0
                    tr.Attachment1 = a1
                    tr.Lifetime = 0.5
                    tr.Color = ColorSequence.new(CFG.Colors.Accent)
                    tr.Parent = handle
                end
            else
                local tr = handle:FindFirstChild("KV1ZZ_Trail")
                if tr then tr:Destroy() end
            end
        end
    end
end
RunService.Heartbeat:Connect(applyKnifeVisuals)

-- ==================== FLY / MOVE ====================
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
task.spawn(function()
    while task.wait(0.2) do
        if CFG.Move.NoClip and LocalPlayer.Character then
            for _, p in ipairs(LocalPlayer.Character:GetDescendants()) do
                if p:IsA("BasePart") and p.CanCollide then p.CanCollide = false end
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
RunService.Heartbeat:Connect(function()
    if not CFG.Move.AntiFling then return end
    local c = LocalPlayer.Character; if not c then return end
    local root = c:FindFirstChild("HumanoidRootPart"); if not root then return end
    for _, v in ipairs(root:GetChildren()) do
        if v:IsA("BodyAngularVelocity") or v:IsA("BodyVelocity") or v:IsA("BodyForce") then
            if v.Name ~= "KV1ZZ_Fly" then pcall(function() v:Destroy() end) end
        end
    end
end)

-- ==================== AUTO ====================
local function getMyTool()
    local c = LocalPlayer.Character; if not c then return nil end
    return c:FindFirstChildOfClass("Tool")
end
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
        if CFG.Auto.AutoPickup then
            for _, obj in ipairs(Workspace:GetChildren()) do
                if obj:IsA("Tool") and not obj:IsDescendantOf(c) then
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
        if CFG.Auto.AutoDodge then
            local t = nearestInRange(12)
            if t and t.Character and roleOf(t) == "Murderer" then
                local tRoot = getRoot(t)
                if tRoot then
                    local dir = (myRoot.Position - tRoot.Position).Unit
                    myRoot.CFrame = myRoot.CFrame + dir * 4
                end
            end
        end
    end
end)

-- ==================== MISC ====================
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
        local r = roleOf(LocalPlayer)
        if r ~= last then last = r; notify("KV1ZZ HUB", "Роль: " .. r, 3) end
    end
end)
Players.PlayerAdded:Connect(function(plr)
    if CFG.Misc.JoinLeave then notify("+", plr.Name, 2) end
end)
Players.PlayerRemoving:Connect(function(plr)
    if CFG.Misc.JoinLeave then notify("-", plr.Name, 2) end
    if espCache[plr] then
        for _, d in pairs(espCache[plr]) do pcall(function() d:Remove() end) end
        espCache[plr] = nil
    end
    if chamsCache[plr] then pcall(function() chamsCache[plr]:Destroy() end); chamsCache[plr] = nil end
end)

-- ==================== UI ====================
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
    Name="KV1ZZ_MM2_Paid", ResetOnSpawn=false,
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
    Size=UDim2.fromOffset(340, 500),
    Position=UDim2.new(0, 80, 0.08, 
