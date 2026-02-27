local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

local Characters = ReplicatedStorage.Characters:GetChildren()

table.sort(Characters, function(A, B)
    return A.Name:lower() < B.Name:lower()
end)

local Lines = {}
table.insert(Lines, "{")

for CharacterIndex, Character in ipairs(Characters) do
    local Skins = {}

    for _, Skin in Character:GetChildren() do
        table.insert(Skins, Skin.Name)
    end

    table.sort(Skins, function(A, B)
        return A:lower() < B:lower()
    end)

    local CharacterNameJson = HttpService:JSONEncode(Character.Name)

    table.insert(Lines, "    " .. CharacterNameJson .. ": [")

    for SkinIndex, SkinName in ipairs(Skins) do
        local SkinJson = HttpService:JSONEncode(SkinName)
        local Comma = (SkinIndex < #Skins) and "," or ""

        table.insert(Lines, "        " .. SkinJson .. Comma)
    end

    local ClosingComma = (CharacterIndex < #Characters) and "," or ""
    table.insert(Lines, "    ]" .. ClosingComma)
end

table.insert(Lines, "}")

local FinalJson = table.concat(Lines, "\n")
setclipboard(FinalJson)
