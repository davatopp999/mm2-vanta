-- language: Lua (Roblox), env: Delta APK, game: Murder Mystery 2
-- KV1ZZ HUB · PAID EDITION · v5 (watermark + key expiry)

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace        = game:GetService("Workspace")
local Lighting         = game:GetService("Lighting")
local TweenService     = game:GetService("TweenService")
local StarterGui       = game:GetService("StarterGui")
local HttpService      = game:GetService("HttpService")
local Stats            = game:GetService("Stats")
local LocalPlayer      = Players.LocalPlayer
local Camera           = Workspace.CurrentCamera

-- ==================== KEY SYSTEM ====================
local KEY_URL = "https://raw.githubusercontent.com/davatopp999/mm2-vanta/refs/heads/main/keys.json"
local MY_HWID = tostring(LocalPlayer.UserId)
local ACTIVE_KEY = ""

local function isKeyValid(k)
    if not k or k == "" then return false, "no key" end
    local ok, raw = pcall(function() return game:HttpGet(KEY_URL) end)
    if not ok or not raw then return false, "network" end
    local ok2, data = pcall(function() return HttpService:JSONDecode(raw) end)
    if not ok2 or type(data) ~= "table" then return false, "json" end
    local now = os.time()
    for _, entry in ipairs(data.keys or {}) do
        if entry.key == k then
            if entry.banned then return false, "banned" end
            if entry.hwid and entry.hwid ~= MY_HWID and entry.hwid ~= "any" then
                return false, "hwid"
            end
            if entry.expires and entry.expires > 0 and now > entry.expires then
                return false, "expired"
            end
            return true, "ok"
        end
    end
    return false, "invalid"
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
    bg.BackgroundTransparency = 0.35
    bg.BorderSizePixel = 0
    bg.Parent = sg

    local box = Instance.new("Frame")
    box.Size = UDim2.fromOffset(340, 210)
    box.Position = UDim2.new(0.5,-170,0.5,-105)
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
    status.Position = UDim2.new(0,10,0,180)
    status.BackgroundTransparency = 1
    status.Text = "HWID: " .. MY_HWID
    status.TextColor3 = Color3.fromRGB(150,145,170)
    status.TextSize = 11
    status.Font = Enum.Font.Gotham
    status.Parent = box

    local done = false
    btn.MouseButton1Click:Connect(function()
        local k = input.Text:gsub("%s","")
        local ok, reason = isKeyValid(k)
        if ok then
            ACTIVE_KEY = k
            done = true
            sg:Destroy()
        else
            status.Text = "Denied: " .. reason
            status.TextColor3 = Color3.fromRGB(255,120,120)
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
            HealthBar=true, Skeleton=false, Chams=false, MaxDist=800 },
    Aim = { Enabled=true, FOV=120, Smooth=0.25, WallCheck=true, TeamCheck=true,
            Priority="Closest", Predict=0.05, Randomize=true },
    Silent = { Enabled=true, FOV=200, WallCheck=false },
    Knife = { Rainbow=false, Trail=false },
    Auto = { AutoKnife=true, AutoShoot=true, AutoPickup=true, AutoDodge=false },
    Move = { Fly=false, FlySpeed=60, Speed=false, SpeedValue=35,
             Jump=false, JumpPower=80, NoClip=false, InfJump=false, AntiFling=false },
    Misc = { Fullbright=true, RoleAlert=true, JoinLeave=true, Watermark=true },
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

local espCache, chamsCache = {}, {}
local currentTarget = nil
local flyConn, flyBodyVel, flyBodyGyro
local mainFrame, toggleBtn, toggleBtnInner, list, tabBar, statusLabel
local watermark, wmLabel
local activeTab = "Main"
local joinTime = os.time()

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
RunService.Heartbeat:Connect(function()
    local c = LocalPlayer.Character; if not c then return end
    for _, t in ipairs(c:GetChildren()) do
        if t:IsA("Tool") and t.Name:lower():find("knife") then
            local handle = t:FindFirstChild("Handle"); if not handle then continue end
            if CFG.Knife.Rainbow then
                local hue = (tick() * 0.5) % 1
                handle.Color = Color3.fromHSV(hue, 1, 1)
            end
            if CFG.Knife.Trail then
                if not handle:FindFirstChild("KV1ZZ_Trail") then
                    local a0 = Instance.new("Attachment", handle)
                    local a1 = Instance.new("Attachment", handle)
                    a0.Position = Vector3.new(0,-0.5,0); a1.Position = Vector3.new(0,0.5,0)
                    local tr = Instance.new("Trail")
                    tr.Name = "KV1ZZ_Trail"; tr.Attachment0 = a0; tr.Attachment1 = a1
                    tr.Lifetime = 0.5; tr.Color = ColorSequence.new(CFG.Colors.Accent)
                    tr.Parent = handle
                end
            else
                local tr = handle:FindFirstChild("KV1ZZ_Trail")
                if tr then tr:Destroy() end
            end
        end
    end
end)

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

-- Watermark
watermark = new("Frame", {
    Size=UDim2.fromOffset(220,58),
    Position=UDim2.new(1,-236,0,12),
    BackgroundColor3=CFG.Colors.Bg, BorderSizePixel=0, Parent=gui,
})
corner(watermark, 10); stroke(watermark, CFG.Colors.Accent, 1)
new("TextLabel", {
    Size=UDim2.new(1,0,0,20), Position=UDim2.new(0,10,0,4),
    BackgroundTransparency=1, Text="KV1ZZ HUB · PAID",
    TextColor3=CFG.Colors.Accent, TextSize=13, Font=Enum.Font.GothamBlack,
    TextXAlignment=Enum.TextXAlignment.Left, Parent=watermark,
})
wmLabel = new("TextLabel", {
    Size=UDim2.new(1,-20,0,32), Position=UDim2.new(0,10,0,22),
    BackgroundTransparency=1, Text="loading...",
    TextColor3=CFG.Colors.TextDim, TextSize=10, Font=Enum.Font.Gotham,
    TextXAlignment=Enum.TextXAlignment.Left, TextYAlignment=Enum.TextYAlignment.Top,
    TextWrapped=true, Parent=watermark,
})

-- Toggle
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

-- Main frame
mainFrame = new("Frame", {
    Size=UDim2.fromOffset(340, 500),
    Position=UDim2.new(0, 80, 0.08, 0),
    BackgroundColor3=CFG.Colors.Bg, BorderSizePixel=0, Visible=false, Parent=gui,
})
corner(mainFrame, 14); stroke(mainFrame, CFG.Colors.Accent, 1)

local header = new("Frame", {
    Size=UDim2.new(1,0,0,52),
    BackgroundColor3=CFG.Colors.Bg2, BorderSizePixel=0, Parent=mainFrame,
})
corner(header, 14)
new("Frame", {
    Size=UDim2.new(1,0,0,16), Position=UDim2.new(0,0,1,-16),
    BackgroundColor3=CFG.Colors.Bg2, BorderSizePixel=0, Parent=header,
})
new("TextLabel", {
    Size=UDim2.new(1,-70,0,22), Position=UDim2.new(0,14,0,6),
    BackgroundTransparency=1, Text="KV1ZZ HUB · PAID",
    TextColor3=CFG.Colors.Accent, TextSize=16, Font=Enum.Font.GothamBlack,
    TextXAlignment=Enum.TextXAlignment.Left, Parent=header,
})
statusLabel = new("TextLabel", {
    Size=UDim2.new(1,-70,0,16), Position=UDim2.new(0,14,0,28),
    BackgroundTransparency=1, Text="key valid · ready",
    TextColor3=CFG.Colors.TextDim, TextSize=11, Font=Enum.Font.Gotham,
    TextXAlignment=Enum.TextXAlignment.Left, Parent=header,
})
local hideBtn = new("TextButton", {
    Size=UDim2.fromOffset(28,28), Position=UDim2.new(1,-36,0,11),
    BackgroundColor3=CFG.Colors.Line, Text="×",
    TextColor3=CFG.Colors.Text, TextSize=18, Font=Enum.Font.GothamBold, Parent=header,
})
corner(hideBtn, 8)
hideBtn.MouseButton1Click:Connect(function() mainFrame.Visible=false end)

-- Tab bar
tabBar = new("Frame", {
    Size=UDim2.new(1,-20,0,30), Position=UDim2.new(0,10,0,58),
    BackgroundColor3=CFG.Colors.Bg2, BorderSizePixel=0, Parent=mainFrame,
})
corner(tabBar, 8)
new("UIListLayout", {
    FillDirection=Enum.FillDirection.Horizontal,
    Padding=UDim.new(0,4), VerticalAlignment=Enum.VerticalAlignment.Center,
    Parent=tabBar,
})
new("UIPadding", {
    PaddingLeft=UDim.new(0,6), PaddingRight=UDim.new(0,6), Parent=tabBar,
})

list = new("ScrollingFrame", {
    Size=UDim2.new(1,-20,1,-100), Position=UDim2.new(0,10,0,94),
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
        Size=UDim2.new(1,0,0,30), BackgroundColor3=CFG.Colors.Bg2,
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
        Size=UDim2.new(1,0,0,44), BackgroundColor3=CFG.Colors.Bg2, Parent=list,
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
local function buttonRow(label, cb)
    local row = new("TextButton", {
        Size=UDim2.new(1,0,0,30), BackgroundColor3=CFG.Colors.Bg2,
        Text="", AutoButtonColor=false, Parent=list,
    })
    corner(row, 8); stroke(row, CFG.Colors.Accent2, 1)
    new("TextLabel", {
        Size=UDim2.fromScale(1,1), BackgroundTransparency=1,
        Text=label, TextColor3=CFG.Colors.Accent2,
        TextSize=13, Font=Enum.Font.GothamBold, Parent=row,
    })
    row.MouseButton1Click:Connect(cb)
end

local function clearList()
    for _, c in ipairs(list:GetChildren()) do
        if c:IsA("GuiObject") then c:Destroy() end
    end
end

local tabs = {}
local function addTab(name)
    local btn = new("TextButton", {
        Size=UDim2.fromOffset(70,22), BackgroundColor3=CFG.Colors.Line,
        Text="", AutoButtonColor=false, Parent=tabBar,
    })
    corner(btn, 6)
    local lbl = new("TextLabel", {
        Size=UDim2.fromScale(1,1), BackgroundTransparency=1,
        Text=name, TextColor3=CFG.Colors.TextDim,
        TextSize=11, Font=Enum.Font.GothamBold, Parent=btn,
    })
    btn.MouseButton1Click:Connect(function()
        activeTab = name
        for _, t in pairs(tabs) do
            t.lbl.TextColor3 = CFG.Colors.TextDim
            t.btn.BackgroundColor3 = CFG.Colors.Line
        end
        lbl.TextColor3 = CFG.Colors.Accent
        btn.BackgroundColor3 = CFG.Colors.Bg
        buildTab(name)
    end)
    tabs[name] = {btn = btn, lbl = lbl}
end

function buildTab(name)
    clearList()
    if name == "Main" then
        section("ESP")
        toggleRow("ESP enabled", function() return CFG.ESP.Enabled end, function(v) CFG.ESP.Enabled=v end)
        toggleRow("Boxes",   function() return CFG.ESP.Boxes end,   function(v) CFG.ESP.Boxes=v end)
        toggleRow("Names",   function() return CFG.ESP.Names end,   function(v) CFG.ESP.Names=v end)
        toggleRow("Roles",   function() return CFG.ESP.Roles end,   function(v) CFG.ESP.Roles=v end)
        toggleRow("Distance",function() return CFG.ESP.Distance end,function(v) CFG.ESP.Distance=v end)
        toggleRow("Tracers", function() return CFG.ESP.Tracers end, function(v) CFG.ESP.Tracers=v end)
        toggleRow("Health bar", function() return CFG.ESP.HealthBar end, function(v) CFG.ESP.HealthBar=v end)
        toggleRow("Chams",   function() return CFG.ESP.Chams end,   function(v) CFG.ESP.Chams=v end)
    elseif name == "Aimbot" then
        section("Aimbot")
        toggleRow("Enabled",   function() return CFG.Aim.Enabled end, function(v) CFG.Aim.Enabled=v end)
        toggleRow("Wall check",function() return CFG.Aim.WallCheck end, function(v) CFG.Aim.WallCheck=v end)
        toggleRow("Team check",function() return CFG.Aim.TeamCheck end, function(v) CFG.Aim.TeamCheck=v end)
        toggleRow("Randomize", function() return CFG.Aim.Randomize end, function(v) CFG.Aim.Randomize=v end)
        sliderRow("FOV", 20, 400, function() return CFG.Aim.FOV end, function(v) CFG.Aim.FOV=v end)
        sliderRow("Smooth x100", 0, 100, function() return math.floor(CFG.Aim.Smooth*100) end,
            function(v) CFG.Aim.Smooth=v/100 end)
        sliderRow("Predict x100", 0, 30, function() return math.floor(CFG.Aim.Predict*100) end,
            function(v) CFG.Aim.Predict=v/100 end)
        buttonRow("Priority: Closest", function() CFG.Aim.Priority = "Closest"; notify("KV1ZZ","Closest") end)
        buttonRow("Priority: Low HP",  function() CFG.Aim.Priority = "LowHP";   notify("KV1ZZ","Low HP") end)
        buttonRow("Priority: Screen",  function() CFG.Aim.Priority = "Screen";  notify("KV1ZZ","Screen") end)
    elseif name == "Silent" then
        section("Silent Aim")
        toggleRow("Silent enabled", function() return CFG.Silent.Enabled end, function(v) CFG.Silent.Enabled=v end)
        toggleRow("Silent wall",    function() return CFG.Silent.WallCheck end, function(v) CFG.Silent.WallCheck=v end)
        sliderRow("Silent FOV", 20, 500, function() return CFG.Silent.FOV end, function(v) CFG.Silent.FOV=v end)
    elseif name == "Knives" then
        section("Knife Visuals")
        toggleRow("Rainbow", function() return CFG.Knife.Rainbow end, function(v) CFG.Knife.Rainbow=v end)
        toggleRow("Trail",   function() return CFG.Knife.Trail end,   function(v) CFG.Knife.Trail=v end)
    elseif name == "Movement" then
        section("Movement")
        toggleRow("Fly",   function() return CFG.Move.Fly end,   function(v) CFG.Move.Fly=v end)
        toggleRow("Speed", function() return CFG.Move.Speed end, function(v) CFG.Move.Speed=v end)
        toggleRow("Jump",  function() return CFG.Move.Jump end,  function(v) CFG.Move.Jump=v end)
        toggleRow("NoClip",function() return CFG.Move.NoClip end,function(v) CFG.Move.NoClip=v end)
        toggleRow("Inf Jump", function() return CFG.Move.InfJump end, function(v) CFG.Move.InfJump=v end)
        toggleRow("Anti-Fling", function() return CFG.Move.AntiFling end, function(v) CFG.Move.AntiFling=v end)
        sliderRow("FlySpeed", 10, 200, function() return CFG.Move.FlySpeed end, function(v) CFG.Move.FlySpeed=v end)
        sliderRow("WalkSpeed",16, 200, function() return CFG.Move.SpeedValue end, function(v) CFG.Move.SpeedValue=v end)
    elseif name == "Auto" then
        section("Auto")
        toggleRow("AutoKnife",  function() return CFG.Auto.AutoKnife end,  function(v) CFG.Auto.AutoKnife=v end)
        toggleRow("AutoShoot",  function() return CFG.Auto.AutoShoot end,  function(v) CFG.Auto.AutoShoot=v end)
        toggleRow("AutoPickup", function() return CFG.Auto.AutoPickup end, function(v) CFG.Auto.AutoPickup=v end)
        toggleRow("AutoDodge",  function() return CFG.Auto.AutoDodge end,  function(v) CFG.Auto.AutoDodge=v end)
    elseif name == "Misc" then
        section("Misc")
        toggleRow("Fullbright", function() return CFG.Misc.Fullbright end, function(v)
            CFG.Misc.Fullbright = v
            if v then pcall(function()
                Lighting.Ambient = Color3.fromRGB(180,180,180)
                Lighting.Brightness = 2; Lighting.ClockTime = 14
                Lighting.FogEnd = 1e6; Lighting.GlobalShadows = false
            end) end
        end)
        toggleRow("Role alert",  function() return CFG.Misc.RoleAlert end, function(v) CFG.Misc.RoleAlert=v end)
        toggleRow("Join/Leave",  function() return CFG.Misc.JoinLeave end, function(v) CFG.Misc.JoinLeave=v end)
        toggleRow("Watermark",   function() return CFG.Misc.Watermark end, function(v) CFG.Misc.Watermark=v end)
    elseif name == "Key" then
        section("Session")
        new("TextLabel", {
            Size=UDim2.new(1,0,0,60), BackgroundTransparency=1,
            Text="Key: " .. ACTIVE_KEY .. "\nHWID: " .. MY_HWID .. "\nEdition: " .. KEY_LABEL,
            TextColor3=CFG.Colors.Text, TextSize=12, Font=Enum.Font.Gotham,
            TextWrapped=true, TextXAlignment=Enum.TextXAlignment.Left, Parent=list,
        })
    end
end

for _, t in ipairs({"Main","Aimbot","Silent","Knives","Movement","Auto","Misc","Key"}) do
    addTab(t)
end
buildTab("Main")
tabs["Main"].lbl.TextColor3 = CFG.Colors.Accent
tabs["Main"].btn.BackgroundColor3 = CFG.Colors.Bg

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

-- Watermark updater
task.spawn(function()
    local frames = 0
    local lastFps = 60
    RunService.RenderStepped:Connect(function()
        frames = frames + 1
    end)
    while gui.Parent do
        task.wait(1)
        lastFps = frames
        frames = 0
        local ping = 0
        pcall(function() ping = math.floor(LocalPlayer:GetNetworkPing() * 1000) end)
        local inGame = os.time() - joinTime
        local h = math.floor(inGame / 3600)
        local m = math.floor((inGame % 3600) / 60)
        local s = inGame % 60
        if wmLabel and CFG.Misc.Watermark then
            watermark.Visible = true
            wmLabel.Text = string.format(
                "%s | %s\n%02d:%02d:%02d | FPS %d | %dms | %d online",
                LocalPlayer.Name, ACTIVE_KEY,
                h, m, s, lastFps, ping, #Players:GetPlayers())
        else
            watermark.Visible = false
        end
        if statusLabel then
            statusLabel.Text = string.format("key ok · %d online · %dms",
                #Players:GetPlayers(), ping)
        end
    end
end)

notify("KV1ZZ HUB", "PAID edition loaded", 3)
