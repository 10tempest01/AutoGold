--[[--
===========================================================================

   █████╗ ██╗   ██╗████████╗ ██████╗  ██████╗  ██████╗ ██╗     ██████╗ 
  ██╔══██╗██║   ██║╚══██╔══╝██╔═══██╗██╔════╝ ██╔═══██╗██║     ██╔══██╗
  ███████║██║   ██║   ██║   ██║   ██║██║  ███╗██║   ██║██║     ██║  ██║
  ██╔══██║██║   ██║   ██║   ██║   ██║██║   ██║██║   ██║██║     ██║  ██║
  ██║  ██║╚██████╔╝   ██║   ╚██████╔╝╚██████╔╝╚██████╔╝███████╗██████╔╝
  ╚═╝  ╚═╝ ╚═════╝    ╚═╝    ╚═════╝  ╚═════╝  ╚═════╝ ╚══════╝╚═════╝ 
                                                                       
  Author  : Tempest (@10.tempest.01)
  Purpose : Automated gold skin farming across a configurable character
            rotation. Supports dual-client communcation, Discord webhook
            notifications, disconnect recovery, and per-character move
            blacklists.

===========================================================================

  COPYRIGHT & LICENSE

  Copyright (c) 2026 Tempest. All rights reserved.

  This script is the intellectual property of Tempest. Redistribution,
  re-upload, resale, or public sharing of this file — in whole or in part,
  modified or unmodified — is strictly prohibited without prior written
  permission from the author.

  This software is provided for PERSONAL, NON-COMMERCIAL use only.
  You may modify this file for your own private use, but you may not
  distribute any derivative works.

===========================================================================

  DISCLAIMER

  This script interacts with a third-party platform (Roblox). The author
  makes no guarantees regarding its continued functionality, compatibility
  with future game updates, or compliance with any platform's terms of
  service. Use is entirely at your own risk.

  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
  OR IMPLIED. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY CLAIM,
  DAMAGES, OR OTHER LIABILITY ARISING FROM THE USE OF THIS SOFTWARE.

===========================================================================
--]]--

-- Init
local Settings = getgenv().Settings
if not Settings then warn("Settings not found!") return end

game.Loaded:Wait()

-- Variables
local TeleportService = game:GetService("TeleportService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local VirtualInput = game:GetService("VirtualInputManager")
local CoreGui = game:GetService("CoreGui")

local Player = Players.LocalPlayer
local PlayerGui = Player.PlayerGui
local MainAccount = Settings.Accounts[1]
local IsMainAccount = Player.Name == MainAccount
local Request = request or (http and http.request) or http_request

local TotalWinCount, TotalDamage, TotalPoints = 0, 0, 0
local Chosen = nil
local SessionStart = tick()
local StartTick = tick()
local LogsPath = "AutoGold/Logs/"
local GoldSkinsPath = "AutoGold/GoldSkins.txt"

-- Tables
local PlaceIds = {
    Game = 1458767429;
    Ranked = 2008032602;
}

local Channels = {
    "ShouldRejoin";
    "ShouldShutdown";
    "Pad";
}

local EmbedColors = {
    Start = 0x5865F2;
    Teleport = 0x5865F2;
    Info = 0x4FC3F7;
    Gold = 0xFFD700;
    Char = 0xA8FF78;
    Win = 0x57FF8E;
    Error = 0xFF5757;
}

local EmbedIcons = {
    Start = "🚀";
    Teleport = "🔄";
    Info = "📊";
    Gold = "✨";
    Char = "🎭";
    Win = "🏆";
    Error = "❌";
}

-- Functions
local function DebugPrint(...)
    if not Settings.DebugMode then return end
    print(("[%s]"):format(Player.Name), ...)
end

local function DeepCopy(Original)
	local Copy = {}
	for k, v in pairs(Original) do
		if type(v) == "table" then
			v = DeepCopy(v)
		end
		Copy[k] = v
	end
	return Copy
end

local function FormatTime(Seconds)
    Seconds = math.floor(Seconds)
    local Hours = math.floor(Seconds / 3600)
    local Minutes = math.floor((Seconds % 3600) / 60)
    local Secs = Seconds % 60

    if Hours > 0 then
        return string.format("%dh %dm %ds", Hours, Minutes, Secs)
    elseif Minutes > 0 then
        return string.format("%dm %ds", Minutes, Secs)
    else
        return string.format("%ds", Secs)
    end
end

local function SendWebhook(EventType, Title, Fields, Ping)
    if not Settings.Webhook then return end
    local Color = EmbedColors[EventType] or EmbedColors.Info
    local Icon = EmbedIcons[EventType]  or "🔔"

    local FieldList = {}
    for _, F in ipairs(Fields or {}) do
        table.insert(FieldList, {
            name = ("`%s`"):format(F.Name);
            value = (F.Custom and tostring(F.Value)) or ("```%s```"):format(tostring(F.Value));
            inline = F.Inline ~= false;
        })
    end

    table.insert(FieldList, {
        name = "`🕐 Session Time`";
        value = ("```%s```"):format(FormatTime(tick() - StartTick));
        inline = false;
    })

    local PingContent
    if Ping and Settings.DiscordId then
        PingContent = "<@" .. Settings.DiscordId .. ">"
    end

    task.spawn(Request, {
        Url = Settings.Webhook,
        Method = "POST",
        Headers = { ["Content-Type"] = "application/json" },
        Body = HttpService:JSONEncode({
            content = PingContent;
            embeds = {{
                author = {
                    name = "AutoGold";
                    icon_url = "https://cdn.discordapp.com/attachments/1359862332091666452/1475527076332306536/autogold.png?ex=699dcf2c&is=699c7dac&hm=d4ceb32cef9ed2abb0cf5ed19877e6823fcb6593442f91af4ba888f2549af563&";
                };
                title = ("[%s] %s"):format(Icon, Title);
                color = Color;
                fields = FieldList;
                footer = {
                    text = "AutoGold by Tempest";
                    icon_url = "https://cdn.discordapp.com/attachments/1359862332091666452/1467894514885726219/a_58051caa60d83e0a99927f8bd9ceef96.gif?ex=69820acc&is=6980b94c&hm=e9e43336ac07811afe2f8fcad1366ab64789a716ea68f45a189b7c8fb595b76a&";
                };
                timestamp = os.date("!%Y-%m-%dT%H:%M:%S.000Z");
            }};
        })
    })
end

local function UpdateLogFile()
    local Elapsed = tick() - StartTick
    local FileName = LogsPath .. os.date("%Y-%m-%d") .. tostring(StartTick) .. ".txt"
    local Entry = tostring(TotalWinCount) .. " Wins | " .. FormatTime(Elapsed)

    if isfile(FileName) then
        writefile(FileName, readfile(FileName) .. "\n" .. Entry)
    else
        writefile(FileName, Entry)
    end
end

local function GetGoldSkins()
    local CasualInfo = ReplicatedStorage:WaitForChild("CasualInfo")
    local Data = HttpService:JSONDecode(CasualInfo:InvokeServer("BoughtChars"))
    local GoldSkins = {}

    for Char, Info in Data do
        if Info and Info.Gold then
            table.insert(GoldSkins, Char)
        end
    end

    DebugPrint(HttpService:JSONEncode(GoldSkins))
    return GoldSkins
end

local function HasGoldSkin(Name)
    if isfile(GoldSkinsPath) then
        local GoldSkins = HttpService:JSONDecode(readfile(GoldSkinsPath))
        for _, Char in GoldSkins do
            if Name == Char then
                task.spawn(SendWebhook, "Char", "Skipping Character (Gold Skin Already Owned)", {
                    { Name = "🎭 Skipped Character", Value = Name },
                    { Name = "📋 Remaining Queue",   Value = tostring(#Settings.Characters) .. " character(s)" },
                })
                return true
            end
        end
    end
    return false
end

local function ChooseNextCharacter()
    local Name = Settings.Characters[1] and Settings.Characters[1].Name
    if not Name then return end

    if HasGoldSkin(Name) then
        table.remove(Settings.Characters, 1)
        DebugPrint("Skipping", Name)
        DebugPrint(HttpService:JSONEncode(Settings.Characters))
        return ChooseNextCharacter()
    end

    table.remove(Settings.Characters, 1)
    Chosen = Name

    DebugPrint("Switching to", Name)
    local Traits = Player.Backpack.ServerTraits
    Traits.Choose:FireServer(Name)
    task.wait(0.1)
    Traits.Input:FireServer("charclose")
    task.wait(0.1)
    Traits.Choose:FireServer("Close")
    task.wait(0.1)
    Traits.Choose:FireServer("PLAY")

    return Name
end

local function GetCurrentCharacter()
    local HUD = PlayerGui:WaitForChild("HUD")
    local CharSelect = HUD:WaitForChild("CharacterSelect")
    if not CharSelect.Visible then return end
    task.wait(2)
    local Text1 = CharSelect.InfoBox.Title1
    local Text2 = CharSelect.InfoBox.Title1.Title2
    local CharacterName = Text1.Text .. Text2.Text
    return CharacterName
end

local function GetCharacterEntryByName(Name)
    for _, Entry in ipairs(getgenv().CharactersCopy) do
        if Entry.Name == Name then
            return Entry
        end
    end
    return nil
end

local function IsGoldLabel(Label)
    return string.find(string.lower(Label.Text), "gold skin unlocked") ~= nil
end

local function TallyAccounts()
    local Count = 0
    for _, P in Players:GetPlayers() do
        if P.Character and table.find(Settings.Accounts, P.Name) then
            Count += 1
        end
    end
    return { Count == #Settings.Accounts, Count }
end

local function CanSpawnIn()
    local Deaths = Player:FindFirstChild("leaderstats"):FindFirstChild("Deaths")
    if Deaths.Value >= 4 then return false end
    return Player.Character:FindFirstChild("Morph") ~= nil
end

local function NoclipStep()
    local Char = Player.Character
    if not Char then return end
    for _, Part in Char:GetDescendants() do
        if Part:IsA("BasePart") and Part.CanCollide then
            Part.CanCollide = false
        end
    end
end

local function GetNearestEnemy()
    local Closest, MinDist = nil, math.huge
    local LocalRoot = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
    if not LocalRoot then return nil end

    for _, P in Players:GetPlayers() do
        if P ~= Player
        and P.Character
        and P.Character:FindFirstChild("HumanoidRootPart")
        and P.Character:FindFirstChild("Humanoid")
        and P.Character.Humanoid.Health > 0 then
            local Dist = (P.Character.HumanoidRootPart.Position - LocalRoot.Position).Magnitude
            if Dist < MinDist then
                MinDist = Dist
                Closest = P.Character
            end
        end
    end

    return Closest
end

local function FindEmptyLobby(LobbyType)
    local Lobbies = workspace:WaitForChild("CasualLobbies")
    if not Lobbies then return nil end

    for _, Lobby in pairs(Lobbies:GetChildren()) do
        if not string.match(Lobby.Name, LobbyType) then continue end

        local Occupied = false
        for _, Model in Lobby:GetChildren() do
            if not Model.Name:match("Team") then continue end
            for _, Pad in Model:GetChildren() do
                if (Pad.Name == "Pad" or Pad.Name == "Leader") and Pad:FindFirstChild("Root") and Pad.Root:FindFirstChild("Weld") then
                    Occupied = true
                    break
                end
            end
            if Occupied then break end
        end

        if not Occupied then return Lobby end
    end

    return nil
end

-- FileBus
local FileBus = loadstring(game:HttpGet("https://raw.githubusercontent.com/10tempest01/AutoGold/refs/heads/main/Modules/FileBus.lua"))()
getgenv().Bus = FileBus.New("AutoGold")

for _, Channel in Channels do
    Bus:InitChannel(Channel)
end

Bus:Listen("ShouldRejoin", function(Value)
    if Value ~= "Yes" then return end

    SendWebhook("Teleport", "Teleporting to Ranked", {
        { Name = "👤 Account", Value = "||" .. Player.Name .. "||", Custom = true },
    })

    while true do
        TeleportService:Teleport(PlaceIds.Ranked)
        task.wait(1)
    end
end)

Bus:Listen("ShouldShutdown", function(Value)
    if Value ~= "Yes" then return end

    SendWebhook("Error", "Shutting Down Client", {
        { Name = "👤 Account", Value = "||" .. Player.Name .. "||", Custom = true },
    })

    task.wait(1)
    game:Shutdown()
end)

-- Anything after this line is pure slop idk how to organize this shit

if Connections then
    for _, Connection in Connections do
        Connection:Disconnect()
    end
end

getgenv().Connections = {}
getgenv().CharactersCopy = DeepCopy(Settings.Characters)

if Settings.DisconnectDetection then
    local Teleporting = false
    Connections["PlayerTeleport"] = Player.OnTeleport:Connect(function(State)
        if State.Name == "InProgress" then
            DebugPrint("Teleport InProgress detected")
            Teleporting = true
        end
    end)

    Connections["DisconnectWatcher"] = RunService.RenderStepped:Connect(function()
        local ErrorCode = GuiService:GetErrorCode()
        if ErrorCode.Name ~= "OK" then
            if Connections["DisconnectWatcher"] then
                Connections["DisconnectWatcher"]:Disconnect()
            end

            DebugPrint(ErrorCode)
            SendWebhook("Error", "Disconnected", {
                { Name = "👤 Account",         Value = "||" .. Player.Name .. "||", Custom = true },
                { Name = "ℹ️ Info",            Value = "Disconnect detected. Rejoin in progress." },
                { Name = "❌ Error Code/Type", Value = tostring(ErrorCode) },
            }, true)
            Bus:Send("ShouldRejoin", "Yes")
        end
    end)

    game.Close:Connect(function()
        if Teleporting then return end
        SendWebhook("Error", "Client Crashed", {
            { Name = "👤 Account", Value = "||" .. Player.Name .. "||", Custom = true },
            { Name = "ℹ️ Info",    Value = "Client has crashed. Due to limited functionality, a rejoin cannot be made, so all other clients will be closed." },
        }, true)
        Bus:Send("ShouldShutdown", "Yes")
    end)
end

task.spawn(function()
    if not IsMainAccount then return end

    SessionStart = tick()
    TotalWinCount = 0

    local DamageStat = Player:WaitForChild("leaderstats"):WaitForChild("Damage")
    local PointsStat = Player:WaitForChild("leaderstats"):WaitForChild("Points")
    local LastDamage = DamageStat.Value
    local LastPoints = PointsStat.Value

    Connections["DamageTracker"] = DamageStat:GetPropertyChangedSignal("Value"):Connect(function()
        local V = DamageStat.Value
        if V < LastDamage then
            LastDamage = V
            return
        end

        TotalDamage += (V - LastDamage)
        LastDamage = V
    end)

    Connections["PointsTracker"] = PointsStat:GetPropertyChangedSignal("Value"):Connect(function()
        local V = PointsStat.Value
        if V < LastPoints then
            LastPoints = V
            return
        end
    
        TotalPoints += (V - LastPoints)
        LastPoints = V
    end)

    if Settings.PeriodicUpdateInterval > 0 then
        task.spawn(function()
            while true do
                task.wait(Settings.PeriodicUpdateInterval * 60)
                SendWebhook("Info", "Periodic Update", {
                    { Name = "💥 Total Damage",     Value = tostring(TotalDamage) },
                    { Name = "🔢 Total Points",     Value = tostring(TotalPoints) },
                    { Name = "🏆 Total Wins",       Value = tostring(TotalWinCount) },
                    { Name = "🎭 Active Character", Value = Chosen or "Unknown" },
                    { Name = "🔄 Next In Queue",    Value = tostring((Settings.Characters[1] and Settings.Characters[1].Name) or "None") },
                })
            end
        end)
    end

    Connections["GoldSkinWatcher"] = PlayerGui.DescendantAdded:Connect(function(Ui)
        task.wait()
        if not Ui:IsA("TextLabel") or not IsGoldLabel(Ui) then return end
        DebugPrint(Ui:GetFullName())

        SendWebhook("Gold", "Gold Skin Unlocked", {
            { Name = "🎭 Character",                 Value = Chosen or "Unknown" },
            { Name = "⏱️ Time on Character",         Value = FormatTime(tick() - SessionStart) },
            { Name = "💥 Total Damage",              Value = tostring(TotalDamage) },
            { Name = "🔢 Total Points",              Value = tostring(TotalPoints) },
            { Name = "🏆 Total Wins",                Value = tostring(TotalWinCount) },
            { Name = "🕐 Time Since Last Gold Skin", Value = (getgenv().LastGoldTime and FormatTime(tick() - getgenv().LastGoldTime)) or "First Gold Skin" },
        }, true)
        getgenv().LastGoldTime = tick()

        repeat task.wait() until PointsStat.Value == 0
        repeat task.wait() until PlayerGui:FindFirstChild("CharacterSelect", true) and PlayerGui:FindFirstChild("CharacterSelect", true).Visible
        task.wait(2)

        Chosen = ChooseNextCharacter()

        if Chosen then
            SessionStart = tick()
            TotalDamage, TotalPoints, TotalWinCount = 0, 0, 0
            SendWebhook("Char", "Switching Character", {
                { Name = "🎭 New Character",   Value = Chosen },
                { Name = "📋 Remaining Queue", Value = tostring(#Settings.Characters) .. " character(s)" },
            })
        else
            SendWebhook("Error", "Character Queue Empty", {
                { Name = "ℹ️ Info", Value = "No characters left in the rotation (or something broke). Closing clients." },
            }, true)
            task.wait(1)
            DebugPrint("Finished")
            Bus:Send("ShouldShutdown", "Yes")
        end
    end)
end)

Connections["GuiHandler"] = PlayerGui.ChildAdded:Connect(function(Child)
    task.wait()

    if Child.Name == "BanChooser" then
        local Remote = Child:FindFirstChild("Communicate", true)
        Remote:FireServer("pass")

    elseif Child.Name == "MapBan" then
        repeat task.wait() until Child:FindFirstChild("Frame") and Child.Frame:FindFirstChild("Maps")
        for _, V in Child.Frame.Maps:GetChildren() do
            if V:FindFirstChild("Title") then
                ReplicatedStorage.MapBanner:FireServer(V.Title.Text)
            end
        end

    elseif Child.Name == "Rematch" then
        ReplicatedStorage:WaitForChild("RematchVote"):FireServer()
    end
end)

local CurrentPlaceId = game.PlaceId
local IsRankedLobby = CurrentPlaceId == PlaceIds.Ranked
local IsMainGame = CurrentPlaceId == PlaceIds.Game
local TeleportData = TeleportService:GetLocalPlayerTeleportData()
local CasualEnterEvent = IsRankedLobby and ReplicatedStorage:WaitForChild("Input")

if TeleportData ~= nil then
    if #TeleportData == 0 then
        if IsRankedLobby then
            local TargetLobby

            if not IsMainAccount then
                Bus:Listen("Pad", function(Value)
                    TargetLobby = workspace.CasualLobbies:WaitForChild(Value)
                end)
            else
                local GoldSkins = HttpService:JSONEncode(GetGoldSkins())
                writefile(GoldSkinsPath, GoldSkins)
            end

            local Tally
            repeat
                Tally = TallyAccounts()
                task.wait()
            until Tally[1] == true

            local AccountCount = Tally[2]
            if AccountCount % 2 ~= 0 then
                if not Settings.Debug then return end
            end

            local LobbyType = tostring(AccountCount / 2) .. "s"

            if IsMainAccount then
                repeat
                    TargetLobby = FindEmptyLobby(LobbyType)
                    task.wait()
                until TargetLobby
                Bus:Send("Pad", TargetLobby.Name)
                DebugPrint("Got", TargetLobby, Player.Name)
            else
                repeat task.wait() until TargetLobby
                DebugPrint("Got", TargetLobby, Player.Name)
            end
            
            repeat task.wait() until Player.Character and Player.Character:FindFirstChild("Humanoid")
            local Char = Player.Character
            local Hum = Char.Humanoid

            for _, Lobby in workspace.CasualLobbies:GetChildren() do
                if Lobby.Name ~= TargetLobby.Name then
                    Lobby:Destroy()
                end
            end

            if Settings.PadMethod == "Walk" then
                while task.wait(0.5) do
                    for _, Brick in TargetLobby:GetDescendants() do
                        if Brick.Name == "TouchBrick" then
                            DebugPrint("Walking to", Brick.Name)
                            Hum.WalkToPart = Brick
                            Hum.WalkToPoint = Vector3.new(0, 0, 0)
                            task.wait(0.5)
                        end
                    end
                end
            elseif Settings.PadMethod == "FireTouchInterest" then
                while task.wait(0.1) do
                    for _, TouchInterest in TargetLobby:GetDescendants() do
                        if TouchInterest:IsA("TouchTransmitter") then
                            DebugPrint(TouchInterest.Name, TouchInterest.Parent.Name)
                            firetouchinterest(TouchInterest.Parent, Char.Head, 0)
                            task.wait()
                            firetouchinterest(TouchInterest.Parent, Char.Head, 1)
                        end
                    end
                end
            end

        elseif IsMainGame then
            if IsMainAccount then
                SendWebhook("Start", "AutoGold Started", {
                    { Name = "👤 Account",         Value = "||" .. Player.Name .. "||", Custom = true },
                    { Name = "🎭 First Character", Value = Settings.Characters[1].Name or "Unknown" },
                    { Name = "📋 Queue Length",    Value = #Settings.Characters .. " character(s)" },
                    { Name = "⏱️ Update Every",    Value = Settings.PeriodicUpdateInterval > 0 and (Settings.PeriodicUpdateInterval .. " min") or  "Disabled" },
                })
            end

            Connections["PlayerCheck"] = Players.PlayerAdded:Connect(function(AddedPlayer)
                if not table.find(Settings.Accounts, AddedPlayer.Name) then
                    Player:Kick("Foreign player detected")
                    SendWebhook("Error", "Foreign Player", {
                        { Name = "👤 Account",      Value = "||" .. Player.Name .. "||", Custom = true },
                        { Name = "🚫 Player Found", Value = "||" .. AddedPlayer.Name .. "||", Custom = true },
                        { Name = "ℹ️ Info",         Value = "Foreign player detected while joining a match. Rejoin in progress." },
                    }, true)
                    Bus:Send("ShouldRejoin", "Yes")
                end
            end)

            for _, CPlayer in Players:GetPlayers() do
                if not table.find(Settings.Accounts, CPlayer.Name) then
                    Player:Kick("Foreign player detected")
                    SendWebhook("Error", "Foreign Player", {
                        { Name = "👤 Account",      Value = "||" .. Player.Name .. "||", Custom = true },
                        { Name = "🚫 Player Found", Value = "||" .. CPlayer.Name .. "||", Custom = true },
                        { Name = "ℹ️ Info",         Value = "Foreign player detected while joining a match. Rejoin in progress." },
                    }, true)
                    Bus:Send("ShouldRejoin", "Yes")
                end
            end

            task.spawn(function()
                if not IsMainAccount then return end

                if Settings.AntiDowntilt and hookmetamethod then
                    local Hook; Hook = hookmetamethod(game, "__namecall", newcclosure(function(...)
                        local self = ...

                        if self.IsA(self, "RemoteEvent") and rawequal(self.Name, "Input") and getnamecallmethod() == "FireServer" then
                            local Args = {select(2, ...)}
                            
                            if Args[1] == "trueml" then
                                Args[2].air = false
                            end
                        end

                        return Hook(...)
                    end))
                end

                local CharacterName
                repeat
                    CharacterName = GetCurrentCharacter()
                    task.wait()
                until CharacterName

                if CharacterName ~= Settings.Characters[1].Name then
                    ChooseNextCharacter()
                    SendWebhook("Char", "Switching Character", {
                        { Name = "🎭 New Character",   Value = Chosen },
                        { Name = "📋 Remaining Queue", Value = tostring(#Settings.Characters) .. " character(s)" },
                    })
                else
                    Chosen = Settings.Characters[1].Name
                    if HasGoldSkin(Chosen) then
                        Chosen = ChooseNextCharacter()
                        DebugPrint("11111111 hellooo pls print")
                    else
                        table.remove(Settings.Characters, 1)
                        SendWebhook("Char", "Keeping Character", {
                            { Name = "🎭 Current Character", Value = Chosen },
                            { Name = "📋 Remaining Queue",   Value = tostring(#Settings.Characters) .. " character(s)" },
                        })
                    end
                end
            end)

            local OverlayGui = Instance.new("ScreenGui")
            OverlayGui.Parent = game:GetService("CoreGui")
            OverlayGui.Enabled = true
            local ModalButton = Instance.new("TextButton", OverlayGui)
            ModalButton.Visible = true
            ModalButton.Modal = true
            ModalButton.Position = UDim2.fromScale(1.1, 1.1)

            if Settings.Noclip then
                task.spawn(function()
                    RunService.RenderStepped:Connect(NoclipStep)
                    Player.CharacterAdded:Connect(function()
                        repeat task.wait() until
                            Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
                        NoclipStep()
                    end)
                end)
            end

            if Settings.LockOn then
                task.spawn(function()
                    RunService.RenderStepped:Connect(function()
                        pcall(function()
                            if not Player.Character then return end
                            if not Player.Character:FindFirstChild("HumanoidRootPart") then return end

                            local Target = GetNearestEnemy()
                            if not Target then return end

                            game:GetService("Workspace").CurrentCamera.CFrame = CFrame.new(
                                workspace.CurrentCamera.CFrame.Position,
                                Target.HumanoidRootPart.Position
                            )
                        end)
                    end)
                end)
            end

            Connections["RematchAdded"] = PlayerGui.ChildAdded:Connect(function(Child)
                if Child.Name == "Rematch" then
                    if IsMainAccount then
                        TotalWinCount += 1
                        UpdateLogFile()
                        SendWebhook("Win", "Match Won", {
                            { Name = "🎭 Character",           Value = Chosen or "Unknown" },
                            { Name = "⏱️ Time on Character",   Value = FormatTime(tick() - SessionStart) },
                            { Name = "🏆 Total Wins",          Value = tostring(TotalWinCount) },
                            { Name = "💥 Damage",              Value = ("%s (%s)"):format(tostring(Player.leaderstats.Damage.Value), TotalDamage) },
                            { Name = "🔢 Points",              Value = ("%s (%s)"):format(tostring(Player.leaderstats.Points.Value), TotalPoints) },
                            { Name = "🕐 Time Since Last Win", Value = (getgenv().LastMatchTime and FormatTime(tick() - getgenv().LastMatchTime)) or "First Match" },
                        })
                    end
                    getgenv().LastMatchTime = tick()
                end
            end)

            Connections["CharacterSpawn"] = Player.CharacterAdded:Connect(function(Char)
                local SpawnReady = false

                if not IsMainAccount
                and Players:FindFirstChild(MainAccount)
                and Player.Team ~= Players[MainAccount].Team then
                    repeat
                        SpawnReady = CanSpawnIn()
                        task.wait()
                    until SpawnReady

                    if Player.Character == Char and Players[MainAccount].Character then
                        local Deaths = Player.leaderstats.Deaths
                        local DeathSnapshot = Deaths.Value

                        local BV = Instance.new("BodyVelocity")
                        BV.Parent = Player.Character.HumanoidRootPart
                        BV.velocity = Vector3.new(0, 0, 0)
                        BV.MaxForce = Vector3.new(9e9, 9e9, 9e9)

                        task.spawn(function()
                            VirtualInput:SendKeyEvent(true,  Enum.KeyCode.W, false, game)
                            task.wait(3)
                            VirtualInput:SendKeyEvent(false, Enum.KeyCode.W, false, game)
                        end)

                        repeat
                            pcall(function()
                                Char:PivotTo(Players[MainAccount].Character.HumanoidRootPart.CFrame + Settings.TPOffset)
                            end)
                            task.wait()
                        until DeathSnapshot ~= Deaths.Value
                    end
                elseif IsMainAccount then
                    repeat
                        SpawnReady = CanSpawnIn()
                        task.wait()
                    until SpawnReady

                    task.spawn(function()
                        repeat
                            task.wait()
                        until Player.Character:FindFirstChild("Humanoid").FloorMaterial ~= Enum.Material.Air
                        task.wait(1)
                        local BV = Instance.new("BodyVelocity")
                        BV.Parent = Player.Character.HumanoidRootPart
                        BV.velocity = Vector3.new(0, 0, 0)
                        BV.MaxForce = Vector3.new(9e9, 9e9, 9e9)
                    end)

                    repeat
                        task.spawn(function()

                            if not Settings.SpamMoves then return end

                            for _, Key in ipairs(Settings.MoveKeys) do
                                local Entry = Chosen and GetCharacterEntryByName(Chosen)

                                if not (Entry and Entry.Blacklist and table.find(Entry.Blacklist, Key)) then
                                    VirtualInput:SendKeyEvent(true, Key, false, game)
                                    task.wait(0.05)
                                    VirtualInput:SendKeyEvent(false, Key, false, game)
                                    task.wait(0.05)
                                end
                            end

                        end)

                        VirtualInput:SendMouseButtonEvent(0, 0, 0, true,  game, 1)
                        task.wait()
                        VirtualInput:SendMouseButtonEvent(0, 0, 0, false, game, 1)
                        task.wait(0.01)
                    until PlayerGui:FindFirstChild("Rematch")
                end
            end)
        end
    end
else
    if IsRankedLobby then
        SendWebhook("Teleport", "Teleporting to Casuals", {
            { Name = "👤 Account", Value = "||" .. Player.Name .. "||", Custom = true },
        })
        while true do
            CasualEnterEvent:FireServer("CasualEnter")
            task.wait(1)
        end
    elseif IsMainGame then
        SendWebhook("Teleport", "Teleporting to Ranked", {
            { Name = "👤 Account", Value = "||" .. Player.Name .. "||", Custom = true },
        })
        while true do
            TeleportService:Teleport(PlaceIds.Ranked)
            task.wait(1)
        end
    end
end
