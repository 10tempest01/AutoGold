local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local Data = {}

for _, Character in ReplicatedStorage.Characters:GetChildren() do
    Data[Character.Name] = {}
    for _, Skin in Character:GetChildren() do
        table.insert(Data[Character.Name], Skin.Name)
    end
end

setclipboard(HttpService:JSONEncode(Data))
