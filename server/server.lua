truck = {}
route = {}

--truck[ID] -> route name
--			-> route number
--			-> timer
--			-> timer state
--			-> trash collected
--			-> Driver - Picker
-- 			-> Object


RegisterServerEvent("Garbage:NewVehicle")
AddEventHandler("Garbage:NewVehicle", function(key,id,driver,job)
	print("test")
	truck[id].routeName = key
	truck[id].routeNumber = 1
	truck[id].timer = 0
	truck[id].timerState = true
	truck[id].trashCollected = 0
	truck[id].object = {}
	truck[id].driver = driver
	truck[id].finish = false
	if job == "solo" then
		truck[id].picker = {driver}
	else
		truck[id].picker = {}
	end
	print("newvehcile")
	TriggerClientEvent("Garbage:createZone",source,truck[id],id)
end)

RegisterServerEvent("Garbage:DeleteVehicle")
AddEventHandler("Garbage:DeleteVehicle", function(id)
	truck[id] = {}
	TriggerClientEvent("Garbage:vehicleDestroy",-1,id)
end)

RegisterServerEvent("Garbage:getDriverList")
AddEventHandler("Garbage:getDriverList",function()
	local listTempo[source] = {}
	for k,v in pairs(truck) do
		if exports.ft_libs:TableLength(v.picker) == 0 then
			table.insert(listTempo[source],truck[k])
		end
	end
	TriggerClientEvent("Garbage:getDriverList",source,listTempo[source])
end)

RegisterServerEvent("Garbage:AddPicker")
AddEventHandler("Garbage:AddPicker",function(truckid,pickerId)
	table.insert(truck[truckid].picker, pickerId)
	TriggerClientEvent("Garbage:createZone",source,truck[truckid],truckid)
end)

RegisterServerEvent("Garbage:RemovePlayer")
AddEventHandler("Garbage:RemovePlayer",function(truckId,job,playerid)
	if job == "driver" then
		TriggerEvent("Garbage:DeleteVehicle",truckid)
	elseif job == "picker" then
		for i = exports.ft_libs:TableLength(truck[truckid].picker),1,-1 do
			if truck[truckid].picker[i] == playerid then
				table.remove(truck[truckid].picker,i)
			end
		end
	elseif job == "solo" then
		TriggerEvent("Garbage:DeleteVehicle",truckid)
	end
end)

RegisterServerEvent("Garbage:addObject")
AddEventHandler("Garbage:addObject",function(objectTrash,id)
	truck[id].object = objectTrash
end)


RegisterServerEvent("Garbage:updateObject")
AddEventHandler("Garbage:updateObject",function(id,object,remove)
	if remove == "remove" then
		for i = #truck[id].object, 1,-1 do
	  		if truck[id].object[i]==object then
	  			table.remove(truck[id].object,i)
	  		end
  		end
	elseif remove == "add" then
		table.insert(truck[id].object, object)
	elseif remove == "update" then
		truck[id].object = object
	end
	TriggerClientEvent("Garbage:updateObject",truck[id].driver,truck[id].object)
	for k,v in pairs(truck[id].picker) do
		TriggerClientEvent("Garbage:updateObject",v,truck[id].object)
	end
end)

RegisterServerEvent("Garbage:truckFinish")
AddEventHandler("Garbage:truckFinish",function(id)
	truck[id].timerState = false

	TriggerClientEvent("Garbage:showTimer",truck[id].driver,truck[id].timer)
	for k,v in pairs(truck[id].picker) do
		TriggerClientEvent("Garbage:showTimer",v,truck[id].timer)
	end

end)




--[[Citizen.CreateThread(function() 
	while true do
		Citizen.Wait(1000)
		for k,v in pairs(truck) do
			if v.timerState then
				v.timer = v.timer + 1
			end	
		end
	end
end)

Citizen.CreateThread(function()
	while true do
		Citizen.Wait(1)
		for k,v in pairs(truck) do
			if exports.ft_libs:TableLength(v.object) == 0 then
				v.routeNumber = v.routeNumber + 1
				if v.routeNumber <= exports.ft_libs:TableLength(route[v.routeName].stop) then
					TriggerClientEvent("Garbage:createZone",v.driver,truck[k],k,true)
				else
					if not v.finish then
						v.finish = true
						TriggerClientEvent("Garbage:finish",v.driver,truck[k])
						for k1,v1 in pairs(v.picker) do
							TriggerClientEvent("Garbage:finish",v1,truck[k])
						end
					end
				end
			end
		end
	end
end)--]]

