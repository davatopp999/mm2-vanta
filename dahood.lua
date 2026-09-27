-- language: Lua (Roblox), env: Delta APK, game: Da Hood
-- KV1ZZ HUB — da hood edition

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace        = game:GetService("Workspace")
local TweenService     = game:GetService("TweenService")
local StarterGui       = game:GetService("StarterGui")
local LocalPlayer      = Players.LocalPlayer
local Camera           = Workspace.CurrentCamera

local CFG = {
    ESP = { Enabled=true, Names=true, Distance=true, MaxDist=1000 },
    Aim = { Enabled=true, FOV=140, Smooth=0.35, Part="Head" },
    Move = { Speed=false, SpeedValue=45, BunnyHop=false },
    Farm = { Enabled=false, Target="Cashiers", Range=25 },
    Colors = {
        Accent = Color3.fromRGB(120, 220, 255),
        Accent2= Color3.fromRGB(255, 170, 80),
        Enemy  = Color3.fromRGB(255, 90, 120),
        Money  = Color3.fromRGB(120, 255, 140),
        Bg     = Color3.fromRGB(12, 10, 18),
        Bg2    = Color3.fromRGB(22, 18, 30),
        Line   = Color3.fromRGB(48, 42, 62),
        Text   = Color3.fromRGB(230, 225, 245),
        TextDim= Color3.fromRGB(150, 145, 170),
    }
}

local espCache = {}
local currentTarget = nil
local mainFrame, toggleBtn, toggleBtnInner, list, statusLabel

local function getRoot(plr)
    local c = plr.Character; return c and c:FindFirstChild("HumanoidRootPart")
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
local function notify(t, x, d)
    pcall(function() StarterGui:SetCore("SendNotification",
        {Title=t or "KV1ZZ", Text=x or "", Duration=d or 3}) end)
end

-- AIMBOT
local function getClosestTarget()
    local best, bd = nil, math.huge
    local center = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr == LocalPlayer or not isAlive(plr) then continue end
        local char = plr.Character; if not char then continue end
        local part = char:FindFirstChild(CFG.Aim.Part) or char:FindFirstChild("HumanoidRootPart")
        if not part then continue end
        local sp, on = Camera:WorldToViewportPoint(part.Position)
        if not on then continue end
        local d = (Vector2.new(sp.X, sp.Y) - center).Magnitude
        if d < CFG.Aim.FOV and d < bd then best, bd = plr, d end
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
    local t = getClosestTarget()
    currentTarget = t
    if not t or not t.Character then return end
    local part = t.Character:FindFirstChild(CFG.Aim.Part) or t.Character:FindFirstChild("HumanoidRootPart")
    if not part then return end
    local desired = CFrame.lookAt(Camera.CFrame.Position, part.Position)
    if CFG.Aim.Smooth <= 0 then Camera.CFrame = desired
    else Camera.CFrame = Camera.CFrame:Lerp(desired, 1 - CFG.Aim.Smooth) end
end)

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
local function updateESP()
    for _, t in pairs(espCache) do hide(t) end
    if not CFG.ESP.Enabled then return end
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr == LocalPlayer or not isAlive(plr) then continue end
        local root = getRoot(plr); if not root then continue end
        local dv = (root.Position - Camera.CFrame.Position).Magnitude
        if dv > CFG.ESP.MaxDist then continue end
        local sp, on = Camera:WorldToViewportPoint(root.Position)
        if not on then continue end
        local t = makeESP(plr)
        t.box.Size = Vector2.new(40, 60)
        t.box.Position = Vector2.new(sp.X - 20, sp.Y - 50)
        t.box.Color = CFG.Colors.Enemy; t.box.Visible = true
        if CFG.ESP.Names then
            t.name.Text = plr.Name
            t.name.Position = Vector2.new(sp.X, sp.Y - 68)
            t.name.Color = CFG.Colors.Enemy; t.name.Visible = true
        end
        if CFG.ESP.Distance then
            t.dist.Text = string.format("[%d]", math.floor(dv))
            t.dist.Position = Vector2.new(sp.X, sp.Y + 14)
            t.dist.Color = CFG.Colors.Enemy; t.dist.Visible = true
        end
    end
end

-- MONEY FARM
task.spawn(function()
    while task.wait(0.5) do
        if not CFG.Farm.Enabled then continue end
        local root = getRoot(LocalPlayer); if not root then continue end
        local best, bd = nil, CFG.Farm.Range
        if CFG.Farm.Target == "Cashiers" then
            local folder = Workspace:FindFirstChild("Cashiers")
            if folder then
                for _, v in ipairs(folder:GetChildren()) do
                    if v:FindFirstChild("Head") and v:FindFirstChild("Humanoid")
                    and v.Humanoid.Health > 0 then
                        local d = (v.Head.Position - root.Position).Magnitude
                        if d < bd then best, bd = v, d end
                    end
                end
            end
        elseif CFG.Farm.Target == "Drops" then
            local ignored = Workspace:FindFirstChild("Ignored")
            if ignored then
                local drop = ignored:FindFirstChild("Drop")
                if drop then
                    for _, v in ipairs(drop:GetDescendants()) do
                        if v:IsA("ClickDetector") and v.Parent
                        and v.Parent.Name:find("Money") then
                            local d = (v.Parent.Position - root.Position).Magnitude
                            if d < bd then best, bd = v, d end
                        end
                    end
                end
            end
        end
        if best then
            local targetPos = (best.Head or best.Parent):GetPivot()
            pcall(function()
                root.CFrame = CFrame.new(targetPos.Position + Vector3.new(0, 3, 0))
                task.wait(0.1)
                local combat = LocalPlayer.Backpack:FindFirstChild("Combat")
                    or LocalPlayer.Character:FindFirstChild("Combat")
                if combat and best:FindFirstChild("Humanoid") then
                    combat:Activate()
                elseif best:IsA("ClickDetector") then
                    fireclickdetector(best)
                end
            end)
        end
    end
end)

-- MOVEMENT
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
    if CFG.Move.BunnyHop and LocalPlayer.Character then
        local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
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
    Name="KV1ZZ_DaHood", ResetOnSpawn=false,
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
    BackgroundTransparency=1, Text="da hood edition",
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

section("Visuals")
toggleRow("ESP enabled", function() return CFG.ESP.Enabled end, function(v) CFG.ESP.Enabled=v end)
toggleRow("Names",       function() return CFG.ESP.Names end, function(v) CFG.ESP.Names=v end)
toggleRow("Distance",    function() return CFG.ESP.Distance end, function(v) CFG.ESP.Distance=v end)

section("Combat")
toggleRow("Aimbot enabled", function() return CFG.Aim.Enabled end, function(v) CFG.Aim.Enabled=v end)
sliderRow("FOV", 20, 400, function() return CFG.Aim.FOV end, function(v) CFG.Aim.FOV=v end)
sliderRow("Smooth x100", 0, 100, function() return math.floor(CFG.Aim.Smooth*100) end,
    function(v) CFG.Aim.Smooth = v/100 end)

section("Movement")
toggleRow("Speed hack", function() return CFG.Move.Speed end, function(v) CFG.Move.Speed=v end)
toggleRow("Bunny hop",  function() return CFG.Move.BunnyHop end, function(v) CFG.Move.BunnyHop=v end)
sliderRow("Speed value", 16, 200, function() return CFG.Move.SpeedValue end, function(v) CFG.Move.SpeedValue=v end)

section("Money Farm")
toggleRow("Auto farm", function() return CFG.Farm.Enabled end, function(v) CFG.Farm.Enabled=v end)
buttonRow("Target: Cashiers", function()
    CFG.Farm.Target = "Cashiers"
    notify("KV1ZZ", "Target: Cashiers")
end)
buttonRow("Target: Drops", function()
    CFG.Farm.Target = "Drops"
    notify("KV1ZZ", "Target: Drops")
end)
sliderRow("Farm range", 5, 100, function() return CFG.Farm.Range end, function(v) CFG.Farm.Range=v end)

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
            statusLabel.Text = string.format("target: %s · speed %d",
                CFG.Farm.Target, CFG.Move.SpeedValue)
        end
    end
end)

notify("KV1ZZ HUB", "Da Hood loaded — tap K", 3)
