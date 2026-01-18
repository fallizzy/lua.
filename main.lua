local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

local Window = Fluent:CreateWindow({
    Title = "Ryuma Hub | Universal v1.0",
    SubTitle = "by Gemini",
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 460),
    Acrylic = true, 
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.RightControl
})

local Tabs = {
    Main = Window:AddTab({ Title = "Karakter", Icon = "user" }),
    Visuals = Window:AddTab({ Title = "Görsel (ESP)", Icon = "eye" }),
    Misc = Window:AddTab({ Title = "Araçlar", Icon = "box" }),
    Settings = Window:AddTab({ Title = "Ayarlar", Icon = "settings" })
}

local Options = Fluent.Options
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local LocalPlayer = Players.LocalPlayer

-- --- ÖZELLİK FONKSİYONLARI ---

-- Fullbright (Karanlığı Kaldır)
local function toggleFullbright(state)
    if state then
        Lighting.Brightness = 2
        Lighting.ClockTime = 14
        Lighting.FogEnd = 100000
        Lighting.GlobalShadows = false
        Lighting.OutdoorAmbient = Color3.fromRGB(128, 128, 128)
    else
        Lighting.GlobalShadows = true -- Oyunu eski haline döndürmek zordur, genelde rejoin gerekir
    end
end

-- Spin (Mevlana Modu)
local spinVelocity
local function toggleSpin(state, speed)
    if spinVelocity then spinVelocity:Destroy() end
    if state and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        spinVelocity = Instance.new("BodyAngularVelocity")
        spinVelocity.Name = "Spinbot"
        spinVelocity.Parent = LocalPlayer.Character.HumanoidRootPart
        spinVelocity.MaxTorque = Vector3.new(0, math.huge, 0)
        spinVelocity.AngularVelocity = Vector3.new(0, speed, 0)
    end
end

-- ESP Yöneticisi
local EspFolder = Instance.new("Folder", game.CoreGui)
EspFolder.Name = "RyumaESP"
local function updateESP(enableBox, enableName, enableTracer)
    EspFolder:ClearAllChildren()
    if not (enableBox or enableName or enableTracer) then return end

    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
            -- Kutu (Highlight)
            if enableBox then
                local hl = Instance.new("Highlight")
                hl.Adornee = plr.Character
                hl.FillTransparency = 0.5
                hl.OutlineColor = Color3.fromRGB(255, 0, 0)
                hl.FillColor = Color3.fromRGB(255, 0, 0)
                hl.Parent = EspFolder
            end
            
            -- İsim (BillboardGui)
            if enableName then
                local bg = Instance.new("BillboardGui")
                bg.Adornee = plr.Character.Head
                bg.Size = UDim2.new(0, 100, 0, 50)
                bg.StudsOffset = Vector3.new(0, 2, 0)
                bg.AlwaysOnTop = true
                
                local txt = Instance.new("TextLabel", bg)
                txt.Size = UDim2.new(1, 0, 1, 0)
                txt.BackgroundTransparency = 1
                txt.TextColor3 = Color3.new(1, 1, 1)
                txt.TextStrokeTransparency = 0
                txt.Text = plr.Name
                bg.Parent = EspFolder
            end
        end
    end
end

-- --- UI ELEMENTLERİ ---

-- Karakter Sekmesi
Tabs.Main:AddSlider("WalkSpeed", {
    Title = "Yürüme Hızı", Min = 16, Max = 300, Default = 16, Rounding = 0,
    Callback = function(Value) if LocalPlayer.Character then LocalPlayer.Character.Humanoid.WalkSpeed = Value end end
})

Tabs.Main:AddSlider("JumpPower", {
    Title = "Zıplama Gücü", Min = 50, Max = 300, Default = 50, Rounding = 0,
    Callback = function(Value) if LocalPlayer.Character then LocalPlayer.Character.Humanoid.JumpPower = Value end end
})

Tabs.Main:AddToggle("InfiniteJump", { Title = "Sınırsız Zıplama", Default = false }):OnChanged(function()
    local connection
    if Options.InfiniteJump.Value then
        connection = game:GetService("UserInputService").JumpRequest:Connect(function()
            if LocalPlayer.Character then LocalPlayer.Character.Humanoid:ChangeState("Jumping") end
        end)
    end
end)

-- Görsel Sekmesi
local EspBoxToggle = Tabs.Visuals:AddToggle("EspBox", { Title = "ESP Box (Kutu)", Default = false })
local EspNameToggle = Tabs.Visuals:AddToggle("EspName", { Title = "ESP Name (İsim)", Default = false })

-- ESP Döngüsü (Her saniye yeniler)
task.spawn(function()
    while true do
        if Options.EspBox.Value or Options.EspName.Value then
            updateESP(Options.EspBox.Value, Options.EspName.Value, false)
        else
            EspFolder:ClearAllChildren()
        end
        task.wait(1)
    end
end)

Tabs.Visuals:AddToggle("Fullbright", { Title = "Fullbright (Karanlığı Sil)", Default = false }):OnChanged(function()
    toggleFullbright(Options.Fullbright.Value)
end)

-- Araçlar Sekmesi
Tabs.Misc:AddButton({
    Title = "Rejoin Server (Tekrar Gir)",
    Callback = function()
        game:GetService("TeleportService"):Teleport(game.PlaceId, LocalPlayer)
    end
})

Tabs.Misc:AddButton({
    Title = "Server Hop (Başka Sunucu)",
    Callback = function()
        -- Basit Server Hop mantığı
        local Http = game:GetService("HttpService")
        local TPS = game:GetService("TeleportService")
        local Api = "https://games.roblox.com/v1/games/"
        local _place = game.PlaceId
        local _servers = Api.._place.."/servers/Public?sortOrder=Asc&limit=100"
        
        local function ListServers(cursor)
            local Raw = game:HttpGet(_servers .. ((cursor and "&cursor="..cursor) or ""))
            return Http:JSONDecode(Raw)
        end
        
        local Server, Next; repeat
            local Servers = ListServers(Next)
            Server = Servers.data[math.random(1, #Servers.data)]
            Next = Servers.nextPageCursor
        until Server.playing < Server.maxPlayers and Server.id ~= game.JobId
        
        TPS:TeleportToPlaceInstance(_place, Server.id, LocalPlayer)
    end
})

Tabs.Misc:AddToggle("Spinbot", { Title = "Spinbot (Dönme)", Default = false }):OnChanged(function()
    if Options.Spinbot.Value then
        toggleSpin(true, 50)
    else
        toggleSpin(false)
    end
end)


-- Ayarlar Kaydı
SaveManager:SetLibrary(Fluent)
InterfaceManager:SetLibrary(Fluent)
SaveManager:IgnoreThemeSettings()
InterfaceManager:BuildInterfaceSection(Tabs.Settings)
SaveManager:BuildConfigSection(Tabs.Settings)

Window:SelectTab(1)
Fluent:Notify({ Title = "Ryuma Hub", Content = "Script başarıyla yüklendi!", Duration = 5 })
