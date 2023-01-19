ESX = nil

Citizen.CreateThread(function()
	while ESX == nil do
		TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
		Citizen.Wait(0)
	end
	while not ESX.GetPlayerData().job do
		Citizen.Wait(10)
	end
	ESX.PlayerData = ESX.GetPlayerData()
	-- Update the door list
	ESX.TriggerServerCallback('pb_doorlock:getDoorState', function(doorState)
		for index,state in pairs(doorState) do
			Config.DoorList[index].locked = state
		end
	end)
end)

RegisterNetEvent('esx:setJob')
AddEventHandler('esx:setJob', function(job) ESX.PlayerData.job = job end)

RegisterNetEvent('pb_doorlock:setDoorState')
AddEventHandler('pb_doorlock:setDoorState', function(index, state) Config.DoorList[index].locked = state end)

Citizen.CreateThread(function()
	while true do
		Citizen.Wait(100)
		local playerCoords = GetEntityCoords(PlayerPedId())
		for k,v in ipairs(Config.DoorList) do
			if v.doors then
				for k2,v2 in ipairs(v.doors) do
					if v2.object and DoesEntityExist(v2.object) then
						if k2 == 1 then
							v.distanceToPlayer = #(playerCoords - GetEntityCoords(v2.object))
						end
						-- if v.locked and v2.objHeading and ESX.Math.Round(GetEntityHeading(v2.object)) ~= v2.objHeading then
						-- 	SetEntityHeading(v2.object, v2.objHeading)
						-- end
					else
						v.distanceToPlayer = nil
						v2.object = GetClosestObjectOfType(v2.objCoords, 1.0, v2.objHash, false, false, false)
					end
				end
			else
				if v.object and DoesEntityExist(v.object) then
					v.distanceToPlayer = #(playerCoords - GetEntityCoords(v.object))
					-- if v.locked and v.objHeading and ESX.Math.Round(GetEntityHeading(v.object)) ~= v.objHeading then
					-- 	SetEntityHeading(v.object, v.objHeading)
					-- end
				else
					v.distanceToPlayer = nil
					v.object = GetClosestObjectOfType(v.objCoords, 1.0, v.objHash, false, false, false)
				end
			end
		end
		local letSleep = true
		for k,v in ipairs(Config.DoorList) do
			if v.distanceToPlayer and v.distanceToPlayer < 50 then
				letSleep = false
				if v.doors then
					for k2,v2 in ipairs(v.doors) do
						FreezeEntityPosition(v2.object, v.locked)
					end
				else
					FreezeEntityPosition(v.object, v.locked)
				end
			end
		end
		if letSleep then
			Citizen.Wait(500)
		end
		Citizen.Wait(500)
	end
end)

RegisterNetEvent("chave")
AddEventHandler("chave", function(chave)
	for k,v in ipairs(Config.DoorList) do
		if v.distanceToPlayer and v.distanceToPlayer < 10 then
			if v.doors then
				for k2,v2 in ipairs(v.doors) do
					FreezeEntityPosition(v2.object, v.locked)
				end
			else
				FreezeEntityPosition(v.object, v.locked)
			end
		end
		if v.distanceToPlayer and v.distanceToPlayer < v.maxDistance then
			for j,job in pairs(v.authorizedJobs) do
				if job == chave then
					local ped = PlayerPedId()
					if chave == 2 or chave == 'comando_cartel' then
						local dict = loadDict("anim@mp_player_intmenu@key_fob@")
						TaskPlayAnim(ped, dict, "fob_click_fp", 1.0, 1.0, 1.0, 1, 0.0, 0, 0, 0)
					else
						local dict = loadDict("veh@break_in@0h@p_m_one@")
						TaskPlayAnim(ped, dict, "low_force_entry_ds", 1.0, 1.0, 1.0, 1, 0.0, 0, 0, 0)
					end
					Wait(700)
					v.locked = not v.locked
					TriggerServerEvent('pb_doorlock:updateState', k, v.locked) -- broadcast new state of the door to everyone
					ClearPedTasks(ped)
				end
			end
		end
	end
end)

loadDict = function(dict, anim)
    while not HasAnimDictLoaded(dict) do Wait(0) RequestAnimDict(dict) end
    return dict
end

RegisterCommand('comandoD', function()
	TriggerEvent("player:receiveItem", "comando", 1 , {}, {num = 2})
end)

-- (Re)set locals at start
local infoOn = false    -- Disables the info on restart.
local coordsText = ""   -- Removes any text the coords had stored.
local headingText = ""  -- Removes any text the heading had stored.
local modelText = ""    -- Removes any text the model had stored.



-- Thread that makes everything happen.
Citizen.CreateThread(function()                             -- Create the thread.
    while true do                                           -- Loop it infinitely.
        local pause = 250                                   -- If infos are off, set loop to every 250ms. Eats less resources.
        if infoOn then                                      -- If the info is on then...
            pause = 5                                       -- Only loop every 5ms (equivalent of 200fps).
            local player = GetPlayerPed(-1)                 -- Get the player.
            if IsPlayerFreeAiming(PlayerId()) then          -- If the player is free-aiming (update texts)...
                local entity = getEntity(PlayerId())        -- Get what the player is aiming at. This isn't actually the function, that's below the thread.
                local coords = GetEntityCoords(entity)      -- Get the coordinates of the object.
                local heading = GetEntityHeading(entity)    -- Get the heading of the object.
                local model = GetEntityModel(entity)        -- Get the hash of the object.
                coordsText = coords                         -- Set the coordsText local.
                headingText = heading                       -- Set the headingText local.
                modelText = model                           -- Set the modelText local.
            end                                             -- End (player is not freeaiming: stop updating texts).
            DrawInfos("Coordinates: " .. coordsText .. "\nHeading: " .. headingText .. "\nHash: " .. modelText)     -- Draw the text on screen
        end                                                 -- Info is off, don't need to do anything.
        Citizen.Wait(pause)                                 -- Now wait the specified time.
    end                                                     -- End (stop looping).
end)                                                        -- Endind the entire thread here.



-- Function to get the object the player is actually aiming at.
function getEntity(player)                                          -- Create this function.
    local result, entity = GetEntityPlayerIsFreeAimingAt(player)    -- This time get the entity the player is aiming at.
    return entity                                                   -- Returns what the player is aiming at.
end                                                                 -- Ends the function.



-- Function to draw the text.
function DrawInfos(text)
    SetTextColour(255, 255, 255, 255)   -- Color
    SetTextFont(1)                      -- Font
    SetTextScale(0.4, 0.4)              -- Scale
    SetTextWrap(0.0, 1.0)               -- Wrap the text
    SetTextCentre(false)                -- Align to center(?)
    SetTextDropshadow(0, 0, 0, 0, 255)  -- Shadow. Distance, R, G, B, Alpha.
    SetTextEdge(50, 0, 0, 0, 255)       -- Edge. Width, R, G, B, Alpha.
    SetTextOutline()                    -- Necessary to give it an outline.
    SetTextEntry("STRING")
    AddTextComponentString(text)
    DrawText(0.015, 0.71)               -- Position
end



-- Creating the function to toggle the info.
ToggleInfos = function()                -- "ToggleInfos" is a function
    infoOn = not infoOn                 -- Switch them around
end                                     -- Ending the function here.



-- Creating the command.
RegisterCommand("idgun", function()     -- Listen for this command.
    ToggleInfos()                       -- Heard it! Let's toggle the function above.
end)