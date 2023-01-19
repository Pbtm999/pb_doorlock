ESX = nil
local doorState = {}

TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)

RegisterServerEvent('pb_doorlock:updateState')
AddEventHandler('pb_doorlock:updateState', function(doorIndex, state)
	local xPlayer = ESX.GetPlayerFromId(source)

	if xPlayer and type(doorIndex) == 'number' and type(state) == 'boolean' and Config.DoorList[doorIndex] then
		doorState[doorIndex] = state
		TriggerClientEvent('pb_doorlock:setDoorState', -1, doorIndex, state)
	end
end)

ESX.RegisterServerCallback('pb_doorlock:getDoorState', function(source, cb)
	cb(doorState)
end)