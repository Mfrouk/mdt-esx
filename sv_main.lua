---@diagnostic disable: need-check-nil, missing-parameter
ESX = nil
local policeJobs = {
    ['ambulance'] = true,
    ['police'] = true,
    ['sheriff'] = true
}
local usersRadios = {}

TriggerEvent('esx:getSharedObject', function(obj)
    ESX = obj
end)

exports('open', function(event, item, inventory, slot, data)
    if event == 'usingItem' then
        local src = inventory.id
        local xPlayer = ESX.GetPlayerFromId(src)
        local rank = xPlayer.getJob().grade_label
        if policeJobs[xPlayer.job.name] then
            TriggerClientEvent('rx_mdt:open', src, rank, xPlayer.variables.firstName, xPlayer.variables.lastName)
        end
    end
end)

RegisterCommand("+showMDT", function(source)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    local rank = xPlayer.getJob().grade_label
    if policeJobs[xPlayer.job.name] then
        TriggerClientEvent('rx_mdt:open', src, rank, xPlayer.variables.firstName, xPlayer.variables.lastName)
    end
end)

local CallSigns = {}
function GetCallsign(identifier)
    local result = MysqlConverter(Config.Mysql, 'fetchAll',
        'SELECT `callsign` FROM `users` WHERE identifier = @identifier', {
            ["@identifier"] = identifier
        })
    if result[1] ~= nil and result[1].callsign ~= nil then
        return result[1].callsign
    elseif CallSigns[identifier] then
        return CallSigns[identifier]
    else
        return 0
    end
end


RegisterServerEvent('rx_mdt:setRadio')
AddEventHandler("rx_mdt:setRadio", function(radio)
    local src = source
    local user = ESX.GetPlayerFromId(src)
    local char = user.getJob().grade_salary
    if not user then
        return
    end
    usersRadios[tonumber(char)] = radio
end)

RegisterServerEvent('police:setCallSign')
AddEventHandler("police:setCallSign", function(callsign)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    local char = xPlayer.getJob().grade_salary
    if not xPlayer then
        return
    end
    CallSigns[tonumber(char)] = callsign
end)

RegisterServerEvent("rx_mdt:opendashboard")
AddEventHandler("rx_mdt:opendashboard", function()
    local src = source
    UpdateWarrants(src)
    Updatebulletin(src)
    UpdateDispatch(src)
    UpdateUnits(src)
 --   getVehicles(src)
 --   getProfiles(src)
 --   UpdateReports(src)
end)

function UpdateWarrants(src)
    local firsttime = true
    local result = MysqlConverter(Config.Mysql, 'fetchAll', 'SELECT * FROM user_licenses WHERE type = "patrani"', {})
    local warrnts = {}

    TriggerClientEvent('rx_mdt:ResetWarants', src)
    if result then
        for k, v in pairs(result) do
            local result2 = MysqlConverter(Config.Mysql, 'fetchAll', 'SELECT firstname, lastname, dateofbirth FROM users WHERE identifier = "'..v.owner..'"', {})
            local player = ESX.GetPlayerFromIdentifier(string.sub(v.owner, 7))
            if player then
                TriggerClientEvent("rx_mdt:dashboardWarrants", src, {
                    firsttime = firsttime,
                    name = player.getName(),
                    cid = v.owner,
                    dob = result2[1].dateofbirth
                })
                firsttime = false 
            end
        end
    else
        print('Nikdo nebol najdeny') 
    end
end

function UpdateReports(src)
    local result = MysqlConverter(Config.Mysql, 'fetchAll', 'SELECT * FROM mdw_reports', {})
    TriggerClientEvent("rx_mdt:dashboardReports", src, result)
end

function Updatebulletin(src)
    local result = MysqlConverter(Config.Mysql, 'fetchAll', 'SELECT * FROM mdw_bulletin', {})
    TriggerClientEvent("rx_mdt:dashboardbulletin", src, result)
end

local playerOffDuty = {}
RegisterNetEvent('rx_mdt:toggleDuty', function(status)
    if status == 1 then
        status = 0
    else
        status = 1
    end
    playerOffDuty[source] = status
end)

function UpdateUnits(src)
    local lspd, sheriff, sasp, doc, sapr, pa, ems = {}, {}, {}, {}, {}, {}, {}

    for _, v in pairs(ESX.GetPlayers()) do
        local xPlayer = ESX.GetPlayerFromId(tonumber(v))
        if xPlayer then
            local xPlayerjob = xPlayer.getJob()
            local character = xPlayer.getIdentifier()
            local rank = xPlayerjob.grade and xPlayerjob.grade or 0
            local name = xPlayer.getName()
            local callSign = GetCallsign(character)
            if xPlayerjob.name == "police" then
                lspds = #lspd + 1
                lspd[lspds] = {}
                lspd[lspds].duty = playerOffDuty[tonumber(v)] == 1 and 0 or 1
                lspd[lspds].cid = character
                lspd[lspds].radio = usersRadios[character] or nil
                lspd[lspds].callsign = callSign
                lspd[lspds].name = name
            elseif xPlayerjob.name == "sheriff" then
                sheriffn = #sheriff + 1
                sheriff[sheriffn] = {}
                sheriff[sheriffn].duty = playerOffDuty[tonumber(v)] == 1 and 0 or 1
                sheriff[sheriffn].cid = character
                sheriff[sheriffn].radio = usersRadios[character] or nil
                sheriff[sheriffn].callsign = callSign
                sheriff[sheriffn].name = name
            elseif xPlayerjob.name == "sasp" then
                saspn = #lspd + 1
                sasp[saspn] = {}
                sasp[saspn].duty = playerOffDuty[tonumber(v)] == 1 and 0 or 1
                sasp[saspn].cid = character
                sasp[saspn].radio = usersRadios[character] or nil
                sasp[saspn].callsign = callSign
                sasp[saspn].name = name
            elseif xPlayer.job.name == "ambulance" then
                emss = #ems + 1
                ems[emss] = {}
                ems[emss].duty = playerOffDuty[tonumber(v)] == 1 and 0 or 1
                ems[emss].cid = character
                ems[emss].radio = usersRadios[character] or nil
                ems[emss].callsign = callSign
                ems[emss].name = name
            elseif xPlayer.job.name == 'lsfd' then
                saprs = #sapr + 1
                sapr[saprs] = {}
                sapr[saprs].duty = playerOffDuty[tonumber(v)] == 1 and 0 or 1
                sapr[saprs].cid = character
                sapr[saprs].radio = usersRadios[character] or nil
                sapr[saprs].callsign = callSign
                sapr[saprs].name = name
            end
        end
    end

    TriggerClientEvent("rx_mdt:getActiveUnits", src, lspd, sheriff, sasp, doc, sapr, pa, ems)
end

function getVehicles(src)
    local result = MysqlConverter(Config.Mysql, 'fetchAll',
        'SELECT * FROM owned_vehicles aa LEFT JOIN vehicle_mdt a ON a.license_plate = aa.plate LEFT JOIN mdw_bolos at ON at.license_plate = aa.plate ORDER BY time ASC',
        {})
    for k, v in pairs(result) do
        if v.image and v.image ~= nil and v.image ~= "" then
            result[k].image = v.image
        else
            result[k].image =
                "https://cdn.discordapp.com/attachments/832371566859124821/881624386317201498/Screenshot_1607.png"
        end

        local owner = MysqlConverter(Config.Mysql, 'fetchAll', 'SELECT firstname, lastname from users left join owned_vehicles ON users.identifier = owned_vehicles.owner where owned_vehicles.plate =  @plate',
            {
                ['@plate'] = v.plate
            })
        result[k].owner = 'Firma'

        if owner[1] and owner[1].firstname then
            result[k].owner = owner[1].firstname .. ' ' .. owner[1].lastname
        end

        if v.stolen and v.stolen ~= nil then
            result[k].stolen = v.stolen
        else
            result[k].stolen = false
        end
        if v.code and v.code ~= nil then
            result[k].code = v.code
        else
            result[k].code = false
        end
        if v.author and v.author ~= nil and v.title ~= nil then
            result[k].bolo = true
        else
            result[k].bolo = false
        end
    end

    TriggerClientEvent("rx_mdt:searchVehicles", src, result, true)
end

RegisterServerEvent("rx_mdt:getProfileData")
AddEventHandler("rx_mdt:getProfileData", function(identifier)
    local src = source
    local data = getProfile(identifier)
    TriggerClientEvent("rx_mdt:getProfileData", src, data, false)
end)

RegisterServerEvent("rx_mdt:getVehicleData")
AddEventHandler("rx_mdt:getVehicleData", function(plate)
    local src = source
    local result = MysqlConverter(Config.Mysql, 'fetchAll',
        'SELECT * FROM owned_vehicles aa LEFT JOIN vehicle_mdt a ON a.license_plate = aa.plate LEFT JOIN mdw_bolos at ON at.license_plate = aa.plate WHERE aa.plate = @plate LIMIT 1',
        {
            ['@plate'] = plate
        })
    for k, v in pairs(result) do
        if v.image and v.image ~= nil and v.image ~= "" then
            result[k].image = v.image
        else
            result[k].image =
                "https://cdn.discordapp.com/attachments/832371566859124821/881624386317201498/Screenshot_1607.png"
        end
        local owner = MysqlConverter(Config.Mysql, 'fetchAll', 'SELECT firstname, lastname from users left join owned_vehicles ON users.identifier = owned_vehicles.owner where owned_vehicles.plate =  @plate',
            {
                ['@plate'] = v.plate
            })
        result[k].owner = 'Firma'

        if owner[1] and owner[1].firstname then
            result[k].owner = owner[1].firstname .. ' ' .. owner[1].lastname
        end

        if v.stolen and v.stolen ~= nil then
            result[k].stolen = v.stolen
        else
            result[k].stolen = false
        end
        if v.code and v.code ~= nil then
            result[k].code = v.code
        else
            result[k].code = false
        end
        if v.notes and v.notes ~= nil then
            result[k].information = v.notes
        else
            result[k].information = ""
        end

        if v.author and v.author ~= nil and v.title ~= nil then
            result[k].bolo = true
        else
            result[k].bolo = false
        end
    end
    TriggerClientEvent("rx_mdt:updateVehicleDbId", src, result[1].id)
    TriggerClientEvent("rx_mdt:getVehicleData", src, result)
end)

RegisterServerEvent("rx_mdt:knownInformation")
AddEventHandler("rx_mdt:knownInformation", function(dbid, type, status, plate)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not policeJobs[xPlayer.job.name] then
        exports['esx_holdup']:BanPlayer(source, 'Cheating, trigger event! (rx_mdt:knownInformation)')
        return
    end
    if not dbid then
        dbid = 'NDBID'
    end
    local saveData = {
        type = type,
        status = status
    }
    local result = MysqlConverter(Config.Mysql, 'fetchAll',
        'SELECT * FROM `vehicle_mdt` WHERE `license_plate` = @plate', {
            ['@plate'] = plate
        })
    if result[1] then
        if type == "stolen" then
            MysqlConverter(Config.Mysql, 'execute',
                'UPDATE `vehicle_mdt` SET `stolen` = @stolen WHERE `license_plate` = @plate', {
                    ['@stolen'] = status,
                    ['@dbid'] = dbid,
                    ['@plate'] = plate
                })
        elseif type == "code5" then
            MysqlConverter(Config.Mysql, 'execute',
                'UPDATE `vehicle_mdt` SET `code` = @code WHERE `license_plate` = @plate', {
                    ['@code'] = status,
                    ['@dbid'] = dbid,
                    ['@plate'] = plate
                })
        end
    else
        if type == "stolen" then
            MysqlConverter(Config.Mysql, 'execute',
                'INSERT INTO `vehicle_mdt` (`license_plate`, `stolen`, `dbid`) VALUES (@plate, @stolen, @dbid)', {
                    ['@dbid'] = dbid,
                    ['@plate'] = plate,
                    ['@stolen'] = status
                })
        elseif type == "code5" then
            MysqlConverter(Config.Mysql, 'execute',
                'INSERT INTO `vehicle_mdt` (`license_plate`, `code`, `dbid`) VALUES (@plate, @code, @dbid)', {
                    ['@dbid'] = dbid,
                    ['@plate'] = plate,
                    ['@code'] = status
                })
        end
    end
end)

RegisterServerEvent("rx_mdt:searchVehicles")
AddEventHandler("rx_mdt:searchVehicles", function(plate)
    local src = source
    local lowerplate = string.lower('%' .. plate .. '%')
    local result = MysqlConverter(Config.Mysql, 'fetchAll',
        'SELECT * FROM owned_vehicles aa LEFT JOIN vehicle_mdt a ON a.license_plate = aa.plate LEFT JOIN mdw_bolos at ON at.license_plate = aa.plate WHERE LOWER(plate) LIKE @plate ORDER BY plate ASC',
        {
            ['@plate'] = lowerplate
        })
    for k, v in pairs(result) do
        if v.image and v.image ~= nil and v.image ~= "" then
            result[k].image = v.image
        else
            result[k].image =
                "https://cdn.discordapp.com/attachments/832371566859124821/881624386317201498/Screenshot_1607.png"
        end

        local owner = MysqlConverter(Config.Mysql, 'fetchAll', 'SELECT firstname, lastname from users left join owned_vehicles ON users.identifier = owned_vehicles.owner where owned_vehicles.plate =  @plate',
            {
                ['@plate'] = v.plate
            })
        result[k].owner = 'Firma'

        if owner[1] and owner[1].firstname then
            result[k].owner = owner[1].firstname .. ' ' .. owner[1].lastname
        end

        if v.stolen and v.stolen ~= nil then
            result[k].stolen = v.stolen
        else
            result[k].stolen = false
        end
        if v.code and v.code ~= nil then
            result[k].code = v.code
        else
            result[k].code = false
        end
        if v.author and v.author ~= nil and v.title ~= nil then
            result[k].bolo = true
        else
            result[k].bolo = false
        end
    end
    TriggerClientEvent("rx_mdt:searchVehicles", src, result)
end)

RegisterServerEvent("rx_mdt:saveVehicleInfo")
AddEventHandler("rx_mdt:saveVehicleInfo", function(dbid, plate, imageurl, notes)
    if imageurl == "" or not imageurl then
        imageurl = ""
    end
    if notes == "" or not notes then
        notes = ""
    end
    if not dbid then
        dbid = 'NDBID'
    end
    if plate == "" then
        return
    end
    local xPlayer = ESX.GetPlayerFromId(source)
    if not policeJobs[xPlayer.job.name] then
        exports['esx_holdup']:BanPlayer(source, 'Cheating, trigger event! (rx_mdt:saveVehicleInfo)')
        return
    end
    local usource = source
    local result = MysqlConverter(Config.Mysql, 'fetchAll',
        'SELECT * FROM `vehicle_mdt` WHERE `license_plate` = @license_plate', {
            ['@license_plate'] = plate
        })
    if result[1] then
        MysqlConverter(Config.Mysql, 'execute',
            'UPDATE `vehicle_mdt` SET `image` = @image, `notes` = @notes WHERE `license_plate` = @license_plate', {
                ['@image'] = imageurl,
                ['@dbid'] = dbid,
                ['@license_plate'] = plate,
                ['@notes'] = notes
            })
    else
        MysqlConverter(Config.Mysql, 'execute',
            'INSERT INTO `vehicle_mdt` (`license_plate`, `stolen`, `notes`, `image`, `dbid`) VALUES (@license_plate, @stolen, @notes, @image, @dbid)',
            {
                ['@dbid'] = dbid,
                ['@license_plate'] = plate,
                ['@stolen'] = 0,
                ['@image'] = imageurl,
                ['@notes'] = notes
            })
    end
end)

RegisterServerEvent("rx_mdt:saveProfile")
AddEventHandler("rx_mdt:saveProfile", function(profilepic, information, identifier, fName, sName)
    if imageurl == "" or not imageurl then
        imageurl = ""
    end
    if notes == "" or not notes then
        notes = ""
    end
    if dbid == 0 then
        return
    end
    if plate == "" then
        return
    end
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not policeJobs[xPlayer.job.name] then
        exports['esx_holdup']:BanPlayer(src, 'Cheating, trigger event! (rx_mdt:saveProfile)')
        return
    end
    local result = MysqlConverter(Config.Mysql, 'fetchAll', 'SELECT * FROM `mdw_profiles` WHERE `cid` = @cid', {
        ['@cid'] = identifier
    })
    if result[1] then
        MysqlConverter(Config.Mysql, 'execute',
            'UPDATE `mdw_profiles` SET `image` = @image, `description` = @description, `name` = @name WHERE `cid` = @cid',
            {
                ['@image'] = profilepic,
                ['@description'] = information,
                ['@name'] = fName .. " " .. sName,
                ['@cid'] = identifier
            }
        )

        lib.logger(xPlayer.identifier, 'mdt', ('Hráč: **%s/%s %s** \nUpravil/a profil \nMeno: **%s** \nZmena: **%s**'):format(GetPlayerName(src), xPlayer.getName(), GetCallsign(xPlayer.identifier), fName .. " " .. sName, information))
    else
        MysqlConverter(Config.Mysql, 'execute',
            'INSERT INTO `mdw_profiles` (`cid`, `image`, `description`, `name`) VALUES (@cid, @image, @description, @name)',
            {
                ['@cid'] = identifier,
                ['@image'] = profilepic,
                ['@description'] = information,
                ['@name'] = fName .. " " .. sName
            })
    end
end)

RegisterServerEvent("rx_mdt:addGalleryImg")
AddEventHandler("rx_mdt:addGalleryImg", function(identifier, url)
    local result = MysqlConverter(Config.Mysql, 'fetchAll', 'SELECT * FROM `mdw_profiles` WHERE cid = @identifier', {
        ["@identifier"] = identifier
    })
    local xPlayer = ESX.GetPlayerFromId(source)
    if not policeJobs[xPlayer.job.name] then
        exports['esx_holdup']:BanPlayer(source, 'Cheating, trigger event! (rx_mdt:addGalleryImg)')
        return
    end
    if result and result[1] then
        result[1].gallery = json.decode(result[1].gallery)
        table.insert(result[1].gallery, url)
        MysqlConverter(Config.Mysql, 'execute',
            'UPDATE `mdw_profiles` SET `gallery` = @gallery WHERE `cid` = @identifier', {
                ['@identifier'] = identifier,
                ['@gallery'] = json.encode(result[1].gallery)
            })
    end
end)

RegisterServerEvent("rx_mdt:removeGalleryImg")
AddEventHandler("rx_mdt:removeGalleryImg", function(identifier, url)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not policeJobs[xPlayer.job.name] then
        exports['esx_holdup']:BanPlayer(source, 'Cheating, trigger event! (rx_mdt:removeGalleryImg)')
        return
    end
    local result = MysqlConverter(Config.Mysql, 'fetchAll', 'SELECT * FROM `mdw_profiles` WHERE cid = @identifier', {
        ["@identifier"] = identifier
    })
    if result and result[1] then
        result[1].gallery = json.decode(result[1].gallery)
        for k, v in ipairs(result[1].gallery) do
            if v == url then
                table.remove(result[1].gallery, k)
            end
        end
        MysqlConverter(Config.Mysql, 'execute',
            'UPDATE `mdw_profiles` SET `gallery` = @gallery WHERE `cid` = @identifier', {
                ['@identifier'] = identifier,
                ['@gallery'] = json.encode(result[1].gallery)
            })
    end
end)

RegisterServerEvent("rx_mdt:searchProfile")
AddEventHandler("rx_mdt:searchProfile", function(query)
    local src = source
    local queryData = string.lower('%' .. query .. '%')
    local result = MysqlConverter(Config.Mysql, 'fetchAll',
        "SELECT * FROM `users` WHERE LOWER(`firstname`) LIKE @var1 OR LOWER(`identifier`) LIKE @var2 OR LOWER(`lastname`) LIKE @var3 OR CONCAT(LOWER(`firstname`), ' ', LOWER(`lastname`), ' ', LOWER(`identifier`)) LIKE @var4 ORDER BY firstname DESC",
        {
            ['@var1'] = queryData,
            ['@var2'] = queryData,
            ['@var3'] = queryData,
            ['@var4'] = queryData

        })
    local licenses = MysqlConverter(Config.Mysql, 'fetchAll', 'SELECT * FROM user_licenses', {})
    local mdw_profiles = MysqlConverter(Config.Mysql, 'fetchAll', 'SELECT * FROM mdw_profiles', {})

    for k, v in pairs(result) do
        result[k].firstname = v.firstname
        result[k].lastname = v.lastname

        local patrani = MysqlConverter(Config.Mysql, 'fetchAll',
        'SELECT status FROM user_licenses WHERE owner = @owner AND type = @lictype', {
            ['@owner'] = v.identifier,
            ['@lictype'] = 'patrani'
        })
        if patrani and patrani[1] then
            if patrani[1].status == 1 then
                result[k].patrani = true
            end
        end

        local zadrzeny = MysqlConverter(Config.Mysql, 'fetchAll',
            'SELECT status FROM user_licenses WHERE owner = @owner AND type = @lictype', {
                ['@owner'] = v.identifier,
                ['@lictype'] = 'zadrzany'
            })
        if zadrzeny and zadrzeny[1] then
            if zadrzeny[1].status == 1 then
                result[k].zadrzeny = true
            end
        end

        result[k].policemdtinfo = ""
        result[k].pp = "https://cdn.discordapp.com/attachments/904822052358336573/1016298208516915260/male.png"
        for i = 1, #mdw_profiles do
            if mdw_profiles[i].cid == v.idenitifer then
                if mdw_profiles[i].image and mdw_profiles[i].image ~= nil then
                    result[k].pp = mdw_profiles[i].image
                end
                if mdw_profiles[i].description and mdw_profiles[i].description ~= nil then
                    result[k].policemdtinfo = mdw_profiles[i].description
                end
                result[k].policemdtinfo = mdw_profiles[i].description
            end
        end
        result[k].warrant = false
        result[k].convictions = 0
        result[k].cid = v.idenitifer
    end

    TriggerClientEvent("rx_mdt:searchProfile", src, result, true)
end)

function getProfile(identifier)
    local result = MysqlConverter(Config.Mysql, 'fetchAll', 'SELECT * FROM users WHERE identifier = @identifier', {
        ['@identifier'] = identifier
    })
    local resultI = MysqlConverter(Config.Mysql, 'fetchAll', 'SELECT * FROM mdw_incidents WHERE associated LIKE "%'..identifier..'%"', {})

    local vehresult = MysqlConverter(Config.Mysql, 'fetchAll', 'SELECT * FROM owned_vehicles WHERE owner = @owner', {
        ['@owner'] = identifier
    })

    local totalCharges = {}
    for k, v in pairs(resultI) do
        for k2, v2 in ipairs(json.decode(v.associated)) do
            if v2.cid == result[1].identifier then
                table.insert(totalCharges, {label = v.title .. '- '..v.id, id = v.id})
            end
        end
    end
    result[1].convictions = totalCharges
    result[1].vehicles = vehresult
    result[1].firstname = result[1].firstname
    result[1].lastname = result[1].lastname
    result[1].phone = exports["lb-phone"]:GetEquippedPhoneNumber(identifier)

    local invoices = MysqlConverter(Config.Mysql, 'fetchAll', 'SELECT status, sent_date, invoice_value, item FROM okokbilling WHERE receiver_identifier = @owner AND (society = "society_police" OR society = "society_sheriff" OR society = "society_sasp")', {
        ['@owner'] = identifier
    })
    result[1].bills = invoices
    

    local weapon2 = MysqlConverter(Config.Mysql, 'fetchAll',
        'SELECT status FROM user_licenses WHERE owner = @owner AND type = @lictype', {
            ['@owner'] = identifier,
            ['@lictype'] = 'weapon'
        })
    if weapon2 and weapon2[1] then
        if weapon2[1].status == 1 then
            result[1].Weapon = true
        end
    end

    local drivers2 = MysqlConverter(Config.Mysql, 'fetchAll',
        'SELECT status FROM user_licenses WHERE owner = @owner AND type = @lictype', {
            ['@owner'] = identifier,
            ['@lictype'] = 'dmv'
        })
    if drivers2 and drivers2[1] then
        if drivers2[1].status == 1 then
            result[1].Drivers = true
        end
    end

    local patrani = MysqlConverter(Config.Mysql, 'fetchAll',
        'SELECT status FROM user_licenses WHERE owner = @owner AND type = @lictype', {
            ['@owner'] = identifier,
            ['@lictype'] = 'patrani'
        })
    if patrani and patrani[1] then
        if patrani[1].status == 1 then
            result[1].patrani = true
        end
    end

    local zadrzeny = MysqlConverter(Config.Mysql, 'fetchAll',
        'SELECT status FROM user_licenses WHERE owner = @owner AND type = @lictype', {
            ['@owner'] = identifier,
            ['@lictype'] = 'zadrzany'
        })
    if zadrzeny and zadrzeny[1] then
        if zadrzeny[1].status == 1 then
            result[1].zadrzeny = true
        end
    end

    local hunting2 = MysqlConverter(Config.Mysql, 'fetchAll',
        'SELECT status FROM user_licenses WHERE owner = @owner AND type = @lictype', {
            ['@owner'] = identifier,
            ['@lictype'] = 'drive'
        })
    if hunting2 and hunting2[1] then
        if hunting2[1].status == 1 then
            result[1].Hunting = true
        end
    end

    local huntingreal = MysqlConverter(Config.Mysql, 'fetchAll',
    'SELECT status FROM user_licenses WHERE owner = @owner AND type = @lictype', {
        ['@owner'] = identifier,
        ['@lictype'] = 'hunting'
    })
    if huntingreal and huntingreal[1] then
        if huntingreal[1].status == 1 then
            result[1].huntingreal = true
        end
    end

    local fishing2 = MysqlConverter(Config.Mysql, 'fetchAll',
        'SELECT status FROM user_licenses WHERE owner = @owner AND type = @lictype', {
            ['@owner'] = identifier,
            ['@lictype'] = 'drive_bike'
        })
    if fishing2 and fishing2[1] then
        if fishing2[1].status == 1 then
            result[1].Fishing = true
        end
    end

    local atpla = MysqlConverter(Config.Mysql, 'fetchAll',
    'SELECT status FROM user_licenses WHERE owner = @owner AND type = @lictype', {
        ['@owner'] = identifier,
        ['@lictype'] = 'atpla'
    })
    if atpla and atpla[1] then
        if atpla[1].status == 1 then
            result[1].atpla = true
        end
    end

    local housesTable = {}
    local houses = MysqlConverter(Config.Mysql, 'fetchAll',
    'SELECT propertyid FROM loaf_properties WHERE owner = @identifier', {
        ['@identifier'] = identifier,
    })
    if houses and houses[1] then
        for k, v in pairs(houses) do
            local houseData = exports['loaf_housing']:GetHouse(v.propertyid)
            table.insert(housesTable, {label = houseData.label .. ' - ' .. k, entrance = houseData.entrance, propertyid = v.propertyid})
        end
    end
    result[1].houses = housesTable

    local ppla = MysqlConverter(Config.Mysql, 'fetchAll',
    'SELECT status FROM user_licenses WHERE owner = @owner AND type = @lictype', {
        ['@owner'] = identifier,
        ['@lictype'] = 'ppla'
    })
    if ppla and ppla[1] then
        if ppla[1].status == 1 then
            result[1].ppla = true
        end
    end
    --[[
    local sluzebni_prukaz = MysqlConverter(Config.Mysql, 'fetchAll',
    'SELECT status FROM user_licenses WHERE owner = @owner AND type = @lictype', {
        ['@owner'] = identifier,
        ['@lictype'] = 'sluzebni_prukaz'
    })
    if sluzebni_prukaz and sluzebni_prukaz[1] then
        if sluzebni_prukaz[1].status == 1 then
            result[1].sluzebni_prukaz = true
        end
    end]]
    local atplh = MysqlConverter(Config.Mysql, 'fetchAll',
    'SELECT status FROM user_licenses WHERE owner = @owner AND type = @lictype', {
        ['@owner'] = identifier,
        ['@lictype'] = 'atplh'
    })
    if atplh and atplh[1] then
        if atplh[1].status == 1 then
            result[1].atplh = true
        end
    end
    local pplh = MysqlConverter(Config.Mysql, 'fetchAll',
    'SELECT status FROM user_licenses WHERE owner = @owner AND type = @lictype', {
        ['@owner'] = identifier,
        ['@lictype'] = 'pplh'
    })
    if pplh and pplh[1] then
        if pplh[1].status == 1 then
            result[1].pplh = true
        end
    end
    local pilot2 = MysqlConverter(Config.Mysql, 'fetchAll',
        'SELECT status FROM user_licenses WHERE owner = @owner AND type = @lictype', {
            ['@owner'] = identifier,
            ['@lictype'] = 'drive_truck'
        })
    if pilot2 and pilot2[1] then
        if pilot2[1].status == 1 then
            result[1].Pilot = true
        end
    end

    local weaponka = MysqlConverter(Config.Mysql, 'fetchAll',
    'SELECT status FROM user_licenses WHERE owner = @owner AND type = @lictype', {
        ['@owner'] = identifier,
        ['@lictype'] = 'weaponka'
    })
    if weaponka and weaponka[1] then
        if weaponka[1].status == 1 then
            result[1].weaponka = true
        end
    end


    local weaponda = MysqlConverter(Config.Mysql, 'fetchAll',
        'SELECT status FROM user_licenses WHERE owner = @owner AND type = @lictype', {
            ['@owner'] = identifier,
            ['@lictype'] = 'weaponda'
        })
    if weaponda and weaponda[1] then
        if weaponda[1].status == 1 then
            result[1].weaponda = true
        end
    end

    result[1].warrant = false
    result[1].identifier = result[1].identifier
    result[1].job = result[1].job

    local proresult = MysqlConverter(Config.Mysql, 'fetchAll',
        'SELECT * FROM mdw_profiles WHERE cid = @identifier LIMIT 1', {
            ['@identifier'] = identifier
        })
    if proresult and proresult[1] ~= nil then
        result[1].profilepic = proresult[1].image
        result[1].tags = json.decode(proresult[1].tags)
        result[1].gallery = json.decode(proresult[1].gallery)
        result[1].policemdtinfo = proresult[1].description
    else
        result[1].tags = {}
        result[1].gallery = {}
        result[1].pp =
            "https://cdn.discordapp.com/attachments/904822052358336573/1016298208516915260/male.png"
    end
    return result[1]
end

function getProfiles(src)

    local result = MysqlConverter(Config.Mysql, 'fetchAll',
        'SELECT * FROM users aa LEFT JOIN mdw_profiles at ON at.cid = aa.identifier ORDER BY firstname DESC', {})
    for k, v in pairs(result) do
        result[k].firstname = v.firstname
        result[k].lastname = v.lastname

        local patrani = MysqlConverter(Config.Mysql, 'fetchAll',
        'SELECT status FROM user_licenses WHERE owner = @owner AND type = @lictype', {
            ['@owner'] = v.identifier,
            ['@lictype'] = 'patrani'
        })
        if patrani and patrani[1] then
            if patrani[1].status == 1 then
                result[k].patrani = true
            end
        end

        local zadrzeny = MysqlConverter(Config.Mysql, 'fetchAll',
            'SELECT status FROM user_licenses WHERE owner = @owner AND type = @lictype', {
                ['@owner'] = v.identifier,
                ['@lictype'] = 'zadrzany'
            })
        if zadrzeny and zadrzeny[1] then
            if zadrzeny[1].status == 1 then
                result[k].zadrzeny = true
            end
        end

        result[k].warrant = false
        result[k].convictions = 0
        result[k].cid = v.id

        if v.image and v.image ~= nil and v.image ~= "" then
            result[k].pp = v.image
        else
            result[k].pp =
                "https://cdn.discordapp.com/attachments/904822052358336573/1016298208516915260/male.png"
        end
        local proresult = MysqlConverter(Config.Mysql, 'fetchAll',
            'SELECT * FROM `mdw_profiles` WHERE `cid` = @identifier', {
                ['@identifier'] = v.identifier
            })
        if proresult and proresult[1] ~= nil then

            result[k].pp = proresult[1].image
            result[k].policemdtinfo = proresult[1].description
        end
    end
    TriggerClientEvent("rx_mdt:searchProfile", src, result, true)
end

RegisterServerEvent("rx_mdt:updateLicense")
AddEventHandler("rx_mdt:updateLicense", function(identifier, type, status)
    local _oldType = type
    local xPlayer = ESX.GetPlayerFromId(source)
    if not policeJobs[xPlayer.job.name] then
        exports['esx_holdup']:BanPlayer(source, 'Cheating, trigger event! (rx_mdt:updateLicense)')
        return
    end

    if type == 'ŘP Teorie' then
        type = 'dmv'
    elseif type == 'ŘP - A' then
        type = 'drive_bike'
    elseif type == 'ŘP - B' then
        type = 'drive'
    elseif type == 'ŘP - C' then
        type = 'drive_truck'
    elseif type == 'Zbrojní Průkaz' then
        type = 'weapon'
    elseif type == 'ZP - Velké' then
        type = 'weaponka'
    elseif type == 'ZP - Lovecký' then
        type = 'weaponda'
    elseif type == 'V Pátrani' then
        type = 'patrani'
    elseif type == 'Zadržený' then
        type = 'zadrzany'
    elseif type == 'ATPL [A] - Dopravní letadlo' then
        type = 'atpla'
    elseif type == 'PPL [A] - Soukromé letadlo' then
        type = 'ppla'
    elseif type == 'ATPL [H] - Dopravní vrtulník' then
        type = 'atplh'
    elseif type == 'PPL [H] - Soukromý vrtulník' then
        type = 'pplh'
    elseif type == 'Lovecký průkaz' then
        type = 'hunting'
    --[[
    elseif type == 'Služební průkaz' then
        type = 'sluzebni_prukaz']]
    end

    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    local name = xPlayer.variables.firstName .. " " .. xPlayer.variables.lastName
    local time = os.date()
    if status == "revoke" then
        action = "Odebral"
    else
        action = "Dal"
    end

    local resukt = MysqlConverter(Config.Mysql, 'fetchAll', 'SELECT firstname, lastname FROM users WHERE identifier = @identifier', {
        ['@identifier'] = identifier
    })

    TriggerEvent("rx_mdt:newLog", name .. " " .. action .. " licensi: " .. firstToUpper(_oldType) ..
        " - upravil data o občanovi: " .. resukt[1].firstname .. ' '..resukt[1].lastname, time)

    if status == "revoke" then
        MysqlConverter(Config.Mysql, 'execute', 'DELETE FROM user_licenses WHERE owner = @identifier AND type = @type',
            {
                ['@identifier'] = identifier,
                ['@type'] = type
            })
    else
        MysqlConverter(Config.Mysql, 'execute',
            'INSERT INTO user_licenses (type, owner, status) VALUES(@type, @owner, @status)', {
                ['@type'] = type,
                ['@owner'] = identifier,
                ['@status'] = 1
            })
    end
end)

RegisterServerEvent("rx_mdt:newBulletin")
AddEventHandler("rx_mdt:newBulletin", function(title, info, time, id)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not policeJobs[xPlayer.job.name] then
        exports['esx_holdup']:BanPlayer(source, 'Cheating, trigger event! (rx_mdt:newBulletin)')
        return
    end
    local name = xPlayer.variables.firstName .. " " .. xPlayer.variables.lastName
    local Bulletin = {
        title = title,
        id = id,
        info = info,
        time = time,
        src = src,
        author = name
    }
    MysqlConverter(Config.Mysql, 'execute',
        'INSERT INTO mdw_bulletin (title, info, time, src, author, id) VALUES(@title, @info, @time, @src, @author, @id)',
        {

            ["@title"] = title,
            ["@info"] = info,
            ["@time"] = time,
            ["@src"] = src,
            ["@author"] = name,
            ["@id"] = id
        })
    TriggerClientEvent("rx_mdt:newBulletin", -1, src, Bulletin, xPlayer.job.name)
end)

RegisterServerEvent("rx_mdt:deleteBulletin")
AddEventHandler("rx_mdt:deleteBulletin", function(id)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not policeJobs[xPlayer.job.name] then
        exports['esx_holdup']:BanPlayer(source, 'Cheating, trigger event! (rx_mdt:deleteBulletin)')
        return
    end
    local name = xPlayer.variables.firstName .. " " .. xPlayer.variables.lastName
    MysqlConverter(Config.Mysql, 'execute', 'DELETE FROM mdw_bulletin WHERE id = @id', {

        ["@id"] = id
    })
    TriggerClientEvent("rx_mdt:deleteBulletin", -1, src, id, xPlayer.job.name)
end)

RegisterServerEvent("rx_mdt:newLog")
AddEventHandler("rx_mdt:newLog", function(text, time)
    local xPlayer = ESX.GetPlayerFromId(source)
    if xPlayer and not policeJobs[xPlayer.job.name] then
        exports['esx_holdup']:BanPlayer(source, 'Cheating, trigger event! (rx_mdt:newLog)')
        return
    end

    time = os.date ("%c")

    MysqlConverter(Config.Mysql, 'execute', 'INSERT INTO mdw_logs (text, time) VALUES(@text, @time)', {

        ["@text"] = text,
        ["@time"] = time
    })
end)

RegisterServerEvent("rx_mdt:getAllLogs")
AddEventHandler("rx_mdt:getAllLogs", function()
    local src = source
    local result = MysqlConverter(Config.Mysql, 'fetchAll', 'SELECT * FROM mdw_logs', {})
    TriggerClientEvent("rx_mdt:getAllLogs", src, result)
end)

RegisterServerEvent("rx_mdt:getAllIncidents")
AddEventHandler("rx_mdt:getAllIncidents", function()
    local src = source
    local result = MysqlConverter(Config.Mysql, 'fetchAll', 'SELECT * FROM mdw_incidents', {})
    TriggerClientEvent("rx_mdt:getAllIncidents", src, result)
end)

RegisterServerEvent("rx_mdt:getIncidentData")
AddEventHandler("rx_mdt:getIncidentData", function(id)
    local src = source
    local result = MysqlConverter(Config.Mysql, 'fetchAll', 'SELECT * FROM mdw_incidents WHERE id = @id', {
        ["@id"] = id
    })
    result[1].tags = json.decode(result[1].tags)
    result[1].officersinvolved = json.decode(result[1].officers)
    result[1].civsinvolved = json.decode(result[1].civilians)
    result[1].evidence = json.decode(result[1].evidence)
    result[1].convictions = json.decode(result[1].associated)
    result[1].charges = json.decode(result[1].associated.charges)
    TriggerClientEvent("rx_mdt:updateIncidentDbId", src, result[1].id)
    TriggerClientEvent("rx_mdt:getIncidentData", src, result[1], json.decode(result[1].associated))
end)

RegisterServerEvent("rx_mdt:incidentSearchPerson")
AddEventHandler("rx_mdt:incidentSearchPerson", function(query1)
    local src = source
    local queryData = string.lower('%' .. query1 .. '%')
    local result = MysqlConverter(Config.Mysql, 'fetchAll',
        "SELECT firstname, lastname, identifier FROM `users`  WHERE LOWER(`firstname`) LIKE @var1 OR LOWER(`identifier`) LIKE @var2 OR LOWER(`lastname`) LIKE @var3 OR CONCAT(LOWER(`firstname`), ' ', LOWER(`lastname`), ' ', LOWER(`identifier`)) LIKE @var4",
        {

            ["@var1"] = queryData,
            ["@var2"] = queryData,
            ["@var3"] = queryData,
            ["@var4"] = queryData

        })
    local mdw_profiles = MysqlConverter(Config.Mysql, 'fetchAll', 'SELECT * FROM mdw_profiles', {})
    for k, v in pairs(result) do
        result[k].firstname = v.firstname
        result[k].lastname = v.lastname
        result[k].profilepic =
            "https://cdn.discordapp.com/attachments/904822052358336573/1016298208516915260/male.png"
        for i = 1, #mdw_profiles do
            if mdw_profiles[i].cid == v.identifier then
                if mdw_profiles[i].image and mdw_profiles[i].image ~= nil then
                    result[k].profilepic = mdw_profiles[i].image
                end
            end
        end
    end
    TriggerClientEvent('rx_mdt:incidentSearchPerson', src, result)
end)

RegisterServerEvent("rx_mdt:removeIncidentCriminal")
AddEventHandler("rx_mdt:removeIncidentCriminal", function(cid, icId)

    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not policeJobs[xPlayer.job.name] then
        exports['esx_holdup']:BanPlayer(source, 'Cheating, trigger event! (rx_mdt:removeIncidentCriminal)')
        return
    end
    local name = xPlayer.variables.firstName .. " " .. xPlayer.variables.lastName
    local time = os.time()
    local action = "Odstranil občana z pátraní, ID záznamu: " .. icId
    local Cname = ""
    local result = MysqlConverter(Config.Mysql, 'fetchAll', "SELECT * FROM mdw_incidents WHERE id = @id", {
        ["@id"] = icId
    })
    for k, v in pairs(result) do
        for k2, v2 in ipairs(json.decode(v.associated)) do
            if v2.cid == cid then
                table.remove(v2, k)
                Cname = v2.name
            end
        end
    end

    local resukt = MysqlConverter(Config.Mysql, 'fetchAll', 'SELECT * FROM users WHERE identifier = @identifier', {
        ['@identifier'] = cid
    })
    TriggerEvent("rx_mdt:newLog", name .. ", " .. action .. ", Jméno: " .. Cname .. "", time)
    MysqlConverter(Config.Mysql, 'execute', 'UPDATE mdw_incidents SET tags = @tags WHERE id = @id', {
        ["@tags"] = json.encode(result[1].associated),
        ["@id"] = icId
    })
end)

RegisterServerEvent("rx_mdt:searchIncidents")
AddEventHandler("rx_mdt:searchIncidents", function(query)
    local src = source
    local result = MysqlConverter(Config.Mysql, 'fetchAll', "SELECT * FROM `mdw_incidents` WHERE id = @query", {
        ['@query'] = tonumber(query)
    })

    TriggerClientEvent('rx_mdt:getIncidents', src, result)
end)

RegisterServerEvent("rx_mdt:saveIncident")
AddEventHandler("rx_mdt:saveIncident", function(data)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    local name = xPlayer.variables.firstName .. " " .. xPlayer.variables.lastName
    if not policeJobs[xPlayer.job.name] then
        exports['esx_holdup']:BanPlayer(source, 'Cheating, trigger event! (rx_mdt:saveIncident)')
        return
    end
    for i = 1, #data.associated do
        local result2 = MysqlConverter(Config.Mysql, 'fetchAll', 'SELECT * FROM users WHERE identifier = @identifier', {
            ["@identifier"] = data.associated[i].cid
        })
        if result2 and result2[1] then
            data.associated[i].name = result2[1].firstname .. " " .. result2[1].lastname
        end
        local xTarget = ESX.GetPlayerFromIdentifier(result2[1].identifier)
        if tonumber(data.associated[i].fine) > 0 and data.ID == 0 then
            exports['billing']:CreateBill(tonumber(data.associated[i].fine), xTarget, xPlayer)
        end
    end
    if data.ID ~= 0 then
        MysqlConverter(Config.Mysql, 'execute',
            'UPDATE `mdw_incidents` SET `title` = @title, `author` = @author, `time` = @time, `details` = @details, `tags` = @tags, `officers` = @officers, `civilians` = @civilians, `evidence` = @evidence, `associated` = @associated WHERE `id` = @id',
            {
                ['@id'] = data.ID,
                ['@title'] = data.title,
                ['@author'] = name,
                ['@time'] = data.time,
                ['@details'] = data.information,
                ['@tags'] = json.encode(data.tags),
                ['@officers'] = json.encode(data.officers),
                ['@civilians'] = json.encode(data.civilians),
                ['@evidence'] = json.encode(data.evidence),
                ['@associated'] = json.encode(data.associated)
            })
    else
        MysqlConverter(Config.Mysql, 'execute',
            'INSERT INTO `mdw_incidents` (`title`, `author`, `time`, `details`, `tags`, `officers`, `civilians`, `evidence`, `associated`) VALUES (@title, @author, @time, @details, @tags, @officers, @civilians, @evidence, @associated)',
            {
                ['@title'] = data.title,
                ['@author'] = name,
                ['@time'] = data.time,
                ['@details'] = data.information,
                ['@tags'] = json.encode(data.tags),
                ['@officers'] = json.encode(data.officers),
                ['@civilians'] = json.encode(data.civilians),
                ['@evidence'] = json.encode(data.evidence),
                ['@associated'] = json.encode(data.associated)
            })
    end
end)

RegisterServerEvent("rx_mdt:newTag")
AddEventHandler("rx_mdt:newTag", function(cid, tag)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not policeJobs[xPlayer.job.name] then
        exports['esx_holdup']:BanPlayer(src, 'Cheating, trigger event! (rx_mdt:newTag)')
        return
    end
    local result = MysqlConverter(Config.Mysql, 'fetchAll', 'SELECT * FROM mdw_profiles WHERE cid = @identifier', {
        ['@identifier'] = cid
    })
    local newTags = {}
    if result and result[1] then

        result[1].tags = json.decode(result[1].tags)
        table.insert(result[1].tags, tag)
        MysqlConverter(Config.Mysql, 'execute', 'UPDATE `mdw_profiles` SET `tags` = @tags WHERE `cid` = @cid', {
            ['@cid'] = cid,
            ['@tags'] = json.encode(result[1].tags)
        })
    else
        newTags[1] = tag
        MysqlConverter(Config.Mysql, 'execute',
            'INSERT INTO `mdw_profiles` (`cid`, `image`, `description`, `name`) VALUES (@cid, @image, @description, @name)',
            {
                ['@cid'] = cid,
                ['@image'] = "",
                ['@description'] = "",
                ['@tags'] = json.encode(newTags),
                ['@name'] = ""
            })
    end
end)

RegisterServerEvent("rx_mdt:removeProfileTag")
AddEventHandler("rx_mdt:removeProfileTag", function(cid, tag)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not policeJobs[xPlayer.job.name] then
        exports['esx_holdup']:BanPlayer(source, 'Cheating, trigger event! (rx_mdt:removeProfileTag)')
        return
    end
    local query = "SELECT * FROM mdw_profiles WHERE cid = ?"
    local result = MysqlConverter(Config.Mysql, 'fetchAll', 'SELECT * FROM mdw_profiles WHERE cid = @identifier', {
        ['@identifier'] = cid
    })
    if result and result[1] then
        result[1].tags = json.decode(result[1].tags)
        for k, v in ipairs(result[1].tags) do
            if v == tag then
                table.remove(result[1].tags, k)
            end
        end
        MysqlConverter(Config.Mysql, 'execute', 'UPDATE mdw_profiles SET tags = @tags WHERE cid = @identifier', {
            ['@tags'] = json.encode(result[1].tags),
            ['@identifier'] = cid
        })
    end
end)

RegisterServerEvent("rx_mdt:getPenalCode")
AddEventHandler("rx_mdt:getPenalCode", function()
    local src = source
    local titles = {}
    local penalcode = {}
    local result = MysqlConverter(Config.Mysql, 'fetchAll', 'SELECT * FROM fine_types ORDER BY category ASC', {})
    for i = 1, #result do
        local id = result[i].id
        local res = result[i]
        table.insert(titles, res.group)
        local color = "green"
        class = "Infraction"
        if res.category == 0 then
            color = "green"
            class = "Záznam"
        elseif res.category == 1 then
            color = "orange"
            class = "Přestupek"
        elseif res.category == 2 or res.category == 3 then
            color = "red"
            class = "Trestný čin"
        end

        table.insert(penalcode, {
            color = color,
            title = res.label,
            id = res.id,
            class = class,
            months = res.months,
            fine = res.amount,
            group = res.group
        })

    end
    TriggerClientEvent('rx_mdt:getPenalCode', src, titles, penalcode)
end)

RegisterServerEvent("rx_mdt:getAllBolos")
AddEventHandler("rx_mdt:getAllBolos", function()
    local src = source
    local result = MysqlConverter(Config.Mysql, 'fetchAll', 'SELECT * FROM mdw_bolos', {})
    TriggerClientEvent("rx_mdt:getBolos", src, result)
end)

RegisterServerEvent("rx_mdt:getBoloData")
AddEventHandler("rx_mdt:getBoloData", function(id)
    local src = source
    local result = MysqlConverter(Config.Mysql, 'fetchAll', "SELECT * FROM mdw_bolos WHERE dbid = @id", {
        ["@id"] = id
    })
    result[1].tags = json.decode(result[1].tags)
    result[1].gallery = json.decode(result[1].gallery)
    result[1].officersinvolved = json.decode(result[1].officers)
    result[1].officers = json.decode(result[1].officers)
    TriggerClientEvent("rx_mdt:getBoloData", src, result[1])
end)

RegisterServerEvent("rx_mdt:searchBolos")
AddEventHandler("rx_mdt:searchBolos", function(query)
    local src = source
    local result = MysqlConverter(Config.Mysql, 'fetchAll',
        "SELECT * FROM `mdw_bolos` WHERE LOWER(`license_plate`) LIKE @query OR LOWER(`title`) LIKE @query OR CONCAT(LOWER(`license_plate`), ' ', LOWER(`title`)) LIKE @query",
        {
            ['@query'] = string.lower('%' .. query .. '%') -- % wildcard, needed to search for all alike results
        })
    TriggerClientEvent("rx_mdt:getBolos", src, result)
end)

RegisterServerEvent("rx_mdt:newBolo")
AddEventHandler("rx_mdt:newBolo", function(data)
    if data.title == "" then
        return
    end
    local xPlayer = ESX.GetPlayerFromId(source)
    if not policeJobs[xPlayer.job.name] then
        exports['esx_holdup']:BanPlayer(source, 'Cheating, trigger event! (rx_mdt:newBolo)')
        return
    end
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    local char = xPlayer.getIdentifier()
    local name = xPlayer.variables.firstName .. " " .. xPlayer.variables.lastName
    local result = MysqlConverter(Config.Mysql, 'fetchAll', 'SELECT * FROM `mdw_bolos` WHERE `dbid` = @id', {
        ['@id'] = data.id
    })
    if data.id ~= nil and data.id ~= 0 then
        MysqlConverter(Config.Mysql, 'execute',
            'UPDATE `mdw_bolos` SET `title` = @title, `license_plate` = @plate, `owner` = @owner, `individual` = @individual, `detail` = @detail, `tags` = @tags, `gallery` = @gallery, `officers` = @officers, `time` = @time, `author` = @author WHERE `dbid` = @id',
            {
                ['@title'] = data.title,
                ['@plate'] = data.plate,
                ['@owner'] = data.owner,
                ['@individual'] = data.individual,
                ['@detail'] = data.detail,
                ['@tags'] = json.encode(data.tags),
                ['@gallery'] = json.encode(data.gallery),
                ['@officers'] = json.encode(data.officers),
                ['@time'] = data.time,
                ['@author'] = name,
                ['@id'] = data.id
            })
    else
        MysqlConverter(Config.Mysql, 'execute',
            'INSERT INTO `mdw_bolos` (`title`, `license_plate`, `owner`, `individual`, `detail`, `tags`, `gallery`, `officers`, `time`, `author`) VALUES (@title, @plate, @owner, @individual, @detail, @tags, @gallery, @officers, @time, @author)',
            {
                ['@title'] = data.title,
                ['@plate'] = data.plate,
                ['@owner'] = data.owner,
                ['@individual'] = data.individual,
                ['@detail'] = data.detail,
                ['@tags'] = json.encode(data.tags),
                ['@gallery'] = json.encode(data.gallery),
                ['@officers'] = json.encode(data.officers),
                ['@time'] = data.time,
                ['@author'] = name

            })
        local result2 = MysqlConverter(Config.Mysql, 'fetchAll',
            "SELECT * FROM mdw_bolos ORDER BY dbid DESC LIMIT 1", {})
        TriggerClientEvent("rx_mdt:boloComplete", src, result2[1].dbid)
    end
end)

RegisterServerEvent("rx_mdt:deleteBolo")
AddEventHandler("rx_mdt:deleteBolo", function(id)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(source)
    if not policeJobs[xPlayer.job.name] then
        exports['esx_holdup']:BanPlayer(source, 'Cheating, trigger event! (rx_mdt:deleteBolo)')
        return
    end
    MysqlConverter(Config.Mysql, 'execute', "DELETE FROM mdw_bolos WHERE dbid = @id", {
        ["@id"] = id
    })
end)

local attachedUnits = {}
RegisterServerEvent("rx_mdt:attachedUnits")
AddEventHandler("rx_mdt:attachedUnits", function(callid)
    local src = source
    if not attachedUnits[callid] then
        local id = #attachedUnits + 1
        attachedUnits[callid] = {}
    end
    TriggerClientEvent("rx_mdt:attachedUnits", src, attachedUnits[callid], callid)
end)

RegisterServerEvent("rx_mdt:callDragAttach")
AddEventHandler("rx_mdt:callDragAttach", function(callid, cid)
    local src = source

    local targetPlayer = ESX.GetPlayerFromIdentifier(cid)
    if targetPlayer == false then
        return
    end
    local name = targetPlayer.variables.firstName .. " " .. targetPlayer.variables.lastName
    local userjob = targetPlayer.getJob().name

    local id = callid

    attachedUnits[id] = {}
    attachedUnits[id][cid] = {}

    local units = 0
    for k, v in ipairs(attachedUnits[id]) do
        units = units + 1
    end

    attachedUnits[id][cid].job = userjob
    attachedUnits[id][cid].callsign = GetCallsign(cid)
    attachedUnits[id][cid].fullname = name
    attachedUnits[id][cid].cid = cid
    attachedUnits[id][cid].callid = callid
    attachedUnits[id][cid].radio = units
    TriggerClientEvent("rx_mdt:callAttach", -1, callid, units)
end)

RegisterServerEvent("rx_mdt:callAttach")
AddEventHandler("rx_mdt:callAttach", function(callid)
    local src = source

    local xPlayer = ESX.GetPlayerFromId(src)
    local name = xPlayer.variables.firstName .. " " .. xPlayer.variables.lastName
    local userjob = xPlayer.getJob().name
    local id = callid
    local cid = xPlayer.getIdentifier()
    attachedUnits[id] = {}
    attachedUnits[id][cid] = {}

    local units = 0
    for k, v in pairs(attachedUnits[id]) do
        units = units + 1
    end
    attachedUnits[id][cid].job = userjob
    attachedUnits[id][cid].callsign = GetCallsign(cid)
    attachedUnits[id][cid].fullname = name
    attachedUnits[id][cid].cid = cid
    attachedUnits[id][cid].callid = callid
    attachedUnits[id][cid].radio = units

    TriggerClientEvent("rx_mdt:callAttach", -1, callid, units)
end)

RegisterServerEvent("rx_mdt:callDetach")
AddEventHandler("rx_mdt:callDetach", function(callid)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    local charid = xPlayer.getIdentifier()
    local id = callid
    attachedUnits[id][charid] = nil
    local units = 0
    for k, v in ipairs(attachedUnits[id]) do
        units = units + 1
    end
    TriggerClientEvent("rx_mdt:callDetach", -1, callid, units)
end)

RegisterServerEvent("rx_mdt:callDispatchDetach")
AddEventHandler("rx_mdt:callDispatchDetach", function(callid, cid)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    local id = callid

    attachedUnits[id][cid] = nil

    local units = 0
    for k, v in ipairs(attachedUnits[id]) do
        units = units + 1
    end
    TriggerClientEvent("rx_mdt:callDetach", -1, callid, units)
end)

RegisterServerEvent("rx_mdt:setWaypoint:unit")
AddEventHandler("rx_mdt:setWaypoint:unit", function(cid)
    local src = source

    local targetPlayer = ESX.GetPlayerFromIdentifier(cid)
    if targetPlayer == false then
        return
    end
    local coords = targetPlayer.getCoords(true)
    TriggerClientEvent("rx_mdt:setWaypoint:unit", src, coords)
end)

RegisterServerEvent("rx_mdt:setDispatchWaypoint")
AddEventHandler("rx_mdt:setDispatchWaypoint", function(callid, cid)
    local src = source
    local targetPlayer = ESX.GetPlayerFromIdentifier(cid)
    if targetPlayer == false then
        return
    end
    local coords = targetPlayer.getCoords(true)
    TriggerClientEvent("rx_mdt:setWaypoint:unit", src, coords)
end)

local CallResponses = {}

RegisterServerEvent("rx_mdt:getCallResponses")
AddEventHandler("rx_mdt:getCallResponses", function(callid)
    local src = source
    if not CallResponses[callid] then
        CallResponses[callid] = {}
    end
    TriggerClientEvent("rx_mdt:getCallResponses", src, CallResponses[callid], callid)
end)

RegisterServerEvent("rx_mdt:sendCallResponse")
AddEventHandler("rx_mdt:sendCallResponse", function(message, time, callid, name)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    local char = xPlayer.getIdentifier()
    local name = xPlayer.variables.firstName .. " " .. xPlayer.variables.lastName
    if not CallResponses[callid] then
        CallResponses[callid] = {}
    end
    local id = #CallResponses[callid] + 1
    CallResponses[callid][id] = {}

    CallResponses[callid][id].name = name
    CallResponses[callid][id].message = message
    CallResponses[callid][id].time = time
    
    TriggerClientEvent("rx_mdt:sendCallResponse", src, message, time, callid, name)
end)

RegisterServerEvent("rx_mdt:getAllReports")
AddEventHandler("rx_mdt:getAllReports", function()
    local src = source
    local result = MysqlConverter(Config.Mysql, 'fetchAll', 'SELECT * FROM mdw_reports', {})
    TriggerClientEvent("rx_mdt:getAllReports", src, result)
end)

RegisterServerEvent("rx_mdt:getReportData")
AddEventHandler("rx_mdt:getReportData", function(id)
    local src = source
    local result = MysqlConverter(Config.Mysql, 'fetchAll', 'SELECT * FROM mdw_reports WHERE dbid = @id', {
        ["@id"] = id
    })
    result[1].tags = json.decode(result[1].tags)
    result[1].gallery = json.decode(result[1].gallery)
    result[1].officersinvolved = json.decode(result[1].officers)
    result[1].officers = json.decode(result[1].officers)
    result[1].civsinvolved = json.decode(result[1].civsinvolved)
    TriggerClientEvent("rx_mdt:getReportData", src, result[1])
end)

RegisterServerEvent("rx_mdt:searchReports")
AddEventHandler("rx_mdt:searchReports", function(querydata)
    local src = source
    local string = string.lower('%' .. querydata .. '%')
    local result = MysqlConverter(Config.Mysql, 'fetchAll',
        "SELECT * FROM mdw_reports aa WHERE LOWER(`type`) LIKE @var1 OR LOWER(`title`) LIKE @var2 OR LOWER(`dbid`) LIKE @var3 OR CONCAT(LOWER(`type`), ' ', LOWER(`title`), ' ', LOWER(`dbid`)) LIKE @var4",
        {
            ["@var1"] = string,
            ["@var2"] = string,
            ["@var3"] = string,
            ["@var4"] = string
        })
    TriggerClientEvent("rx_mdt:getAllReports", src, result)
end)

RegisterServerEvent("rx_mdt:newReport")
AddEventHandler("rx_mdt:newReport", function(data)
    if data.title == "" then
        return
    end

    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not policeJobs[xPlayer.job.name] then
        exports['esx_holdup']:BanPlayer(source, 'Cheating, trigger event! (rx_mdt:newReport)')
        return
    end
    local name = xPlayer.variables.firstName .. " " .. xPlayer.variables.lastName
    local time = os.date()

    local result = MysqlConverter(Config.Mysql, 'fetchAll', 'SELECT * FROM `mdw_reports` WHERE `dbid` = @id', {
        ['@id'] = data.id
    })
    if data.id ~= nil and data.id ~= 0 then

        local action = "Upravil/a záznam, ID: " .. data.id
        TriggerEvent("rx_mdt:newLog", name .. ", " .. action .. ", Zmena: " .. json.encode(data), time)

        lib.logger(xPlayer.identifier, 'mdt', ('Hráč: **%s/%s %s** \nUpravil/a záznam \nID: **%s** \nZmena: **%s**'):format(GetPlayerName(src), name, GetCallsign(xPlayer.identifier), data.id, json.encode(data)))

        MysqlConverter(Config.Mysql, 'execute',
            'UPDATE `mdw_reports` SET `title` = @title, `type` = @type, `detail` = @detail, `tags` = @tags, `gallery` = @gallery, `officers` = @officers, `civsinvolved` = @civsinvolved, `time` = @time, `author` = @author WHERE `dbid` = @id',
            {
                ['@title'] = data.title,
                ['@type'] = data.type,
                ['@detail'] = data.detail,
                ['@tags'] = json.encode(data.tags),
                ['@gallery'] = json.encode(data.gallery),
                ['@officers'] = json.encode(data.officers),
                ['@civsinvolved'] = json.encode(data.civilians),
                ['@time'] = data.time,
                ['@author'] = name,
                ['@id'] = data.id
            })
    else
        MysqlConverter(Config.Mysql, 'execute',
            'INSERT INTO `mdw_reports` (`title`, `type`, `detail`, `tags`, `gallery`, `officers`, `civsinvolved`, `time`, `author`) VALUES (@title, @type, @detail, @tags, @gallery, @officers, @civsinvolved, @time, @author)',
            {
                ['@title'] = data.title,
                ['@type'] = data.type,
                ['@detail'] = data.detail,
                ['@tags'] = json.encode(data.tags),
                ['@gallery'] = json.encode(data.gallery),
                ['@officers'] = json.encode(data.officers),
                ['@civsinvolved'] = json.encode(data.civilians),
                ['@time'] = data.time,
                ['@author'] = name
            })
        Wait(500)
        local result2 = MysqlConverter(Config.Mysql, 'fetchAll',
            "SELECT * FROM mdw_reports ORDER BY dbid DESC LIMIT 1", {})
        TriggerClientEvent("rx_mdt:reportComplete", src, result2[1].dbid)
    end
end)

function UpdateDispatch(src)
    local result = MysqlConverter(Config.Mysql, 'fetchAll', "SELECT * FROM mdw_messages LIMIT 200", {})
    TriggerClientEvent("rx_mdt:dashboardMessages", src, result)
end

RegisterServerEvent("rx_mdt:sendMessage")
AddEventHandler("rx_mdt:sendMessage", function(message, time)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not policeJobs[xPlayer.job.name] then
        exports['esx_holdup']:BanPlayer(source, 'Cheating, trigger event! (rx_mdt:sendMessage)')
        return
    end
    local char = xPlayer.getIdentifier()
    local name = xPlayer.variables.firstName .. " " .. xPlayer.variables.lastName
    local pic = "https://cdn.discordapp.com/attachments/904822052358336573/1016298208516915260/male.png"

    local result = MysqlConverter(Config.Mysql, 'fetchAll', 'SELECT * FROM mdw_profiles WHERE cid = @identifier', {
        ["@identifier"] = char
    })
    if result and result[1] ~= nil then
        if result[1].image and result[1].image ~= nil and result[1].image ~= "" then
            pic = result[1].image
        end
    end
    lib.logger(xPlayer.identifier, 'mdt', ('Hráč: **%s/%s %s** \nnapsal správu: **%s**'):format(GetPlayerName(src), name, GetCallsign(char), message))
    MysqlConverter(Config.Mysql, 'execute',
        'INSERT INTO mdw_messages (name, message, time, profilepic, job) VALUES(@name, @message, @time, @pic, @job)',
        {
            ["@name"] = name,
            ["@message"] = message,
            ["@time"] = time,
            ["@pic"] = pic,
            ["@job"] = 'police'
        })
    local lastMsg = {
        name = name,
        message = message,
        time = time,
        profilepic = pic,
        job = 'police'
    }
    TriggerClientEvent("rx_mdt:dashboardMessage", -1, lastMsg)
end)

RegisterServerEvent("rx_mdt:refreshDispatchMsgs")
AddEventHandler("rx_mdt:refreshDispatchMsgs", function()
    local src = source
    local result = MysqlConverter(Config.Mysql, 'fetchAll', 'SELECT * FROM mdw_messages LIMIT 200', {})
    TriggerClientEvent("rx_mdt:dashboardMessages", src, result)
end)

-- RegisterNetEvent('rx_mdt:dashboardMessage')
-- AddEventHandler('rx_mdt:dashboardMessage', function(sentData)
--     local job = exports["isPed"]:isChar("myjob")
--     if job == xPlayer.job.name or job.name == 'ambulance' then
--         SendNUIMessage({ type = "dispatchmessage", data = sentData })
--     end
-- end)

RegisterServerEvent("rx_mdt:setCallsign")
AddEventHandler("rx_mdt:setCallsign", function(identifier, callsign)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not policeJobs[xPlayer.job.name] then
        exports['esx_holdup']:BanPlayer(source, 'Cheating, trigger event! (rx_mdt:setCallsign)')
        return
    end
    lib.logger(xPlayer.identifier, 'mdt', ('Hráč: **%s/%s %s** \nnastavil volací znak: **%s**'):format(GetPlayerName(src), xPlayer.getName(), GetCallsign(xPlayer.identifier), callsign))
    MysqlConverter(Config.Mysql, 'execute', "UPDATE users SET `callsign` = @callsign WHERE identifier = @identifier", {
        ['@callsign'] = callsign,
        ['@identifier'] = identifier
    })
end)

function tprint(t, s)
    for k, v in pairs(t) do
        local kfmt = '["' .. tostring(k) .. '"]'
        if type(k) ~= 'string' then
            kfmt = '[' .. k .. ']'
        end
        local vfmt = '"' .. tostring(v) .. '"'
        if type(v) == 'table' then
            tprint(v, (s or '') .. kfmt)
        else
            if type(v) ~= 'string' then
                vfmt = tostring(v)
            end
            print(type(t) .. (s or '') .. kfmt .. ' = ' .. vfmt)
        end
    end
end

function getUserFromCid(cid)
    local users = ESX.GetPlayerFromId(source)
    for k, v in pairs(users) do
        local user = ESX.GetPlayerFromId(v)
        if user then
            local char = user.getJob().grade_salary
            if char.id == cid then
                return user
            end
        end
    end
    return false
end

function MysqlConverter(plugin, type, query, var)
    local wait = promise.new()
    if type == 'fetchAll' and plugin == 'mysql-async' then
        MySQL.Async.fetchAll(query, var, function(result)
            wait:resolve(result)
        end)
    end
    if type == 'execute' and plugin == 'mysql-async' then
        MySQL.Async.execute(query, var, function(result)
            wait:resolve(result)
        end)
    end
    if type == 'execute' and plugin == 'ghmattisql' then
        exports['ghmattimysql']:execute(query, var, function(result)
            wait:resolve(result)
        end)
    end
    if type == 'fetchAll' and plugin == 'ghmattisql' then
        exports.ghmattimysql:execute(query, var, function(result)
            wait:resolve(result)
        end)
    end
    if type == 'execute' and plugin == 'oxmysql' then
        exports.oxmysql:execute(query, var, function(result)
            wait:resolve(result)
        end)
    end
    if type == 'fetchAll' and plugin == 'oxmysql' then
        exports['oxmysql']:fetch(query, var, function(result)
            wait:resolve(result)
        end)
    end
    return Citizen.Await(wait)
end

function firstToUpper(str)
    return (str:gsub("^%l", string.upper))
end
