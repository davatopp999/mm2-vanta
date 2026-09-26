-- language: Lua (Roblox), env: Delta APK, game: Steal a Brainrot
-- KV1ZZ HUB — brainrot edition

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
    ESP = { Enabled=true, Brainrots=true, Players=true, Names=true, Prices=true,
            Distance=true, MaxDist=1200 },
    Steal = { Auto=false, Range=80, TPOnClick=true },
    Buy   = { Auto=false, OnlySelected=true, MaxPrice=1e12,
              Rarities = { Common=true, Rare=true, Epic=true, Legendary=true,
                           Mythic=true, Secret=true },
              Selected = {} },
    Move  = { Speed=false, SpeedValue=50, Jump=false, JumpPower=90,
              Fly=false, FlySpeed=80, Invisible=false, NoClip=false },
    Auto  = { CollectCash=false, AntiAFK=true },
    Colors = {
        Accent = Color3.fromRGB(180, 140, 255),
        Accent2= Color3.fromRGB(120, 220, 255),
        Brainrot = Color3.fromRGB(120, 220, 255),
        Mine     = Color3.fromRGB(120, 255, 140),
        Player   = Color3.fromRGB(255, 120, 120),
        Bg       = Color3.fromRGB(12, 10, 18),
        Bg2      = Color3.fromRGB(22, 18, 32),
        Line     = Color3.fromRGB(48, 42, 65),
        Text     = Color3.fromRGB(230, 225, 245),
        TextDim  = Color3.fromRGB(150, 145, 170),
    }
}

local espCache = {}
local flyConn, flyBodyVel, flyBodyGyro
local invConn
local mainFrame, toggleBtn, toggleBtnInner, list, statusLabel
local brainrotCatalog = {}      -- {name, model, price, rarity}
local lastScan = 0

local function getRoot(plr)
    local c = plr.Character; return c and c:FindFirstChild("HumanoidRootPart")
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

-- ==== SCAN ====
local function detectRarity(name)
    local n = name:lower()
    if n:find("secret") then return "Secret" end
    if n:find("mythic") or n:find("mythical") then return "Mythic" end
    if n:find("legend") then return "Legendary" end
    if n:find("epic") then return "Epic" end
    if n:find("rare") then return "Rare" end
    return "Common"
end

local function getPriceFromModel(model)
    local gui = model:FindFirstChildWhichIsA("BillboardGui", true)
        or model:FindFirstChildWhichIsA("SurfaceGui", true)
    if gui then
        for _, d in ipairs(gui:GetDescendants()) do
            if d:IsA("TextLabel") then
                local s = d.Text:gsub("[^%d]", "")
                local n = tonumber(s)
                if n and n > 0 then return n end
            end
        end
    end
    return 0
end

local function scanBrainrots()
    local now = os.clock()
    if now - lastScan < 1.5 then return brainrotCatalog end
    lastScan = now
    brainrotCatalog = {}
    local ok = pcall(function()
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj:IsA("Model") then
                local part = obj:FindFirstChild("HumanoidRootPart") or obj:FindFirstChild("Head")
                if part and not Players:GetPlayerFromCharacter(obj) then
                    local nm = obj.Name
                    if #nm > 0 and nm ~= "Baseplate" then
                        table.insert(brainrotCatalog, {
                            model = obj, part = part, name = nm,
                            price = getPriceFromModel(obj),
                            rarity = detectRarity(nm),
                        })
                    end
                end
            end
        end
    end)
    return brainrotCatalog
end

local function getBrainrots()
    if #brainrotCatalog == 0 or os.clock() - lastScan > 1.5 then
        return scanBrainrots()
    end
    return brainrotCatalog
end

-- ==== ESP ====
local function makeESP(key)
    if espCache[key] then return espCache[key] end
    local t = {}
    t.box = Drawing.new("Square"); t.box.Thickness=1; t.box.Filled=false; t.box.Transparency=1
    t.name = Drawing.new("Text"); t.name.Size=14; t.name.Center=true; t.name.Outline=true
    t.dist = Drawing.new("Text"); t.dist.Size=12; t.dist.Center=true; t.dist.Outline=true
    t.price = Drawing.new("Text"); t.price.Size=12; t.price.Center=true; t.price.Outline=true
    espCache[key] = t
    return t
end
local function hide(t)
    t.box.Visible=false; t.name.Visible=false
    t.dist.Visible=false; t.price.Visible=false
end
local function updateESP()
    for _, t in pairs(espCache) do hide(t) end
    if CFG.ESP.Brainrots then
        for _, b in ipairs(getBrainrots()) do
            local t = makeESP(b.model)
            local pos = b.part.Position
            local dv = (pos - Camera.CFrame.Position).Magnitude
            if dv > CFG.ESP.MaxDist then hide(t); continue end
            local sp, on = Camera:WorldToViewportPoint(pos)
            if not on then hide(t); continue end
            t.box.Size = Vector2.new(60, 80)
            t.box.Position = Vector2.new(sp.X - 30, sp.Y - 40)
            t.box.Color = CFG.Colors.Brainrot; t.box.Visible = true
            if CFG.ESP.Names then
                t.name.Text = b.name .. " (" .. b.rarity .. ")"
                t.name.Position = Vector2.new(sp.X, sp.Y - 56)
                t.name.Color = CFG.Colors.Brainrot; t.name.Visible = true
            end
            if CFG.ESP.Prices and b.price > 0 then
                t.price.Text = "$" .. tostring(b.price)
                t.price.Position = Vector2.new(sp.X, sp.Y + 42)
                t.price.Color = CFG.Colors.Mine; t.price.Visible = true
            end
            if CFG.ESP.Distance then
                t.dist.Text = string.format("[%d]", math.floor(dv))
                t.dist.Position = Vector2.new(sp.X, sp.Y + 58)
                t.dist.Color = CFG.Colors.Brainrot; t.dist.Visible = true
            end
        end
    end
    if CFG.ESP.Players then
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr == LocalPlayer then continue end
            local root = getRoot(plr)
            if not root then continue end
            local hum = plr.Character:FindFirstChildOfClass("Humanoid")
            if not hum or hum.Health <= 0 then continue end
            local t = makeESP(plr)
            local pos = root.Position
            local dv = (pos - Camera.CFrame.Position).Magnitude
            if dv > CFG.ESP.MaxDist then hide(t); continue end
            local sp, on = Camera:WorldToViewportPoint(pos)
            if not on then hide(t); continue end
            t.box.Size = Vector2.new(40, 60)
            t.box.Position = Vector2.new(sp.X - 20, sp.Y - 50)
            t.box.Color = CFG.Colors.Player; t.box.Visible = true
            t.name.Text = plr.Name
            t.name.Position = Vector2.new(sp.X, sp.Y - 68)
            t.name.Color = CFG.Colors.Player; t.name.Visible = true
            t.dist.Text = string.format("[%d]", math.floor(dv))
            t.dist.Position = Vector2.new(sp.X, sp.Y + 14)
            t.dist.Color = CFG.Colors.Player; t.dist.Visible = true
        end
    end
end

-- ==== ACTIONS ====
local function tpTo(model)
    local root = getRoot(LocalPlayer)
    local part = model:FindFirstChild("HumanoidRootPart") or model:FindFirstChild("Head")
    if root and part then
        root.CFrame = CFrame.new(part.Position + Vector3.new(0, 2, 0))
    end
end
local function stealNearest(range)
    range = range or CFG.Steal.Range
    local root = getRoot(LocalPlayer); if not root then return end
    local best, bd = nil, range
    for _, b in ipairs(getBrainrots()) do
        local d = (b.part.Position - root.Position).Magnitude
        if d < bd then best, bd = b, d end
    end
    if best then
        pcall(function()
            local p = best.model:FindFirstChildWhichIsA("ProximityPrompt", true)
            if p then fireproximityprompt(p) end
            local c = best.model:FindFirstChildWhichIsA("ClickDetector", true)
            if c then fireclickdetector(c) end
        end)
    end
    return best
end

-- Auto buy (пытается нажать Prompt/Purchase у выбранных)
local function autoBuyLoop()
    task.spawn(function()
        while task.wait(0.8) do
            if not CFG.Buy.Auto then continue end
            for _, b in ipairs(getBrainrots()) do
                if CFG.Buy.OnlySelected then
                    if not CFG.Buy.Selected[b.name] then continue end
                else
                    if not CFG.Buy.Rarities[b.rarity] then continue end
                end
                if b.price > CFG.Buy.MaxPrice then continue end
                pcall(function()
                    for _, d in ipairs(b.model:GetDescendants()) do
                        if d:IsA("ProximityPrompt") then fireproximityprompt(d) end
                        if d:IsA("ClickDetector") then fireclickdetector(d) end
                    end
                end)
            end
        end
    end)
end

-- ==== MOVEMENT ====
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
    flyBodyVel.Name = "KV1ZZ_Fly"
    flyBodyVel.MaxForce = Vector3.new(1e5,1e5,1e5)
    flyBodyVel.Velocity = Vector3.zero; flyBodyVel.Parent = root
    flyBodyGyro = Instance.new("BodyGyro")
    flyBodyGyro.Name = "KV1ZZ_Fly"
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
        else
            if flyConn then stopFly() end
        end
    end
end)
task.spawn(function()
    while task.wait(0.25) do
        local c = LocalPlayer.Character
        if not c then continue end
        if CFG.Move.Invisible then
            for _, p in ipairs(c:GetDescendants()) do
                if p:IsA("BasePart") then
                    p.LocalTransparencyModifier = 1
                end
            end
        end
        if CFG.Move.NoClip then
            for _, p in ipairs(c:GetDescendants()) do
                if p:IsA("BasePart") and p.CanCollide then p.CanCollide = false end
            end
        end
    end
end)

-- ==== AUTO ====
task.spawn(function()
    while task.wait(0.5) do
        if CFG.Auto.CollectCash then
            local root = getRoot(LocalPlayer)
            if root then
                for _, obj in ipairs(Workspace:GetDescendants()) do
                    if obj:IsA("BasePart") then
                        local n = obj.Name:lower()
                        if n:find("cash") or n:find("money") or n:find("coin") then
                            if (obj.Position - root.Position).Magnitude < 15 then
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
        end
        if CFG.Auto.AntiAFK then
            pcall(function()
                local VU = game:GetService("VirtualUser")
                VU:CaptureController(); VU:ClickButton2(Vector2.new())
            end)
        end
    end
end)
task.spawn(function()
    while task.wait(0.6) do
        if CFG.Steal.Auto then stealNearest() end
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
    Name="KV1ZZ_Brainrot", ResetOnSpawn=false,
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
    BackgroundTransparency=1, Text="brainrot edition",
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

local function buttonRow(label, cb)
    local row = new("TextButton", {
        Size=UDim2.new(1,0,0,32), BackgroundColor3=CFG.Colors.Bg2,
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

-- ==== BRAINROT PICKER (собираем список уникальных) ====
local pickerRefresh
local function rebuildPicker()
    if pickerRefresh then pcall(pickerRefresh) end
    local seen, uniq = {}, {}
    for _, b in ipairs(getBrainrots()) do
        if not seen[b.name] then
            seen[b.name] = true
            table.insert(uniq, b)
        end
    end
    table.sort(uniq, function(a, c) return a.price > c.price end)

    local heading = new("TextLabel", {
        Size=UDim2.new(1,0,0,20), BackgroundTransparency=1,
        Text="▸ Brainrots to buy (tap to toggle)", TextColor3=CFG.Colors.Accent2,
        TextSize=11, Font=Enum.Font.GothamBold,
        TextXAlignment=Enum.TextXAlignment.Left, Parent=list,
    })
    local created = {heading}
    for _, b in ipairs(uniq) do
        local sel = CFG.Buy.Selected[b.name] == true
        local row = new("TextButton", {
            Size=UDim2.new(1,0,0,30), BackgroundColor3=CFG.Colors.Bg2,
            Text="", AutoButtonColor=false, Parent=list,
        })
        corner(row, 6); stroke(row, sel and CFG.Colors.Accent or CFG.Colors.Line, 1)
        local lbl = new("TextLabel", {
            Size=UDim2.new(1,-50,1,0), Position=UDim2.new(0,10,0,0),
            BackgroundTransparency=1,
            Text="[" .. b.rarity .. "] " .. b.name .. (b.price>0 and " · $"..b.price or ""),
            TextColor3=CFG.Colors.Text, TextSize=12, Font=Enum.Font.Gotham,
            TextXAlignment=Enum.TextXAlignment.Left, Parent=row,
        })
        local mark = new("TextLabel", {
            Size=UDim2.fromOffset(26,26), Position=UDim2.new(1,-32,0.5,-13),
            BackgroundTransparency=1,
            Text=sel and "✓" or "",
            TextColor3=CFG.Colors.Accent, TextSize=16,
            Font=Enum.Font.GothamBold, Parent=row,
        })
        row.MouseButton1Click:Connect(function()
            CFG.Buy.Selected[b.name] = not CFG.Buy.Selected[b.name]
            local on = CFG.Buy.Selected[b.name]
            mark.Text = on and "✓" or ""
            stroke(row, on and CFG.Colors.Accent or CFG.Colors.Line, 1)
        end)
        table.insert(created, row)
    end
    pickerRefresh = function()
        for _, o in ipairs(created) do pcall(function() o:Destroy() end) end
    end
end

-- ==== SECTIONS ====
section("Visuals")
toggleRow("ESP enabled", function() return CFG.ESP.Enabled end, function(v) CFG.ESP.Enabled=v end)
toggleRow("Brainrots",   function() return CFG.ESP.Brainrots end, function(v) CFG.ESP.Brainrots=v end)
toggleRow("Players",     function() return CFG.ESP.Players end, function(v) CFG.ESP.Players=v end)
toggleRow("Names",       function() return CFG.ESP.Names end, function(v) CFG.ESP.Names=v end)
toggleRow("Prices",      function() return CFG.ESP.Prices end, function(v) CFG.ESP.Prices=v end)
toggleRow("Distance",    function() return CFG.ESP.Distance end, function(v) CFG.ESP.Distance=v end)

section("Steal")
toggleRow("Auto steal",  function() return CFG.Steal.Auto end, function(v) CFG.Steal.Auto=v end)
sliderRow("Steal range", 20, 250, function() return CFG.Steal.Range end, function(v) CFG.Steal.Range=v end)
toggleRow("Tap to TP+steal", function() return CFG.Steal.TPOnClick end, function(v) CFG.Steal.TPOnClick=v end)
buttonRow("TP to nearest + steal", function()
    local root = getRoot(LocalPlayer); if not root then return end
    local best, bd = nil, math.huge
    for _, b in ipairs(getBrainrots()) do
        local d = (b.part.Position - root.Position).Magnitude
        if d < bd then best, bd = b, d end
    end
    if best then tpTo(best.model); task.wait(0.2); stealNearest(30) end
end)

section("Auto Buy")
toggleRow("Auto buy",     function() return CFG.Buy.Auto end, function(v) CFG.Buy.Auto=v end)
toggleRow("Only selected",function() return CFG.Buy.OnlySelected end, function(v) CFG.Buy.OnlySelected=v end)
sliderRow("Max price", 0, 1000000, function() return math.min(CFG.Buy.MaxPrice, 1000000) end,
    function(v) CFG.Buy.MaxPrice = v end)
buttonRow("Refresh brainrot list", function() rebuildPicker() end)

section("Brainrots to buy")
rebuildPicker()

section("Movement")
toggleRow("Speed",     function() return CFG.Move.Speed end, function(v) CFG.Move.Speed=v end)
toggleRow("Jump",      function() return CFG.Move.Jump end, function(v) CFG.Move.Jump=v end)
toggleRow("Fly",       function() return CFG.Move.Fly end, function(v) CFG.Move.Fly=v end)
toggleRow("Invisible", function() return CFG.Move.Invisible end, function(v) CFG.Move.Invisible=v end)
toggleRow("NoClip",    function() return CFG.Move.NoClip end, function(v) CFG.Move.NoClip=v end)
sliderRow("WalkSpeed", 16, 250, function() return CFG.Move.SpeedValue end, function(v) CFG.Move.SpeedValue=v end)
sliderRow("FlySpeed",  10, 250, function() return CFG.Move.FlySpeed end, function(v) CFG.Move.FlySpeed=v end)

section("Auto")
toggleRow("Collect cash", function() return CFG.Auto.CollectCash end, function(v) CFG.Auto.CollectCash=v end)
toggleRow("Anti-AFK",     function() return CFG.Auto.AntiAFK end, function(v) CFG.Auto.AntiAFK=v end)

-- toggle open/close
toggleBtn.MouseButton1Click:Connect(function()
    mainFrame.Visible = not mainFrame.Visible
end)

-- drag by header
do
    local drag, ds, sp
    header.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.Touch
        or i.UserInputType==Enum.UserInputType.MouseButton1 then
            drag=true; ds=i.Position; sp=mainFrame.Position
        end
    end)
    User
