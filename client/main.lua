onDuty = false
job = nil
vehicleId=nil
route = {}


RegisterNetEvent("ft_libs:OnClientReady")
AddEventHandler('ft_libs:OnClientReady', function()
	for k,v in pairs (baseLocation) do
		exports.ft_libs:PrintTable(v)
		exports.ft_libs:AddArea("Garbage"..tostring(k),{
			marker = {
				text = "Entrance",
				type = 1,
				weight = 1,
				height = 1,
				red = 35,
				green = 35,
				blue = 35,
				showDistance = 20,
			},
			blip = {
				text = v.name,
				colorId = 31,
				imageId = 318,
			},
			trigger = {
				weight = 2,
				active = {
					callback = Entrance,
				},
				exit = {
					callback = function() exports.ft_libs:CloseMenu() end
				}
			},
			locations = v.EntranceMarkerPosition
		})

		exports.ft_libs:AddArea("GarbageVehicle"..v.name, {
			marker = {
				text = "vehicle",
				type = 1,
				weight = 3,
				height = 1,
				red = 35,
				green = 35,
				blue = 35,
				showDistance = 20,
			},
			blip = {
				text = v.name.." garage",
				colorId = 31,
				imageId = 318,
			},
			trigger = {
				weight = 3,
				active = {
					callback = Vehicle,
				},
				exit = {
					callback = function() exports.ft_libs:CloseMenu() end
				},
				data = {
					TruckSpawnHeading = v.TruckSpawnHeading,
					position = v.TruckSpawnPosition[1],
				}
			},
			locations = v.TruckSpawnPosition
		})
	end

	exports.ft_libs:AddMenu("garbage:Entrance",{
		menuTitle = "Garbage Duty",
		closable = true,
		buttons = {
			{
				text = "Go to on Duty (Driver)",
				exec = { callback = enterDriver},
			},
			{
				text = "Go to on Duty (Picker)",
				exec = { callback = enterPicker},
			},
			{
				text = "Go to on Duty (Solo)",
				exec = { callback = enterSolo},
			},
			{
				text = "Leave Duty",
				exec = { callback = exit},
			}
		}
	})

	exports.ft_libs:AddMenu("garbage:Vehicle",{
		menuTitle = "Garbage garage",
		closable = true,
	})

	exports.ft_libs:AddMenu("garbage:routeSelected",{
		menuTitle = "Garbage route",
	})

	exports.ft_libs:AddMenu("garbage:pickerSelect",{
		menuTitle = "Driver list",
	})
end)



function Entrance()
	if not exports.ft_libs:MenuIsOpen() then
		exports.ft_libs:HelpPromt("Press ~b~"..GetControlInstructionalButton(1, control.InteractionKey, 1).."~s~ to open duty menu")
		if IsControlJustPressed(1, control.InteractionKey) then
			exports.ft_libs:OpenMenu("garbage:Entrance")
		end
	end
end

function enterDriver()
	if not onDuty then
		changeTenu()
		onDuty = true
		job = "driver"
	else
		exports.ft_libs:Notification("You are already on duty")
	end
end

function enterPicker()
	if not onDuty then
		changeTenu()
		onDuty = true
		job = "picker"
		TriggerServerEvent("Garbage:getDriverList")
	else
		exports.ft_libs:Notification("You are already on duty")
	end
end

RegisterNetEvent("Garbage:getDriverList")
AddEventHandler("Garbage:getDriverList", function(list)
	exports.ft_libs:CloseMenu()
	exports.ft_libs:CleanMenuButtons("garbage:pickerSelect")
	exports.ft_libs:AddMenuButton("garbage:pickerSelect", {{text = "Leave", exec = {callback = exit}}})
	for k,v in pairs(list) do
		exports.ft_libs:AddMenuButton("garbage:pickerSelect", {{text = "Road : "..route[v.routeName].routeName, exec = {callback = selectedPicker}, data = k}})
	end
	exports.ft_libs:OpenMenu("garbage:pickerSelect")
end)

function selectedPicker(data)
	local pickerId =  GetPlayerServerId(PlayerId())
	TriggerServerEvent("Garbage:AddPicker",data,pickerId)
	vehicleId = data
end

function enterSolo()
	if not onDuty then
		changeTenu()
		onDuty = true
		job = "solo"
	else
		exports.ft_libs:Notification("You are already on duty")
	end
end

function exit()
	if onDuty then
		if vehicleId ~= nil then
			local playerId =  GetPlayerServerId(PlayerId())
			TriggerServerEvent("Garbage:RemovePlayer",vehicleId,job,playerId)
			vehicleId = nil
		end
		setTenu()
		onDuty = false
		job = nil
		exports.ft_libs:CloseMenu()

	else
		exports.ft_libs:Notification("You are not already on duty")
	end
end





function Vehicle(data)
	if not exports.ft_libs:MenuIsOpen() then
		if onDuty then
			if job == "driver" or job == "solo" then
				exports.ft_libs:HelpPromt("Pressr ~b~"..GetControlInstructionalButton(1, control.InteractionKey, 1).."~s~ to go in Garage")
				if IsControlJustPressed(1, control.InteractionKey) then
					exports.ft_libs:CleanMenuButtons("garbage:Vehicle")
					exports.ft_libs:SetMenuButtons("garbage:Vehicle", {
				      	{text = "Get Vehicle", exec = { callback = selectRoad}, data = data},
						{text = "Put Vehicle in garage", exec = { callback = PutVehicle}, data = data}
				    })
					exports.ft_libs:OpenMenu("garbage:Vehicle")
				end
			else
				exports.ft_libs:Notification("You are a picker not a driver")
			end
		else
			exports.ft_libs:Notification("You are not in duty")
		end
	end
end

function selectRoad(data)
	if IsPedSittingInAnyVehicle(GetPlayerPed(-1)) then
		exports.ft_libs:Notification("You are in vehicle")
	else
		exports.ft_libs:CleanMenuButtons("garbage:routeSelected")
		for k,v in pairs(route) do
			exports.ft_libs:AddMenuButton("garbage:routeSelected", {{text = v.routeName, exec = {callback = selectedRoad}, data = {key = k, vehicle = data}}})
		end
		exports.ft_libs:NextMenu("garbage:routeSelected")
	end
end



function selectedRoad(data)
	routeKey = data.key
	vehicleData = data.vehicle
	exports.ft_libs:Notification("You have selected Road : "..route[routeKey].routeName)

	getVehicle(routeKey,vehicleData)
end


function getVehicle(key, vehicleData)
	local vehicleModel = GetHashKey("trash2")
	RequestModel(vehicleModel)
	while not HasModelLoaded(vehicleModel) do
		Citizen.Wait(0)
	end

	i = 0
	while IsAnyVehicleNearPoint(vehicleData.position.x,vehicleData.position.y,vehicleData.position.z, 3.0) and i < 500 do 
		Citizen.Wait(100) 
		exports.ft_libs:Notification("Place not safe to spawn vehicle") 
		i= i + 1 
	end

	local vehicle = CreateVehicle(vehicleModel,vehicleData.position.x,vehicleData.position.y,vehicleData.position.z,vehicleData.TruckSpawnHeading, true, false)
	SetVehicleOnGroundProperly(vehicle)
	SetEntityAsMissionEntity(vehicle,  true,  true)
	local id = NetworkGetNetworkIdFromEntity(vehicle)
	SetNetworkIdCanMigrate(id, true)
	TaskWarpPedIntoVehicle(GetPlayerPed(-1), vehicle, -1)
	exports.ft_libs:CloseMenu()			

	local driverId =  GetPlayerServerId(PlayerId())
	Citizen.Trace("playerId")
	
	TriggerServerEvent("Garbage:NewVehicle",key,id,driverId,job)
	Citizen.Trace(key)
	Citizen.Trace(id)
	Citizen.Trace(driverId)
	Citizen.Trace(job)
	
	vehicleId = id
end



function PutVehicle()
	if not IsPedSittingInAnyVehicle(GetPlayerPed(-1)) then
		exports.ft_libs:Notification("You are not in vehicle")
	else
		vehicletempo = GetVehiclePedIsIn(GetPlayerPed(-1), true)
		if GetHashKey("trash2") == GetEntityModel(vehicletempo) then
			local id = NetworkGetNetworkIdFromEntity(vehicletempo)
			DeleteVehicle(vehicletempo)
			exports.ft_libs:CloseMenu()
			TriggerServerEvent("Garbage:DeleteVehicle",id)
		else
			exports.ft_libs:Notification("The boss doesn't want this vehicle")
		end
	end
end








local data = {}
function changeTenu()
	player = GetPlayerPed(-1)
	data.skin = GetEntityModel(player)
	data.component = {}
	data.prop = {}
	for i = 0, 11 do
		data.component[i] = {}
		data.component[i].value =  GetPedDrawableVariation(player, i)
		data.component[i].valueTexture = GetPedTextureVariation(player, i)
	end
	for i = 0, 2 do
		data.prop[i] = {}
		data.prop[i].value = GetPedPropIndex(player, i)
		data.prop[i].valueTexture = GetPedPropTextureIndex(player, i)
	end
	local tenu = {}
	local player = GetPlayerPed(-1)
	-- 3 = gloves, 11 = vest, 4 = pants, 8 = shirt, 6 = shoes
	if(GetEntityModel(player) == GetHashKey("mp_m_freemode_01")) then
		tenu = { [11] = {item = 97,item_texture = 1}, [4] ={item = 36, item_texture = 0}, [8] = {item = 59, item_texture = 1}, [6] = {item = 71,item_texture =1}}
	else
		tenu = { [11] = {item = 36,item_texture = 0}, [4] ={item = 35, item_texture = 0}, [6] = {item = 71,item_texture =0}}
	end


	for k,v in pairs(tenu) do
	    SetPedComponentVariation(GetPlayerPed(-1), k, tonumber(v.item), tonumber(v.item_texture), 0)
	end
end

function setTenu()
	setSkin(data.skin)

    local player = GetPlayerPed(-1)
	for i = 0, 11 do
		SetPedComponentVariation(player, i, data.component[i].value, data.component[i].valueTexture, 0)
	end
	for i = 0, 2 do
		SetPedPropIndex(player, i,  data.component[i].value, data.component[i].valueTexture, 0)
	end
end

function setSkin(hash)
	modelhashed = hash
	RequestModel(modelhashed)
    while not HasModelLoaded(modelhashed) do
        RequestModel(modelhashed)
        Citizen.Wait(0)
    end
    SetPlayerModel(PlayerId(), modelhashed)
    SetModelAsNoLongerNeeded(modelhashed)
end



local objectTrash = {}

RegisterNetEvent("Garbage:createZone")
AddEventHandler("Garbage:createZone",function(truck,id,nexts)
	Citizen.Trace("CreateZone")
	if job == "driver" or job == "solo" then 
		Citizen.Trace("Driver")
		local trashmodel = {"prop_cs_rub_binbag_01","prop_rub_binbag_sd_01","prop_rub_binbag_sd_02","prop_cs_street_binbag_01","hei_prop_heist_binbag"}
		local stop = route[truck.routeName].stop[truck.routeNumber]

		for _,v in pairs(stop.trash) do
			local random = math.random(1,5)
			Citizen.Trace(trashmodel[random])
			Citizen.Trace(v.x)
			hash = GetHashKey(trashmodel[random])
		    RequestModel(hash)
		    while not HasModelLoaded(hash) do 
		        Citizen.Wait(1) 
		    end
	    	local object = CreateObjectNoOffset(hash,v.x,v.y,v.z,true,true,true)
	    	PlaceObjectOnGroundProperly(object)
	   	 	SetModelAsNoLongerNeeded(hash)
	    	SetEntityAsMissionEntity(object)
	    	table.insert(objectTrash, object)
		end
		TriggerServerEvent("Garbage:addObject",objectTrash,id)
		if nexts then
			TriggerServerEvent("Garbage:updateObject",id,objectTrash,"update")
		end
	elseif job == "picker" then
		objectTrash = truck.object
	end

	exports.ft_libs:AddArea("garbage:collect", {
		marker = { type = 1, weight = 2, height = 1, red = 255, green = 255, blue = 153 },
		blip = { text = "Trash", colorId = 1, imageId = 1 },
		trigger = {weight = 10, active= {callback = collect}},
		locations = {
			route[truck.routeName].stop[truck.routeNumber].blip,
		}
 	})
end)



function collect()
	if job == "solo" then
		exports.ft_libs:HelpPromt("Press ~b~"..GetControlInstructionalButton(1, control.OpenTruckBackKey, 1).."~s~ to open/close the back of the truck \n and press ~b~"..GetControlInstructionalButton(1, control.InteractionKey, 1).."~s~ to collect trash")
	elseif job =="driver" then
		exports.ft_libs:HelpPromt("Press ~b~"..GetControlInstructionalButton(1, control.OpenTruckBackKey, 1).."~s~ to open/close the back of the truck and wait picker")
	elseif job =="picker" then
		exports.ft_libs:HelpPromt("Press ~b~"..GetControlInstructionalButton(1, control.InteractionKey, 1).."~s~ to collect trash")
	end
end


local atach = false
local objectAttached

Citizen.CreateThread(function() 
	while true do
		Citizen.Wait(1)
		if job == "driver" or job == "solo" then
			if IsControlJustPressed(1, control.OpenTruckBackKey) then
				if IsPedSittingInAnyVehicle(GetPlayerPed(-1)) then
					vehicle = GetVehiclePedIsIn(GetPlayerPed(-1), true)
					if GetEntityModel(vehicle) == GetHashKey("trash2") then
						if GetVehicleDoorAngleRatio(vehicle, 5) > 0.0 then	
				        	SetVehicleDoorShut(vehicle, 5, false)
						else
					        SetVehicleDoorOpen(vehicle, 5, false) 
					    end
					end
			    end    
			end
		elseif job == "picker" or job == "solo" then
			if IsControlJustPressed(1, control.InteractionKey)then
				if atach then 
					local pos = GetEntityCoords(GetPlayerPed(-1),true)
			  		local veh = exports.ft_libs:GetEntityInDirection(3)
			  		Citizen.Trace(GetEntityModel(veh))
			  		Citizen.Trace(GetHashKey("trash2"))
			  		if veh ~= false and GetEntityModel(veh) == GetHashKey("trash2") then
			  			if GetVehicleDoorAngleRatio(vehicle, 5) > 0.0 then
			  				deleteTrash("missfbi4prepp1","_bag_throw_garbage_man",false)
			  			else
			  				exports.ft_libs:Notification("The back of vehicle is not open")
			  				deleteTrash("missfbi4prepp1","_bag_drop_garbage_man",true)
			  			end
			  		else
			  			exports.ft_libs:Notification("No vehicle")
						deleteTrash("missfbi4prepp1","_bag_drop_garbage_man",true)
			  		end
				else
					for _,v in pairs(objectTrash) do
						local ox,oy,oz = table.unpack(GetEntityCoords(v))
						local x,y,z = table.unpack(GetEntityCoords(GetPlayerPed(-1),true))
						if GetDistanceBetweenCoords(ox,oy,oz,x,y,z) <= 1.75 and not IsEntityAttachedToAnyPed(v) then
			                playAnim( "missfbi4prepp1","_bag_pickup_garbage_man",48)
			                while GetEntityAnimCurrentTime(GetPlayerPed(-1), "missfbi4prepp1","_bag_pickup_garbage_man") <= 0.95 and IsEntityPlayingAnim(GetPlayerPed(-1), "missfbi4prepp1","_bag_pickup_garbage_man",3) do
			                    Citizen.Wait(0)
			                end
			                   
			                AttachEntityToEntity(v,  GetPlayerPed(-1),  GetPedBoneIndex(GetPlayerPed(-1), 28422), 0.02700003, 0.06399997, 0.3449997, 0.2150002, 2.226021, 0.8569925)
			                atach = true
			                objectAttached = v
							playAnim("missfbi4prepp1","_idle_garbage_man",49)
			                return
						end
					end
				end
			end
		end
	end
end)


function deleteTrash(dict,name,create)
	playAnim(dict,name,48)
	while GetEntityAnimCurrentTime(GetPlayerPed(-1), dict,name) <= 0.95 and IsEntityPlayingAnim(GetPlayerPed(-1), dict,name,3) do
        Citizen.Wait(0)
    end

   local hash = GetEntityModel(objectAttached)

	SetEntityAsMissionEntity(objectAttached,  false,  true)
	for i = #objectTrash, 1,-1 do
  		if objectTrash[i]==objectAttached then
  			table.remove(objectTrash,i)
  			TriggerServerEvent("Garbage:updateObject",vehicleId,objectAttached,"remove")
  		end
  	end

  	DeleteEntity(objectAttached)
  	objectAttached = nil
  	atach = false

  	if create then
 		RequestModel(hash)
	    while not HasModelLoaded(hash) do 
	        Citizen.Wait(1) 
	    end
	    local x,y,z = table.unpack(GetEntityCoords(GetPlayerPed(-1),true))
    	local object = CreateObjectNoOffset(hash,x+1,y,z,true,true,true)
    	PlaceObjectOnGroundProperly(object)
   	 	SetModelAsNoLongerNeeded(hash)
    	SetEntityAsMissionEntity(object)
    	table.insert(objectTrash, object)

    	TriggerServerEvent("Garbage:updateObject",vehicleId,object,"add")
  	end
end

RegisterNetEvent("Garbage:updateObject")
AddEventHandler("Garbage:updateObject",function(object)
	objectTrash = object
end)


function playAnim(dict,name,flag)
	RequestAnimDict(dict)
    while not HasAnimDictLoaded(dict) do
        Citizen.Wait(10)
        RequestAnimDict(dict)
    end
    if HasAnimDictLoaded(dict) then 
        TaskPlayAnim(GetPlayerPed(-1), dict, name, 2.0001, 2.0001, -1, flag, 0, 0, 0, 0) 
    end
end



Citizen.CreateThread(function()
	while true do
		Citizen.Wait(1000)
		if onDuty and vehicleId ~= nil then
			while exports.ft_libs:TableLength(objectTrash) ~= 0 do
			 	Citizen.Wait(100)
			 	exports.ft_libs:TextNotification({ text = "Trash remind : "..exports.ft_libs:TableLength(objectTrash), time = 101})
			end
		end
	end
end)


RegisterNetEvent("Garbage:finish")
AddEventHandler("Garbage:finish",function(truck)
	exports.ft_libs:AddArea("garbage:collectFinish", {
		marker = { type = 1, weight = 2, height = 1, red = 255, green = 255, blue = 153 },
		blip = { text = "Trash", colorId = 18, imageId = 51 },
		trigger = {weight = 5, active= {callback = collectFinish},data = truck},
		locations = {
			route[truck.routeName].finish,
		}
	})
end)


function collectFinish(data)
	local money =  data.trashcollected * (route[data.routeName].moneyPerTrashBag or 1)
	TriggerServerEvent("Garbage:TrashReward",money)
	TriggerServerEvent("Garbage:truckFinish",vehicleId)
	if job == "Driver" or job == "solo" then
		PutVehicle()
	end
end


RegisterNetEvent("Garbage:showTimer")
AddEventHandler("Garbage:showTimer",function(timer)
	local minute = math.floor(timer/60)
	local seconde = math.mod(timer,60)

	exports.ft_libs:TextNotification({ text = "Recolt time : "..minute.." min "..seconde.." s", time = 5000})
end)