-- Kütüphaneleri Yükle
local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

local Window = Fluent:CreateWindow({
    Title = "Ryuma Hub | v2.0 Protected",
    SubTitle = "by Gemini",
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 460),
    Acrylic = true, 
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.RightControl
})

local Tabs = {
    Combat = Window:AddTab({ Title = "Combat (Aimbot)", Icon = "swords" }),
    Main = Window:AddTab({ Title = "Karakter", Icon = "user" }),
    Visuals = Window:AddTab({ Title = "Görsel (ESP)", Icon = "eye" }),
    Misc = Window:AddTab({ Title = "Araçlar & Koruma", Icon = "shield" }),
    Settings = Window:AddTab({ Title = "Ayarlar", Icon = "settings" })
}

local Options = Fluent.Options
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

-- --- YARDIMCI FONKSİYONLAR ---

-- En Yakın Oyuncuyu Bul (Aimbot İçin)
local function getClosestPlayer()
    local closestDist = math.huge
    local target = nil
    
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") and plr.Character:FindFirstChild("Humanoid").Health > 0 then
            -- Takım Kontrolü (Varsa)
            if Options.TeamCheck.Value and plr.Team == LocalPlayer.Team then continue end

            local screenPos, onScreen = Camera:WorldToViewportPoint(plr.Character.HumanoidRootPart.Position)
            local mousePos = Vector2.new(Mouse.X, Mouse.Y)
            local dist = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude

            if onScreen and dist < Options.FovRadius.Value then
                if dist < closestDist then
                    closestDist = dist
                    target = plr.Character.HumanoidRootPart
                end
            end
        end
    end
    return target
end

-- --- SEKMELER ---

-- >> COMBAT TAB <<
local AimbotToggle = Tabs.Combat:AddToggle("Aimbot", { Title = "Aimbot (Kamera Kilidi)", Default = false })
Tabs.Combat:AddToggle("TeamCheck", { Title = "Takım Arkadaşını Vurma", Default = true })
Tabs.Combat:AddSlider("AimbotSmooth", { Title = "Smoothness (Yumuşaklık)", Min = 1, Max = 10, Default = 5, Description = "Düşük = Robot gibi, Yüksek = İnsan gibi." })
Tabs.Combat:AddSlider("FovRadius", { Title = "FOV Çapı", Min = 50, Max = 800, Default = 150 })

-- Aimbot Döngüsü
RunService.RenderStepped:Connect(function()
    if Options.Aimbot.Value and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then -- Sağ Tık Basılıyken
        local target = getClosestPlayer()
        if target then
            local currentCFrame = Camera.CFrame
            local targetCFrame = CFrame.new(currentCFrame.Position, target.Position)
            -- Yumuşak Geçiş (Legit görünmesi için)
            Camera.CFrame = currentCFrame:Lerp(targetCFrame, 1 / Options.AimbotSmooth.Value)
        end
    end
end)

-- >> MAIN TAB (KARAKTER) <<
Tabs.Main:AddSlider("WalkSpeed", { Title = "Yürüme Hızı", Min = 16, Max = 200, Default = 16, Callback = function(v) if LocalPlayer.Character then LocalPlayer.Character.Humanoid.WalkSpeed = v end end })
Tabs.Main:AddSlider("JumpPower", { Title = "Zıplama Gücü", Min = 50, Max = 300, Default = 50, Callback = function(v) if LocalPlayer.Character then LocalPlayer.Character.Humanoid.JumpPower = v end end })

-- Click TP (Ctrl + Sol Tık)
local clickTP = false
Tabs.Main:AddToggle("ClickTP", { Title = "Click TP (Ctrl + Click)", Default = false }):OnChanged(function() clickTP = Options.ClickTP.Value end)

Mouse.Button1Down:Connect(function()
    if clickTP and UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
        if Mouse.Target then
            LocalPlayer.Character:MoveTo(Mouse.Hit.Position)
        end
    end
end)

-- >> VISUALS TAB (ESP) <<
local EspEnabled = false
local EspContainer = Instance.new("Folder", game.CoreGui)
EspContainer.Name = "RyumaESP_v2"

local function UpdateESP()
    EspContainer:ClearAllChildren()
    if not EspEnabled then return end
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
             -- Kutu
             local hl = Instance.new("Highlight", EspContainer)
             hl.Adornee = plr.Character
             hl.FillTransparency = 0.5
             hl.OutlineColor = Color3.fromRGB(255, 0, 0)
        end
    end
end

Tabs.Visuals:AddToggle("ESP", { Title = "Player ESP", Default = false }):OnChanged(function()
    EspEnabled = Options.ESP.Value
    if not EspEnabled then EspContainer:ClearAllChildren() end
end)

task.spawn(function()
    while true do
        if EspEnabled then UpdateESP() end
        task.wait(1)
    end
end)

-- >> MISC / KORUMA TAB <<

-- Anti-AFK (Server'ın atmasını engeller)
Tabs.Misc:AddToggle("AntiAFK", { Title = "Anti-AFK (Atılmayı Önle)", Default = true }):OnChanged(function()
    local bb = game:GetService("VirtualUser")
    LocalPlayer.Idled:Connect(function()
        bb:CaptureController()
        bb:ClickButton2(Vector2.new())
    end)
end)

-- FPS Booster (Doku Silici)
Tabs.Misc:AddButton({
    Title = "🔥 FPS Booster (Dokuları Sil)",
    Description = "PC kasıyorsa buna bas, oyun çamur olur ama FPS artar.",
    Callback = function()
        for _, v in pairs(workspace:GetDescendants()) do
            if v:IsA("BasePart") and not v:IsA("MeshPart") then
                v.Material = Enum.Material.SmoothPlastic
                v.Reflectance = 0
            elseif v:IsA("Decal") or v:IsA("Texture") then
                v:Destroy()
            end
        end
        Lighting.GlobalShadows = false
        Lighting.FogEnd = 9e9
    end
})

-- Server Hop
Tabs.Misc:AddButton({
    Title = "Server Hop (Sunucu Değiştir)",
    Callback = function()
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

-- Ayarlar
SaveManager:SetLibrary(Fluent)
InterfaceManager:SetLibrary(Fluent)
InterfaceManager:BuildInterfaceSection(Tabs.Settings)
SaveManager:BuildConfigSection(Tabs.Settings)

Window:SelectTab(1)
Fluent:Notify({ Title = "Ryuma Hub v2", Content = "Script başarıyla yüklendi! Koruma Aktif.", Duration = 5 })
