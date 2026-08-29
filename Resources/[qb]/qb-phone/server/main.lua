local QBCore = exports[Config.corename]:GetCoreObject()
local QBPhone = {}
local AppAlerts = {}
local MentionedTweets = {}
local Hashtags = {}
local Calls = {}
local Adverts = {}
local GeneratedPlates = {}
local WebHook = Config.serverwebhook
local bannedCharacters = {'%','$',';'}
local TWData = {}

-- Functions

local function GetOnlineStatus(number)
    local Target = QBCore.Functions.GetPlayerByPhone(number)
    local retval = false
    if Target ~= nil then
        retval = true
    end
    return retval
end

local function GenerateMailId()
    return math.random(111111, 999999)
end

local function escape_sqli(source)
    local replacements = {
        ['"'] = '\\"',
        ["'"] = "\\'"
    }
    return source:gsub("['\"]", replacements)
end

local function round(num, numDecimalPlaces)
    if numDecimalPlaces and numDecimalPlaces > 0 then
        local mult = 10 ^ numDecimalPlaces
        return math.floor(num * mult + 0.5) / mult
    end
    return math.floor(num + 0.5)
end

function QBPhone.AddMentionedTweet(citizenid, TweetData)
    if MentionedTweets[citizenid] == nil then
        MentionedTweets[citizenid] = {}
    end
    MentionedTweets[citizenid][#MentionedTweets[citizenid]+1] = TweetData
end

function QBPhone.SetPhoneAlerts(citizenid, app, alerts)
    if citizenid ~= nil and app ~= nil then
        if AppAlerts[citizenid] == nil then
            AppAlerts[citizenid] = {}
            if AppAlerts[citizenid][app] == nil then
                if alerts == nil then
                    AppAlerts[citizenid][app] = 1
                else
                    AppAlerts[citizenid][app] = alerts
                end
            end
        else
            if AppAlerts[citizenid][app] == nil then
                if alerts == nil then
                    AppAlerts[citizenid][app] = 1
                else
                    AppAlerts[citizenid][app] = 0
                end
            else
                if alerts == nil then
                    AppAlerts[citizenid][app] = AppAlerts[citizenid][app] + 1
                else
                    AppAlerts[citizenid][app] = AppAlerts[citizenid][app] + 0
                end
            end
        end
    end
end

local function SplitStringToArray(string)
    local retval = {}
    for i in string.gmatch(string, "%S+") do
        retval[#retval+1] = i
    end
    return retval
end

local function GenerateOwnerName()
    local names = {
        [1] = { name = "Bailey Sykes",          citizenid = "DSH091G93" },
        [2] = { name = "Aroush Goodwin",        citizenid = "AVH09M193" },
        [3] = { name = "Tom Warren",            citizenid = "DVH091T93" },
        [4] = { name = "Abdallah Friedman",     citizenid = "GZP091G93" },
        [5] = { name = "Lavinia Powell",        citizenid = "DRH09Z193" },
        [6] = { name = "Andrew Delarosa",       citizenid = "KGV091J93" },
        [7] = { name = "Skye Cardenas",         citizenid = "ODF09S193" },
        [8] = { name = "Amelia-Mae Walter",     citizenid = "KSD0919H3" },
        [9] = { name = "Elisha Cote",           citizenid = "NDX091D93" },
        [10] = { name = "Janice Rhodes",        citizenid = "ZAL0919X3" },
        [11] = { name = "Justin Harris",        citizenid = "ZAK09D193" },
        [12] = { name = "Montel Graves",        citizenid = "POL09F193" },
        [13] = { name = "Benjamin Zavala",      citizenid = "TEW0J9193" },
        [14] = { name = "Mia Willis",           citizenid = "YOO09H193" },
        [15] = { name = "Jacques Schmitt",      citizenid = "QBC091H93" },
        [16] = { name = "Mert Simmonds",        citizenid = "YDN091H93" },
        [17] = { name = "Rickie Browne",        citizenid = "PJD09D193" },
        [18] = { name = "Deacon Stanley",       citizenid = "RND091D93" },
        [19] = { name = "Daisy Fraser",         citizenid = "QWE091A93" },
        [20] = { name = "Kitty Walters",        citizenid = "KJH0919M3" },
        [21] = { name = "Jareth Fernandez",     citizenid = "ZXC09D193" },
        [22] = { name = "Meredith Calhoun",     citizenid = "XYZ0919C3" },
        [23] = { name = "Teagan Mckay",         citizenid = "ZYX0919F3" },
        [24] = { name = "Kurt Bain",            citizenid = "IOP091O93" },
        [25] = { name = "Burt Kain",            citizenid = "PIO091R93" },
        [26] = { name = "Joanna Huff",          citizenid = "LEK091X93" },
        [27] = { name = "Carrie-Ann Pineda",    citizenid = "ALG091Y93" },
        [28] = { name = "Gracie-Mai Mcghee",    citizenid = "YUR09E193" },
        [29] = { name = "Robyn Boone",          citizenid = "SOM091W93" },
        [30] = { name = "Aliya William",        citizenid = "KAS009193" },
        [31] = { name = "Rohit West",           citizenid = "SOK091093" },
        [32] = { name = "Skylar Archer",        citizenid = "LOK091093" },
        [33] = { name = "Jake Kumar",           citizenid = "AKA420609" },
    }
    return names[math.random(1, #names)]
end


local function sendNewMailToOffline(citizenid, mailData)
    local Player = QBCore.Functions.GetPlayerByCitizenId(citizenid)
    if Player then
        local src = Player.PlayerData.source
        if mailData.button == nil then
            MySQL.insert('INSERT INTO player_mails (`citizenid`, `sender`, `subject`, `message`, `mailid`, `read`) VALUES (?, ?, ?, ?, ?, ?)', {Player.PlayerData.citizenid, mailData.sender, mailData.subject, mailData.message, GenerateMailId(), 0})
            TriggerClientEvent('qb-phone:client:NewMailNotify', src, mailData)
        else
            MySQL.insert('INSERT INTO player_mails (`citizenid`, `sender`, `subject`, `message`, `mailid`, `read`, `button`) VALUES (?, ?, ?, ?, ?, ?, ?)', {Player.PlayerData.citizenid, mailData.sender, mailData.subject, mailData.message, GenerateMailId(), 0, json.encode(mailData.button)})
            TriggerClientEvent('qb-phone:client:NewMailNotify', src, mailData)
        end
        SetTimeout(200, function()
            local mails = MySQL.query.await(
                'SELECT * FROM player_mails WHERE citizenid = ? ORDER BY `date` ASC', {Player.PlayerData.citizenid})
            if mails[1] ~= nil then
                for k, _ in pairs(mails) do
                    if mails[k].button ~= nil then
                        mails[k].button = json.decode(mails[k].button)
                    end
                end
            end

            TriggerClientEvent('qb-phone:client:UpdateMails', src, mails)
        end)
    else
        if mailData.button == nil then
            MySQL.insert('INSERT INTO player_mails (`citizenid`, `sender`, `subject`, `message`, `mailid`, `read`) VALUES (?, ?, ?, ?, ?, ?)', {citizenid, mailData.sender, mailData.subject, mailData.message, GenerateMailId(), 0})
        else
            MySQL.insert('INSERT INTO player_mails (`citizenid`, `sender`, `subject`, `message`, `mailid`, `read`, `button`) VALUES (?, ?, ?, ?, ?, ?, ?)', {citizenid, mailData.sender, mailData.subject, mailData.message, GenerateMailId(), 0, json.encode(mailData.button)})
        end
    end
end
exports("sendNewMailToOffline",sendNewMailToOffline)
-- Callbacks

QBCore.Functions.CreateCallback('qb-phone:server:GetCallState', function(_, cb, ContactData)
    local Target = QBCore.Functions.GetPlayerByPhone(ContactData.number)
    if Target ~= nil then
        if Calls[Target.PlayerData.citizenid] ~= nil then
            if Calls[Target.PlayerData.citizenid].inCall then
                cb(false, true)
            else
                cb(true, true)
            end
        else
            cb(true, true)
        end
    else
        cb(false, false)
    end
end)

QBCore.Functions.CreateCallback('qb-phone:server:GetPhoneData', function(source, cb)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if Player ~= nil then
        local PhoneData = {
            Applications = {},
            PlayerContacts = {},
            MentionedTweets = {},
            Chats = {},
            Hashtags = {},
            Invoices = {},
            Garage = {},
            Mails = {},
            Adverts = {},
            CryptoTransactions = {},
            Tweets = {},
            Images = {},
            InstalledApps = Player.PlayerData.metadata["phonedata"].InstalledApps
        }
        PhoneData.Adverts = Adverts

        local result = MySQL.query.await('SELECT * FROM player_contacts WHERE citizenid = ? ORDER BY name ASC', {Player.PlayerData.citizenid})
        if result[1] ~= nil then
            for _, v in pairs(result) do
                v.status = GetOnlineStatus(v.number)
            end

            PhoneData.PlayerContacts = result
        end

        local invoices = MySQL.query.await('SELECT * FROM phone_invoices WHERE citizenid = ?', {Player.PlayerData.citizenid})
        if invoices[1] ~= nil then
            for _, v in pairs(invoices) do
                local Ply = QBCore.Functions.GetPlayerByCitizenId(v.sender)
                if Ply ~= nil then
                    v.number = Ply.PlayerData.charinfo.phone
                else
                    local res = MySQL.query.await('SELECT * FROM players WHERE citizenid = ?', {v.sender})
                    if res[1] ~= nil then
                        res[1].charinfo = json.decode(res[1].charinfo)
                        v.number = res[1].charinfo.phone
                    else
                        v.number = nil
                    end
                end
            end
            PhoneData.Invoices = invoices
        end

        local garageresult = MySQL.query.await('SELECT * FROM player_vehicles WHERE citizenid = ?', {Player.PlayerData.citizenid})
        if garageresult[1] ~= nil then
            for _, v in pairs(garageresult) do
                local vehicleModel = v.vehicle
                if (QBCore.Shared.Vehicles[vehicleModel] ~= nil) and (Config.Garages[tonumber(v.garage)] ~= nil) then
                    v.garage = Config.Garages[tonumber(v.garage)].name
                    v.vehicle = QBCore.Shared.Vehicles[vehicleModel].name
                    v.brand = QBCore.Shared.Vehicles[vehicleModel].brand
                end
            end
            PhoneData.Garage = garageresult
        end

        local messages = MySQL.query.await('SELECT * FROM phone_messages WHERE citizenid = ?', {Player.PlayerData.citizenid})
        if messages ~= nil and next(messages) ~= nil then
            PhoneData.Chats = messages
        end

        if AppAlerts[Player.PlayerData.citizenid] ~= nil then
            PhoneData.Applications = AppAlerts[Player.PlayerData.citizenid]
        end

        if MentionedTweets[Player.PlayerData.citizenid] ~= nil then
            PhoneData.MentionedTweets = MentionedTweets[Player.PlayerData.citizenid]
        end

        if Hashtags ~= nil and next(Hashtags) ~= nil then
            PhoneData.Hashtags = Hashtags
        end

        local Tweets = MySQL.query.await('SELECT * FROM phone_tweets WHERE `date` > NOW() - INTERVAL ? hour', {Config.TweetDuration})

        if Tweets ~= nil and next(Tweets) ~= nil then
            PhoneData.Tweets = Tweets
            TWData = Tweets
        end

        local mails = MySQL.query.await('SELECT * FROM player_mails WHERE citizenid = ? ORDER BY `date` ASC', {Player.PlayerData.citizenid})
        if mails[1] ~= nil then
            for k, _ in pairs(mails) do
                if mails[k].button ~= nil then
                    mails[k].button = json.decode(mails[k].button)
                end
            end
            PhoneData.Mails = mails
        end

        local transactions = MySQL.query.await('SELECT * FROM crypto_transactions WHERE citizenid = ? ORDER BY `date` ASC', {Player.PlayerData.citizenid})
        if transactions[1] ~= nil then
            for _, v in pairs(transactions) do
                PhoneData.CryptoTransactions[#PhoneData.CryptoTransactions+1] = {
                    TransactionTitle = v.title,
                    TransactionMessage = v.message
                }
            end
        end
        local images = MySQL.query.await('SELECT * FROM phone_gallery WHERE citizenid = ? ORDER BY `date` DESC',{Player.PlayerData.citizenid})
        if images ~= nil and next(images) ~= nil then
            PhoneData.Images = images
        end
        cb(PhoneData)
    end
end)

QBCore.Functions.CreateCallback('qb-phone:server:PayInvoice', function(source, cb, society, amount, invoiceId, sendercitizenid)
    local Invoices = {}
    local Ply = QBCore.Functions.GetPlayer(source)
    if not Ply then cb(false, Invoices) return end

    -- Money Authority fix (2026-08-29): society/amount/sendercitizenidはクライアント申告値のため使用せず、
    -- invoiceId(識別子)からDBの実際の請求内容(phone_invoices)を取得して使用する。
    local invoice = MySQL.single.await('SELECT * FROM phone_invoices WHERE id = ?', { invoiceId })
    if not invoice or invoice.citizenid ~= Ply.PlayerData.citizenid then
        cb(false, Invoices)
        return
    end

    local realAmount = tonumber(invoice.amount)
    local realSociety = invoice.society
    local realSenderCitizenId = invoice.sendercitizenid
    if not realAmount or realAmount <= 0 then
        cb(false, Invoices)
        return
    end

    if not Ply.Functions.RemoveMoney('bank', realAmount, "paid-invoice") then
        cb(false, Invoices)
        return
    end

    local SenderPly = QBCore.Functions.GetPlayerByCitizenId(realSenderCitizenId)
    local invoiceMailData = {}
    if SenderPly and Config.BillingCommissions[realSociety] then
        local commission = round(realAmount * Config.BillingCommissions[realSociety])
        SenderPly.Functions.AddMoney('bank', commission)
        invoiceMailData = {
            sender = 'Billing Department',
            subject = 'Commission Received',
            message = string.format('You received a commission check of $%s when %s %s paid a bill of $%s.', commission, Ply.PlayerData.charinfo.firstname, Ply.PlayerData.charinfo.lastname, realAmount)
        }
    elseif not SenderPly and Config.BillingCommissions[realSociety] then
        invoiceMailData = {
            sender = 'Billing Department',
            subject = 'Bill Paid',
            message = string.format('%s %s paid a bill of $%s', Ply.PlayerData.charinfo.firstname, Ply.PlayerData.charinfo.lastname, realAmount)
        }
    end
    exports['qb-phone']:sendNewMailToOffline(realSenderCitizenId, invoiceMailData)
    exports['qb-management']:AddMoney(realSociety, realAmount)
    MySQL.query('DELETE FROM phone_invoices WHERE id = ?', {invoiceId})
    local invoices = MySQL.query.await('SELECT * FROM phone_invoices WHERE citizenid = ?', {Ply.PlayerData.citizenid})
    if invoices[1] ~= nil then
        Invoices = invoices
    end
    cb(true, Invoices)
end)

QBCore.Functions.CreateCallback('qb-phone:server:DeclineInvoice', function(source, cb, _, _, invoiceId)
    local Invoices = {}
    local Ply = QBCore.Functions.GetPlayer(source)
    MySQL.query('DELETE FROM phone_invoices WHERE id = ?', {invoiceId})
    local invoices = MySQL.query.await('SELECT * FROM phone_invoices WHERE citizenid = ?', {Ply.PlayerData.citizenid})
    if invoices[1] ~= nil then
        Invoices = invoices
    end
    cb(true, Invoices)
end)

QBCore.Functions.CreateCallback('qb-phone:server:GetContactPictures', function(_, cb, Chats)
    for _, v in pairs(Chats) do
        local query = '%' .. v.number .. '%'
        local result = MySQL.query.await('SELECT * FROM players WHERE charinfo LIKE ?', {query})
        if result[1] ~= nil then
            local MetaData = json.decode(result[1].metadata)

            if MetaData.phone.profilepicture ~= nil then
                v.picture = MetaData.phone.profilepicture
            else
                v.picture = "default"
            end
        end
    end
    SetTimeout(100, function()
        cb(Chats)
    end)
end)

QBCore.Functions.CreateCallback('qb-phone:server:GetContactPicture', function(_, cb, Chat)
    local query = '%' .. Chat.number .. '%'
    local result = MySQL.query.await('SELECT * FROM players WHERE charinfo LIKE ?', {query})
    local MetaData = json.decode(result[1].metadata)
    if MetaData.phone.profilepicture ~= nil then
        Chat.picture = MetaData.phone.profilepicture
    else
        Chat.picture = "default"
    end
    SetTimeout(100, function()
        cb(Chat)
    end)
end)

QBCore.Functions.CreateCallback('qb-phone:server:GetPicture', function(_, cb, number)
    local query = '%' .. number .. '%'
    local result = MySQL.query.await('SELECT * FROM players WHERE charinfo LIKE ?', {query})
    if result[1] ~= nil then
        local Picture = "default"
        local MetaData = json.decode(result[1].metadata)
        if MetaData.phone.profilepicture ~= nil then
            Picture = MetaData.phone.profilepicture
        end
        cb(Picture)
    else
        cb(nil)
    end
end)

QBCore.Functions.CreateCallback('qb-phone:server:FetchResult', function(_, cb, search)
    search = escape_sqli(search)
    local searchData = {}
    local ApaData = {}
    local query = 'SELECT * FROM `players` WHERE `citizenid` = "' .. search .. '"'
    -- Split on " " and check each var individual
    local searchParameters = SplitStringToArray(search)
    -- Construct query dynamicly for individual parm check
    if #searchParameters > 1 then
        query = query .. ' OR `charinfo` LIKE "%' .. searchParameters[1] .. '%"'
        for i = 2, #searchParameters do
            query = query .. ' AND `charinfo` LIKE  "%' .. searchParameters[i] .. '%"'
        end
    else
        query = query .. ' OR `charinfo` LIKE "%' .. search .. '%"'
    end
    local ApartmentData = MySQL.query.await('SELECT * FROM apartments', {})
    for k, v in pairs(ApartmentData) do
        ApaData[v.citizenid] = ApartmentData[k]
    end
    local result = MySQL.query.await(query)
    if result[1] ~= nil then
        for _, v in pairs(result) do
            local charinfo = json.decode(v.charinfo)
            local metadata = json.decode(v.metadata)
            local appiepappie = {}
            if ApaData[v.citizenid] ~= nil and next(ApaData[v.citizenid]) ~= nil then
                appiepappie = ApaData[v.citizenid]
            end
            searchData[#searchData+1] = {
                citizenid = v.citizenid,
                firstname = charinfo.firstname,
                lastname = charinfo.lastname,
                birthdate = charinfo.birthdate,
                phone = charinfo.phone,
                nationality = charinfo.nationality,
                gender = charinfo.gender,
                warrant = false,
                driverlicense = metadata["licences"]["driver"],
                appartmentdata = appiepappie
            }
        end
        cb(searchData)
    else
        cb(nil)
    end
end)

QBCore.Functions.CreateCallback('qb-phone:server:GetVehicleSearchResults', function(_, cb, search)
    search = escape_sqli(search)
    local searchData = {}
    local query = '%' .. search .. '%'
    local result = MySQL.query.await('SELECT * FROM player_vehicles WHERE plate LIKE ? OR citizenid = ?',
        {query, search})
    if result[1] ~= nil then
        for k, _ in pairs(result) do
            local player = MySQL.query.await('SELECT * FROM players WHERE citizenid = ?', {result[k].citizenid})
            if player[1] ~= nil then
                local charinfo = json.decode(player[1].charinfo)
                local vehicleInfo = QBCore.Shared.Vehicles[result[k].vehicle]
                if vehicleInfo ~= nil then
                    searchData[#searchData+1] = {
                        plate = result[k].plate,
                        status = true,
                        owner = charinfo.firstname .. " " .. charinfo.lastname,
                        citizenid = result[k].citizenid,
                        label = vehicleInfo["name"]
                    }
                else
                    searchData[#searchData+1] = {
                        plate = result[k].plate,
                        status = true,
                        owner = charinfo.firstname .. " " .. charinfo.lastname,
                        citizenid = result[k].citizenid,
                        label = "Name not found.."
                    }
                end
            end
        end
    else
        if GeneratedPlates[search] ~= nil then
            searchData[#searchData+1] = {
                plate = GeneratedPlates[search].plate,
                status = GeneratedPlates[search].status,
                owner = GeneratedPlates[search].owner,
                citizenid = GeneratedPlates[search].citizenid,
                label = "Brand unknown.."
            }
        else
            local ownerInfo = GenerateOwnerName()
            GeneratedPlates[search] = {
                plate = search,
                status = true,
                owner = ownerInfo.name,
                citizenid = ownerInfo.citizenid
            }
            searchData[#searchData+1] = {
                plate = search,
                status = true,
                owner = ownerInfo.name,
                citizenid = ownerInfo.citizenid,
                label = "Brand unknown.."
            }
        end
    end
    cb(searchData)
end)

QBCore.Functions.CreateCallback('qb-phone:server:ScanPlate', function(source, cb, plate)
    local src = source
    local vehicleData
    if plate ~= nil then
        local result = MySQL.query.await('SELECT * FROM player_vehicles WHERE plate = ?', {plate})
        if result[1] ~= nil then
            local player = MySQL.query.await('SELECT * FROM players WHERE citizenid = ?', {result[1].citizenid})
            local charinfo = json.decode(player[1].charinfo)
            vehicleData = {
                plate = plate,
                status = true,
                owner = charinfo.firstname .. " " .. charinfo.lastname,
                citizenid = result[1].citizenid
            }
        elseif GeneratedPlates ~= nil and GeneratedPlates[plate] ~= nil then
            vehicleData = GeneratedPlates[plate]
        else
            local ownerInfo = GenerateOwnerName()
            GeneratedPlates[plate] = {
                plate = plate,
                status = true,
                owner = ownerInfo.name,
                citizenid = ownerInfo.citizenid
            }
            vehicleData = {
                plate = plate,
                status = true,
                owner = ownerInfo.name,
                citizenid = ownerInfo.citizenid
            }
        end
        cb(vehicleData)
    else
        TriggerClientEvent('QBCore:Notify', src, 'No Vehicle Nearby', 'error')
        cb(nil)
    end
end)

QBCore.Functions.CreateCallback('qb-phone:server:HasPhone', function(source, cb)
    local Player = QBCore.Functions.GetPlayer(source)
    if Player ~= nil then
        local HasPhone = Player.Functions.GetItemByName("phone")
        if HasPhone ~= nil then
            cb(true)
        else
            cb(false)
        end
    end
end)

-- Added: correctly-named callback for the Garage app vehicle list.
-- Fixes a naming mismatch bug: client/main.lua previously called the
-- non-existent callback 'qb-garage:server:GetPlayerVehicles1', which was
-- never registered anywhere, so the Garage app's vehicle list never
-- populated. This callback queries player_vehicles by citizenid (the same
-- ownership check qb-garages itself uses) and resolves the fields the
-- Garage app UI (html/js/garage.js) expects: fullname, brand, and the
-- garage's display label (Config.Garages here is qb-garages' own config,
-- loaded via the '@qb-garages/config.lua' shared/server script in
-- fxmanifest.lua, and uses string keys with a 'label' field, not numeric
-- keys with a 'name' field as the old, unused code elsewhere in this file
-- assumed).
QBCore.Functions.CreateCallback('qb-phone:server:GetGarageVehicles', function(source, cb)
    local Player = QBCore.Functions.GetPlayer(source)
    if Player == nil then
        cb({})
        return
    end

    local vehicles = MySQL.query.await('SELECT * FROM player_vehicles WHERE citizenid = ?', { Player.PlayerData.citizenid })
    if vehicles[1] ~= nil then
        for _, v in pairs(vehicles) do
            local vehInfo = QBCore.Shared.Vehicles[v.vehicle]
            if vehInfo ~= nil then
                v.brand = vehInfo.brand
                v.fullname = vehInfo.brand .. ' ' .. vehInfo.name
            end
            if v.garage ~= nil and Config.Garages[v.garage] ~= nil then
                v.garage = Config.Garages[v.garage].label
            end
        end
    end

    cb(vehicles)
end)

QBCore.Functions.CreateCallback('qb-phone:server:CanTransferMoney', function(source, cb, amount, iban)
    -- strip bad characters from bank transfers
    local newAmount = tostring(amount)
    local newiban = tostring(iban)
    for _, v in pairs(bannedCharacters) do
        newAmount = string.gsub(newAmount, '%' .. v, '')
        newiban = string.gsub(newiban, '%' .. v, '')
    end
    iban = newiban
    amount = tonumber(newAmount)

    local Player = QBCore.Functions.GetPlayer(source)
    if (Player.PlayerData.money.bank - amount) >= 0 then
        local query = '%"account":"' .. iban .. '"%'
        local result = MySQL.query.await('SELECT * FROM players WHERE charinfo LIKE ?', {query})
        if result[1] ~= nil then
            local Reciever = QBCore.Functions.GetPlayerByCitizenId(result[1].citizenid)
            Player.Functions.RemoveMoney('bank', amount)
            if Reciever ~= nil then
                Reciever.Functions.AddMoney('bank', amount)
            else
                local RecieverMoney = json.decode(result[1].money)
                RecieverMoney.bank = (RecieverMoney.bank + amount)
                MySQL.update('UPDATE players SET money = ? WHERE citizenid = ?', {json.encode(RecieverMoney), result[1].citizenid})
            end
            cb(true)
        else
            cb(false)
        end
    end
end)

QBCore.Functions.CreateCallback('qb-phone:server:GetCurrentLawyers', function(_, cb)
    local Lawyers = {}
    for _, v in pairs(QBCore.Functions.GetPlayers()) do
        local Player = QBCore.Functions.GetPlayer(v)
        if Player ~= nil then
            if (Player.PlayerData.job.name == "lawyer" or Player.PlayerData.job.name == "realestate" or
                Player.PlayerData.job.name == "mechanic" or Player.PlayerData.job.name == "taxi" or
                Player.PlayerData.job.name == "police" or Player.PlayerData.job.name == "ambulance") and
                Player.PlayerData.job.onduty then
                Lawyers[#Lawyers+1] = {
                    name = Player.PlayerData.charinfo.firstname .. " " .. Player.PlayerData.charinfo.lastname,
                    phone = Player.PlayerData.charinfo.phone,
                    typejob = Player.PlayerData.job.name
                }
            end
        end
    end
    cb(Lawyers)
end)

local webhookRequestCooldown = {}
QBCore.Functions.CreateCallback("qb-phone:server:GetWebhook",function(src,cb)
	-- [SECURITY FIX 2026-08-29] Basic anti-abuse: require a loaded player and
	-- rate-limit repeated requests. This does not make the URL secret from a
	-- determined attacker (the camera feature inherently needs the URL on the
	-- client to upload the photo), but it blocks casual spam/automated
	-- scraping and leaves a server console trail to help catch abuse early.
	local Player = QBCore.Functions.GetPlayer(src)
	if not Player then
		cb(nil)
		return
	end
	local now = GetGameTimer()
	if webhookRequestCooldown[src] and (now - webhookRequestCooldown[src]) < 5000 then
		print(('[qb-phone] GetWebhook requested too frequently by src %s (citizenid %s) - ignored'):format(src, Player.PlayerData.citizenid))
		cb(nil)
		return
	end
	webhookRequestCooldown[src] = now
	if WebHook ~= "" then
		print(('[qb-phone] Webhook URL was requested by src %s (citizenid %s) for camera upload'):format(src, Player.PlayerData.citizenid))
		cb(WebHook)
	else
		print('Set your webhook to ensure that your camera will work!!!!!! Set it in server/webhook_config.lua!!!!!')
		cb(nil)
	end
end)

AddEventHandler('playerDropped', function()
	webhookRequestCooldown[source] = nil
end)

-- Events

RegisterNetEvent('qb-phone:server:AddAdvert', function(msg, url)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local CitizenId = Player.PlayerData.citizenid
    if Adverts[CitizenId] ~= nil then
        Adverts[CitizenId].message = msg
        Adverts[CitizenId].name = "@" .. Player.PlayerData.charinfo.firstname .. "" .. Player.PlayerData.charinfo.lastname
        Adverts[CitizenId].number = Player.PlayerData.charinfo.phone
        Adverts[CitizenId].url = url
    else
        Adverts[CitizenId] = {
            message = msg,
            name = "@" .. Player.PlayerData.charinfo.firstname .. "" .. Player.PlayerData.charinfo.lastname,
            number = Player.PlayerData.charinfo.phone,
            url = url
        }
    end
    TriggerClientEvent('qb-phone:client:UpdateAdverts', -1, Adverts, "@" .. Player.PlayerData.charinfo.firstname .. "" .. Player.PlayerData.charinfo.lastname)
end)

RegisterNetEvent('qb-phone:server:DeleteAdvert', function()
    local Player = QBCore.Functions.GetPlayer(source)
    local citizenid = Player.PlayerData.citizenid
    Adverts[citizenid] = nil
    TriggerClientEvent('qb-phone:client:UpdateAdvertsDel', -1, Adverts)
end)

RegisterNetEvent('qb-phone:server:SetCallState', function(bool)
    local src = source
    local Ply = QBCore.Functions.GetPlayer(src)
    if Calls[Ply.PlayerData.citizenid] ~= nil then
        Calls[Ply.PlayerData.citizenid].inCall = bool
    else
        Calls[Ply.PlayerData.citizenid] = {}
        Calls[Ply.PlayerData.citizenid].inCall = bool
    end
end)

RegisterNetEvent('qb-phone:server:RemoveMail', function(MailId)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    MySQL.query('DELETE FROM player_mails WHERE mailid = ? AND citizenid = ?', {MailId, Player.PlayerData.citizenid})
    SetTimeout(100, function()
        local mails = MySQL.query.await('SELECT * FROM player_mails WHERE citizenid = ? ORDER BY `date` ASC', {Player.PlayerData.citizenid})
        if mails[1] ~= nil then
            for k, _ in pairs(mails) do
                if mails[k].button ~= nil then
                    mails[k].button = json.decode(mails[k].button)
                end
            end
        end
        TriggerClientEvent('qb-phone:client:UpdateMails', src, mails)
    end)
end)

RegisterNetEvent('qb-phone:server:sendNewMail', function(mailData)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if mailData.button == nil then
        MySQL.insert('INSERT INTO player_mails (`citizenid`, `sender`, `subject`, `message`, `mailid`, `read`) VALUES (?, ?, ?, ?, ?, ?)', {Player.PlayerData.citizenid, mailData.sender, mailData.subject, mailData.message, GenerateMailId(), 0})
    else
        MySQL.insert('INSERT INTO player_mails (`citizenid`, `sender`, `subject`, `message`, `mailid`, `read`, `button`) VALUES (?, ?, ?, ?, ?, ?, ?)', {Player.PlayerData.citizenid, mailData.sender, mailData.subject, mailData.message, GenerateMailId(), 0, json.encode(mailData.button)})
    end
    TriggerClientEvent('qb-phone:client:NewMailNotify', src, mailData)
    SetTimeout(200, function()
        local mails = MySQL.query.await('SELECT * FROM player_mails WHERE citizenid = ? ORDER BY `date` DESC',
            {Player.PlayerData.citizenid})
        if mails[1] ~= nil then
            for k, _ in pairs(mails) do
                if mails[k].button ~= nil then
                    mails[k].button = json.decode(mails[k].button)
                end
            end
        end

        TriggerClientEvent('qb-phone:client:UpdateMails', src, mails)
    end)
end)

RegisterNetEvent('qb-phone:server:sendNewEventMail', function(citizenid, mailData)
    local Player = QBCore.Functions.GetPlayerByCitizenId(citizenid)
    if mailData.button == nil then
        MySQL.insert('INSERT INTO player_mails (`citizenid`, `sender`, `subject`, `message`, `mailid`, `read`) VALUES (?, ?, ?, ?, ?, ?)', {citizenid, mailData.sender, mailData.subject, mailData.message, GenerateMailId(), 0})
    else
        MySQL.insert('INSERT INTO player_mails (`citizenid`, `sender`, `subject`, `message`, `mailid`, `read`, `button`) VALUES (?, ?, ?, ?, ?, ?, ?)', {citizenid, mailData.sender, mailData.subject, mailData.message, GenerateMailId(), 0, json.encode(mailData.button)})
    end
    SetTimeout(200, function()
        local mails = MySQL.query.await('SELECT * FROM player_mails WHERE citizenid = ? ORDER BY `date` ASC', {citizenid})
        if mails[1] ~= nil then
            for k, _ in pairs(mails) do
                if mails[k].button ~= nil then
                    mails[k].button = json.decode(mails[k].button)
                end
            end
        end
        TriggerClientEvent('qb-phone:client:UpdateMails', Player.PlayerData.source, mails)
    end)
end)

RegisterNetEvent('qb-phone:server:ClearButtonData', function(mailId)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    MySQL.update('UPDATE player_mails SET button = ? WHERE mailid = ? AND citizenid = ?', {'', mailId, Player.PlayerData.citizenid})
    SetTimeout(200, function()
        local mails = MySQL.query.await('SELECT * FROM player_mails WHERE citizenid = ? ORDER BY `date` ASC', {Player.PlayerData.citizenid})
        if mails[1] ~= nil then
            for k, _ in pairs(mails) do
                if mails[k].button ~= nil then
                    mails[k].button = json.decode(mails[k].button)
                end
            end
        end
        TriggerClientEvent('qb-phone:client:UpdateMails', src, mails)
    end)
end)

RegisterNetEvent('qb-phone:server:MentionedPlayer', function(firstName, lastName, TweetMessage)
    for _, v in pairs(QBCore.Functions.GetPlayers()) do
        local Player = QBCore.Functions.GetPlayer(v)
        if Player ~= nil then
            if (Player.PlayerData.charinfo.firstname == firstName and Player.PlayerData.charinfo.lastname == lastName) then
                QBPhone.SetPhoneAlerts(Player.PlayerData.citizenid, "twitter")
                QBPhone.AddMentionedTweet(Player.PlayerData.citizenid, TweetMessage)
                TriggerClientEvent('qb-phone:client:GetMentioned', Player.PlayerData.source, TweetMessage, AppAlerts[Player.PlayerData.citizenid]["twitter"])
            else
                local query1 = '%' .. firstName .. '%'
                local query2 = '%' .. lastName .. '%'
                local result = MySQL.query.await('SELECT * FROM players WHERE charinfo LIKE ? AND charinfo LIKE ?', {query1, query2})
                if result[1] ~= nil then
                    local MentionedTarget = result[1].citizenid
                    QBPhone.SetPhoneAlerts(MentionedTarget, "twitter")
                    QBPhone.AddMentionedTweet(MentionedTarget, TweetMessage)
                end
            end
        end
    end
end)

RegisterNetEvent('qb-phone:server:CallContact', function(TargetData, CallId, AnonymousCall)
    local src = source
    local Ply = QBCore.Functions.GetPlayer(src)
    local Target = QBCore.Functions.GetPlayerByPhone(TargetData.number)
    if Target ~= nil then
        TriggerClientEvent('qb-phone:client:GetCalled', Target.PlayerData.source, Ply.PlayerData.charinfo.phone, CallId, AnonymousCall)
    end
end)

RegisterNetEvent('qb-phone:server:BillingEmail', function(data, paid)
    for _, v in pairs(QBCore.Functions.GetPlayers()) do
        local target = QBCore.Functions.GetPlayer(v)
        if target.PlayerData.job.name == data.society then
            if paid then
                local name = '' .. QBCore.Functions.GetPlayer(source).PlayerData.charinfo.firstname .. ' ' .. QBCore.Functions.GetPlayer(source).PlayerData.charinfo.lastname .. ''
                TriggerClientEvent('qb-phone:client:BillingEmail', target.PlayerData.source, data, true, name)
            else
                local name = '' .. QBCore.Functions.GetPlayer(source).PlayerData.charinfo.firstname .. ' ' .. QBCore.Functions.GetPlayer(source).PlayerData.charinfo.lastname .. ''
                TriggerClientEvent('qb-phone:client:BillingEmail', target.PlayerData.source, data, false, name)
            end
        end
    end
end)

RegisterNetEvent('qb-phone:server:UpdateHashtags', function(Handle, messageData)
    if Hashtags[Handle] ~= nil and next(Hashtags[Handle]) ~= nil then
        Hashtags[Handle].messages[#Hashtags[Handle].messages+1] = messageData
    else
        Hashtags[Handle] = {
            hashtag = Handle,
            messages = {}
        }
        Hashtags[Handle].messages[#Hashtags[Handle].messages+1] = messageData
    end
    TriggerClientEvent('qb-phone:client:UpdateHashtags', -1, Handle, messageData)
end)

RegisterNetEvent('qb-phone:server:SetPhoneAlerts', function(app, alerts)
    local src = source
    local CitizenId = QBCore.Functions.GetPlayer(src).citizenid
    QBPhone.SetPhoneAlerts(CitizenId, app, alerts)
end)

RegisterNetEvent('qb-phone:server:DeleteTweet', function(tweetId)
    local Player = QBCore.Functions.GetPlayer(source)
    local delete = false
    local TID = tweetId
    local Data = MySQL.scalar.await('SELECT citizenid FROM phone_tweets WHERE tweetId = ?', {TID})
    if Data == Player.PlayerData.citizenid then
        MySQL.query.await('DELETE FROM phone_tweets WHERE tweetId = ?', {TID})
        delete = true
    end

    if delete then
        for k, _ in pairs(TWData) do
            if TWData[k].tweetId == TID then
                TWData = nil
            end
        end
        TriggerClientEvent('qb-phone:client:UpdateTweets', -1, TWData, nil, true)
    end
end)

RegisterNetEvent('qb-phone:server:UpdateTweets', function(NewTweets, TweetData)
    local src = source
    if Config.Linux then
        MySQL.insert('INSERT INTO phone_tweets (citizenid, firstName, lastName, message, date, url, picture, tweetid) VALUES (?, ?, ?, ?, ?, ?, ?, ?)', {
            TweetData.citizenid,
            TweetData.firstName,
            TweetData.lastName,
            TweetData.message,
            TweetData.date,
            TweetData.url:gsub("[%<>\"()\' $]",""),
            TweetData.picture:gsub("[%<>\"()\' $]",""),
            TweetData.tweetId
        })
        TriggerClientEvent('qb-phone:client:UpdateTweets', -1, src, NewTweets, TweetData, false)
    else
        MySQL.insert('INSERT INTO phone_tweets (citizenid, firstName, lastName, message, date, url, picture, tweetid) VALUES (?, ?, ?, ?, ?, ?, ?, ?)', {
            TweetData.citizenid,
            TweetData.firstName,
            TweetData.lastName,
            TweetData.message,
            TweetData.time,
            TweetData.url:gsub("[%<>\"()\' $]",""),
            TweetData.picture:gsub("[%<>\"()\' $]",""),
            TweetData.tweetId
        })
        TriggerClientEvent('qb-phone:client:UpdateTweets', -1, src, NewTweets, TweetData, false)
    end
end)

RegisterNetEvent('qb-phone:server:TransferMoney', function(iban, amount)
    local src = source
    local sender = QBCore.Functions.GetPlayer(src)
    if not sender then return end

    -- Money Authority fix (2026-08-29): amountを検証し、送金元からの引き落としが成功した場合のみ着金させる。
    -- 従来は着金(AddMoney)が先に実行され、引き落とし(RemoveMoney)の成否も見ていなかったため、
    -- 残高不足でも相手に入金されてしまう複製バグになっていた。
    amount = tonumber(amount)
    if not amount or amount <= 0 then return end

    local query = '%' .. iban .. '%'
    local result = MySQL.query.await('SELECT * FROM players WHERE charinfo LIKE ?', {query})
    if result[1] ~= nil then
        if not sender.Functions.RemoveMoney('bank', amount, "phone-transfered") then
            TriggerClientEvent('QBCore:Notify', src, "You don't have enough money!", "error")
            return
        end

        local reciever = QBCore.Functions.GetPlayerByCitizenId(result[1].citizenid)

        if reciever ~= nil then
            local PhoneItem = reciever.Functions.GetItemByName("phone")
            reciever.Functions.AddMoney('bank', amount, "phone-transfered-from-" .. sender.PlayerData.citizenid)

            if PhoneItem ~= nil then
                TriggerClientEvent('qb-phone:client:TransferMoney', reciever.PlayerData.source, amount,
                    reciever.PlayerData.money.bank)
            end
        else
            local moneyInfo = json.decode(result[1].money)
            moneyInfo.bank = round((moneyInfo.bank + amount))
            MySQL.update('UPDATE players SET money = ? WHERE citizenid = ?',
                {json.encode(moneyInfo), result[1].citizenid})
        end
    else
        TriggerClientEvent('QBCore:Notify', src, "This account number doesn't exist!", "error")
    end
end)

RegisterNetEvent('qb-phone:server:EditContact', function(newName, newNumber, newIban, oldName, oldNumber, _)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    MySQL.update(
        'UPDATE player_contacts SET name = ?, number = ?, iban = ? WHERE citizenid = ? AND name = ? AND number = ?',
        {newName, newNumber, newIban, Player.PlayerData.citizenid, oldName, oldNumber})
end)

RegisterNetEvent('qb-phone:server:RemoveContact', function(Name, Number)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    MySQL.query('DELETE FROM player_contacts WHERE name = ? AND number = ? AND citizenid = ?',
        {Name, Number, Player.PlayerData.citizenid})
end)

RegisterNetEvent('qb-phone:server:AddNewContact', function(name, number, iban)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    MySQL.insert('INSERT INTO player_contacts (citizenid, name, number, iban) VALUES (?, ?, ?, ?)', {Player.PlayerData.citizenid, tostring(name), tostring(number), tostring(iban)})
end)

RegisterNetEvent('qb-phone:server:UpdateMessages', function(ChatMessages, ChatNumber, _)
    local src = source
    local SenderData = QBCore.Functions.GetPlayer(src)
    local query = '%' .. ChatNumber .. '%'
    local Player = MySQL.query.await('SELECT * FROM players WHERE charinfo LIKE ?', {query})
    if Player[1] ~= nil then
        local TargetData = QBCore.Functions.GetPlayerByCitizenId(Player[1].citizenid)
        if TargetData ~= nil then
            local Chat = MySQL.query.await('SELECT * FROM phone_messages WHERE citizenid = ? AND number = ?', {SenderData.PlayerData.citizenid, ChatNumber})
            if Chat[1] ~= nil then
                -- Update for target
                MySQL.update('UPDATE phone_messages SET messages = ? WHERE citizenid = ? AND number = ?', {json.encode(ChatMessages), TargetData.PlayerData.citizenid, SenderData.PlayerData.charinfo.phone})
                -- Update for sender
                MySQL.update('UPDATE phone_messages SET messages = ? WHERE citizenid = ? AND number = ?', {json.encode(ChatMessages), SenderData.PlayerData.citizenid, TargetData.PlayerData.charinfo.phone})
                -- Send notification & Update messages for target
                TriggerClientEvent('qb-phone:client:UpdateMessages', TargetData.PlayerData.source, ChatMessages, SenderData.PlayerData.charinfo.phone, false)
            else
                -- Insert for target
                MySQL.insert('INSERT INTO phone_messages (citizenid, number, messages) VALUES (?, ?, ?)', {TargetData.PlayerData.citizenid, SenderData.PlayerData.charinfo.phone, json.encode(ChatMessages)})
                -- Insert for sender
                MySQL.insert('INSERT INTO phone_messages (citizenid, number, messages) VALUES (?, ?, ?)', {SenderData.PlayerData.citizenid, TargetData.PlayerData.charinfo.phone, json.encode(ChatMessages)})
                -- Send notification & Update messages for target
                TriggerClientEvent('qb-phone:client:UpdateMessages', TargetData.PlayerData.source, ChatMessages, SenderData.PlayerData.charinfo.phone, true)
            end
        else
            local Chat = MySQL.query.await('SELECT * FROM phone_messages WHERE citizenid = ? AND number = ?', {SenderData.PlayerData.citizenid, ChatNumber})
            if Chat[1] ~= nil then
                -- Update for target
                MySQL.update('UPDATE phone_messages SET messages = ? WHERE citizenid = ? AND number = ?', {json.encode(ChatMessages), Player[1].citizenid, SenderData.PlayerData.charinfo.phone})
                -- Update for sender
                Player[1].charinfo = json.decode(Player[1].charinfo)
                MySQL.update('UPDATE phone_messages SET messages = ? WHERE citizenid = ? AND number = ?', {json.encode(ChatMessages), SenderData.PlayerData.citizenid, Player[1].charinfo.phone})
            else
                -- Insert for target
                MySQL.insert('INSERT INTO phone_messages (citizenid, number, messages) VALUES (?, ?, ?)', {Player[1].citizenid, SenderData.PlayerData.charinfo.phone, json.encode(ChatMessages)})
                -- Insert for sender
                Player[1].charinfo = json.decode(Player[1].charinfo)
                MySQL.insert('INSERT INTO phone_messages (citizenid, number, messages) VALUES (?, ?, ?)', {SenderData.PlayerData.citizenid, Player[1].charinfo.phone, json.encode(ChatMessages)})
            end
        end
    end
end)

RegisterNetEvent('qb-phone:server:AddRecentCall', function(type, data)
    local src = source
    local Ply = QBCore.Functions.GetPlayer(src)
    local Hour = os.date("%H")
    local Minute = os.date("%M")
    local label = Hour .. ":" .. Minute
    TriggerClientEvent('qb-phone:client:AddRecentCall', src, data, label, type)
    local Trgt = QBCore.Functions.GetPlayerByPhone(data.number)
    if Trgt ~= nil then
        TriggerClientEvent('qb-phone:client:AddRecentCall', Trgt.PlayerData.source, {
            name = Ply.PlayerData.charinfo.firstname .. " " .. Ply.PlayerData.charinfo.lastname,
            number = Ply.PlayerData.charinfo.phone,
            anonymous = data.anonymous
        }, label, "outgoing")
    end
end)

RegisterNetEvent('qb-phone:server:CancelCall', function(ContactData)
    local Ply = QBCore.Functions.GetPlayerByPhone(ContactData.TargetData.number)
    if Ply ~= nil then
        TriggerClientEvent('qb-phone:client:CancelCall', Ply.PlayerData.source)
    end
end)

RegisterNetEvent('qb-phone:server:AnswerCall', function(CallData)
    local Ply = QBCore.Functions.GetPlayerByPhone(CallData.TargetData.number)
    if Ply ~= nil then
        TriggerClientEvent('qb-phone:client:AnswerCall', Ply.PlayerData.source)
    end
end)

RegisterNetEvent('qb-phone:server:SaveMetaData', function(MData)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local result = MySQL.query.await('SELECT * FROM players WHERE citizenid = ?', {Player.PlayerData.citizenid})
    local MetaData = json.decode(result[1].metadata)
    MetaData.phone = MData
    MySQL.update('UPDATE players SET metadata = ? WHERE citizenid = ?',
        {json.encode(MetaData), Player.PlayerData.citizenid})
    Player.Functions.SetMetaData("phone", MData)
end)

RegisterNetEvent('qb-phone:server:GiveContactDetails', function(PlayerId)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local SuggestionData = {
        name = {
            [1] = Player.PlayerData.charinfo.firstname,
            [2] = Player.PlayerData.charinfo.lastname
        },
        number = Player.PlayerData.charinfo.phone,
        bank = Player.PlayerData.charinfo.account
    }

    TriggerClientEvent('qb-phone:client:AddNewSuggestion', PlayerId, SuggestionData)
end)

RegisterNetEvent('qb-phone:server:AddTransaction', function(data)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    MySQL.insert('INSERT INTO crypto_transactions (citizenid, title, message) VALUES (?, ?, ?)', {
        Player.PlayerData.citizenid,
        data.TransactionTitle,
        data.TransactionMessage
    })
end)

RegisterNetEvent('qb-phone:server:InstallApplication', function(ApplicationData)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    Player.PlayerData.metadata["phonedata"].InstalledApps[ApplicationData.app] = ApplicationData
    Player.Functions.SetMetaData("phonedata", Player.PlayerData.metadata["phonedata"])

    -- TriggerClientEvent('qb-phone:RefreshPhone', src)
end)

RegisterNetEvent('qb-phone:server:RemoveInstallation', function(App)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    Player.PlayerData.metadata["phonedata"].InstalledApps[App] = nil
    Player.Functions.SetMetaData("phonedata", Player.PlayerData.metadata["phonedata"])

    -- TriggerClientEvent('qb-phone:RefreshPhone', src)
end)

RegisterNetEvent('qb-phone:server:addImageToGallery', function(image)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    MySQL.insert('INSERT INTO phone_gallery (`citizenid`, `image`) VALUES (?, ?)',{Player.PlayerData.citizenid,image})
end)

RegisterNetEvent('qb-phone:server:getImageFromGallery', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local images = MySQL.query.await('SELECT * FROM phone_gallery WHERE citizenid = ? ORDER BY `date` DESC',{Player.PlayerData.citizenid})
    TriggerClientEvent('qb-phone:refreshImages', src, images)
end)

RegisterNetEvent('qb-phone:server:RemoveImageFromGallery', function(data)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local image = data.image
    MySQL.query('DELETE FROM phone_gallery WHERE citizenid = ? AND image = ?',{Player.PlayerData.citizenid,image})
end)

RegisterNetEvent('qb-phone:server:sendPing', function(data)
    local src = source
    if src == data then
        TriggerClientEvent("QBCore:Notify", src, "You cannot ping yourself", "error")
    end
end)

-- Command

QBCore.Commands.Add("setmetadata", "Set Player Metadata (God Only)", {}, false, function(source, args)
    local Player = QBCore.Functions.GetPlayer(source)
    if args[1] then
        if args[1] == "trucker" then
            if args[2] then
                local newrep = Player.PlayerData.metadata["jobrep"]
                newrep.trucker = tonumber(args[2])
                Player.Functions.SetMetaData("jobrep", newrep)
            end
        end
    end
end, "god")

QBCore.Commands.Add('bill', 'Bill A Player', {{name = 'id', help = 'Player ID'}, {name = 'amount', help = 'Fine Amount'}}, false, function(source, args)
    local biller = QBCore.Functions.GetPlayer(source)
    local billed = QBCore.Functions.GetPlayer(tonumber(args[1]))
    local amount = tonumber(args[2])
    if biller.PlayerData.job.name == "police" or biller.PlayerData.job.name == 'ambulance' or biller.PlayerData.job.name == 'mechanic' then
        if billed ~= nil then
            if biller.PlayerData.citizenid ~= billed.PlayerData.citizenid then
                if amount and amount > 0 then
                    MySQL.insert(
                        'INSERT INTO phone_invoices (citizenid, amount, society, sender, sendercitizenid) VALUES (?, ?, ?, ?, ?)',
                        {billed.PlayerData.citizenid, amount, biller.PlayerData.job.name,
                         biller.PlayerData.charinfo.firstname, biller.PlayerData.citizenid})
                    TriggerClientEvent('qb-phone:RefreshPhone', billed.PlayerData.source)
                    TriggerClientEvent('QBCore:Notify', source, 'Invoice Successfully Sent', 'success')
                    TriggerClientEvent('QBCore:Notify', billed.PlayerData.source, 'New Invoice Received')
                else
                    TriggerClientEvent('QBCore:Notify', source, 'Must Be A Valid Amount Above 0', 'error')
                end
            else
                TriggerClientEvent('QBCore:Notify', source, 'You Cannot Bill Yourself', 'error')
            end
        else
            TriggerClientEvent('QBCore:Notify', source, 'Player Not Online', 'error')
        end
    else
        TriggerClientEvent('QBCore:Notify', source, 'No Access', 'error')
    end
end)
print("^QBCore#4011^7 ^2 ^1https://discord.gg/qbcoreframework")

-- ping

local Pings = {}

RegisterNetEvent(Config.pings ..'server:SendPing2', function(id)
    local src = source

    TriggerClientEvent(Config.pings ..'client:DoPing', src, tonumber(id))
end)

RegisterNetEvent(Config.pings ..'server:acceptping', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if Pings[src] ~= nil then
        TriggerClientEvent(Config.pings ..'client:AcceptPing', src, Pings[src], QBCore.Functions.GetPlayer(Pings[src].sender))
        TriggerClientEvent('QBCore:Notify', Pings[src].sender, Player.PlayerData.charinfo.firstname.." "..Player.PlayerData.charinfo.lastname.." accepted your ping request!")
        Pings[src] = nil
    else
        TriggerClientEvent('QBCore:Notify', src, "You have no ping...", "error")
    end
end)

RegisterNetEvent(Config.pings ..'server:denyping', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if Pings[src] ~= nil then
        TriggerClientEvent('QBCore:Notify', Pings[src].sender, "Your ping request has been rejected...", "error")
        TriggerClientEvent('QBCore:Notify', src, "You turned down the ping...", "success")
        Pings[src] = nil
    else
        TriggerClientEvent('QBCore:Notify', src, "You have no ping...", "error")
    end
end)

RegisterNetEvent(Config.pings ..'server:SendPing', function(id)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local Target = QBCore.Functions.GetPlayer(id)
    local ped = GetPlayerPed(id)
    local coords = GetEntityCoords(ped)

    if Target ~= nil then
        local OtherItem = Target.Functions.GetItemByName("phone")
        if OtherItem ~= nil then
            TriggerClientEvent('QBCore:Notify', src, "You have requested the location of "..Target.PlayerData.charinfo.firstname.." "..Target.PlayerData.charinfo.lastname)
            Pings[id] = {
                coords = coords,
                sender = src,
            }
            TriggerClientEvent('QBCore:Notify', id, "You have received a ping request from "..Player.PlayerData.charinfo.firstname.." "..Player.PlayerData.charinfo.lastname..". Use the app to allow or reject!")
            TriggerClientEvent('qb-phone:ping:client:UiUppers', id, true)
        else
            TriggerClientEvent('QBCore:Notify', src, "Could not send ping...", "error")
        end
    else
        TriggerClientEvent('QBCore:Notify', src, "This person is not in the city...", "error")
    end
end)

RegisterNetEvent(Config.pings ..'server:SendLocation', function(PingData, SenderData)
    TriggerClientEvent(Config.pings ..'client:SendLocation', PingData.sender, PingData, SenderData)
end)




RegisterNetEvent('qb-phone:server:SendBillForPlayer_bill', function(data)
    local src = source
    local biller = QBCore.Functions.GetPlayer(src)
    local billed = QBCore.Functions.GetPlayer(tonumber(data.ID))
    local amount = tonumber(data.Amount)
    if billed then
            if amount and amount > 0 then
                MySQL.insert('INSERT INTO phone_debt (citizenid, amount,  sender, sendercitizenid, reason) VALUES (?, ?, ?, ?, ?)',{billed.PlayerData.citizenid, amount, biller.PlayerData.charinfo.firstname.." "..biller.PlayerData.charinfo.lastname, biller.PlayerData.citizenid, data.Reason})
                TriggerClientEvent('QBCore:Notify', src, 'bill successfully sent!', 'success')
                TriggerClientEvent('QBCore:Notify', billed.PlayerData.source, 'New bill Received')
                Wait(1)
                TriggerClientEvent('qb-phone:RefreshPhoneForbill', billed.PlayerData.source)
            else
                TriggerClientEvent('QBCore:Notify', src, 'Must be a valid amount above 0', 'error')
            end
    else
        TriggerClientEvent('QBCore:Notify', src, 'Player not Online', 'error')
    end
end)

QBCore.Functions.CreateCallback('qb-phone:server:GetHasBills_bill', function(source, cb)
    local src = source
    local Ply = QBCore.Functions.GetPlayer(src)
    local bill = MySQL.query.await('SELECT * FROM phone_debt WHERE citizenid = ?', {Ply.PlayerData.citizenid})
    Wait(400)
    if bill[1] ~= nil then
        cb(bill)
    end
end)

RegisterNetEvent('qb-phone:server:debit_AcceptBillForPay', function(data)
    local src = source
    local Ply = QBCore.Functions.GetPlayer(src)
    if not Ply then return end
    local ID = tonumber(data.id)
    if not ID then return end

    -- Money Authority fix (2026-08-29): 実際の請求額・請求元はDBのphone_debt行から取得し、
    -- クライアント申告のdata.Amount / data.CSNは使用しない(金額改ざん・送金先すり替えを防ぐ)。
    local bill = MySQL.single.await('SELECT * FROM phone_debt WHERE id = ?', { ID })
    if not bill or bill.citizenid ~= Ply.PlayerData.citizenid then return end

    local Amount = tonumber(bill.amount)
    if not Amount or Amount <= 0 then return end

    local OtherPly = QBCore.Functions.GetPlayerByCitizenId(bill.sendercitizenid)
    if OtherPly then
        if Ply.Functions.RemoveMoney('bank', Amount, "Remove Money For bill") then
            OtherPly.Functions.AddMoney('bank', Amount, "Add Money For bill")
            MySQL.query('DELETE FROM phone_debt WHERE id = ?', {ID})
            Wait(1)
            TriggerClientEvent('qb-phone:RefreshPhoneForbill', OtherPly.PlayerData.source)
        else
            TriggerClientEvent('QBCore:Notify', src, 'You don\'t have enough money...', 'error')
        end
    else
        TriggerClientEvent('QBCore:Notify', src, 'Player not Online', 'error')
    end
end)
