local holdingup = false
local bank = ""
local secondsRemaining = 0
local blipRobbery = nil
local job = nil
local blips = {}
ESX = nil

Citizen.CreateThread(function()
	while ESX == nil do
		TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
		Citizen.Wait(0)
	end

	while true do
        local playerData = ESX.GetPlayerData()
        if playerData.job ~= nil then
            handleJobChange(playerData.job)
            break
        end
        Citizen.Wait(10)
	end

	RegisterNetEvent('esx:setJob')
	AddEventHandler('esx:setJob', handleJobChange)
end)

function handleJobChange(newJob)
	job = newJob.name
	deleteBlips()

	if job ~= 'police' then
		createBlips()
	end
end

function DisplayHelpText(str)
	SetTextComponentFormat("STRING")
	AddTextComponentString(str)
	DisplayHelpTextFromStringLabel(0, 0, 1, -1)
end

function drawTxt(x,y ,width,height,scale, text, r,g,b,a, outline)
    SetTextFont(0)
    SetTextProportional(0)
    SetTextScale(scale, scale)
    SetTextColour(r, g, b, a)
    SetTextDropShadow(0, 0, 0, 0,255)
    SetTextEdge(1, 0, 0, 0, 255)
    SetTextDropShadow()
    if(outline)then
	    SetTextOutline()
	end
    SetTextEntry("STRING")
    AddTextComponentString(text)
    DrawText(x - width/2, y - height/2 + 0.005)
end

RegisterNetEvent('esx_holdupbank:currentlyrobbing')
AddEventHandler('esx_holdupbank:currentlyrobbing', function(robb)
	holdingup = true
	bank = robb
	secondsRemaining = 300
end)

RegisterNetEvent('esx_holdupbank:killblip')
AddEventHandler('esx_holdupbank:killblip', function()
    RemoveBlip(blipRobbery)
end)

RegisterNetEvent('esx_holdupbank:setblip')
AddEventHandler('esx_holdupbank:setblip', function(position)
    blipRobbery = AddBlipForCoord(position.x, position.y, position.z)
    SetBlipSprite(blipRobbery , 161)
    SetBlipScale(blipRobbery , 2.0)
    SetBlipColour(blipRobbery, 3)
    PulseBlip(blipRobbery)
end)

RegisterNetEvent('esx_holdupbank:toofarlocal')
AddEventHandler('esx_holdupbank:toofarlocal', function(robb)
	holdingup = false
	ESX.ShowNotification(_U('robbery_cancelled'))
	robbingName = ""
	secondsRemaining = 0
	incircle = false
end)


RegisterNetEvent('esx_holdupbank:robberycomplete')
AddEventHandler('esx_holdupbank:robberycomplete', function(robb)
	holdingup = false
	ESX.ShowNotification(_U('robbery_complete') .. Banks[bank].reward)
	bank = ""
	secondsRemaining = 0
	incircle = false
end)

Citizen.CreateThread(function()
	while true do
		Citizen.Wait(0)
		if holdingup then
			Citizen.Wait(1000)
			if(secondsRemaining > 0)then
				secondsRemaining = secondsRemaining - 1
			end
		end
	end
end)

function deleteBlips()
	for i = 1, #blips do
		RemoveBlip(table.remove(blips))
	end
end

function createBlips()
	Citizen.CreateThread(function()
		for k,v in pairs(Banks)do
			local ve = v.position

			local blip = AddBlipForCoord(ve.x, ve.y, ve.z)
			SetBlipSprite(blip, 255)--156
			SetBlipScale(blip, 0.8)
			SetBlipColour(blip, 75)
			SetBlipAsShortRange(blip, true)
			BeginTextCommandSetBlipName("STRING")
			AddTextComponentString(_U('bank_robbery'))
			EndTextCommandSetBlipName(blip)
			table.insert(blips, blip)
		end
	end)
end
incircle = false

Citizen.CreateThread(function()
	while true do
		if job == 'police' then
			Citizen.Wait(1000)
		else
			local pos = GetEntityCoords(GetPlayerPed(-1), true)
			drawBankMarkers(pos)
			handleHoldUpIfNeeded(pos)
			Citizen.Wait(0)
		end
	end
end)

function drawBankMarkers(pos)
	for k,v in pairs(Banks) do
		local pos2 = v.position

		if(Vdist(pos.x, pos.y, pos.z, pos2.x, pos2.y, pos2.z) < 15.0) then
			if not holdingup then
				DrawMarker(1, v.position.x, v.position.y, v.position.z - 1, 0, 0, 0, 0, 0, 0, 1.0001, 1.0001, 1.5001, 1555, 0, 0,255, 0, 0, 0,0)

				if (Vdist(pos.x, pos.y, pos.z, pos2.x, pos2.y, pos2.z) < 1.0) then
					if (incircle == false) then
						DisplayHelpText(_U('press_to_rob') .. v.nameofbank)
					end
					incircle = true
					if IsControlJustReleased(1, 51) then
						TriggerServerEvent('esx_holdupbank:rob', k)
					end
				elseif (Vdist(pos.x, pos.y, pos.z, pos2.x, pos2.y, pos2.z) > 1.0) then
					incircle = false
				end
			end
		end
	end
end

function handleHoldUpIfNeeded(pos)
	if holdingup then
		drawTxt(0.66, 1.44, 1.0,1.0,0.4, _U('robbery_of') .. secondsRemaining .. _U('seconds_remaining'), 255, 255, 255, 255)

		local pos2 = Banks[bank].position

		if (Vdist(pos.x, pos.y, pos.z, pos2.x, pos2.y, pos2.z) > 7.5) then
			TriggerServerEvent('esx_holdupbank:toofar', bank)
		end
	end
end
