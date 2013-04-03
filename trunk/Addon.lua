--[[------------------------------------------------------
	OPie Masque
	Adds Masque skinning support to OPie.
	Written by Phanx <addons@phanx.net>
	See the accompanying README file for more information.
	http://www.wowinterface.com/downloads/info22226-OPieMasque.html
	http://www.curse.com/addons/wow/opie-masque/
----------------------------------------------------------------------]]

assert(OneRingLib, "OneRingLib not found")
assert(OneRingLib.ext, "OneRingLib.ext not found")
assert(OneRingLib.ext.OPieUI, "OneRingLib.ext.OPieUI not found")

local Masque = LibStub("Masque", true)
assert(Masque, "Masque not found")

local id
local group
local buttons = {} _G.obuttons=buttons
local prototype = {}

function prototype:SetIcon(texture)
	self.icon:SetTexture(texture)
end

function prototype:SetIconTexCoord(...)
	self.icon:SetTexCoord(...)
end

function prototype:SetIconVertexColor(r, g, b)
	if r == 0.5 and g == 0.5 and b == 0.5 then return end -- don't let OPie darken icons on cooldown
	self.icon:SetVertexColor(r, g, b)
end

function prototype:SetDominantColor(r, g, b)
	self.border:SetShown(floor(r + 0.5) ~= 1 or floor(g + 0.5) ~= 1 or floor(b + 0.5) ~= 1) -- don't override skin color if it's white
	self.border:SetVertexColor(r, g, b)
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

function prototype:SetBindingText(text)
	self.hotkey:SetText(text or "")
end

function prototype:SetCooldown(remain, duration, usable)
	if duration and remain and duration > 0 and remain > 0 then
		local start = GetTime() + remain - duration
		self.cooldown:SetCooldown(start, duration)
		self.cooldown:Show()
	else
		self.cooldown:Hide()
	end
end

function prototype:SetCooldownFormattedText(pattern, ...)
	-- Do nothing, let OmniCC handle it
end

function prototype:SetHighlighted(highlight)
	self[highlight and "LockHighlight" or "UnlockHighlight"](self)
	self:GetPushedTexture():SetShown(highlight)
end

function prototype:SetActive(active)
	self:SetChecked(active)
end

function prototype:SetOuterGlow(shown)
	for i = 1, #self.glowTextures do
		self.glowTextures[i]:SetShown(shown)
	end
end

local function Reskin()
	for _, button in pairs(buttons) do
		local r, g, b = button.glowTextures[1]:GetVertexColor()
		local _, _, _, a = button.border:GetVertexColor()
		button.border:SetVertexColor(r, g, b, a)
	end
end

local id = 1

local function CreateIndicator(name, parent, size, ghost)
	name = name or "OPieSliceButton"..id
	parent = parent or UIParent
	size = size or 36
	id = id + 1

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

	--[[ Cooldown text
	button.cdText = button:CreateFontString(nil, "OVERLAY", "NumberFontNormalHuge")
	button.cdText:SetPoint("CENTER")]]

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