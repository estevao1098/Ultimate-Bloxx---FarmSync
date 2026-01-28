repeat task.wait() until game:IsLoaded() and game.Players.LocalPlayer

local function getAccountData()
    local HttpService = game:GetService("HttpService")
    local Player = game.Players.LocalPlayer
    local CommF = game.ReplicatedStorage.Remotes.CommF_
    local Data = Player:FindFirstChild("Data")
    local PlaceId = game.PlaceId

    local account = {
        Player = { Name = Player.Name, DisplayName = Player.DisplayName, UserId = Player.UserId },
        Level = Data and Data.Level.Value or 0,
        Beli = Data and Data.Beli.Value or 0,
        Fragments = Data and Data.Fragments.Value or 0,
        BountyHonor = Player.leaderstats and Player.leaderstats:FindFirstChild("Bounty/Honor") and Player.leaderstats["Bounty/Honor"].Value or 0,
        Sea = PlaceId == 2753915549 and 1 or PlaceId == 4442272183 and 2 or PlaceId == 7449423635 and 3 or 0,
        Race = { Name = Data and Data.Race.Value or "", Version = 1, Full = false },
        Fruit = { Name = Data and Data.DevilFruit.Value or "", Mastery = 0, Awakened = false, AwakenedSkills = {} },
        Swords = {}, Melees = {}, Guns = {}, Fruits = {}, Accessories = {}, Materials = {},
        PullLever = false
    }

    pcall(function()
        for _, item in pairs(CommF:InvokeServer('getInventory')) do
            if item.Type == "Sword" then table.insert(account.Swords, {Name = item.Name, Mastery = item.Mastery or 0})
            elseif item.Type == "Gun" then table.insert(account.Guns, {Name = item.Name, Mastery = item.Mastery or 0})
            elseif item.Type == "Blox Fruit" or item.Type == "Fruit" then table.insert(account.Fruits, item.Name)
            elseif item.Type == "Wear" then table.insert(account.Accessories, item.Name)
            elseif item.Type == "Material" then table.insert(account.Materials, {Name = item.Name, Count = item.Count or 1})
            end
        end
    end)

    pcall(function()
        local fruit = Data and Data:FindFirstChild("DevilFruit")
        if fruit and fruit.Value ~= "" then
            local tool = Player:FindFirstChild("Backpack") and Player.Backpack:FindFirstChild(fruit.Value)
            if tool and tool:FindFirstChild("Level") then account.Fruit.Mastery = tool.Level.Value end
        end
    end)

    pcall(function()
        local skills = CommF:InvokeServer("getAwakenedAbilities")
        if skills then
            for _, s in pairs(skills) do if s.Awakened then table.insert(account.Fruit.AwakenedSkills, s.Key) end end
            account.Fruit.Awakened = #account.Fruit.AwakenedSkills > 0
        end
    end)

    pcall(function()
        for _, m in pairs({"Superhuman", "ElectricClaw", "DragonTalon", "SharkmanKarate", "DeathStep", "Godhuman", "SanguineArt"}) do
            if CommF:InvokeServer("Buy" .. m, true) == 1 then table.insert(account.Melees, m) end
        end
    end)

    pcall(function() account.PullLever = CommF:InvokeServer("CheckTempleDoor") end)

    pcall(function()
        local hasV4 = Player.Character and Player.Character:FindFirstChild("RaceTransformed")
        if hasV4 then account.Race.Version = 4
        elseif CommF:InvokeServer("Wenlocktoad", "1") == -2 then account.Race.Version = 3
        elseif CommF:InvokeServer("Alchemist", "1") == -2 then account.Race.Version = 2
        else account.Race.Version = 1 end
        account.Race.Full = account.Race.Version == 4
    end)

    local json = HttpService:JSONEncode(account)
    if setclipboard then setclipboard(json) end
    return json
end

local function Any(items)
    return { _any = true, items = items }
end

local function checkRequirements(data, requirements)
    for key, required in pairs(requirements) do
        local value = data[key]
        if type(required) == "number" then
            if (tonumber(value) or 0) < required then return false end
        elseif type(required) == "string" then
            local actualValue = type(value) == "table" and value.Name or value
            if actualValue ~= required then return false end
        elseif type(required) == "table" and type(value) == "table" then
            local isAny = required._any == true
            local items = isAny and required.items or required
            
            if isAny then
                local anyFound = false
                for _, req in pairs(items) do
                    if type(req) == "table" and req.Name then
                        for _, v in pairs(value) do
                            if type(v) == "table" and v.Name == req.Name then
                                local itemValue = v.Mastery or v.Count or 0
                                if itemValue >= req.Value then anyFound = true break end
                            end
                        end
                    else
                        for _, v in pairs(value) do
                            if (type(v) == "table" and v.Name or v) == req then anyFound = true break end
                        end
                    end
                    if anyFound then break end
                end
                if not anyFound then return false end
            else
                for _, req in pairs(items) do
                    local found = false
                    if type(req) == "table" and req.Name then
                        for _, v in pairs(value) do
                            if type(v) == "table" and v.Name == req.Name then
                                local itemValue = v.Mastery or v.Count or 0
                                if itemValue >= req.Value then found = true break end
                            end
                        end
                    else
                        for _, v in pairs(value) do
                            if (type(v) == "table" and v.Name or v) == req then found = true break end
                        end
                    end
                    if not found then return false end
                end
            end
        end
    end
    return true
end

local function checkData(filters)
    local data = getAccountData()
    local account = game:GetService("HttpService"):JSONDecode(data)

    for _, filter in pairs(filters) do
        if checkRequirements(account, filter.Requirements) then
            print(filter.Name .. " - Requirements met!")
            return true, filter.Folders.Input, filter.Folders.Output
        end
    end
    
    print("No requirements met!")
    return false, nil, nil
end

return checkData
