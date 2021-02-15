local _, addon = ...

local _, _, rID = UnitRace("player")
addon.rID = rID
local _, _, cID = UnitClass("player")
addon.cID = cID

local canPurge = {
	[3] = {
		["Magic"] = true,
		[""] = true,
	},
	[4] = {
		[""] = true
	},
	[5] = {
		["Magic"] = true
	},
	[7] = {
		["Magic"] = true
	},
	[8] = {
		["Magic"] = true
	},
	[11] = {
		[""] = true
	},
	[12] = {
		["Magic"] = true
	}
}
addon.canPurge = canPurge

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
addon.racialID = racialID

local defaultDB = {
	["settings"] = {
		["showPlayers"] = true,
		["anchorPoint"] = "LEFT",
		["relativeAnchor"] = "CENTER",
		["xOff"] = 100,
		["yOff"] = 0,
		["borderSize"] = 1,
		["growthDirection"] = "RIGHT",
		["auraW"] = 24,
		["auraH"] = 24,
		["showGlow"] = true,
		["showExplosive"] = true,
		["showBE"] = true,
		["showBECD"] = true
	},
	["whitelist"] = {
		[209859] = true,
		[343502] = true,
		[226510]= true,
		[299150] = true,
	},
	["blacklist"] = {
		[21562] = true,
		[1459] = true
	}
}
addon.defaultDB = defaultDB

local growthDirectionValues = {
    ["UP"] = {xDir =  0, yDir =  1},
    ["DOWN"] = {xDir =  0, yDir = -1},
    ["LEFT"] = {xDir = -1, yDir =  0},
    ["RIGHT"] = {xDir =  1, yDir =  0},
}
addon.growthDirectionValues = growthDirectionValues

local color_enrage = {red = 0.85, green = 0.2, blue = 0.1,}
addon.color_enrage = color_enrage
local color_explo = {red = 0.85, green = 0.85, blue = 0.1,}
addon.color_explo = color_explo

local dropdowns = {
	["anchors"] = {"TOP", "BOTTOM", "LEFT", "RIGHT", "CENTER", "TOPLEFT", "TOPRIGHT", "BOTTOMLEFT", "BOTTOMRIGHT"},
	["direction"] = {"UP", "DOWN", "LEFT", "RIGHT", "CENTER"}
}
addon.dropdowns = dropdowns

local testauras = {
	[1] = {
		["show"] = true,
		["spellId"] = 324776,
		["unit"] = "target",
		["duration"] = 30,
		["expirationTime"] = 20,
		["icon"] = 136006,
		["stacks"] = 0,
		["aura_type"] = "Magic",
		["cloneId"] = "target".."-"..324776,
		["isStealable"] = true,
	},
	[2] = {
		["show"] = true,
		["spellId"] = 325418,
		["unit"] = "target",
		["duration"] = 20,
		["expirationTime"] = 16,
		["icon"] = 132104,
		["stacks"] = 3,
		["aura_type"] = "none",
		["cloneId"] = "target".."-"..325418,
		["isStealable"] = false,
	},
	[3] = {
		["show"] = true,
		["spellId"] = 326450,
		["unit"] = "target",
		["duration"] = 15,
		["expirationTime"] = 12,
		["icon"] = 458967,
		["stacks"] = 0,
		["aura_type"] = "",
		["cloneId"] = "target".."-"..326450,
		["isStealable"] = true,
	},
	[4] = {
		["show"] = true,
		["spellId"] = 326617,
		["unit"] = "target",
		["duration"] = 10,
		["expirationTime"] = 8,
		["icon"] = 645792,
		["stacks"] = 0,
		["aura_type"] = "Magic",
		["cloneId"] = "target".."-"..326617,
		["isStealable"] = true,
	},
	[5] = {
		["show"] = true,
		["spellId"] = 774,
		["unit"] = "target",
		["duration"] = 16,
		["expirationTime"] = 10,
		["icon"] = 136081,
		["stacks"] = 0,
		["aura_type"] = "Magic",
		["cloneId"] = "target".."-"..774,
		["isStealable"] = true,
	}
}
addon.testauras = testauras

