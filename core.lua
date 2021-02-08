-- ### CONFIG VALUES:
local showPlayers = true -- If enemy players should be included.
local anchorPoint = "LEFT" -- Anchor point for aura:
--TOP, BOTTOM, LEFT, RIGHT, CENTER, TOPLEFT, TOPRIGHT, BOTTOMLEFT, BOTTOMRIGHT.
local relativeAnchor = "CENTER" -- Nameplate anchorpoint:
--TOP, BOTTOM, LEFT, RIGHT, CENTER, TOPLEFT, TOPRIGHT, BOTTOMLEFT, BOTTOMRIGHT.
local xOffset = 100
local yOffset = 0
local borderSize = 1 -- Thickness of border. NB! Setting to 0 will break it. Looks best at 1.
local growthDirection = "RIGHT" -- Direction new auras are added: UP, DOWN, LEFT, RIGHT.
local growEvenly = false -- Grow centered on your anchor point (should only be used for top/bottom anchor).
local auraWidth = 24 -- Width of each aura.
local auraHeight = 24 -- Height of each aura.
local showGlow = true -- Show autocast shine on dispellable auras.
local showExplosive = true -- If you want an icon with countdown for explosive casts (x2 normal size).
local showBE = true -- Show dispellable magic buffs for Blood Elves.
local showBECD = true -- Blood Elves only see buffs when their racial is usable (does not affect classes that can dispel more frequently).

local whitelist = { -- Enable certain buffs to show regardless of being purgable
	[209859] = true, -- Bolstering
	[343502] = true, -- Inspiring (New affix in Shadowlands)
	[226510]= true, -- Sanguine Ichor (M+ Affix heal on mobs)
	[299150] = true, -- Unnatural Power (Elite stacking buff in Torghast)
}
local blacklist = { -- Disable certain buffs
	[21562] = true, -- Power Word: Fortitude
	[1459] = true, -- Arcane Intellect
}

-- ###########################################
--     DONT TOUCH ANYTHING BELOW THIS LINE
-- ###########################################
ES_DispelEnemyBuff = LibStub("AceAddon-3.0"):NewAddon("ES_DispelEnemyBuff", "AceEvent-3.0")

local UIscale = UIParent:GetEffectiveScale()
xOffset = xOffset * UIscale
yOffset = yOffset * UIscale
auraWidth = auraWidth * UIscale
auraHeight = auraHeight * UIscale
local cWidth = auraWidth + 1 + borderSize
local cHeight = auraHeight + 1 + borderSize
local name, addon = ...
local framePool = {}
local auraPool = {}
local canPurge = "none"
local numFrames = 0
local tarNPname
local _, _, rID = UnitRace("player")
local _, _, cID = UnitClass("player")
local racialID = {
	[1] = 69179,
	[2] = 155145,
	[3] = 80483,
	[4] = 25046,
	[5] = 232633,
	[6] = 50613,
	[8] = 28730,
	[9] = 28730,
	[10] = 129597,
	[12] = 202719
}
local backdrop = {
    edgeFile = "Interface\\AddOns\\\ES_DispelEnemyBuff\\backdrop.tga",
    edgeSize = borderSize,
    insets = {left = 0, right = 0, top = 0, bottom = 0,}
}

local function getFrame()
	for _,frame in pairs(framePool) do
		if not frame.show then
			frame.show = true
			return frame
		end
	end
	numFrames = numFrames + 1
	local frame = CreateFrame("Frame", nil)
	frame:SetFrameLevel(1)
	frame:SetWidth(auraWidth)
	frame:SetHeight(auraHeight)
	frame:SetFrameStrata("BACKGROUND")
	frame.txt = frame:CreateFontString(nil)
	frame.txt:SetFont("Fonts\\FRIZQT__.TTF", auraWidth/1.5, "OUTLINE")
	frame.txt:SetPoint("CENTER", frame, "TOP", 0, 0)
	frame.txt:SetTextColor(1,0,1,1)
	frame.icon = frame:CreateTexture(nil)
	frame.icon:SetAllPoints(frame)
	frame.Backdrop = CreateFrame("Frame", nil, frame, BackdropTemplateMixin and "BackdropTemplate");
	frame.Backdrop:SetBackdrop(backdrop)
	frame.Backdrop:SetBackdropColor(0,0,0,0)
	frame.Backdrop:SetFrameLevel(0)
	frame.Backdrop:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", -borderSize, -borderSize)
	frame.Backdrop:SetPoint("TOPRIGHT", frame, "TOPRIGHT", borderSize, borderSize)
	frame.shine = CreateFrame("Frame", "ES_DEB_shine"..numFrames, frame, "AutoCastShineTemplate")
	frame.shine:SetAllPoints(frame.Backdrop)
	frame.shine:Hide()
	frame.cd = CreateFrame("Cooldown",nil, frame, "CooldownFrameTemplate")
	frame.cd:SetAlpha(0)
	frame.cd:SetAllPoints(frame)
	frame.cd:SetDrawEdge(false)
	frame.show = true
	tinsert(framePool,frame)
	return frame
end

local function ForceGenerate()
	for i=1,50,1 do
		local f = getFrame()
	end
	for _,frame in pairs(framePool) do
		if frame.show then
			frame.plate = nil
			frame.show = false
			frame.unit = nil
			frame:Hide()
		end
	end
end

local function cSteal(spellId, isStealable)
	if whitelist[spellId] then
        return false
    else
        return isStealable
    end
end

local growthDirectionValues = {
    ["UP"] = {xDir =  0, yDir =  1},
    ["DOWN"] = {xDir =  0, yDir = -1},
    ["LEFT"] = {xDir = -1, yDir =  0},
    ["RIGHT"] = {xDir =  1, yDir =  0},
}

local color_enrage = {red = 0.85, green = 0.2, blue = 0.1,}
local color_explo = {red = 0.85, green = 0.85, blue = 0.1,}

local function HideFrame(unit)
	local lUnit = false
	if (unit == "target") then
		lUnit = tarNPname
	elseif C_NamePlate.GetNamePlateForUnit(unit) then
		lUnit = C_NamePlate.GetNamePlateForUnit(unit):GetName()
	end
	
	if lUnit then
		auraPool[lUnit] = nil
		auraPool[lUnit] = {}
		for _,frame in pairs(framePool) do
			if (frame.plate == lUnit) then
				frame.plate = nil
				frame.show = false
				frame.unit = nil
				AutoCastShine_AutoCastStop(frame.shine)
				frame.shine:Hide()
				frame.cd:Clear()
				frame:Hide()
			end
		end
	else
		for _,frame in pairs(framePool) do
			if (frame.show) and (frame.unit == unit) then
				frame.plate = nil
				frame.show = false
				frame.unit = nil
				AutoCastShine_AutoCastStop(frame.shine)
				frame.shine:Hide()
				frame.cd:Clear()
				frame:Hide()
			end
		end
	end
	auraPool[unit] = nil
	auraPool[unit] = {}
end

local function UpdateNameplate(unit)
	local parent = C_NamePlate.GetNamePlateForUnit(unit)
	if not parent then
		HideFrame(unit)
		return
	end
	local aura_number = 0
	if GetRaidTargetIndex(unit) then
		aura_number = 1
	end
	local num_auras = 0
	if growEvenly then
		for k,v in pairs(auraPool[unit]) do
			num_auras = num_auras + 1
		end
	end
	for _, state in pairs(auraPool[unit]) do
		aura_number = aura_number+ 1
		local frame = getFrame()
		local red = DebuffTypeColor["none"].r
		local green = DebuffTypeColor["none"].g
		local blue = DebuffTypeColor["none"].b
		local type = state.aura_type
		
		if type == "" then
			red = color_enrage.red
			green = color_enrage.green
			blue = color_enrage.blue
		elseif type == "Expl" then
			red = color_explo.red
			green = color_explo.green
			blue = color_explo.blue
		elseif not state.isStealable then
			red = DebuffTypeColor["none"].r
			green = DebuffTypeColor["none"].g
			blue = DebuffTypeColor["none"].b
		elseif type then
			red = DebuffTypeColor[type].r
			green = DebuffTypeColor[type].g
			blue = DebuffTypeColor[type].b
		end
		
		if state.spellId == 240446 then
			frame:SetWidth(auraWidth * 2)
			frame:SetHeight(auraHeight * 2)
		else
			frame:SetWidth(auraWidth)
			frame:SetHeight(auraHeight)
		end
		
		frame.plate = parent:GetName()
		frame.unit = unit
		frame.Backdrop:SetBackdropBorderColor(red,green,blue,1)
			
		local xOffset1 = xOffset+cWidth*(aura_number-1)*growthDirectionValues[growthDirection].xDir
		local yOffset1 = yOffset+cHeight*(aura_number-1)*growthDirectionValues[growthDirection].yDir
		
		if growEvenly then 
			xOffset1 = xOffset-cWidth*((num_auras or 1)-1)/2*growthDirectionValues[growthDirection].xDir
			yOffset1 = yOffset-cHeight*((num_auras or 1)-1)/2*growthDirectionValues[growthDirection].yDir
		end
		
		frame:ClearAllPoints()
		frame:SetPoint(anchorPoint, parent, relativeAnchor, xOffset1, yOffset1)
		local expire = 0
		local dur = 0
		if state.duration then dur = state.duration end
		if state.expirationTime then expire = GetTime() - (dur - (state.expirationTime - GetTime())) end
		frame.cd:SetCooldown(expire, dur)
		frame.icon:SetTexture(state.icon)
		frame.icon:SetTexCoord(.15, .85, .15, .85)
		local stacks = ""
		if state.stacks >= 2 then stacks = state.stacks end
		frame.txt:SetText(stacks)
		if showGlow and state.isStealable then
			AutoCastShine_AutoCastStart(frame.shine, red, green, blue)
			frame.shine:Show()
		end
		frame:Show()
	end    
end

local function NEAisShowBuff(state)
    if not state.show then return end
    local isPlayer = UnitIsPlayer(state.unit)
    local canAttack = UnitCanAttack("player", state.unit);
    local inInstance, instanceType = IsInInstance()
    local showAura = (not isPlayer or showPlayers) or (inInstance and canAttack and instanceType == "party")
    local type = state.type
    if showAura then
        state.aura_type = type
        return true
    end
    return false
end

local function rBelf(dbType)
	if not (dbType == "Magic") then return false end
	if showBE and (rID == 10) then
		if not showBECD then
			return true
		else
			local onCD, CDdur = GetSpellCooldown(racialID[cID])
			local _, GCDdur = GetSpellCooldown(61304)
			local CDfin = CDdur - GCDdur
			if (onCD ~= 0) and (CDfin > 0) then
				return false
			else
				return true
			end
		end
	else
		return false
	end
end

local function ES_CheckAura(unit)
	local locstates = {}
    local bolster = 0
	local numAuras = 0
	
	if showExplosive and UnitName(unit) and (UnitName(unit) == "Explosives") then
			numAuras = 1
			state = {
				show = true,
				spellId = 240446,
				unit = unit,
				duration = 6,
				expirationTime = GetTime() + 6,
				icon = 2175503,
				plate = C_NamePlate.GetNamePlateForUnit(unit),
				stacks = 0,
				type = "Expl",
				cloneId = unit.."-"..240446,
				isStealable = true,
			}
			if NEAisShowBuff(state) then
				table.insert(locstates, state)
			end
	else
		for i = 1, 255 do
			local name, icon, count, dType, duration, expirationTime, _, isStealable, _, spellId = UnitBuff(unit, i)
			if not name then break end
			local state = {}
			local debuffType = nil
			if dType then debuffType = dType else debuffType = "" end
			
			if (not blacklist[spellId]) then
				if whitelist[spellId] or (isStealable and debuffType == canPurge) or rBelf(debuffType) then
					numAuras = numAuras + 1
					if (spellId == 209859 ) then -- Handle bolster stacks
						bolster = bolster + 1
						state = {
							show = true,
							spellId = spellId,
							unit = unit,
							duration = duration,
							expirationTime = expirationTime,
							icon = icon,
							plate = C_NamePlate.GetNamePlateForUnit(unit),
							stacks = bolster,
							type = debuffType,
							cloneId = unit.."-"..spellId,
							isStealable = cSteal(spellId, isStealable),
						}
					else
						state = {
							show = true,
							spellId = spellId,
							unit = unit,
							duration = duration,
							expirationTime = expirationTime,
							icon = icon,
							plate = C_NamePlate.GetNamePlateForUnit(unit),
							stacks = count or 0,
							type = debuffType,
							cloneId = unit.."-"..spellId,
							isStealable = cSteal(spellId, isStealable),
						}
					end
				end
			else
				state = {
					show = false,
				}
			end
			if NEAisShowBuff(state) then
				table.insert(locstates, state)
			end
		end
	end
	auraPool[unit] = nil
	auraPool[unit] = {}
	if (numAuras > 0) then
		table.sort(locstates, function(t1, t2)
				if not t2 then
					return true
				end
				return t1.spellId < t2.spellId
		end)
		for aura_num, state in ipairs(locstates) do
			auraPool[unit][state.cloneId] = state
		end
		UpdateNameplate(unit)
	end
end

local function ES_CheckUnit(unit)
	if not unit then return false end
	if not UnitExists(unit) then return false end
	local unitReaction = UnitReaction(unit, "player")
	local isPlayer = UnitIsPlayer(unit)
	if (unitReaction and unitReaction >= 5) or not (not isPlayer or showPlayers) then
		return false
	else
		return true
	end
end


-- Testing AceEvents
function ES_DispelEnemyBuff:Handler1(event, unit, ...)
	HideFrame(unit)
end
ES_DispelEnemyBuff:RegisterEvent("NAME_PLATE_UNIT_REMOVED", "Handler1")

function ES_DispelEnemyBuff:Handler2(event, unit, ...)
	if not ES_CheckUnit(unit) then return end	
	if (event == "PLAYER_TARGET_CHANGED") then tarNPname = C_NamePlate.GetNamePlateForUnit("target"):GetName() end
	if (unit == "target") and UnitExists("target") and not C_NamePlate.GetNamePlateForUnit("target") then return end
    if C_NamePlate.GetNamePlateForUnit(unit) then HideFrame(unit) end
	ES_CheckAura(unit)
end
ES_DispelEnemyBuff:RegisterEvent("PLAYER_TARGET_CHANGED", "Handler2")
ES_DispelEnemyBuff:RegisterEvent("UNIT_AURA", "Handler2")

function ES_DispelEnemyBuff:Handler3(event, unit, ...)
	if not ES_CheckUnit(unit) then return end
	local check = false
	for i = 1, 2, 1 do
		if UnitBuff(unit, i) then check = true end
		break
	end
	if check then ES_CheckAura(unit) end
end
ES_DispelEnemyBuff:RegisterEvent("NAME_PLATE_UNIT_ADDED", "Handler3")

function ES_DispelEnemyBuff:OnEnable()
    -- Called when the addon is enabled
end
function ES_DispelEnemyBuff:OnDisable()
    -- Called when the addon is disabled
end
function ES_DispelEnemyBuff:OnInitialize()
	local _, _, classID = UnitClass("player")
	if (classID == 12) or (classID == 8) or (classID == 7) or (classID == 5) or (classID == 3) then
		canPurge = "Magic"
	elseif (classID == 11) or (classID == 3) or (classID == 4) then
		canPurge = ""
	else
		local unreg = false
		for k,v in pairs(whitelist) do
			if v then
				unreg = true
				break
			end
		end
		if not showExplosive and not unreg and (not showBE or not(rID == 10))  then
			print('|cFFFF0000ES_DispelEnemyBuff |r','No auras is set to be tracked. Addon disabled!')
			ES_DispelEnemyBuff:UnregisterEvent("NAME_PLATE_UNIT_REMOVED")
			ES_DispelEnemyBuff:UnregisterEvent("PLAYER_TARGET_CHANGED")
			ES_DispelEnemyBuff:UnregisterEvent("UNIT_AURA")
			ES_DispelEnemyBuff:UnregisterEvent("NAME_PLATE_UNIT_ADDED")
		end
	end
	ForceGenerate()
end