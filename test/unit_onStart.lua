local scriptVersion = "2.0"
-------------------------
-- USER DEFINED DATA ----
-------------------------
local damaged_elements_to_check = 100 --export: The number of elements checked in one cycle

local damage_text_color = "#FFC2C2" --export: damage text color for the system screen
local fuel_tank_text_color = "#C2F7FF" --export: fuel tank text color for the system screen
local screen_text_shadow_color = "black" --export: text shadow color for the system screen

local update_time = 1 --export: time in seconds to update data

local pointer_max_distance = 6 --export: distance in meters from element to start pointing
local pointer_fps = 30 --export: pointer movement fps (not more than 30)
local pointer_speed = 2 --export: pointer speed m/s
if pointer_fps > 30 then pointer_fps = 30 end
local pointerUpdateTime = 1 / pointer_fps
local pointerStep = pointer_speed / pointer_fps
local pointerSteps = math.floor(pointer_max_distance / pointerStep)
local stringMax = 1024 --export: max string size to transmit

-------------------------
-- VARIABLES ------------
-------------------------
local tanks = {
	atmo = {},
	space = {},
	rocket = {}
}
local tanksIdToShow = {}

local damaged = {}
local damagedIdToShow = {}
local tempDamaged = {}
local tempDamagedIdToShow = {}

local core = nil
local uidList = {}
local numberIdToCheck = 0
local currentIdToCheck = 0
local damageScreens = {}
local fuelScreens = {}

local elementsToScroll = {}
local activeScrollList = 0

local activeElementId = 0
local pointCounter = 0
local pointTimerIsActive = false
local activatePointTimer = false
local isDamageListComplete = false
local isTransmissionFuelInProgress = false
local isTransmissionDamageInProgress = false

local noDamageFoundText = "NO DAMAGE FOUND"
local damageIndicatorActivatedText = "DAMAGE INDICATOR ACTIVATED"
local noFuelTanksFoundText = "NO FUEL TANKS FOUND"
local fuelTankIndicatorActivatedText ="FUEL TANK INDICATOR ACTIVATED"

-------------------------
-- HTML -----------------
-------------------------
local systemScreenHtmlTemplate = [[<div style="position:absolute;top:10vh;right:5vw;height:5vh;width:90vw;color:%s;text-shadow:0.2vw 0.2vh 1vw %s;font-size:2vh;text-align:center;">%s</div>]]

-------------------------
-- FUNCTIONS ------------
-------------------------
local function initiateSlots()
	for _, slot in pairs(unit) do
		if type(slot) == "table" and type(slot.export) == "table" and slot.getClass then
			local elementClass = slot.getClass():lower()
			if elementClass:find("coreunit") then
				core = slot
				uidList = core.getElementIdList()
				numberIdToCheck = #uidList
			elseif elementClass == "screenunit" then
				if slot.getScriptOutput() == "damage" then
					table.insert(damageScreens,slot)
				elseif slot.getScriptOutput() == "fuel" then
					table.insert(fuelScreens,slot)
				end
				table.insert(screens,slot)
			elseif elementClass == "atmofuelcontainer" then
				table.insert(tanks.atmo,slot)
				table.insert(tanksIdToShow,slot.getLocalId())
			elseif elementClass == "spacefuelcontainer" then
				table.insert(tanks.space,slot)
				table.insert(tanksIdToShow,slot.getLocalId())
			elseif elementClass == "rocketfuelcontainer" then
				table.insert(tanks.rocket,slot)
				table.insert(tanksIdToShow,slot.getLocalId())
			end
		end
	end
	
	if not core then
		error("No core connected!")
	end
	
	--table.sort(screens, function (a, b) return (a.getLocalId() < b.getLocalId()) end)
end

local function setDamagedElements()
	if core then
		local maxId = currentIdToCheck + damaged_elements_to_check
		if maxId > numberIdToCheck then
			maxId = numberIdToCheck
		end
		
		for i = currentIdToCheck, maxId , 1 do
			local uid = uidList[i]
			local maxHitpoints = math.floor(core.getElementMaxHitPointsById(uid)) or 0
			local hitPoints = math.floor(core.getElementHitPointsById(uid)) or 0
			
			if hitPoints < maxHitpoints then
				local element = {}
				element.uid = uid
				element.type = core.getElementDisplayNameById(uid) or "unknown"
				element.name = core.getElementDisplayNameById(uid) or "unknown"
				element.hitPoints = hitPoints
				element.maxHitPoints = maxHitpoints
				element.position = core.getElementPositionById(uid) or 0
				table.insert(tempDamaged,element)
				table.insert(tempDamagedIdToShow,uid)
			end
		end
		
		if maxId == numberIdToCheck then
			damaged = tempDamaged
			damagedIdToShow = tempDamagedIdToShow
			tempDamaged = {}
			tempDamagedIdToShow = {}
			currentIdToCheck = 0
			isDamageListComplete = true
		--elseif #damaged < #tempDamaged then
			--damaged = tempDamaged
			--damagedIdToShow = tempDamagedIdToShow
			--currentIdToCheck = maxId + 1
		else
			currentIdToCheck = maxId + 1
		end
	end
end

local function getDefaultTextAndColor()
	local text = ""
	local textColor = "#000000"
	
	if activeScrollList == 1 then
		if #damagedIdToShow < 1 then
			text = noDamageFoundText
		else
			text = damageIndicatorActivatedText
		end
		textColor = damage_text_color
	elseif activeScrollList == 2 then
		if #tanksIdToShow < 1 then
			text = noFuelTanksFoundText
		else
			text = fuelTankIndicatorActivatedText
		end
		textColor = fuel_tank_text_color
	end
	
	return text, textColor
end

local function setScreenTextHtml(text,textColor)
	system.setScreen(string.format(systemScreenHtmlTemplate,textColor,screen_text_shadow_color,text))
end

local function messageToShow(elementId)
	if elementId > 0 and #elementsToScroll > 0 then
		local uid = elementsToScroll[elementId]
		
		if not uid then
			activeElementId = 1
			uid = elementsToScroll[activeElementId]
		end
		
		local _, textColor = getDefaultTextAndColor()	
		local text = [[SELECTED: №]]
			..uid..[[ | ]]
			..core.getElementDisplayNameById(uid)..[[ | ]]
			..core.getElementDisplayNameById(uid)
		setScreenTextHtml(text,textColor)
	else
		local text, textColor = getDefaultTextAndColor()
		setScreenTextHtml(text,textColor)
	end
end

local function sendToScreens(screens,stringData)
	for _, screen in ipairs(screens) do
		screen.setScriptInput(stringData)
	end
end

local function setProcessing()
	local stringToSend = "processing"
	sendToScreens(damageScreens,stringToSend)
	sendToScreens(fuelScreens,stringToSend)
end

function changeElementsToScroll()
	activeElementId = 0
	
	if activeScrollList == 0 then
		elementsToScroll = damagedIdToShow
		activeScrollList = 1
	elseif activeScrollList == 1 then
		elementsToScroll = tanksIdToShow
		activeScrollList = 2
	else
		elementsToScroll = {}
		activeScrollList = 0
	end
	
	local text, textColor = getDefaultTextAndColor()
	setScreenTextHtml(text,textColor)
end

function activeElementIdUp()
	if #elementsToScroll > 0 then
		activatePointTimer = true
		activeElementId = activeElementId + 1
		if activeElementId > #elementsToScroll then
			activeElementId = 0
			activatePointTimer = false
		end
		messageToShow(activeElementId)
		pointCounter = 0
	else
		messageToShow(0)
	end
end

function activeElementIdDown()
	if #elementsToScroll > 0 then
		activatePointTimer = true
		activeElementId = activeElementId - 1
		if activeElementId == 0 then
			activatePointTimer = false
		elseif activeElementId < 0 then
			activeElementId = #elementsToScroll
		end
		messageToShow(activeElementId)
		pointCounter = 0
	else
		messageToShow(0)
	end
end

local function getFuelTanksString()
	if #fuelScreens > 0 then
		local dataStringRows = {}
		for tankType, subTanks in pairs(tanks) do
			for key, tank in ipairs(subTanks) do
				local data = json.decode(tank.getWidgetData())
				local objectToRecord = {}
				objectToRecord[1] = tank.getLocalId()
				objectToRecord[2] = tankType
				objectToRecord[3] = data.name
				objectToRecord[4] = data.percentage
				table.insert(dataStringRows,table.concat(objectToRecord,","))
			end
		end
		
		return table.concat(dataStringRows,";")
	end
end

local function getDamagedElementsString()
	if #damageScreens > 0 then
		local dataStringRows = {}
		for _, element in ipairs(damaged) do
			local data = json.decode(tank.getWidgetData())
			local objectToRecord = {}
			objectToRecord[1] = element.uid
			objectToRecord[2] = element.type
			objectToRecord[3] = element.name
			objectToRecord[4] = element.hitPoints
			objectToRecord[5] = element.maxHitPoints
			table.insert(dataStringRows,table.concat(objectToRecord,","))
		end
		
		return table.concat(dataStringRows,";")
	end
end


-------------------------
-- UPDATE FUNCTION ------
-------------------------
function update()
	-- pointing the element
	if not pointTimerIsActive and activatePointTimer then
		unit.setTimer("point", pointerUpdateTime)
		pointTimerIsActive = true
	end
	
	-- fuel tanks section
	if not isTransmissionFuelInProgress then
		-- start transmission
		fuelTransmission(getFuelTanksString())
	end
	
	-- damage elements section	
	if not isTransmissionDamageInProgress then
		if not isDamageListComplete then
			setDamagedElements()
		else
			-- start transmission
			damageTransmission(getDamagedElementsString())
		end
	end
end

function fuelTransmission(dataString)
	if not isTransmissionFuelInProgress then
		if dataString and dataString ~= "" then
			stringFuelToTransmit = startPattern .. dataString .. stopPattern
			--system.print("stringFuelToTransmit = "..stringFuelToTransmit)
			isTransmissionFuelInProgress = true
			unit.setTimer("transmit_fuel", 0.05)
			return
		end
	end
	
	if #stringFuelToTransmit > stringMax then
		local stringPart = string.sub(stringFuelToTransmit,1,stringMax)
		sendToScreens(fuelScreens,stringPart)
		stringFuelToTransmit = string.sub(stringFuelToTransmit,stringMax+1)
	else
		sendToScreens(fuelScreens,stringFuelToTransmit)
		isTransmissionFuelInProgress = false
		unit.stopTimer("transmit_fuel")
		--system.print("fuel transmission complete")
	end
end

function damageTransmission(dataString)
	if not isTransmissionDamageInProgress then
		if dataString and dataString ~= "" then
			stringDamageToTransmit = startPattern .. dataString .. stopPattern
			--system.print("stringDamageToTransmit = "..stringDamageToTransmit)
			isTransmissionDamageInProgress = true
			unit.setTimer("transmit_fuel", 0.05)
			return
		end
	end
	
	if #stringDamageToTransmit > stringMax then
		local stringPart = string.sub(stringDamageToTransmit,1,stringMax)
		sendToScreens(damageScreens,stringPart)
		stringDamageToTransmit = string.sub(stringDamageToTransmit,stringMax+1)
	else
		sendToScreens(damageScreens,stringDamageToTransmit)
		isTransmissionDamageInProgress = false
		unit.stopTimer("transmit_fuel")
		--system.print("fuel transmission complete")
	end
end

-------------------------
-- POINTER FUNCTION -----
-------------------------
function pointElement()
	if #elementsToScroll > 0 and activeElementId > 0 then
		local uid = elementsToScroll[activeElementId]
		
		if not uid then
			activeElementId = 1
			uid = elementsToScroll[activeElementId]
			messageToShow(activeElementId)
		end
		
		local position = core.getElementPositionById(elementsToScroll[activeElementId])
		local x = position[1]
		local y = position[2]
		local z = position[3]
		local arrowShift = pointerStep * (pointerSteps - pointCounter)
		
		if not arrowId then
			arrowId = {
				up = core.spawnArrowSticker(0,0,0,"up"),
				down = core.spawnArrowSticker(0,0,0,"down"),
				north = core.spawnArrowSticker(0,0,0,"north"),
				south = core.spawnArrowSticker(0,0,0,"south"),
				east = core.spawnArrowSticker(0,0,0,"east"),
				west = core.spawnArrowSticker(0,0,0,"west")
			}				
		end
		
		core.moveSticker(arrowId.up,x,y,z - arrowShift)
		core.moveSticker(arrowId.down,x,y,z + arrowShift)
		core.moveSticker(arrowId.north,x + arrowShift,y,z)
		core.moveSticker(arrowId.south,x - arrowShift,y,z)
		core.moveSticker(arrowId.east,x,y - arrowShift,z)
		core.moveSticker(arrowId.west,x,y + arrowShift,z)
		
		pointCounter = pointCounter + 1
		if pointCounter > pointerSteps then pointCounter = 0 end
	else
		if arrowId then
			for _, id in pairs(arrowId) do
				core.deleteSticker(id)
			end
			arrowId = nil
		end
		pointCounter = 0
		unit.stopTimer("point")
		activatePointTimer = false
		pointTimerIsActive = false
		messageToShow(0)
	end
end

------------------------------
-- STOP FUNCTION -------------
------------------------------
function stop()
	local stringToSend = "stopped"
	sendToScreens(damageScreens,stringToSend)
	sendToScreens(fuelScreens,stringToSend)
	
	system.setScreen("")
	system.showScreen(0)
end

------------------------------------
-- START CODE ----------------------
------------------------------------
initiateSlots()
setProcessing()
system.showScreen(1)

------------------------------
-- UPDATE REFRESH TIMER ------
------------------------------
unit.setTimer("update", update_time)
