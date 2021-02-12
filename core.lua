ES_DispelEnemyBuff = LibStub("AceAddon-3.0"):NewAddon("ES_DispelEnemyBuff", "AceEvent-3.0")
local _, addon = ...
ESDEB_DB = {}
--/ Vars
local framePool,auraPool,btnPool = {},{},{}
local currTab,tarNPname,testing,backdrop_tmp
local canPurge = "none"
local initpad,chkbtns,nrInput,numFrames = 5,1,1,0
local UIscale = UIParent:GetEffectiveScale()
local xOffset, yOffset, auraWidth, auraHeight, cWidth, cHeight
local anchorPoint, relativeAnchor, xOff, yOff
local auraW, auraH, borderSize, showGlow, growthDirection
local showExplosive, showBE, showBECD, showPlayers
local whitelist, blacklist
local function ES_UpdateVar()
	-- Saved
	local db = ESDEB_DB["settings"]
	anchorPoint = db.anchorPoint
	relativeAnchor = db.relativeAnchor
	xOff = db.xOff
	yOff = db.yOff
	auraW = db.auraW
	auraH = db.auraH
	borderSize = db.borderSize
	showGlow = db.showGlow
	growthDirection = db.growthDirection
	showExplosive = db.showExplosive
	showBE = db.showBE
	showBECD = db.showBECD
	showPlayers = db.showPlayers
	whitelist = ESDEB_DB["whitelist"]
	blacklist = ESDEB_DB["blacklist"]
	-- Local
	xOffset = db.xOff * UIscale
	yOffset = db.yOff * UIscale
	auraWidth = db.auraW * UIscale
	auraHeight = db.auraH * UIscale
	cWidth = (db.auraW + 2 + (2 * db.borderSize)) * UIscale
	cHeight = (db.auraH + 2 + (2 * db.borderSize)) * UIscale
	for _,frame in pairs(framePool) do
		frame:SetWidth(db.auraW * UIscale)
		frame:SetHeight(db.auraH * UIscale)
		frame.txt:SetFont("Fonts\\FRIZQT__.TTF", (db.auraH * UIscale)/1.5, "OUTLINE")
		frame.Backdrop:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", -db.borderSize*UIscale, -db.borderSize*UIscale)
		frame.Backdrop:SetPoint("TOPRIGHT", frame, "TOPRIGHT", db.borderSize*UIscale, db.borderSize*UIscale)
		frame.show = false
		frame.test = false
		frame:Hide()
	end
end
--/

local function printInit()
	print('|cff6495edES_DispelEnemyBuff:|r' .. ' Initial load. Type ' .. '|cff6495ed /es_deb |r' .. 'to bring up the settings and alter the appearance of auras.')
end

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
	frame.Backdrop = frame:CreateTexture(nil, "BACKGROUND")
	frame.Backdrop:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", -borderSize*UIscale, -borderSize*UIscale)
	frame.Backdrop:SetPoint("TOPRIGHT", frame, "TOPRIGHT", borderSize*UIscale, borderSize*UIscale)
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
				frame.test = false
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
				frame.test = false
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
	
	local handletest = false
	local auras = auraPool[unit]
	if testing and (C_NamePlate.GetNamePlateForUnit("target") == parent) then
		handletest = true
		auras = addon.testauras
	end
	
	if growthDirection == "CENTER" then
		for k,v in pairs(auras) do
			num_auras = num_auras + 1
		end
		aura_number = 0
	end
	
	for _, state in pairs(auras) do
		aura_number = aura_number + 1
		local frame = getFrame()
		local red = DebuffTypeColor["none"].r
		local green = DebuffTypeColor["none"].g
		local blue = DebuffTypeColor["none"].b
		local type = state.aura_type
		
		if type == "" then
			red = addon.color_enrage.red
			green = addon.color_enrage.green
			blue = addon.color_enrage.blue
		elseif type == "Expl" then
			red = addon.color_explo.red
			green = addon.color_explo.green
			blue = addon.color_explo.blue
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
		
		frame.unit = unit
		frame.Backdrop:SetColorTexture(red,green,blue,1)
			
		local xOffset1, yOffset1
		if growthDirection == "CENTER" then 
			xOffset1 = xOffset - (cWidth*(num_auras-1)/2) + (cWidth*(aura_number-1))
			yOffset1 = yOffset
		else
			xOffset1 = xOffset+cWidth*(aura_number-1)*addon.growthDirectionValues[growthDirection].xDir
			yOffset1 = yOffset+cHeight*(aura_number-1)*addon.growthDirectionValues[growthDirection].yDir
		end
		
		frame:ClearAllPoints()
		frame:SetPoint(anchorPoint, parent, relativeAnchor, xOffset1, yOffset1)
		local expire = 0
		local dur = 0
		if state.duration then dur = state.duration end
		
		if handletest then
			frame.test = true
			frame.plate = C_NamePlate.GetNamePlateForUnit("target"):GetName()
			expire = GetTime() + state.expirationTime
		else
			frame.plate = parent:GetName()
			if state.expirationTime then
				expire = GetTime() - (dur - (state.expirationTime - GetTime()))
			end
		end
		
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
	if showBE and (addon.rID == 10) then
		if not showBECD then
			return true
		else
			local onCD, CDdur = GetSpellCooldown(addon.racialID[addon.cID])
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

function ES_DEB_ListToggle(list, btn, setting,tmpl)
	local table = {}
	for _,v in pairs(addon.dropdowns[tmpl]) do
		local insert = {text = v, hasArrow = false, notCheckable = true, func = function() CloseDropDownMenus(); ESDEB_DB["settings"][setting] = v; btn:SetText(v); ES_UpdateVar(); end}
		tinsert(table, insert)
	end
	EasyMenu(table, list, btn, 0 , 0, "MENU");
end

local function CreateDropDown(parent,x,y,setting,text,tmpl)
	local btn = CreateFrame("DropDownToggleButton", nil, parent, "UIMenuButtonStretchTemplate")
	if setting == "spellid" then
		btn:SetWidth(36)
		btn:SetHeight(22)
		btn:SetPoint("LEFT", parent, "TOPLEFT", x, y)
		btn:SetText(text)
	elseif setting == "none" then
		btn:SetWidth(36)
		btn:SetHeight(22)
		btn:SetPoint("LEFT", parent, "TOPLEFT", x, y)
		btn:SetText(text)
	else
		btn.dd = CreateFrame("Frame", nil, parent, "UIDropDownMenuTemplate")
		btn:SetWidth(100)
		btn:SetHeight(22)
		btn:SetPoint("LEFT", parent, "TOPLEFT", 170+x, y)
		btn:SetText(ESDEB_DB["settings"][setting])
		btn:SetScript("OnMouseDown", function(self)
			if DropDownList1:IsVisible() then
				CloseDropDownMenus()
			else
				UIMenuButtonStretchMixin.OnMouseDown(self, button);
				ES_DEB_ListToggle(btn.dd ,btn, setting,tmpl)
			end
		end)
		local font = btn:CreateFontString(btn, "OVERLAY", "GameFontNormal")
		font:SetTextColor(0.5, 0.8, 0.8, 1)
		font:SetPoint("LEFT", -170, 0)
		font:SetText(text)
	end
	return btn
end

local function CreateCheckBtn(parent,x,y,setting,text,control,invert)
	local chkb = CreateFrame("CheckButton", "ESDEBCHK"..chkbtns, parent, "ChatConfigCheckButtonTemplate")
	chkbtns = chkbtns + 1
	chkb:SetPoint("LEFT", parent, "TOPLEFT", x, y)
	getglobal(chkb:GetName() .. 'Text'):SetText('|cff7fcccc '..text..'|r')
	if control then
		if invert then
			chkb:SetScript("OnClick", function(self,button,down) 
				if self:GetChecked(true) then
					ESDEB_DB["settings"][setting] = true
					control:Show()
					ES_UpdateVar()
				else
					ESDEB_DB["settings"][setting] = false
					control:Hide()
					ES_UpdateVar()
				end
			end)
		else
			chkb:SetScript("OnClick", function(self,button,down) 
				if self:GetChecked(true) then
					ESDEB_DB["settings"][setting] = true
					control:Hide()
					ES_UpdateVar()
				else
					ESDEB_DB["settings"][setting] = false
					control:Show()
					ES_UpdateVar()
				end
			end)
		end
	else
		chkb:SetScript("OnClick", function(self,button,down) 
			if self:GetChecked(true) then
				ESDEB_DB["settings"][setting] = true
				ES_UpdateVar()
			else
				ESDEB_DB["settings"][setting] = false
				ES_UpdateVar()
			end
		end)
	end
	return chkb
end

local function getButton()
	for _,frame in pairs(btnPool) do
		if not frame.show then
			frame.show = true
			return frame
		end
	end
	local frame = CreateFrame("Frame", nil)
	frame:SetFrameLevel(1)
	frame:SetWidth(200)
	frame:SetHeight(30)
	frame:SetFrameStrata("BACKGROUND")
	frame.bar = frame:CreateTexture(nil, "BACKGROUND")
	frame.bar:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, -3)
	frame.bar:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 3)
	frame.bar:SetTexture("Interface\\AddOns\\ES_DispelEnemyBuff\\bar.tga")
	frame.txt = frame:CreateFontString(nil)
	frame.txt:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
	frame.txt:SetPoint("CENTER", frame, "CENTER", 0, 0)
	frame.tt = CreateFrame("Frame", nil, frame)
	frame.tt:SetPoint("LEFT", frame, "LEFT", 4, 0)
	frame.tt:SetSize(20,20)
	frame.tt:EnableMouse(true)
	frame.icon = frame:CreateTexture(nil, "ARTWORK")
	frame.icon:SetSize(20,20)
	frame.icon:SetPoint("LEFT", frame, "LEFT", 4, 0)
	frame.tt:SetScript("OnEnter", function(self)
		local link, _ = GetSpellLink(self:GetParent().spellId)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT", -20, 0)
		GameTooltip:SetHyperlink(GetSpellLink(self:GetParent().spellId))
		GameTooltip:Show()
	end)
	frame.tt:SetScript("OnLeave", function(self)
		GameTooltip:Hide()
	end)
	frame.btn = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
	frame.btn:SetSize(30,30)
	frame.btn:SetPoint("RIGHT", frame, "RIGHT", 0, 0)
	frame.btn:SetScript("OnClick", function(self)
		local f = self:GetParent()
		ESDEB_DB[f.tab][f.spellId] = nil
		f.show = false
		f:Hide()
		ESDEB_refreshList(false)
	end)
	frame.show = true
	tinsert(btnPool,frame)
	return frame
end

function ESDEB_refreshList(tbl)
	local parent
	for i=1,2,1 do
		local tab = _G["ES_DispelEnemyBuff_Container".."Tab"..i]
		if string.lower(tab:GetText()) == currTab then
			parent = tab.content
			break
		end
	end
	if not tbl then
		tbl = ESDEB_DB[currTab]
	end
	for _,frame in pairs(btnPool) do
		frame.show = false
		frame:Hide()
	end
	local sorted = {}
	for id,_ in pairs(tbl) do
		table.insert(sorted, id)
	end
	table.sort(sorted)
	local count = 0
	for _, spellId in ipairs(sorted) do
		local name, _, icon = GetSpellInfo(spellId)
		local frame = getButton()
		frame.spellId = spellId
		frame.tab = currTab
		local text
		if string.len(name) > 12 then
			text = string.sub(name, 1, 12) .. '...'
		else
			text = name
		end
		frame.txt:SetText(text)
		frame.icon:SetTexture(icon)
		if (count > 0) then initpad = 0 end
		frame:SetPoint("TOP", parent, "TOP", 0, -1*((30 * count ) + 5))
		frame:SetParent(parent)
		frame:Show()
		count = count + 1
	end
	parent:SetHeight((30 * count )+20)
end

local function ErrorPopup(msg)
	local frame = _G["ES_DispelEnemyBuff_Error"]
	frame.txt:SetText(msg)
	frame:Show()
	C_Timer.After(4, function()
		frame:Hide()
	end)
end
local function AddSpell(spellId,input)
	if not tonumber(spellId) then
		ErrorPopup('Not a valid number!')
	elseif not GetSpellInfo(spellId) then
		ErrorPopup('No spell matches that spellId!')
	else
		if ESDEB_DB["whitelist"][tonumber(spellId)] then
			ErrorPopup('SpellId already exist in Whitelist')
		elseif ESDEB_DB["blacklist"][tonumber(spellId)] then
			ErrorPopup('SpellId already exist in Blacklist')
		else
			ESDEB_DB[currTab][tonumber(spellId)] = true
			ESDEB_refreshList(false)
		end
	end	
	input:SetText("")
end

local function CreateInput(parent,x,y,setting,text)
	local inp = CreateFrame("EditBox", "ESDEBINP"..nrInput, parent, "InputBoxTemplate")
	nrInput = nrInput + 1
	if setting == "spellid" then
		inp:SetPoint("CENTER", parent, "TOP", x, y)
	else
		inp:SetPoint("LEFT", parent, "TOPLEFT", x, y)
	end
	
	inp:SetFontObject(ChatFontNormal)
	local font = inp:CreateFontString(inp, "OVERLAY", "GameFontNormal")
	font:SetTextColor(0.5, 0.8, 0.8, 1)
	font:SetPoint("RIGHT", inp, "LEFT", -10, 0)
	font:SetText(text)
	inp:SetHeight(20)
	inp:SetAutoFocus(false)
	
	if setting == "spellid" then
		inp:SetMaxLetters(9)
		inp:SetWidth(100)
		inp:SetScript("OnEscapePressed", function(self,button,down) 
			local val = self:GetText()
			if not tonumber(val) then
				self:SetText("")
			end
			self:ClearFocus()
		end)
		inp:SetScript("OnEnterPressed", function(self,button,down) 
			local val = self:GetText()
			if not tonumber(val) then
				self:SetText("")
			end
			self:ClearFocus()
		end)
		inp:SetScript("OnTabPressed", function(self,button,down) 
			local val = self:GetText()
			if not tonumber(val) then
				self:SetText("")
			end
			self:ClearFocus()
		end)
		inp:SetScript("OnEditFocusLost", function(self,button,down) 
			local val = self:GetText()
			if not tonumber(val) then
				self:SetText("")
			end
			self:ClearFocus()
		end)
	else
		inp:SetMaxLetters(4)
		inp:SetWidth(40)
		inp:SetScript("OnEscapePressed", function(self,button,down) 
			local val = self:GetText()
			if tonumber(val) then
				ESDEB_DB["settings"][setting] = tonumber(val)
				ES_UpdateVar()
			else
				ESDEB_DB["settings"][setting] = 0
				self:SetText("0")
			end
			self:ClearFocus()
		end)
		inp:SetScript("OnEnterPressed", function(self,button,down) 
			local val = self:GetText()
			if tonumber(val) then
				ESDEB_DB["settings"][setting] = tonumber(val)
				ES_UpdateVar()
			else
				ESDEB_DB["settings"][setting] = 0
				self:SetText("0")
			end
			self:ClearFocus()
		end)
		inp:SetScript("OnTabPressed", function(self,button,down) 
			local val = self:GetText()
			if tonumber(val) then
				ESDEB_DB["settings"][setting] = tonumber(val)
				ES_UpdateVar()
			else
				ESDEB_DB["settings"][setting] = 0
				self:SetText("0")
			end
			self:ClearFocus()
		end)
		inp:SetScript("OnEditFocusLost", function(self,button,down) 
			local val = self:GetText()
			if tonumber(val) then
				ESDEB_DB["settings"][setting] = tonumber(val)
				ES_UpdateVar()
			else
				ESDEB_DB["settings"][setting] = 0
				self:SetText("0")
			end
			self:ClearFocus()
		end)
	end
	return inp
end

local function CreateSeperator(parent,y)
	local line = parent:CreateTexture(nil, "ARTWORK")
	line:SetPoint("TOP", 0, y)
	line:SetSize(parent:GetWidth() / 1.1, 2)
	line:SetColorTexture(0.6, 0.6, 0.6, 0.5)
end

local function Tab_OnClick(self)
	PanelTemplates_SetTab(self:GetParent(), self:GetID())
	local scrollChild = ES_DispelEnemyBuff_Container.sf:GetScrollChild()
	if scrollChild then
		scrollChild:Hide()
	end
	ES_DispelEnemyBuff_Container.sf:SetScrollChild(self.content)
	self.content:Show()
	currTab = string.lower(self:GetText())
	ESDEB_refreshList(ESDEB_DB[string.lower(self:GetText())])
end

local function SetTabs(frame, numTabs, ...)
	frame.numTabs = numTabs
	local contents = {}
	local frameName = frame:GetName()
	for i = 1, numTabs do
		local tab = CreateFrame("Button", frameName.."Tab"..i, frame, "TabButtonTemplate")
		tab:SetID(i)
		tab:SetText(select(i, ...))
		tab:SetScript("OnClick", Tab_OnClick)
		tab.content = CreateFrame("Frame", nil, ES_DispelEnemyBuff_Container.sf)
		tab.content:SetSize(280, 500)
		tab.content:Hide()
		table.insert(contents, tab.content)
		PanelTemplates_TabResize(tab, 0);
		if (i == 1) then
			tab:SetPoint("BOTTOMLEFT", ES_DispelEnemyBuff_Container, "TOPLEFT", 5, 0)
		else
			tab:SetPoint("BOTTOMLEFT", _G[frameName.."Tab"..(i - 1)], "BOTTOMRIGHT", 0, 0)
		end
	end
	Tab_OnClick(_G[frameName.."Tab1"])
	return unpack(contents)
end

local function ESDEB_StopTesting()
	testing = false
	for _,frame in pairs(framePool) do
		if (frame.test == true) then
			frame.plate = nil
			frame.show = false
			frame.test = false
			frame.unit = nil
			AutoCastShine_AutoCastStop(frame.shine)
			frame.shine:Hide()
			frame.cd:Clear()
			frame:Hide()
		end
	end
end

local function CreateSettingsFrame()
	local leftX = 15
	local f = CreateFrame("Frame", "ES_DispelEnemyBuff_Settings", UIParent, "BasicFrameTemplateWithInset")
	f:SetFrameStrata("HIGH")
	f:SetHeight(600)
	f:SetWidth(300)
	f:SetMovable(true)
	f:EnableMouse(true)
	f:RegisterForDrag("LeftButton")
	f:SetScript("OnDragStart", f.StartMoving)
	f:SetScript("OnDragStop", f.StopMovingOrSizing)
	f:SetClampedToScreen(true)
	f:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
	f.TitleText:SetText("ES_DispelEnemyBuff")
	f:SetScript("OnHide", function()
		ESDEB_StopTesting()
	end)
	
	local test = CreateDropDown(f,leftX+236,-388,"none","Test")
	test:SetScript("OnMouseDown", function(self)
		if UnitExists("target") then
			if testing then ESDEB_StopTesting() end
			testing = true
			UpdateNameplate("target")
		else
			ErrorPopup('You dont have a target')
		end
	end)
	test:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT", -20, 0)
		GameTooltip:AddLine("Generate test auras for your current target")
		GameTooltip:AddLine(" ")
		GameTooltip:AddLine("Test will cancel once you close the",1,1,1)
		GameTooltip:AddLine("settings window.",1,1,1)
		GameTooltip:AddLine(" ")
		GameTooltip:AddLine("Will refresh existing auras if you",1,1,1)
		GameTooltip:AddLine("maintain the same target.",1,1,1)
		GameTooltip:Show()
	end)
	test:SetScript("OnLeave", function(self)
		GameTooltip:Hide()
	end)
	
	
	
	local inp1 = CreateInput(f,leftX+220,-50,'xOff',"X offset:")
	inp1:SetText(tostring(ESDEB_DB["settings"].xOff))
	local inp2 = CreateInput(f,leftX+220,-75,'yOff',"Y offset:")
	inp2:SetText(tostring(ESDEB_DB["settings"].yOff))
	local inp3 = CreateInput(f,leftX+90,-50,'auraW',"Aura width:")
	inp3:SetText(tostring(ESDEB_DB["settings"].auraW))
	local inp4 = CreateInput(f,leftX+90,-75,'auraH',"Aura height:")
	inp4:SetText(tostring(ESDEB_DB["settings"].auraH))
	
	CreateDropDown(f,leftX,-110,'anchorPoint',"Aura Anchor: ","anchors")
	CreateDropDown(f,leftX,-135,'relativeAnchor',"Anchored to nameplate's: ","anchors")
	CreateDropDown(f,leftX,-160,'growthDirection',"Growth direction: ","direction")
	
	CreateSeperator(f,-180)
	
	local font = f:CreateFontString(f, "OVERLAY", "GameFontNormal")
	font:SetTextColor(0.5, 0.8, 0.8, 1)
	font:SetPoint("LEFT", f, "TOPLEFT", leftX, -200)
	font:SetText("Border size:")
	
	local rb1 = CreateFrame("CheckButton", "ESDEBRB1", f, "UIRadioButtonTemplate")
	rb1:SetPoint("LEFT", f, "TOPLEFT", leftX + 85, -200)
	getglobal(rb1:GetName() .. 'Text'):SetText('|cff7fcccc1px|r')
	rb1:SetScript("OnClick", function(self,button,down) 
		if self:GetChecked(true) then
			ESDEB_DB["settings"].borderSize = 1
			_G["ESDEBRB2"]:SetChecked(false)
			_G["ESDEBRB3"]:SetChecked(false)
			ES_UpdateVar()
		else
			self:SetChecked(true)
		end
	end)
	
	local rb2 = CreateFrame("CheckButton", "ESDEBRB2", f, "UIRadioButtonTemplate")
	rb2:SetPoint("LEFT", f, "TOPLEFT", leftX + 140, -200)
	getglobal(rb2:GetName() .. 'Text'):SetText('|cff7fcccc2px|r')
	rb2:SetScript("OnClick", function(self,button,down) 
		if self:GetChecked(true) then
			ESDEB_DB["settings"].borderSize = 2
			_G["ESDEBRB1"]:SetChecked(false)
			_G["ESDEBRB3"]:SetChecked(false)
			ES_UpdateVar()
		else
			self:SetChecked(true)
		end
	end)
	
	local rb3 = CreateFrame("CheckButton", "ESDEBRB3", f, "UIRadioButtonTemplate")
	rb3:SetPoint("LEFT", f, "TOPLEFT", leftX + 195, -200)
	getglobal(rb3:GetName() .. 'Text'):SetText('|cff7fcccc3px|r')
	rb3:SetScript("OnClick", function(self,button,down) 
		if self:GetChecked(true) then
			ESDEB_DB["settings"].borderSize = 3
			_G["ESDEBRB1"]:SetChecked(false)
			_G["ESDEBRB2"]:SetChecked(false)
			ES_UpdateVar()
		else
			self:SetChecked(true)
		end
	end)
	_G["ESDEBRB"..tostring(ESDEB_DB["settings"].borderSize)]:SetChecked(true)
	
	local chk1 = CreateCheckBtn(f,leftX,-225,'showGlow','Autoshine on dispellable (by you)',false)
	chk1:SetChecked(ESDEB_DB["settings"].showGlow)
	
	CreateSeperator(f,-240)
	
	local chk2 = CreateCheckBtn(f,leftX,-260,'showPlayers','Enable on enemy players',false)
	chk2:SetChecked(ESDEB_DB["settings"].showPlayers)
	
	local chk3 = CreateCheckBtn(f,leftX,-285,'showExplosive','Explosive display (M+ affix)',false)
	chk3:SetChecked(ESDEB_DB["settings"].showExplosive)
	
	local chk4 = CreateCheckBtn(f,leftX+18,-328,'showBECD','Hide while on cooldown',false)
	chk4:SetChecked(ESDEB_DB["settings"].showBECD)
	
	local chk5 = CreateCheckBtn(f,leftX,-310,'showBE','Arcane Torrent - support',chk4,true)
	chk5:SetChecked(ESDEB_DB["settings"].showBE)
	if not chk5:GetChecked() then chk4:Hide() end
	
	CreateSeperator(f,-338)
	
	local spellid = CreateInput(f,0,-360,'spellid',"SpellId: ")
	local spAdd = CreateDropDown(f,leftX+190,-360,"spellid","Add")
	spAdd:SetScript("OnMouseDown", function(self)
		local val = spellid:GetText()
		AddSpell(val,spellid)
	end)
	
	
	local fr = CreateFrame("Frame", "ES_DispelEnemyBuff_Container", f, "InsetFrameTemplate")
	fr:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 5, 5)
	fr:SetPoint("TOPRIGHT", f, "BOTTOMRIGHT", -7, 200)
	
	fr.sf = CreateFrame("ScrollFrame", nil, fr, "UIPanelScrollFrameTemplate")
	fr.sf:SetPoint("TOPLEFT", fr, "TOPLEFT", 0, 0)
	fr.sf:SetPoint("BOTTOMRIGHT", fr, "BOTTOMRIGHT", 0, 0)
	fr.sf:SetClipsChildren(true)
	
	local tab1, tab2 = SetTabs(fr, 2, "Blacklist", "Whitelist")
	
	
	fr.sf.ScrollBar:ClearAllPoints()
	fr.sf.ScrollBar:SetPoint("TOPLEFT", fr.sf, "TOPRIGHT", -15, -18)
	fr.sf.ScrollBar:SetPoint("BOTTOMRIGHT", fr.sf, "BOTTOMRIGHT", -10, 18)
	
	
	fr.sf:SetScript("OnMouseWheel", function(self, delta)
		local newValue = self:GetVerticalScroll() - (delta * 20)
		if (newValue < 0) then
			newValue = 0
		elseif (newValue > self:GetVerticalScrollRange()) then
			newValue = self:GetVerticalScrollRange()
		end
		self:SetVerticalScroll(newValue)
	end)	
	
	local error = CreateFrame("Frame", "ES_DispelEnemyBuff_Error", fr, "GlowBoxTemplate")
	error:SetPoint("TOPLEFT", fr, "TOPLEFT", 0, -5)
	error:SetPoint("TOPRIGHT", fr, "TOPRIGHT", 0, -5)
	error:SetHeight(40)
	error.txt = error:CreateFontString(nil)
	error.txt:SetFont("Fonts\\FRIZQT__.TTF", 16, "OUTLINE")
	error.txt:SetPoint("CENTER", 0, 0)
	error.txt:SetTextColor(1,1,0,1)
	error:Hide()
	
	f:Hide()
end

function ES_DispelEnemyBuff:OnInitialize()
	local _, _, classID = UnitClass("player")
	local load = true
	testing = false
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
		if not showExplosive and not unreg and (not showBE or not(addon.rID == 10))  then
			load = false
			print('|cFFFF0000ES_DispelEnemyBuff |r','No auras is set to be tracked. Addon disabled!')
			ES_DispelEnemyBuff:UnregisterEvent("NAME_PLATE_UNIT_REMOVED")
			ES_DispelEnemyBuff:UnregisterEvent("PLAYER_TARGET_CHANGED")
			ES_DispelEnemyBuff:UnregisterEvent("UNIT_AURA")
			ES_DispelEnemyBuff:UnregisterEvent("NAME_PLATE_UNIT_ADDED")
		end
	end
	if load then
		if not ESDEB_DB["settings"] then
			ESDEB_DB = addon.defaultDB
			C_Timer.After(5, printInit)
		end
		ES_UpdateVar()
		if not _G["ES_DispelEnemyBuff_Settings"] then
			CreateSettingsFrame()
		end
		ForceGenerate()
	end
end

local function ESDEB_Reset()
	ESDEB_DB = addon.defaultDB
	Tab_OnClick(_G["ES_DispelEnemyBuff_ContainerTab1"])
end
SLASH_ESDEB1 = "/es_deb";
SlashCmdList["ESDEB"] = function(msg)
	if msg == "reset" then
		ESDEB_Reset()
	else
		if ES_DispelEnemyBuff_Settings:IsVisible() then
			ES_DispelEnemyBuff_Settings:Hide()
		else
			ES_DispelEnemyBuff_Settings:Show()
		end
	end
end