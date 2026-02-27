local Settings = getgenv().Settings
if not Settings then
    print("FileBus failed to fetch settings!")
    return
end

local FileBus = {}
FileBus.__index = FileBus

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local Player = Players.LocalPlayer

local function DebugPrint(...)
    if not Settings.DebugMode then return end
    print(("[%s]"):format(Player.Name), ...)
end

function FileBus.New(BaseFolder)
    if not isfolder(BaseFolder) then
        makefolder(BaseFolder)
    end

    return setmetatable({
        BaseFolder = BaseFolder,
        Listeners = {},
        ProcessedIds = {}
    }, FileBus)
end

function FileBus:GetPath(Channel)
    assert(self.BaseFolder, "FileBus not constructed properly.")
    assert(Channel, "Channel cannot be nil.")

    return self.BaseFolder .. "/" .. Channel .. ".txt"
end

function FileBus:InitChannel(Channel)
    local Path = self:GetPath(Channel)
    writefile(Path, "")
end

function FileBus:Send(Channel, Value)
    local Path = self:GetPath(Channel)

    local Packet = {
        Id = HttpService:GenerateGUID(false),
        Timestamp = os.clock(),
        Data = Value
    }

    local Encoded = HttpService:JSONEncode(Packet)
    writefile(Path, Encoded)

    DebugPrint(("SENT | Channel: %s | Value: %s | Id: %s"):format(Channel, Value, Packet.Id))
end

function FileBus:Listen(Channel, Callback)
    local Path = self:GetPath(Channel)

    task.spawn(function()
        DebugPrint(("LISTENING | Channel: %s"):format(Channel))

        while true do
            task.wait(1)

            if not isfile(Path) then
                continue
            end

            local Raw = readfile(Path)
            if Raw == "" then
                continue
            end

            local Success, Packet = pcall(function()
                return HttpService:JSONDecode(Raw)
            end)

            if not Success or not Packet or not Packet.Id then
                continue
            end

            if self.ProcessedIds[Packet.Id] then
                continue
            end

            self.ProcessedIds[Packet.Id] = true

            DebugPrint(("CALLBACK | Channel: %s | Value: %s | Id: %s"):format(Channel, Packet.Data, Packet.Id))

            Callback(Packet.Data, Packet)
        end
    end)
end

return FileBus
