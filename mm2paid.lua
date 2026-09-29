-- language: Lua (Roblox), env: Delta APK, game: Murder Mystery 2
-- KV1ZZ HUB · PAID v9 · redesign + polish

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace        = game:GetService("Workspace")
local Lighting         = game:GetService("Lighting")
local TweenService     = game:GetService("TweenService")
local StarterGui       = game:GetService("StarterGui")
local LocalPlayer      = Players.LocalPlayer
local Camera           = Workspace.CurrentCamera

-- ==================== KEYS ====================
local MY_HWID = tostring(LocalPlayer.UserId)
local HOUR, DAY, WEEK, MONTH = 3600, 86400, 604800, 2592000

local KEYS = {
    ["KV1ZZ-TEST-0001"]=0,
    ["KV1ZZ-H-0001"]=HOUR,["KV1ZZ-H-0002"]=HOUR,["KV1ZZ-H-0003"]=HOUR,["KV1ZZ-H-0004"]=HOUR,["KV1ZZ-H-0005"]=HOUR,
    ["KV1ZZ-H-0006"]=HOUR,["KV1ZZ-H-0007"]=HOUR,["KV1ZZ-H-0008"]=HOUR,["KV1ZZ-H-0009"]=HOUR,["KV1ZZ-H-0010"]=HOUR,
    ["KV1ZZ-H-0011"]=HOUR,["KV1ZZ-H-0012"]=HOUR,["KV1ZZ-H-0013"]=HOUR,["KV1ZZ-H-0014"]=HOUR,["KV1ZZ-H-0015"]=HOUR,
    ["KV1ZZ-H-0016"]=HOUR,["KV1ZZ-H-0017"]=HOUR,["KV1ZZ-H-0018"]=HOUR,["KV1ZZ-H-0019"]=HOUR,["KV1ZZ-H-0020"]=HOUR,
    ["KV1ZZ-H-0021"]=HOUR,["KV1ZZ-H-0022"]=HOUR,["KV1ZZ-H-0023"]=HOUR,["KV1ZZ-H-0024"]=HOUR,["KV1ZZ-H-0025"]=HOUR,
    ["KV1ZZ-D-0001"]=DAY,["KV1ZZ-D-0002"]=DAY,["KV1ZZ-D-0003"]=DAY,["KV1ZZ-D-0004"]=DAY,["KV1ZZ-D-0005"]=DAY,
    ["KV1ZZ-D-0006"]=DAY,["KV1ZZ-D-0007"]=DAY,["KV1ZZ-D-0008"]=DAY,["KV1ZZ-D-0009"]=DAY,["KV1ZZ-D-0010"]=DAY,
    ["KV1ZZ-D-0011"]=DAY,["KV1ZZ-D-0012"]=DAY,["KV1ZZ-D-0013"]=DAY,["KV1ZZ-D-0014"]=DAY,["KV1ZZ-D-0015"]=DAY,
    ["KV1ZZ-D-0016"]=DAY,["KV1ZZ-D-0017"]=DAY,["KV1ZZ-D-0018"]=DAY,["KV1ZZ-D-0019"]=DAY,["KV1ZZ-D-0020"]=DAY,
    ["KV1ZZ-D-0021"]=DAY,["KV1ZZ-D-0022"]=DAY,["KV1ZZ-D-0023"]=DAY,["KV1ZZ-D-0024"]=DAY,["KV1ZZ-D-0025"]=DAY,
    ["KV1ZZ-W-0001"]=WEEK,["KV1ZZ-W-0002"]=WEEK,["KV1ZZ-W-0003"]=WEEK,["KV1ZZ-W-0004"]=WEEK,["KV1ZZ-W-0005"]=WEEK,
    ["KV1ZZ-W-0006"]=WEEK,["KV1ZZ-W-0007"]=WEEK,["KV1ZZ-W-0008"]=WEEK,["KV1ZZ-W-0009"]=WEEK,["KV1ZZ-W-0010"]=WEEK,
    ["KV1ZZ-W-0011"]=WEEK,["KV1ZZ-W-0012"]=WEEK,["KV1ZZ-W-0013"]=WEEK,["KV1ZZ-W-0014"]=WEEK,["KV1ZZ-W-0015"]=WEEK,
    ["KV1ZZ-W-0016"]=WEEK,["KV1ZZ-W-0017"]=WEEK,["KV1ZZ-W-0018"]=WEEK,["KV1ZZ-W-0019"]=WEEK,["KV1ZZ-W-0020"]=WEEK,
    ["KV1ZZ-W-0021"]=WEEK,["KV1ZZ-W-0022"]=WEEK,["KV1ZZ-W-0023"]=WEEK,["KV1ZZ-W-0024"]=WEEK,["KV1ZZ-W-0025"]=WEEK,
    ["KV1ZZ-M-0001"]=MONTH,["KV1ZZ-M-0002"]=MONTH,["KV1ZZ-M-0003"]=MONTH,["KV1ZZ-M-0004"]=MONTH,["KV1ZZ-M-0005"]=MONTH,
    ["KV1ZZ-M-0006"]=MONTH,["KV1ZZ-M-0007"]=MONTH,["KV1ZZ-M-0008"]=MONTH,["KV1ZZ-M-0009"]=MONTH,["KV1ZZ-M-0010"]=MONTH,
    ["KV1ZZ-M-0011"]=MONTH,["KV1ZZ-M-0012"]=MONTH,["KV1ZZ-M-0013"]=MONTH,["KV1ZZ-M-0014"]=MONTH,["KV1ZZ-M-0015"]=MONTH,
    ["KV1ZZ-M-0016"]=MONTH,["KV1ZZ-M-0017"]=MONTH,["KV1ZZ-M-0018"]=MONTH,["KV1ZZ-M-0019"]=MONTH,["KV1ZZ-M-0020"]=MONTH,
    ["KV1ZZ-M-0021"]=MONTH,["KV1ZZ-M-0022"]=MONTH,["KV1ZZ-M-0023"]=MONTH,["KV1ZZ-M-0024"]=MONTH,["KV1ZZ-M-0025"]=MONTH,
}
local BANNED_HWID = {}
local ACTIVATIONS = {}

local function actFile() return "kv1zz_act.json" end
local function loadActivations()
    pcall(function()
        if readfile and isfile and isfile(actFile()) then
            local raw = readfile(actFile())
            local data = game:GetService("HttpService"):JSONDecode(raw)
            if type(data) == "table" then ACTIVATIONS = data end
        end
    end)
end
local function saveActivations()
    pcall(function()
        if writefile then
            writefile(actFile(), game:GetService("HttpService"):JSONEncode(ACTIVATIONS))
        end
    end)
end
loadActivations()

local ACTIVE_KEY, KEY_EXPIRES, EXPIRED = "", 0, false

local function isKeyValid(k)
    if not k or k == "" then return false, "no key" end
    if BANNED_HWID[MY_HWID] then return false, "hwid banned" end
    local dur = KEYS[k]
    if dur == nil then return false, "invalid" end
    local started = ACTIVATIONS[k]
    if not started then
        ACTIVATIONS[k] = os.time(); saveActivations(); started = ACTIVATIONS[k]
    end
    if os.time() > started + dur then return false, "expired" end
    KEY_EXPIRES = started + dur
    return true, "ok"
end

local function checkExpired()
    if not ACTIVE_KEY or ACTIVE_KEY == "" then return end
    local dur = KEYS[ACTIVE_KEY]
    if dur == nil then EXPIRED = true; return end
    local started = ACTIVATIONS[ACTIVE_KEY]
    if started and os.time() > started + dur then EXPIRED = true end
end

local function promptKey()
    local sg = Instance.new("ScreenGui")
    sg.Name = "KV1ZZ_KEY"; sg.ResetOnSpawn = false
    sg.IgnoreGuiInset = true; sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    local parent = (function()
        local ok, cg = pcall(function() return game:GetService("CoreGui") end)
        if ok and cg then return cg end
        return LocalPlayer:WaitForChild("PlayerGui")
    end)()
    sg.Parent = parent
    local bg = Instance.new("Frame")
    bg.Size = UDim2.new(1,0,1,0); bg.BackgroundColor3 = Color3.fromRGB(0,0,0)
    bg.BackgroundTransparency = 0.4; bg.BorderSizePixel = 0; bg.Parent = sg
    local box = Instance.new("Frame")
    box.Size = UDim2.fromOffset(360, 240); box.Position = UDim2.new(0.5,-180,0.5,-120)
    box.BackgroundColor3 = Color3.fromRGB(14,14,20); box.BorderSizePixel = 0; box.Parent = sg
    local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0,16); c.Parent = box
    local g = Instance.new("UIGradient")
    g.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(120,220,255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(180,140,255)),
    })
    g.Rotation = 30; g.Parent = box
    local gFix = Instance.new("Frame")
    gFix.Size = UDim2.new(1,-2,1,-2); gFix.Position = UDim2.new(0,1,0,1)
    gFix.BackgroundColor3 = Color3.fromRGB(14,14,20); gFix.BorderSizePixel = 0
    gFix.ZIndex = 2; gFix.Parent = box
    local gc = Instance.new("UICorner"); gc.CornerRadius = UDim.new(0,15); gc.Parent = gFix
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1,-20,0,40); title.Position = UDim2.new(0,10,0,15)
    title.BackgroundTransparency = 1; title.Text = "KV1ZZ HUB"
    title.TextColor3 = Color3.fromRGB(120,220,255); title.TextSize = 22
    title.Font = Enum.Font.GothamBlack; title.ZIndex = 3; title.Parent = box
    local sub = Instance.new("TextLabel")
    sub.Size = UDim2.new(1,-20,0,18); sub.Position = UDim2.new(0,10,0,48)
    sub.BackgroundTransparency = 1; sub.Text = "ACCESS · PAID EDITION"
    sub.TextColor3 = Color3.fromRGB(150,145,170); sub.TextSize = 11
    sub.Font = Enum.Font.Gotham; sub.ZIndex = 3; sub.Parent = box
    local input = Instance.new("TextBox")
    input.Size = UDim2.new(1,-30,0,44); input.Position = UDim2.new(0,15,0,80)
    input.BackgroundColor3 = Color3.fromRGB(22,18,28)
    input.TextColor3 = Color3.fromRGB(230,225,245)
    input.PlaceholderText = "KV1ZZ-XXXX-XXXX"; input.Text = ""
    input.TextSize = 14; input.Font = Enum.Font.Gotham
    input.ClearTextOnFocus = false; input.ZIndex = 3; input.Parent = box
    local ic = Instance.new("UICorner"); ic.CornerRadius = UDim.new(0,10); ic.Parent = input
    local ist = Instance.new("UIStroke"); ist.Color = Color3.fromRGB(60,60,80); ist.Parent = input
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1,-30,0,44); btn.Position = UDim2.new(0,15,0,136)
    btn.BackgroundColor3 = Color3.fromRGB(120,220,255); btn.Text = "ENTER"
    btn.TextColor3 = Color3.fromRGB(14,14,20); btn.TextSize = 15
    btn.Font = Enum.Font.GothamBlack; btn.ZIndex = 3; btn.Parent = box
    local bc = Instance.new("UICorner"); bc.CornerRadius = UDim.new(0,10); bc.Parent = btn
    local status = Instance.new("TextLabel")
    status.Size = UDim2.new(1,-20,0,20); status.Position = UDim2.new(0,10,0,200)
    status.BackgroundTransparency = 1; status.Text = "HWID: " .. MY_HWID
    status.TextColor3 = Color3.fromRGB(120,120,140); status.TextSize = 11
    status.Font = Enum.Font.Gotham; status.ZIndex = 3; status.Parent = box
    local done = false
    btn.MouseButton1Click:Connect(function()
        local k = input.Text:gsub("%s","")
        local ok, reason = isKeyValid(k)
        if ok then ACTIVE_KEY = k; done = true; sg:Destroy()
        else status.Text = "Denied: " .. reason; status.TextColor3 = Color3.fromRGB(255,120,120) end
    end)
    while not done and sg.Parent do task.wait(0.1) end
    return done
end

if not promptKey() then return warn("[KV1ZZ] Access denied") end

-- ==================== CONFIG ====================
local CFG = {
    ESP = { Enabled=true, Boxes=true, Names=true, Roles=true, Distance=true, Tracers=true,
            HealthBar=true, Chams=false, MaxDist=800 },
    Aim = { Enabled=true, Mode="Hold", FOV=120, Smooth=0.25, WallCheck=true, TeamCheck=true,
            Priority="Closest", Predict=0.05, Randomize=true, FreezeCam=false,
            DynamicFOV=false, DynamicFOVMax=250 },
    Silent = { Enabled=true, FOV=200, WallCheck=false },
    Knife = { Rainbow=false, Trail=false },
    Auto = { AutoKnife=true, AutoShoot=true, AutoPickup=true, AutoDodge=false,
             KillAura=false, KillAuraRange=8, AutoReload=false },
    Move = { Fly=false, FlySpeed=60, Speed=false, SpeedValue=35,
             Jump=false, JumpPower=80, NoClip=false, InfJump=false, AntiFling=false },
    Misc = { Fullbright=true, RoleAlert=true, Watermark=true, HitboxExpand=false, HitboxSize=3 },
    Colors = {
        Murderer = Color3.fromRGB(255,70,70),
        Sheriff  = Color3.fromRGB(70,150,255),
        Innocent = Color3.fromRGB(80,230,120),
        Unknown  = Color3.fromRGB(200,200,200),
        Accent   = Color3.fromRGB(120,220,255),
        Accent2  = Color3.fromRGB(180,140,255),
        Bg       = Color3.fromRGB(10,10,16),
        Bg2      = Color3.fromRGB(20,16,28),
        Bg3      = Color3.fromRGB(28,24,38),
        Line     = Color3.fromRGB(48,42,62),
        Text     = Color3.fromRGB(230,225,245),
        TextDim  = Color3.fromRGB(150,145,170),
    }
}

local espCache, chamsCache = {}, {}
local currentTarget = nil
local aimToggle = false
local flyConn, flyBodyVel, flyBodyGyro
local mainFrame, toggleBtn, toggleBtnInner, contentHolder, sideBar, statusLabel
local watermark, wmLabel
local joinTime = os.time()
local activeSection = "Main"

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
    if EXPIRED then return end
    if not CFG.Aim.Enabled then currentTarget = nil; return end
    local active
    if CFG.Aim.Mode == "Toggle" then active = aimToggle
    else active = aimHeld end
    if not active then currentTarget = nil; return end
    local useFov = CFG.Aim.FOV
    if CFG.Aim.DynamicFOV then
        local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum and hum.MoveDirection.Magnitude > 0.1 then
            useFov = math.max(useFov, CFG.Aim.DynamicFOVMax)
        end
    end
    local t = getClosest(useFov, CFG.Aim.WallCheck, CFG.Aim.TeamCheck)
    currentTarget = t
    if not t or not t.Character then return end
    local part = t.Character:FindFirstChild("Head") or t.Character:FindFirstChild("HumanoidRootPart")
    if not part then return end
    local pos = part.Position
    if CFG.Aim.Predict > 0 then
        local vel = part.AssemblyLinearVelocity or Vector3.zero
        pos = pos + vel * CFG.Aim.Predict
    end
    if CFG.Aim.FreezeCam then return end
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
            if EXPIRED then return old(self, ...) end
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
    if EXPIRED or not CFG.ESP.Enabled then return end
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr == LocalPlayer or not isAlive(plr) then continue end
        local char = plr.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        local head = char and char:FindFirstChild("Head")
        local hum  = char and char:FindFirstChildOfClass("Humanoid")
        if not root or not head or not hum then continue end
        local dv = (root.Position - Camera.CFrame.Position).Magnitude
        if dv > CFG.ESP.MaxDist then continue end
        local spTop, onTop = Camera:WorldToViewportPoint(head.Position + Vector3.new(0,1.5,0))
        local spBot, onBot = Camera:WorldToViewportPoint(root.Position - Vector3.new(0,3,0))
        if not onTop or not onBot then continue end
        local top = Vector2.new(spTop.X, spTop.Y); local bot = Vector2.new(spBot.X, spBot.Y)
        local t = makeESP(plr); local r = roleOf(plr); local col = roleColor(r)
        local h = bot.Y - top.Y; local w = h * 0.6
        if CFG.ESP.Boxes then
            t.box.Size = Vector2.new(w, h); t.box.Position = Vector2.new(top.X - w/2, top.Y)
            t.box.Color = col; t.box.Visible = true
        end
        if CFG.ESP.Names then
            t.name.Text = plr.Name; t.name.Position = Vector2.new(top.X, top.Y - 18)
            t.name.Color = col; t.name.Visible = true
        end
        if CFG.ESP.Roles then
            t.role.Text = r; t.role.Position = Vector2.new(top.X, bot.Y + 2)
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
                ch = Instance.new("Highlight"); ch.Name = "KV1ZZ_Cham"
                ch.FillTransparency = 0.65; ch.OutlineTransparency = 0
                ch.Adornee = char; ch.Parent = char; chamsCache[plr] = ch
            end
            ch.FillColor = col
        end
    end
end

-- ==================== KNIVES ====================
RunService.Heartbeat:Connect(function()
    if EXPIRED then return end
    local c = LocalPlayer.Character; if not c then return end
    for _, t in ipairs(c:GetChildren()) do
        if t:IsA("Tool") and t.Name:lower():find("knife") then
            local handle = t:FindFirstChild("Handle"); if not handle then continue end
            if CFG.Knife.Rainbow then
                handle.Color = Color3.fromHSV((tick() * 0.5) % 1, 1, 1)
            end
            if CFG.Knife.Trail then
                if not handle:FindFirstChild("KV1ZZ_Trail") then
                    local a0 = Instance.new("Attachment", handle)
                    local a1 = Instance.new("Attachment", handle)
                    a0.Position = Vector3.new(0,-0.5,0); a1.Position = Vector3.new(0,0.5,0)
                    local tr = Instance.new("Trail"); tr.Name = "KV1ZZ_Trail"
                    tr.Attachment0 = a0; tr.Attachment1 = a1
                    tr.Lifetime = 0.5; tr.Color = ColorSequence.new(CFG.Colors.Accent)
                    tr.Parent = handle
                end
            else
                local tr = handle:FindFirstChild("KV1ZZ_Trail"); if tr then tr:Destroy() end
            end
        end
    end
end)

-- ==================== MOVEMENT ====================
local function stopFly()
    if flyConn then flyConn:Disconnect(); flyConn=nil end
    if flyBodyVel then flyBodyVel:Destroy(); flyBodyVel=nil end
    if flyBodyGyro then flyBodyGyro:Destroy(); flyBodyGyro=nil end
end
local function startFly()
    local c = LocalPlayer.Character; if not c then return end
    local root = c:FindFirstChild("HumanoidRootPart"); if not root then return end
    stopFly()
    flyBodyVel = Instance.new("BodyVelocity"); flyBodyVel.Name="KV1ZZ_Fly"
    flyBodyVel.MaxForce=Vector3.new(1e5,1e5,1e5); flyBodyVel.Velocity=Vector3.zero
    flyBodyVel.Parent=root
    flyBodyGyro = Instance.new("BodyGyro"); flyBodyGyro.Name="KV1ZZ_Fly"
    flyBodyGyro.MaxTorque=Vector3.new(1e5,1e5,1e5); flyBodyGyro.P=1000
    flyBodyGyro.Parent=root
    flyConn = RunService.RenderStepped:Connect(function()
        if EXPIRED then return end
        local hum = c:FindFirstChildOfClass("Humanoid"); if not hum then return end
        local mv = hum.MoveDirection; local cam = Camera.CFrame
        flyBodyVel.Velocity = (cam.LookVector * -mv.Z + cam.RightVector * mv.X) * CFG.Move.FlySpeed
        flyBodyGyro.CFrame = cam
    end)
end
task.spawn(function()
    while task.wait(0.3) do
        if EXPIRED then if flyConn then stopFly() end; continue end
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
        if EXPIRED then continue end
        if CFG.Move.NoClip and LocalPlayer.Character then
            for _, p in ipairs(LocalPlayer.Character:GetDescendants()) do
                if p:IsA("BasePart") and p.CanCollide then p.CanCollide = false end
            end
        end
    end
end)
UserInputService.JumpRequest:Connect(function()
    if EXPIRED then return end
    if CFG.Move.InfJump and LocalPlayer.Character then
        local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end)
RunService.Heartbeat:Connect(function()
    if EXPIRED or not CFG.Move.AntiFling then return end
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
        if EXPIRED then continue end
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
        if CFG.Auto.KillAura then
            local tool = getMyTool()
            if tool then
                for _, plr in ipairs(Players:GetPlayers()) do
                    if plr == LocalPlayer or not isAlive(plr) then continue end
                    local rr = getRoot(plr)
                    if rr and (rr.Position - myRoot.Position).Magnitude < CFG.Auto.KillAuraRange then
                        pcall(function() tool:Activate() end)
                    end
                end
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
        if CFG.Auto.AutoReload then
            local tool = getMyTool()
            if tool then
                for _, v in ipairs(tool:GetDescendants()) do
                    if v:IsA("NumberValue") and v.Name:lower():find("ammo") then v.Value = 100 end
                end
            end
        end
    end
end)

task.spawn(function()
    while task.wait(1) do
        if EXPIRED or not CFG.Misc.HitboxExpand then continue end
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr == LocalPlayer or not plr.Character then continue end
            local hum = plr.Character:FindFirstChildOfClass("Humanoid")
            if hum then pcall(function() hum.HipHeight = CFG.Misc.HitboxSize end) end
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
Players.PlayerRemoving:Connect(function(plr)
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
    Name="KV1ZZ_MM2_Paid", ResetOnSpawn=false,
    ZIndexBehavior=Enum.ZIndexBehavior.Sibling, DisplayOrder=999, IgnoreGuiInset=true,
})
gui.Parent = guiParent()

-- watermark
watermark = new("Frame", {
    Size=UDim2.fromOffset(240,64),
    Position=UDim2.new(1,-256,0,12),
    BackgroundColor3=CFG.Colors.Bg, BorderSizePixel=0, Parent=gui,
})
corner(watermark, 12)
local wGrad = Instance.new("UIGradient")
wGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(120,220,255)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(180,140,255)),
})
wGrad.Rotation = 30; wGrad.Parent = watermark
local wFix = new("Frame", {
    Size=UDim2.new(1,-2,1,-2), Position=UDim2.new(0,1,0,1),
    BackgroundColor3=CFG.Colors.Bg, BorderSizePixel=0, ZIndex=2, Parent=watermark,
})
corner(wFix, 11)
new("TextLabel", {
    Size=UDim2.new(1,0,0,22), Position=UDim2.new(0,12,0,6),
    BackgroundTransparency=1, Text="KV1ZZ HUB · PAID",
    TextColor3=CFG.Colors.Accent, TextSize=14, Font=Enum.Font.GothamBlack,
    TextXAlignment=Enum.TextXAlignment.Left, ZIndex=3, Parent=watermark,
})
wmLabel = new("TextLabel", {
    Size=UDim2.new(1,-24,0,32), Position=UDim2.new(0,12,0,26),
    BackgroundTransparency=1, Text="loading...",
    TextColor3=CFG.Colors.TextDim, TextSize=10, Font=Enum.Font.Gotham,
    TextXAlignment=Enum.TextXAlignment.Left, TextYAlignment=Enum.TextYAlignment.Top,
    TextWrapped=true, ZIndex=3, Parent=watermark,
})

-- toggle K
toggleBtn = new("TextButton", {
    Size=UDim2.fromOffset(56,56), Position=UDim2.new(0,20,0.4,0),
    BackgroundColor3=CFG.Colors.Bg, Text="", AutoButtonColor=false, Parent=gui,
})
corner(toggleBtn, 28)
local tbGrad = Instance.new("UIGradient")
tbGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(120,220,255)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(180,140,255)),
})
tbGrad.Rotation = 45; tbGrad.Parent = toggleBtn
local tbFix = new("Frame", {
    Size=UDim2.new(1,-4,1,-4), Position=UDim2.new(0,2,0,2),
    BackgroundColor3=CFG.Colors.Bg, BorderSizePixel=0, ZIndex=2, Parent=toggleBtn,
})
corner(tbFix, 26)
toggleBtnInner = new("TextLabel", {
    Size=UDim2.fromScale(1,1), BackgroundTransparency=1,
    Text="K", TextColor3=CFG.Colors.Accent,
    TextSize=24, Font=Enum.Font.GothamBlack, ZIndex=3, Parent=toggleBtn,
})
task.spawn(function()
    while gui.Parent do
        tween(toggleBtnInner, 1.4, {TextTransparency=0.4}, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
        task.wait(1.4)
        tween(toggleBtnInner, 1.4, {TextTransparency=0}, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
        task.wait(1.4)
    end
end)

-- main frame
mainFrame = new("Frame", {
    Size=UDim2.fromOffset(520, 380),
    Position=UDim2.new(0.5,-260,0.5,-190),
    BackgroundColor3=CFG.Colors.Bg, BorderSizePixel=0, Visible=false, Parent=gui,
})
corner(mainFrame, 16)
local mGrad = Instance.new("UIGradient")
mGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(120,220,255)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(180,140,255)),
})
mGrad.Rotation = 30; mGrad.Parent = mainFrame
local mFix = new("Frame", {
    Size=UDim2.new(1,-2,1,-2), Position=UDim2.new(0,1,0,1),
    BackgroundColor3=CFG.Colors.Bg, BorderSizePixel=0, ZIndex=2, Parent=mainFrame,
})
corner(mFix, 15)

-- header
local header = new("Frame", {
    Size=UDim2.new(1,0,0,56),
    BackgroundColor3=CFG.Colors.Bg2, BorderSizePixel=0, ZIndex=3, Parent=mainFrame,
})
corner(header, 16)
new("Frame", {
    Size=UDim2.new(1,0,0,16), Position=UDim2.new(0,0,1,-16),
    BackgroundColor3=CFG.Colors.Bg2, BorderSizePixel=0, ZIndex=3, Parent=header,
})
new("TextLabel", {
    Size=UDim2.new(1,-80,0,24), Position=UDim2.new(0,18,0,8),
    BackgroundTransparency=1, Text="KV1ZZ HUB",
    TextColor3=CFG.Colors.Accent, TextSize=18, Font=Enum.Font.GothamBlack,
    TextXAlignment=Enum.TextXAlignment.Left, ZIndex=4, Parent=header,
})
statusLabel = new("TextLabel", {
    Size=UDim2.new(1,-80,0,16), Position=UDim2.new(0,18,0,32),
    BackgroundTransparency=1, Text="key ok · ready",
    TextColor3=CFG.Colors.TextDim, TextSize=11, Font=Enum.Font.Gotham,
    TextXAlignment=Enum.TextXAlignment.Left, ZIndex=4, Parent=header,
})
local hideBtn = new("TextButton", {
    Size=UDim2.fromOffset(30,30), Position=UDim2.new(1,-42,0,13),
    BackgroundColor3=CFG.Colors.Bg3, Text="×",
    TextColor3=CFG.Colors.Text, TextSize=20, Font=Enum.Font.GothamBold,
    ZIndex=4, Parent=header,
})
corner(hideBtn, 10)
hideBtn.MouseButton1Click:Connect(function() mainFrame.Visible=false end)
hideBtn.MouseEnter:Connect(function() tween(hideBtn, 0.15, {BackgroundColor3 = Color3.fromRGB(200,80,80)}) end)
hideBtn.MouseLeave:Connect(function() tween(hideBtn, 0.15, {BackgroundColor3 = CFG.Colors.Bg3}) end)

-- sidebar
sideBar = new("Frame", {
    Size=UDim2.new(0, 130, 1, -72),
    Position=UDim2.new(0, 10, 0, 62),
    BackgroundColor3=CFG.Colors.Bg2, BorderSizePixel=0, ZIndex=3, Parent=mainFrame,
})
corner(sideBar, 12)
local sideList = new("UIListLayout", {
    Padding=UDim.new(0,4), SortOrder=Enum.SortOrder.LayoutOrder, Parent=sideBar,
})
new("UIPadding", {
    PaddingTop=UDim.new(0,8), PaddingBottom=UDim.new(0,8),
    PaddingLeft=UDim.new(0,6), PaddingRight=UDim.new(0,6), Parent=sideBar,
})

-- content holder
contentHolder = new("Frame", {
    Size=UDim2.new(1, -150, 1, -72),
    Position=UDim2.new(0, 140, 0, 62),
    BackgroundTransparency=1, ZIndex=3, Parent=mainFrame,
})
local chLayout = new("UIListLayout", {
    Padding=UDim.new(0,6), SortOrder=Enum.SortOrder.LayoutOrder, Parent=contentHolder,
})
local chScroll = new("ScrollingFrame", {
    Size=UDim2.fromScale(1,1), BackgroundTransparency=1, BorderSizePixel=0,
    ScrollBarThickness=3, ScrollBarImageColor3=CFG.Colors.Line,
    CanvasSize=UDim2.new(0,0,0,0), Parent=contentHolder,
})
chLayout.Parent = chScroll
chScroll:GetPropertyChangedSignal("CanvasSize"):Connect(function() end)
chLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    chScroll.CanvasSize = UDim2.new(0,0,0, chLayout.AbsoluteContentSize.Y + 12)
end)

local function section(text)
    new("TextLabel", {
        Size=UDim2.new(1,0,0,22), BackgroundTransparency=1,
        Text="▸ " .. text, TextColor3=CFG.Colors.Accent2,
        TextSize=12, Font=Enum.Font.GothamBold,
        TextXAlignment=Enum.TextXAlignment.Left, Parent=chScroll,
    })
end
local function toggleRow(label, get, set)
    local row = new("TextButton", {
        Size=UDim2.new(1,0,0,34), BackgroundColor3=CFG.Colors.Bg2,
        Text="", AutoButtonColor=false, Parent=chScroll,
    })
    corner(row, 8); stroke(row, CFG.Colors.Line, 1)
    new("TextLabel", {
        Size=UDim2.new(1,-80,1,0), Position=UDim2.new(0,14,0,0),
        BackgroundTransparency=1, Text=label,
        TextColor3=CFG.Colors.Text, TextSize=13, Font=Enum.Font.Gotham,
        TextXAlignment=Enum.TextXAlignment.Left, Parent=row,
    })
    local box = new("Frame", {
        Size=UDim2.fromOffset(38,22), Position=UDim2.new(1,-52,0.5,-11),
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
        tween(box, 0.2, {BackgroundColor3=v and CFG.Colors.Accent or CFG.Colors.Line},
            Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        tween(knob, 0.2, {Position=v and UDim2.new(1,-18,0,3) or UDim2.new(0,3,0,3)},
            Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    end)
end
local function sliderRow(label, min, max, get, set)
    local row = new("Frame", {
        Size=UDim2.new(1,0,0,48), BackgroundColor3=CFG.Colors.Bg2, Parent=chScroll,
    })
    corner(row, 8); stroke(row, CFG.Colors.Line, 1)
    local lbl = new("TextLabel", {
        Size=UDim2.new(1,-20,0,18), Position=UDim2.new(0,14,0,5),
        BackgroundTransparency=1, Text=label .. ": " .. tostring(get()),
        TextColor3=CFG.Colors.Text, TextSize=13, Font=Enum.Font.Gotham,
        TextXAlignment=Enum.TextXAlignment.Left, Parent=row,
    })
    local bar = new("TextButton", {
        Size=UDim2.new(1,-28,0,12), Position=UDim2.new(0,14,0,28),
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
        Size=UDim2.new(1,0,0,32), BackgroundColor3=CFG.Colors.Bg2,
        Text="", AutoButtonColor=false, Parent=chScroll,
    })
    corner(row, 8); stroke(row, CFG.Colors.Accent2, 1)
    new("TextLabel", {
        Size=UDim2.fromScale(1,1), BackgroundTransparency=1,
        Text=label, TextColor3=CFG.Colors.Accent2,
        TextSize=13, Font=Enum.Font.GothamBold, Parent=row,
    })
    row.MouseButton1Click:Connect(cb)
end

local function clearContent()
    for _, c in ipairs(chScroll:GetChildren()) do
        if c:IsA("GuiObject") then c:Destroy() end
    end
end

local sections = {}
local function addSectionButton(name)
    local btn = new("TextButton", {
        Size=UDim2.new(1,0,0,30), BackgroundColor3=CFG.Colors.Bg3,
        Text="", AutoButtonColor=false, Parent=sideBar,
    })
    corner(btn, 8)
    local lbl = new("TextLabel", {
        Size=UDim2.fromScale(1,1), BackgroundTransparency=1,
        Text=name, TextColor3=CFG.Colors.TextDim,
        TextSize=13, Font=Enum.Font.GothamBold, Parent=btn,
    })
    btn.MouseButton1Click:Connect(function()
        activeSection = name
        for _, s in pairs(sections) do
            s.lbl.TextColor3 = CFG.Colors.TextDim
            s.btn.BackgroundColor3 = CFG.Colors.Bg3
        end
        lbl.TextColor3 = CFG.Colors.Accent
        tween(btn, 0.2, {BackgroundColor3 = CFG.Colors.Bg}, Enum.EasingStyle.Quad)
        buildSection(name)
    end)
    sections[name] = {btn = btn, lbl = lbl}
end

function buildSection(name)
    clearContent()
    if name == "Visuals" then
        section("ESP")
        toggleRow("ESP enabled", function() return CFG.ESP.Enabled end, function(v) CFG.ESP.Enabled=v end)
        toggleRow("Boxes",   function() return CFG.ESP.Boxes end,   function(v) CFG.ESP.Boxes=v end)
        toggleRow("Names",   function() return CFG.ESP.Names end,   function(v) CFG.ESP.Names=v end)
        toggleRow("Roles",   function() return CFG.ESP.Roles end,   function(v) CFG.ESP.Roles=v end)
        toggleRow("Distance",function() return CFG.ESP.Distance end,function(v) CFG.ESP.Distance=v end)
        toggleRow("Tracers", function() return CFG.ESP.Tracers end, function(v) CFG.ESP.Tracers=v end)
        toggleRow("Health bar",function() return CFG.ESP.HealthBar end,function(v) CFG.ESP.HealthBar=v end)
        toggleRow("Chams",   function() return CFG.ESP.Chams end,   function(v) CFG.ESP.Chams=v end)
    elseif name == "Aimbot" then
        section("Aimbot")
        toggleRow("Enabled",   function() return CFG.Aim.Enabled end, function(v) CFG.Aim.Enabled=v end)
        toggleRow("Wall check",function() return CFG.Aim.WallCheck end, function(v) CFG.Aim.WallCheck=v end)
        toggleRow("Team check",function() return CFG.Aim.TeamCheck end, function(v) CFG.Aim.TeamCheck=v end)
        toggleRow("Randomize", function() return CFG.Aim.Randomize end, function(v) CFG.Aim.Randomize=v end)
        toggleRow("Freeze cam",function() return CFG.Aim.FreezeCam end, function(v) CFG.Aim.FreezeCam=v end)
        toggleRow("Dynamic FOV",function() return CFG.Aim.DynamicFOV end, function(v) CFG.Aim.DynamicFOV=v end)
        sliderRow("FOV", 20, 400, function() return CFG.Aim.FOV end, function(v) CFG.Aim.FOV=v end)
        sliderRow("Smooth x100", 0, 100, function() return math.floor(CFG.Aim.Smooth*100) end,
            function(v) CFG.Aim.Smooth=v/100 end)
        sliderRow("Predict x100", 0, 30, function() return math.floor(CFG.Aim.Predict*100) end,
            function(v) CFG.Aim.Predict=v/100 end)
        buttonRow("Mode: Hold",   function() CFG.Aim.Mode="Hold"; notify("KV1ZZ","Mode Hold") end)
        buttonRow("Mode: Toggle", function() CFG.Aim.Mode="Toggle"; notify("KV1ZZ","Mode Toggle") end)
        buttonRow("Priority: Closest", function() CFG.Aim.Priority="Closest"; notify("KV1ZZ","Closest") end)
        buttonRow("Priority: Low HP",  function() CFG.Aim.Priority="LowHP";   notify("KV1ZZ","Low HP") end)
        buttonRow("Priority: Screen",  function() CFG.Aim.Priority="Screen";  notify("KV1ZZ","Screen") end)
    elseif name == "Silent" then
        section("Silent Aim")
        toggleRow("Silent enabled", function() return CFG.Silent.Enabled end, function(v) CFG.Silent.Enabled=v end)
        toggleRow("Silent wall",    function() return CFG.Silent.WallCheck end, function(v) CFG.Silent.WallCheck=v end)
        sliderRow("Silent FOV", 20, 500, function() return CFG.Silent.FOV end, function(v) CFG.Silent.FOV=v end)
    elseif name == "Knives" then
        section("Knife Visuals")
        toggleRow("Rainbow", function() return CFG.Knife.Rainbow end, function(v) CFG.Knife.Rainbow=v end)
        toggleRow("Trail",   function() return CFG.Knife.Trail end,   function(v) CFG.Knife.Trail=v end)
    elseif name == "Auto" then
        section("Auto")
        toggleRow("AutoKnife",  function() return CFG.Auto.AutoKnife end,  function(v) CFG.Auto.AutoKnife=v end)
        toggleRow("AutoShoot",  function() return CFG.Auto.AutoShoot end,  function(v) CFG.Auto.AutoShoot=v end)
        toggleRow("AutoPickup", function() return CFG.Auto.AutoPickup end, function(v) CFG.Auto.AutoPickup=v end)
        toggleRow("AutoDodge",  function() return CFG.Auto.AutoDodge end,  function(v) CFG.Auto.AutoDodge=v end)
        toggleRow("Kill Aura",  function() return CFG.Auto.KillAura end,   function(v) CFG.Auto.KillAura=v end)
        toggleRow("Auto Reload",function() return CFG.Auto.AutoReload end, function(v) CFG.Auto.AutoReload=v end)
        sliderRow("KillAura range", 3, 30, function() return CFG.Auto.KillAuraRange end,
            function(v) CFG.Auto.KillAuraRange=v end)
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
    elseif name == "Misc" then
        section("Misc")
        toggleRow("Fullbright", function() return CFG.Misc.Fullbright end, function(v) CFG.Misc.Fullbright=v end)
        toggleRow("Role alert", function() return CFG.Misc.RoleAlert end, function(v) CFG.Misc.RoleAlert=v end)
        toggleRow("Watermark",  function() return CFG.Misc.Watermark end, function(v) CFG.Misc.Watermark=v end)
        toggleRow("Hitbox expand", function() return CFG.Misc.HitboxExpand end, function(v) CFG.Misc.HitboxExpand=v end)
        sliderRow("Hitbox size", 2, 10, function() return CFG.Misc.HitboxSize end, function(v) CFG.Misc.HitboxSize=v end)
    elseif name == "Key" then
        section("Session")
        local remain = math.max(0, KEY_EXPIRES - os.time())
        local days = math.floor(remain / 86400)
        local hours = math.floor((remain % 86400) / 3600)
        new("TextLabel", {
            Size=UDim2.new(1,0,0,80), BackgroundTransparency=1,
            Text="Key: " .. ACTIVE_KEY .. "\nHWID: " .. MY_HWID
                .. "\nОсталось: " .. days .. "д " .. hours .. "ч",
            TextColor3=EXPIRED and Color3.fromRGB(255,120,120) or CFG.Colors.Text,
            TextSize=13, Font=Enum.Font.Gotham, TextWrapped=true,
            TextXAlignment=Enum.TextXAlignment.Left, Parent=chScroll,
        })
    end
end

for _, s in ipairs({"Visuals","Aimbot","Silent","Knives","Auto","Movement","Misc","Key"}) do
    addSectionButton(s)
end
buildSection("Visuals")
sections["Visuals"].lbl.TextColor3 = CFG.Colors.Accent
sections["Visuals"].btn.BackgroundColor3 = CFG.Colors.Bg

toggleBtn.MouseButton1Click:Connect(function()
    if EXPIRED then notify("KV1ZZ", "KEY EXPIRED", 5); return end
    local wasVisible = mainFrame.Visible
    if not wasVisible then
        mainFrame.Visible = true
        mainFrame.Size = UDim2.fromOffset(480, 350)
        mainFrame.BackgroundTransparency = 1
        tween(mainFrame, 0.24, {
            Size = UDim2.fromOffset(520, 380),
            BackgroundTransparency = 0,
        }, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
    else
        tween(mainFrame, 0.18, {BackgroundTransparency = 1}, Enum.EasingStyle.Quad)
        task.delay(0.18, function() mainFrame.Visible = false; mainFrame.BackgroundTransparency = 0 end)
    end
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
    local frames = 0
    RunService.RenderStepped:Connect(function() frames = frames + 1 end)
    while gui.Parent do
        task.wait(1)
        checkExpired()
        local fps = frames; frames = 0
        local ping = 0
        pcall(function() ping = math.floor(LocalPlayer:GetNetworkPing() * 1000) end)
        local inGame = os.time() - joinTime
        local h = math.floor(inGame / 3600)
        local m = math.floor((inGame % 3600) / 60)
        local s = inGame % 60
        if wmLabel and CFG.Misc.Watermark then
            watermark.Visible = true
            if EXPIRED then
                wmLabel.Text = "EXPIRED · " .. ACTIVE_KEY .. "\nПродлите доступ"
                wmLabel.TextColor3 = Color3.fromRGB(255,120,120)
            else
                wmLabel.Text = string.format(
                    "%s | %s\n%02d:%02d:%02d | FPS %d | %dms | %d online",
                    LocalPlayer.Name, ACTIVE_KEY,
                    h, m, s, fps, ping, #Players:GetPlayers())
                wmLabel.TextColor3 = CFG.Colors.TextDim
            end
        else
            watermark.Visible = false
        end
        if statusLabel then
            statusLabel.Text = EXPIRED and "EXPIRED · key inactive"
                or string.format("key ok · %d online · %dms", #Players:GetPlayers(), ping)
        end
        if EXPIRED and mainFrame.Visible then mainFrame.Visible = false end
    end
end)

task.spawn(function()
    while true do
        task.wait(1)
        if EXPIRED then
            stopFly()
            for _, t in pairs(espCache) do
                for _, d in pairs(t) do pcall(function() d:Remove() end) end
            end
            espCache = {}
            for plr, ch in pairs(chamsCache) do pcall(function() ch:Destroy() end) end
            chamsCache = {}
        end
    end
end)

notify("KV1ZZ HUB", "PAID v9 loaded", 3)
