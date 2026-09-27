-- language: Lua (Roblox), env: Delta APK, game: Steal an Egg
-- KV1ZZ HUB — steal an egg edition

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace        = game:GetService("Workspace")
local TweenService     = game:GetService("TweenService")
local StarterGui       = game:GetService("StarterGui")
local LocalPlayer      = Players.LocalPlayer
local Camera           = Workspace.CurrentCamera

local CFG = {
    ESP = { Enabled=true, Eggs=true, Names=true, Distance=true, MaxDist=2000,
            Biomes = { ["Forest"]=true, ["Lake"]=true, ["Desert"]=true,
                       ["Jungle"]=true, ["Snow"]=true, ["Volcano"]=true,
                       ["Abyss Ocean"]=true, ["Prehistoric"]=true,
                       ["Cosmic"]=true, ["Cherry Blossom"]=true } },
    Farm = { AutoSteal=false, Biome="Forest", Rarity="Any",
             AutoTreadmill=false, AutoHatch=false, AutoEquip=false },
    Move = { Speed=false, SpeedValue=1000, InfJump=false },
    Misc = { AntiAFK=true, Fullbright=true, TPToSpawn=true },
    Colors = {
        Accent = Color3.fromRGB(120, 220, 255),
        Accent2= Color3.fromRGB(255, 170, 80),
        Egg    = Color3.fromRGB(255, 215, 0),
        Common = Color3.fromRGB(180, 180, 180),
        Rare   = Color3.fromRGB(80, 160, 255),
        Epic   = Color3.fromRGB(180, 80, 255),
        Legend = Color3.fromRGB(255, 160, 40),
        Mythic = Color3.fromRGB(255, 80, 80),
        Secret = Color3.fromRGB(255, 60, 200),
        Bg     = Color3.fromRGB(12, 10, 18),
        Bg2    = Color3.fromRGB(22, 18, 30),
        Line   = Color3.fromRGB(48, 42, 62),
        Text   = Color3.fromRGB(230, 225, 245),
        TextDim= Color3.fromRGB(150, 145, 170),
    }
}

-- Биомы и их скорость (из гайда) [citation:1][citation:6][citation:15]
local BIOMES = {
    { Name="Forest",       Speed=0,          Guardian="Chicken" },
    { Name="Lake",         Speed=900,        Guardian="Swan" },
    { Name="Desert",       Speed=10000,      Guardian="Scorpion" },
    { Name="Jungle",       Speed=40000,      Guardian="Tiger" },
    { Name="Snow",         Speed=170000,     Guardian="Yeti" },
    { Name="Volcano",      Speed=700000,     Guardian="Cerberus" },
    { Name="Abyss Ocean",  Speed=2500000,    Guardian="Beluga Whale" },
    { Name="Prehistoric",  Speed=18000000,   Guardian="T-Rex" },
    { Name="Cosmic",       Speed=700000000,  Guardian="Cosmic Skeleton Boss" },
    { Name="Cherry Blossom",Speed=2500000000,Guardian="Oni Tiger" },
}

-- Редкости
local RARITIES = {"Common","Uncommon","Rare","Epic","Legendary","Mythic","Cosmic","Secret","Eternal","Divine"}

local espCache = {}
local mainFrame, toggleBtn, toggleBtnInner, list, statusLabel
local eggs = {}
local lastScan = 0

local function getRoot(plr)
    local c = plr.Character; return c and c:FindFirstChild("HumanoidRootPart")
end
local function notify(t, x, d)
    pcall(function() StarterGui:SetCore("SendNotification",
        {Title=t or "KV1ZZ", Text=x or "", Duration=d or 3}) end)
end
local function detectRarity(nm)
    local n = nm:lower()
    if n:find("secret") then return "Secret" end
    if n:find("eternal") then return "Eternal" end
    if n:find("divine") then return "Divine" end
    if n:find("cosmic") or n:find("leviathan") or n:find("sphinx") then return "Cosmic" end
    if n:find("mythic") or n:find("spider") or n:find("mammoth") then return "Mythic" end
    if n:find("legend") or n:find("brr") or n:find("axolotl") then return "Legendary" end
    if n:find("epic") or n:find("fox") or n:find("swan") then return "Epic" end
    if n:find("rare") or n:find("owl") or n:find("turtle") then return "Rare" end
    if n:find("uncommon") or n:find("bird") then return "Uncommon" end
    return "Common"
end
local function rarityColor(r)
    local map = { Common=CFG.Colors.Common, Uncommon=CFG.Colors.Common,
                  Rare=CFG.Colors.Rare, Epic=CFG.Colors.Epic,
                  Legendary=CFG.Colors.Legend, Mythic=CFG.Colors.Mythic,
                  Cosmic=CFG.Colors.Mythic, Secret=CFG.Colors.Secret,
                  Eternal=CFG.Colors.Secret, Divine=CFG.Colors.Secret }
    return map[r] or CFG.Colors.Egg
end

local function isEgg(nm)
    local n = nm:lower()
    return n:find("egg") or n:find("яйц") or n:find("nest")
end

local function scanEggs()
    if os.clock() - lastScan < 1.5 then return end
    lastScan = os.clock()
    eggs = {}
    pcall(function()
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj:IsA("BasePart") and isEgg(obj.Name) then
                local rarity = detectRarity(obj.Name)
                table.insert(eggs, { part=obj, name=obj.Name, rarity=rarity })
            elseif obj:IsA("Model") and isEgg(obj.Name) then
                local p = obj:FindFirstChild("HumanoidRootPart") or obj:FindFirstChildWhichIsA("BasePart")
                if p then
                    local rarity = detectRarity(obj.Name)
                    table.insert(eggs, { part=p, name=obj.Name, rarity=rarity, model=obj })
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
    if not CFG.ESP.Enabled or not CFG.ESP.Eggs then return end
    scanEggs()
    for _, e in ipairs(eggs) do
        local t = makeESP(e.part)
        local pos = e.part.Position
        local dv = (pos - Camera.CFrame.Position).Magnitude
        if dv > CFG.ESP.MaxDist then hide(t); continue end
        local sp, on = Camera:WorldToViewportPoint(pos)
        if not on then hide(t); continue end
        local col = rarityColor(e.rarity)
        t.box.Size = Vector2.new(40, 40)
        t.box.Position = Vector2.new(sp.X - 20, sp.Y - 20)
        t.box.Color = col; t.box.Visible = true
        if CFG.ESP.Names then
            t.name.Text = "[" .. e.rarity .. "] " .. e.name
            t.name.Position = Vector2.new(sp.X, sp.Y - 32)
            t.name.Color = col; t.name.Visible = true
        end
        if CFG.ESP.Distance then
            t.dist.Text = string.format("[%d]", math.floor(dv))
            t.dist.Position = Vector2.new(sp.X, sp.Y + 22)
            t.dist.Color = col; t.dist.Visible = true
        end
    end
end

-- Auto Steal
local function findTargetEgg()
    local root = getRoot(LocalPlayer); if not root then return nil end
    scanEggs()
    local best, bd = nil, math.huge
    for _, e in ipairs(eggs) do
        if CFG.Farm.Rarity ~= "Any" and e.rarity ~= CFG.Farm.Rarity then continue end
        local d = (e.part.Position - root.Position).Magnitude
        if d < bd then best, bd = e, d end
    end
    return best
end

task.spawn(function()
    while task.wait(0.5) do
        if not CFG.Farm.AutoSteal then continue end
        local target = findTargetEgg()
        if target then
            local root = getRoot(LocalPlayer)
            if root then
                pcall(function()
                    root.CFrame = CFrame.new(target.part.Position + Vector3.new(0, 3, 0))
                    task.wait(0.15)
                    local m = target.model or target.part
                    for _, d in ipairs(m:GetDescendants()) do
                        if d:IsA("ProximityPrompt") then fireproximityprompt(d) end
                        if d:IsA("ClickDetector") then fireclickdetector(d) end
                    end
                    firetouchinterest(root, target.part, 0)
                    task.wait(0.05)
                    firetouchinterest(root, target.part, 1)
                end)
            end
        end
    end
end)

-- Auto Treadmill
task.spawn(function()
    while task.wait(1) do
        if not CFG.Farm.AutoTreadmill then continue end
        local root = getRoot(LocalPlayer); if not root then return end
        pcall(function()
            for _, obj in ipairs(Workspace:GetDescendants()) do
                if (obj:IsA("BasePart") or obj:IsA("Model"))
                and obj.Name:lower():find("treadmill") then
                    local p = obj:IsA("BasePart") and obj or obj:FindFirstChildWhichIsA("BasePart")
                    if p and (p.Position - root.Position).Magnitude < 30 then
                        for _, d in ipairs(obj:GetDescendants()) do
                            if d:IsA("ProximityPrompt") then fireproximityprompt(d) end
                            if d:IsA("ClickDetector") then fireclickdetector(d) end
                        end
                    end
                end
            end
        end)
    end
end)

-- Auto Hatch
task.spawn(function()
    while task.wait(1) do
        if not CFG.Farm.AutoHatch then continue end
        local root = getRoot(LocalPlayer); if not root then return end
        pcall(function()
            for _, obj in ipairs(Workspace:GetDescendants()) do
                if obj.Name:lower():find("hatch") or obj.Name:lower():find("incubator") then
                    local p = obj:IsA("BasePart") and obj or obj:FindFirstChildWhichIsA("BasePart")
                    if p and (p.Position - root.Position).Magnitude < 30 then
                        for _, d in ipairs(obj:GetDescendants()) do
                            if d:IsA("ProximityPrompt") then fireproximityprompt(d) end
                            if d:IsA("ClickDetector") then fireclickdetector(d) end
                        end
                    end
                end
            end
        end)
    end
end)

-- Auto Equip Best
task.spawn(function()
    while task.wait(2) do
        if not CFG.Farm.AutoEquip then continue end
        pcall(function()
            local gui = LocalPlayer:FindFirstChild("PlayerGui")
            if gui then
                for _, d in ipairs(gui:GetDescendants()) do
                    if d:IsA("TextButton") and d.Text:lower():find("equip best") then
                        d.MouseButton1Click:Fire()
                    end
                end
            end
        end)
    end
end)

-- Speed / InfJump
task.spawn(function()
    while task.wait(0.3) do
        local c = LocalPlayer.Character
        if c then
            local hum = c:FindFirstChildOfClass("Humanoid")
            if hum and CFG.Move.Speed then
                hum.WalkSpeed = CFG.Move.SpeedValue
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

-- Anti-AFK / Fullbright
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
    Name="KV1ZZ_StealEgg", ResetOnSpawn=false,
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
    Size=UDim2.fromOffset(310, 480),
    Position=UDim2.new(0, 80, 0.1, 0),
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
    BackgroundTransparency=1, Text="steal an egg edition",
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
toggleRow("Eggs",        function() return CFG.ESP.Eggs end, function(v) CFG.ESP.Eggs=v end)
toggleRow("Names",       function() return CFG.ESP.Names end, function(v) CFG.ESP.Names=v end)
toggleRow("Distance",    function() return CFG.ESP.Distance end, function(v) CFG.ESP.Distance=v end)

section("Farm")
toggleRow("Auto steal",    function() return CFG.Farm.AutoSteal end, function(v) CFG.Farm.AutoSteal=v end)
toggleRow("Auto treadmill",function() return CFG.Farm.AutoTreadmill end, function(v) CFG.Farm.AutoTreadmill=v end)
toggleRow("Auto hatch",    function() return CFG.Farm.AutoHatch end, function(v) CFG.Farm.AutoHatch=v end)
toggleRow("Auto equip best",function() return CFG.Farm.AutoEquip end, function(v) CFG.Farm.AutoEquip=v end)

section("Movement")
toggleRow("Speed boost", function() return CFG.Move.Speed end, function(v) CFG.Move.Speed=v end)
toggleRow("Infinite jump",function() return CFG.Move.InfJump end, function(v) CFG.Move.InfJump=v end)
sliderRow("Speed value", 16, 1000000, function() return CFG.Move.SpeedValue end, function(v) CFG.Move.SpeedValue=v end)

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
            statusLabel.Text = string.format("eggs %d · speed %d",
                #eggs, CFG.Move.SpeedValue)
        end
    end
end)

notify("KV1ZZ HUB", "Steal an Egg loaded — tap K", 3)
