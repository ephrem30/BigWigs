
------------------------------
--      Are you local?      --
------------------------------

local LC = AceLibrary("AceLocale-2.2"):new("BigWigs")
local BZ = AceLibrary("Babble-Zone-2.2")

local withcore = {}
local inzone = {}
local zonelist = {}

local function Split(str, sep)
	local x, y = string.find(str, sep) or 0, string.len(sep) or 1
	return tonumber(string.sub(str, 1, x - 1)) or string.sub(str, 1, x - 1), tonumber(string.sub(str, x + y)) or string.sub(str, x + y)
end

local function Trim(str)
	str = string.gsub(str, "^%s*", "")
	str = string.gsub(str, "%s*$", "")
	return str
end

local function Explode(str, sep)
	local a, b = Split(str, sep)
	if not b or b == "" then return Trim(a) end
	if not string.find(b, sep) then return Trim(a), Trim(b) end
	return Trim(a), Explode(b, sep)
end

------------------------------
--    Addon Declaration     --
------------------------------

BigWigsLoD = AceLibrary("AceAddon-2.0"):new("AceEvent-2.0")

------------------------------
--      Initialization      --
------------------------------

function BigWigsLoD:OnInitialize()
	self:InitializeLoD()
end

function BigWigsLoD:OnEnable()
	if BigWigs:IsActive() then
		self:BigWigs_CoreEnabled()
	else
		self:RegisterEvent("BigWigs_CoreEnabled")
	end
	self:RegisterEvent("ZONE_CHANGED_NEW_AREA")
	self:RegisterEvent("AceEvent_FullyInitialized", "ZONE_CHANGED_NEW_AREA")
end

------------------------------
--     Event Handlers       --
------------------------------

function BigWigsLoD:BigWigs_CoreEnabled()

	for k,v in pairs( withcore ) do
		if not IsAddOnLoaded( v ) then
			LoadAddOn( v )
		end
	end	

	withcore = {}

	-- Fire an event to have the target monitor check it's stuff
	self:TriggerEvent("BigWigs_ModulePackLoaded")
end

function BigWigsLoD:ZONE_CHANGED_NEW_AREA()
	self:LoadZone( GetRealZoneText() )
end

------------------------------
--     Utility Functions    --
------------------------------

function BigWigsLoD:InitializeLoD()
	local numAddons = GetNumAddOns()
	for i = 1, numAddons do
		if not IsAddOnLoaded(i) and IsAddOnLoadOnDemand(i) then
			local meta = GetAddOnMetadata(i, "X-BigWigs-LoadInZone")
			if meta then
				local ignorezone = string.find( meta, LC["Outdoor Raid Bosses Zone"] )
				for k, v in pairs({Explode(meta, ",")}) do
					local zone
					if BZ:HasTranslation(v) then zone = BZ[v] end
					-- elseif LC:HasTranslation(v) then zone = LC[v] end
					if zone then
						if not inzone[zone] then inzone[zone] = {} end
						table.insert( inzone[zone], i)
						if not ignorezone then 
							zonelist[zone] = true
						else 
							if not zonelist[LC["Other"]] then zonelist[LC["Other"]] = {} end
							zonelist[LC["Other"]][zone] = true
						end						
					end
				end
			end
			meta = GetAddOnMetadata(i, "X-BigWigs-LoadWithCore")
			if meta then
				-- register this addon for loading with core
				table.insert( withcore, i )
			end
		end
	end
end

function BigWigsLoD:LoadZone( zone )
	if inzone[zone] then
		for k,v in pairs( inzone[zone] ) do
			if not IsAddOnLoaded( v ) then
				LoadAddOn( v )
			end
		end
		inzone[zone] = nil
		zonelist[zone] = nil
		self:TriggerEvent("BigWigs_ModulePackLoaded", zone)
	end
end

function BigWigsLoD:GetZones()
	return zonelist
end