local scriptVersion = "1.2"
-------------------------
-- USER DEFINED DATA ----
-------------------------
local fuel_screen_number = 1 --export: Found screen number, 1 or 2
local damage_screen_number = 2 --export: Found screen number, 1 or 2
if fuel_screen_number > damage_screen_number then
	fuel_screen_number = 2
	damage_screen_number = 1
else
	fuel_screen_number = 1
	damage_screen_number = 2
end
local damaged_elements_to_check = 100 --export: The number of elements checked in one cycle
local atmo_color = "blue" --export: color for atmo tanks
local space_color = "yellow" --export: color for space tanks
local rocket_color = "pink" --export: color for rocket tanks
local tankColors = {
	atmo = atmo_color,
	space = space_color,
	rocket = rocket_color
}
local font_size = 4 --export: font size for the table
local font_color = "black" --export: font color for the table
local screen_color = "#979A9A" --export: screen background color
local no_damage_color = "green" --export: "No Damage" text color
local progress_color = "#FF8B00" --export: "Progress..." text color
local damage_text_color = "#FFC2C2" --export: damage text color for the system screen
local fuel_tank_text_color = "#C2F7FF" --export: fuel tank text color for the system screen
local screen_text_shadow_color = "black" --export: text shadow color for the system screen
local table_border_color = "black" --export: table border color
local header_background_color = "#959595" --export: table header background color
local header_text_color = "white" --export: table header text color
local row_color_1 = "#ECF0F1" --export: table even line background color
local row_color_2 = "#D0D3D4" --export: table odd line background color
local update_time = 1 --export: time in seconds to update data
local indicator_color = "#229954" --export: indicator color
local pointer_max_distance = 6 --export: distance in meters from element to start pointing
local pointer_fps = 30 --export: pointer movement fps (not more than 30)
local pointer_speed = 2 --export: pointer speed m/s
if pointer_fps > 30 then pointer_fps = 30 end
local pointerUpdateTime = 1 / pointer_fps
local pointerStep = pointer_speed / pointer_fps
local pointerSteps = math.floor(pointer_max_distance / pointerStep)
local show_sketch = false --export: show experimental sketch of the ship
local show_healthy_elements = true --export: show healthy elements on the sketch of the ship
local element_sketch_color_healthy = "black" --export
local element_sketch_color_damaged = "red" --export
local top_view_scale = 1 --export: custom scale for the sketch view
local top_view_x_shift = 0 --export: custom shift for the sketch view
local top_view_y_shift = 0 --export: custom shift for the sketch view
local side_view_scale = 1 --export: custom scale for the sketch view
local side_view_x_shift = 0 --export: custom shift for the sketch view
local side_view_y_shift = 0 --export: custom shift for the sketch view
local front_view_scale = 1 --export: custom scale for the sketch view
local front_view_x_shift = 0 --export: custom shift for the sketch view
local front_view_y_shift = 0 --export: custom shift for the sketch view
local custom_ship_svg = "<svg> </svg>" --export: svg for the custom ship to show, this code must be enveloped to the <svg> tag and contain all three planes

-------------------------
-- VARIABLES ------------
-------------------------
local indicatorColorCurrent = indicator_color

local sketchScreenId = 0
local damageTableScreenId = 0
local customShipScreenId = 0

local elementsList = {}

local tanks = {
	atmo = {},
	space = {},
	rocket = {}
}
local tanksIdToShow = {}

local damaged = {} -- store hitPoints only
local damagedIdToShow = {}
local tempDamaged = {}
local tempDamagedIdToShow = {}

local core = nil
local uidList = {}
local numberIdToCheck = 0
local currentIdToCheck = 1
local screens = {}

local elementsToScroll = {}
local activeScrollList = 0

local activeElementId = 0
local pointCounter = 0
local pointTimerIsActive = false
local activatePointTimer = false

local htmlIndicator = ""

-------------------------
-- HTML -----------------
-------------------------
local htmlStyle = [[<style>
	div.screen {
		background-color:]]..screen_color..[[;
		width:100vw;
		height:100vh;
	}
	
	table {
		table-layout:fixed;
		font-family:"Lucinda Sans";
		position:absolute;
		font-size:]]..font_size..[[vh;
		background-color:]]..screen_color..[[;
		border-collapse:collapse;
		margin:0px auto;
		color:]]..font_color..[[;
		width:90vw;
		left:5vw;
		top:5vh;
	}
	
	table.small {
		font-size:]]..font_size/2 ..[[vh;
		width:45vw;
	}
	
	th {
		background-color:]]..header_background_color..[[;
		color:]]..header_text_color..[[;
	}
	
	td.cell {
		font-family:"Lucinda Sans";
		color:]]..font_color..[[;
	}
	
	th, td {
		border:thin solid ]]..table_border_color..[[;
	}
	
	tbody {
		background-color:]]..row_color_1..[[;
	}
	
	tbody.zebra tr:nth-child(even) {
		background-color:]]..row_color_2..[[;
	}
	
	div.indicator {
		position:absolute;
		top:0;
		left:0;
		width:2vw;
		height:5vh;
	}
	
	div.message {
		position:absolute;
		font-family:"Lucinda Sans";
		top:40vh;
		height:20vh;
		width:90vw;
		font-size:10vh;
		text-align:center;
	}
</style>
<div class="screen"></div>
]]

local htmlNoDamage = [[<div class="message" style="color:]]..no_damage_color..[[;">No Damage Found</div>]]
local htmlProcessing = [[<div class="message" style="color:]]..progress_color..[[;">Processing...</div>]]

local helpInfo = [[<table>
	<tr>
		<th colspan="2">Script v.]]..scriptVersion..[[ stopped</th>
	</tr>
	<tr>
		<td class='cell'>Alt+1</td>
		<td class='cell'>Selector:<br>0 - nothing<br>1 - indicate damaged elements<br>2 - indicate fuel tanks</td>
	</tr>
	<tr>
		<td class='cell'>Alt+2</td>
		<td class='cell'>Select the next element to indicate</td>
	</tr>
	<tr>
		<td class='cell'>Alt+3</td>
		<td class='cell'>Select the previous element to indicate</td>
	</tr>
	<tr>
		<td class='cell'>Alt+9</td>
		<td class='cell'>Stop script</td>
	</tr>
</table>]]

local noDamageFoundText = "NO DAMAGE FOUND"
local damageIndicatorActivatedText = "DAMAGE INDICATOR ACTIVATED"
local noFuelTanksFoundText = "NO FUEL TANKS FOUND"
local fuelTankIndicatorActivatedText ="FUEL TANK INDICATOR ACTIVATED"

local minimizeTableHtml = ""
local minimizeRatio = 1
if show_sketch then
	minimizeTableHtml = " class='small'"
	minimizeRatio = 2
end
local damageTableTemplate = "<table"..minimizeTableHtml.."><tr><th style='width:".. 10/minimizeRatio.."vw'>id</th><th style='width:".. 20/minimizeRatio.."vw'>type</th><th style='width:".. 30/minimizeRatio.."vw'>name</th><th style='width:".. 10/minimizeRatio.."vw'>hp</th><th style='width:".. 10/minimizeRatio.."vw'>max hp</th><th>%%</th></tr><tbody class='zebra'>%s</tbody></table></div>"
local damageRowTemplate = "<tr><td class='cell'>%d</td><td class='cell'>%s</td><td class='cell'>%s</td><td class='cell'>%d</td><td class='cell'>%d</td><td class='cell'>%.1f</td></tr>"

local fuelTanksTableTemplate = "<table><tr><th style='width:10vw'>code</th><th style='width:10vw'>id</th><th style='width:60vw'>name</th><th>%%</th></tr><tbody>%s</tbody></table>"
local fuelTanksRowTemplate = "<tr><td class='cell' style='background-color:%s;'></td><td class='cell'>%d</td><td class='cell'>%s</td><td class='cell'>%d</td></tr>"

local systemScreenHtmlTemplate = [[<div style="position:absolute;top:10vh;right:5vw;height:5vh;width:90vw;color:%s;text-shadow:0.2vw 0.2vh 1vw %s;font-size:2vh;text-align:center;">%s</div>]]

local circleSvgTemplate = [[<circle cx="%.2f" cy="%.2f" r="%.2f" stroke="%s" stroke-width="$.4f" fill="%s"/>]]
local rectangleSvgTemplate = [[<rect x="%.2f" y="%.2f" width="%.2f" height="%.2f" stroke="%s" stroke-width="$.4f" fill="%s"/>]]
local groupSvgTemplate = [[<g transform="scale(%.2f) translate(%.2f %.2f)">%s</g>]]
local coreOffset = 0
local svgTemplate = [[<svg viewBox="0 0 %d %d" style="width:100vw;height:100vh;">%s</svg>]]


-------------------------
-- FUNCTIONS ------------
-------------------------
local function initiateSlots()
	for _, slot in pairs(unit) do
		if type(slot) == "table" and type(slot.export) == "table" and slot.getElementClass then
			local elementClass = slot.getElementClass():lower()
			if elementClass:find("coreunit") then
				core = slot
				local coreHP = core.getMaxHitPoints()
				if coreHP > 10000 then
					coreOffset = 128
				elseif coreHP > 1000 then
					coreOffset = 64
				elseif coreHP > 150 then
					coreOffset = 32
				else
					coreOffset = 16
				end
				uidList = core.getElementIdList()
				numberIdToCheck = #uidList
			elseif elementClass == "screenunit" then
				table.insert(screens,slot)
			elseif elementClass == "atmofuelcontainer" then
				table.insert(tanks.atmo,slot)
				table.insert(tanksIdToShow,slot.getId())
			elseif elementClass == "spacefuelcontainer" then
				table.insert(tanks.space,slot)
				table.insert(tanksIdToShow,slot.getId())
			elseif elementClass == "rocketfuelcontainer" then
				table.insert(tanks.rocket,slot)
				table.insert(tanksIdToShow,slot.getId())
			end
		end
	end
	
	if #screens > 1 then
		local screenId1 = screens[1].getId()
		local screenId2 = screens[2].getId()
		if screenId1 > screenId2 then
			local temp = fuel_screen_number
			fuel_screen_number = damage_screen_number
			damage_screen_number = temp
		end
	end
	
end

local function setElementsList()
	if #uidList > 0 then
		for _, uid in ipairs(uidList) do
			local element = {
				type = core.getElementTypeById(uid),
				name = core.getElementNameById(uid),
				position = core.getElementPositionById(uid),
				maxHitPoints = math.floor(core.getElementMaxHitPointsById(uid)) or 0,
				shape = "circle",
				size = 0.2
			}
			elementsList[uid] = element
		end
	end
end

local function getElementSvg(plane,shape,position,size,isDamaged)
	local x = 0
	local y = 0
	if plane == "top" then
		x = position[2] - coreOffset
		y = position[1] - coreOffset
	elseif plane == "side" then
		x = position[2] - coreOffset
		y = coreOffset - position[3]
	elseif plane == "front" then
		x = position[1] - coreOffset
		y = coreOffset - position[3]
	else
		return ""
	end
	
	local color = element_sketch_color_healthy
	if isDamaged then color = element_sketch_color_damaged end
	
	if shape == "circle" then
		-- x,y,r,srtoke,stroke-width,fill
		return string.format(circleSvgTemplate,x,y,size/2,0,color)
	elseif shape == "rectangle" then
		-- x,y,width,height,stroke,stroke-width,fill
		return string.format(rectangleSvgTemplate,x-size/2,y-size/2,size,size,color,0,color)
	else
		return ""
	end
end

local function displaySketch()
	if #uidList > 0 and screens[damage_screen_number] then
		
		local svgHealthyElements = {
			top = {},
			side = {},
			front = {}
		}
		local svgDamagedElements = {
			top = {},
			side = {},
			front = {}
		}
		
		for _, uid in ipairs(uidList) do
			local color = element_sketch_color_healthy
			local element = elementsList[uid]
			
			if damaged[uid] then
				table.insert(svgDamagedElements.top,getElementSvg("top",element.shape,element.position,element.size,true))
				table.insert(svgDamagedElements.side,getElementSvg("side",element.shape,element.position,element.size,true))
				table.insert(svgDamagedElements.front,getElementSvg("front",element.shape,element.position,element.size,true))				
			elseif show_healthy_elements then
				table.insert(svgHealthyElements.top,getElementSvg("top",element.shape,element.position,element.size,false))
				table.insert(svgHealthyElements.side,getElementSvg("side",element.shape,element.position,element.size,false))
				table.insert(svgHealthyElements.front,getElementSvg("front",element.shape,element.position,element.size,false))				
			end
		end
			
		local svgTop = string.format(groupSvgTemplate,top_view_scale,coreOffset+top_view_x_shift,coreOffset*3+top_view_y_shift,table.concat(svgHealthyElements.top)..table.concat(svgDamagedElements.top))
		local svgSide = string.format(groupSvgTemplate,side_view_scale,coreOffset*3+side_view_x_shift,coreOffset*3+side_view_y_shift,table.concat(svgHealthyElements.side)..table.concat(svgDamagedElements.side))
		local svgFront = string.format(groupSvgTemplate,front_view_scale,coreOffset*3+front_view_x_shift,coreOffset+front_view_y_shift,table.concat(svgHealthyElements.front)..table.concat(svgDamagedElements.front))

		local svg = string.format(svgTemplate,coreOffset*4,coreOffset*4,svgTop..svgSide..svgFront)
		
		if customShipScreenId == 0 then
			customShipScreenId = screens[damage_screen_number].addContent(0,0,custom_ship_svg)
		end
		
		if sketchScreenId == 0 then
			sketchScreenId = screens[damage_screen_number].addContent(0,0,svg)
		else
			screens[damage_screen_number].resetContent(sketchScreenId,svg)
		end
	end
end

local function setDamagedElements()
	if core then
		local maxId = currentIdToCheck + damaged_elements_to_check
		if maxId > numberIdToCheck then
			maxId = numberIdToCheck
		end
		
		for i = currentIdToCheck, maxId , 1 do
			local uid = uidList[i]
			local maxHitPoints = elementsList[uid].maxHitPoints
			local hitPoints = math.floor(core.getElementHitPointsById(uid)) or 0
			
			if hitPoints < maxHitPoints then
				tempDamaged[uid] = hitPoints
				table.insert(tempDamagedIdToShow,uid)
			end
		end
		
		if maxId == numberIdToCheck then
			damaged = tempDamaged
			damagedIdToShow = tempDamagedIdToShow
			tempDamaged = {}
			tempDamagedIdToShow = {}
			currentIdToCheck = 1
		elseif #damagedIdToShow < #tempDamagedIdToShow then
			damaged = tempDamaged
			damagedIdToShow = tempDamagedIdToShow
			currentIdToCheck = maxId + 1
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
			..core.getElementTypeById(uid)..[[ | ]]
			..core.getElementNameById(uid)
		setScreenTextHtml(text,textColor)
	else
		local text, textColor = getDefaultTextAndColor()
		setScreenTextHtml(text,textColor)
	end
end

local function setProcessing()
	for _, screen in ipairs(screens) do
		screen.setHTML(htmlStyle..htmlProcessing)
	end
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

local function displayFuelTanks()
	if screens[fuel_screen_number] then
		local messageRows = {}
		for tankType, subTanks in pairs(tanks) do
			for key, tank in ipairs(subTanks) do
				 local data = json.decode(tank.getData()) 
				 --table.insert(messageRows,string.format(fuelTanksRowTemplate,tankColors[tankType],tank.getId(),data.name,data.percentage))
				 table.insert(messageRows,"<tr><td class='cell' style='background-color:"..tankColors[tankType].."'></td><td class='cell'>"..tank.getId().."</td><td class='cell'>"..data.name.."</td><td class='cell'>"..data.percentage.."%</td></tr>")
			end
		end
		local html = string.format(fuelTanksTableTemplate,table.concat(messageRows))
		screens[fuel_screen_number].setHTML(htmlStyle..html..htmlIndicator)
	end
end

local function displayDamagedElements()
	if screens[damage_screen_number] then
		if #damagedIdToShow < 1 then
			screens[damage_screen_number].setHTML(htmlStyle..htmlNoDamage..htmlIndicator)
		else
			local messageRows = {}
			for _, uid in pairs(damagedIdToShow) do
				local element = elementsList[uid]
				local hitPoints = damaged[uid]
				table.insert(messageRows, string.format(damageRowTemplate, uid, element.type, element.name,hitPoints,element.maxHitPoints,math.floor(1000*hitPoints/element.maxHitPoints)/10))
			end
			
			local rows = 10
			if rows > #damagedIdToShow then rows = #damagedIdToShow end
			local html = string.format(damageTableTemplate,table.concat(messageRows,"",1,rows))
			
			if damageTableScreenId == 0 then
				damageTableScreenId = screens[damage_screen_number].addContent(0,0,htmlStyle..html..htmlIndicator)
			else
				screens[damage_screen_number].resetContent(damageTableScreenId,htmlStyle..html..htmlIndicator)
			end
		end
	end
end

-------------------------
-- UPDATE FUNCTION ------
-------------------------
function update()
	if indicatorColorCurrent == indicator_color then indicatorColorCurrent = screen_color else indicatorColorCurrent = indicator_color end
	htmlIndicator = [[<div class="indicator" style="background-color:]]..indicatorColorCurrent..[[;"></div>]]
	
	displayFuelTanks()
	
	setDamagedElements()
	displayDamagedElements()
	if show_sketch then
		displaySketch()
	end
	
	if not pointTimerIsActive and activatePointTimer then
		unit.setTimer("point", pointerUpdateTime)
		pointTimerIsActive = true
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
		--local position = elementsList[elementsToScroll[activeElementId]]
		local x = position[1] - coreOffset
		local y = position[2] - coreOffset
		local z = position[3] - coreOffset
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
	for _, screen in ipairs(screens) do
		screen.setHTML(htmlStyle..helpInfo)
	end
	system.setScreen("")
	system.showScreen(0)
end

------------------------------------
-- START CODE ----------------------
------------------------------------
initiateSlots()
setElementsList()
setProcessing()
system.showScreen(1)

------------------------------
-- UPDATE REFRESH TIMER ------
------------------------------
unit.setTimer("update", update_time)



-------------------------
-- FILTER UPDATE --------
-------------------------
update()

-------------------------
-- FILTER POINT ---------
-------------------------
pointElement()

-------------------------
-- STOP -----------------
-------------------------
stop()

-------------------------
-- Alt+1 ----------------
-------------------------
changeElementsToScroll()

-------------------------
-- Alt+2 ----------------
-------------------------
activeElementIdUp()

-------------------------
-- Alt+3 ----------------
-------------------------
activeElementIdDown()

-------------------------
-- Alt+9 ----------------
-------------------------
unit.exit()
