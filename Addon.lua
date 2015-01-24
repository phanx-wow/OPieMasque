--[[--------------------------------------------------------------------
	OPie Masque
	Adds Masque skinning support to OPie.
	Copyright (c) 2013-2015 Phanx. All rights reserved.
	http://www.wowinterface.com/downloads/info22226-OPieMasque.html
	http://www.curse.com/addons/wow/opie-masque/
	https://github.com/Phanx/OPieMasque
----------------------------------------------------------------------]]

local SPECIAL_COLOR_ALPHA = 0.75
-- 0 = invisible, 1 = fully visible, lower it if your skin is ugly

------------------------------------------------------------------------

assert(OneRingLib and OneRingLib.ext and OneRingLib.ext.OPieUI, "OPie not found")

local Masque = LibStub("Masque", true)
assert(Masque, "Masque not found")

local id
local group
local buttons = {}
local prototype = {}
local STATE_USABLE, STATE_NOMANA, STATE_NORANGE, STATE_UNUSABLE = 0, 1, 2, 3

function prototype:SetIcon(texture)
	self.icon:SetTexture(texture)
end

function prototype:SetIconTexCoord(a, b, c, d, e, f, g, h)
	if not a or not b or not c or not d then return end -- Broker plugins???
	self.icon:SetTexCoord(a, b, c, d, e, f, g, h)
end

function prototype:SetIconVertexColor(r, g, b)
	if r == 0.5 and g == 0.5 and b == 0.5 then return end -- Don't let OPie darken icons on cooldown.
	self.iconr, self.icong, self.iconb = r, g, b
	if self.ustate == STATE_USABLE then
		self.icon:SetVertexColor(r, g, b)
	end
end

function prototype:SetUsable(usable, usableCharge, cd, nomana, norange)
	local state = usable and STATE_USABLE or (norange and STATE_NORANGE or (nomana and STATE_NOMANA or STATE_UNUSABLE))
	if state == self.ustate then return end
	self.ustate = state
	if state == STATE_NORANGE then
		self.icon:SetVertexColor(0.8, 0.1, 0.1)
	elseif state == STATE_NOMANA then
		self.icon:SetVertexColor(0.5, 0.5, 1)
	elseif state == STATE_UNUSABLE and not cd then -- don't black it out while on cooldown
		self.icon:SetVertexColor(0.4, 0.4, 0.4)
	else
		self.icon:SetVertexColor(self.iconr or 1, self.icong or 1, self.iconb or 1)
	end
end

function prototype:SetDominantColor(r, g, b)
	self.border:SetShown(2.85 > (r + g + b)) -- don't override skin color if it's white
	self.border:SetVertexColor(r, g, b)
	self.border:SetAlpha(SPECIAL_COLOR_ALPHA)
	for i = 1, #self.glowTextures do
		self.glowTextures[i]:SetVertexColor(r, g, b)
	end
end

function prototype:SetOverlayIcon(texture, w, h, ...)
	-- wat?
	--[[
	if not texture then
		self.overIcon:Hide()
	else
		self.overIcon:Show()
		self.overIcon:SetTexture(texture)
		self.overIcon:SetSize(w, h)
		if ... then
			self.overIcon:SetTexCoord(...)
		end
	end
	]]
end

function prototype:SetCount(count)
	self.count:SetText(count or "")
end

local displaySubs = {
	["ALT%-"]      = "a",
	["CTRL%-"]     = "c",
	["SHIFT%-"]    = "s",
	["BUTTON"]     = "m",
	["MOUSEWHEEL"] = "w",
	["NUMPAD"]     = "n",
	["PLUS"]       = "+",
	["MINUS"]      = "-",
	["MULTIPLY"]   = "*",
	["DIVIDE"]     = "/",
	["DECIMAL"]    = ".",
}
function prototype:SetBinding(text)
	if not text then
		return self.hotkey:SetText("")
	end
	for k, v in pairs(displaySubs) do
		text = gsub(text, k, v)
	end
	self.hotkey:SetText(text)
end

function prototype:SetCooldown(remain, duration, usable)
	if duration and remain and duration > 0 and remain > 0 then
		local start = GetTime() + remain - duration
		-- TODO: detect and show loss of control ?
		if usable then
			-- show recharge time
			self.cooldown:SetDrawEdge(true)
			self.cooldown:SetDrawSwipe(false)
		else
			-- show cooldown time
			self.cooldown:SetDrawEdge(false)
			self.cooldown:SetDrawSwipe(true)
			self.cooldown:SetSwipeColor(0, 0, 0, 0.8)
		end
		self.cooldown:SetCooldown(start, duration)
		self.cooldown:Show()
	else
		self.cooldown:Hide()
	end
end

function prototype:SetCooldownFormattedText(pattern, ...)
	-- do nothing
end

function prototype:SetCooldownTextShown()
	-- do nothing
end

function prototype:SetHighlighted(highlight)
	self[highlight and "LockHighlight" or "UnlockHighlight"](self)
end

function prototype:SetActive(active)
	self:SetChecked(active)
end

function prototype:SetOuterGlow(shown)
	for i = 1, #self.glowTextures do
		self.glowTextures[i]:SetShown(shown)
	end
end

function prototype:SetEquipState(inBags, isEquipped)
	if isEquipped then
		self.flash:SetVertexColor(0.1, 0.9, 0.15)
		self.flash:Show()
	elseif inBags then
		self.flash:SetVertexColor(1, 0.9, 0.2)
		self.flash:Show()
	else
		self.flash:Hide()
	end
end

local function Reskin()
	for _, button in pairs(buttons) do
		local r, g, b = button.glowTextures[1]:GetVertexColor()
		local _, _, _, a = button.border:GetVertexColor()
		button.border:SetVertexColor(r, g, b, a)
	end
end

local id = 0

local function CreateIndicator(name, parent, size, ghost)
	id = id + 1
	name = name or "OPieSliceButton"..id
	parent = parent or UIParent
	size = size or 36

	local button = CreateFrame("CheckButton", name, parent, "ActionButtonTemplate")
	button:SetSize(size, size)
	button:EnableMouse(false)

	button.border        = _G[name .. "Border"] -- highlight
	button.cooldown      = _G[name .. "Cooldown"]
	button.count         = _G[name .. "Count"]
	button.flash         = _G[name .. "Flash"] -- inner glow / checked
	button.hotkey        = _G[name .. "HotKey"]
	button.icon          = _G[name .. "Icon"]
	button.normalTexture = _G[name .. "NormalTexture"] -- border

	-- Outer glow
	button.glowTextures = {}
	for i = 1, 4 do
		local glow = button:CreateTexture(nil, "BACKGROUND", nil, -8)
		glow:SetSize(size, size)
		glow:SetTexture("Interface\\AddOns\\OPie\\gfx\\oglow")
		glow:Hide()
		button.glowTextures[i] = glow
	end
	button.glowTextures[1]:SetPoint("CENTER", button, "TOPLEFT")
	button.glowTextures[1]:SetTexCoord(0, 1, 0, 1)
	button.glowTextures[2]:SetPoint("CENTER", button, "TOPRIGHT")
	button.glowTextures[2]:SetTexCoord(1, 0, 0, 1)
	button.glowTextures[3]:SetPoint("CENTER", button, "BOTTOMRIGHT")
	button.glowTextures[3]:SetTexCoord(1, 0, 1, 0)
	button.glowTextures[4]:SetPoint("CENTER", button, "BOTTOMLEFT")
	button.glowTextures[4]:SetTexCoord(0, 1, 1, 0)

	--[[ Overlay icon (???)
	button.overIcon = button:CreateTexture(nil, "ARTWORK", 1)
	button.overIcon:SetPoint("BOTTOMLEFT", button, "BOTTOMLEFT", 4, 4)]]

	for k, v in pairs(prototype) do
		button[k] = v
	end

	-- Let Masque skin it
	if not group then
		group = Masque:Group("OPie")
		Masque:Register("OPie", Reskin)
	end
	group:AddButton(button)

	tinsert(buttons, button)
	return button
end

OneRingLib.ext.OPieUI:SetIndicatorConstructor(CreateIndicator)