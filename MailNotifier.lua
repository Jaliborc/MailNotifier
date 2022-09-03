--[[
Copyright 2007-2022 João Cardoso
MailNotifier is distributed under the terms of the GNU General Public License (or the Lesser GPL).
This file is part of MailNotifier.

MailNotifier is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

MailNotifier is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with MailNotifier. If not, see <http://www.gnu.org/licenses/>.
--]]

local MailNotifier = CreateFrame('Frame', 'MailNotifier')
local Parent, Indicator, Shine, Flasher

local FakeEvent, NewMails, AtInbox
local LastAlert, StartDelay = 0

local L = MailNotifier_Locals
local AUCTION_OUTBID = ERR_AUCTION_OUTBID_S:gsub('%%s', '%.+')
local AUCTION_WON = ERR_AUCTION_WON_S:gsub('%%s', '%.+')


--[[ Startup ]]--

function MailNotifier:Startup()
	MiniMapMailFrame:SetScript('OnEnter', self.OnEnter)
	MiniMapMailFrame:SetScript('OnEvent', nil)

	MailNotifier_Senders = MailNotifier_Senders or {}
	MailNotifier_Count = MailNotifier_Count or 0

	Indicator = MiniMapMailFrame:CreateFontString('MailNotifierIndicator', 'OVERLAY')
	Indicator:SetFontObject('NumberFontNormal')
	Indicator:SetPoint('CENTER', MiniMapMailFrame, 'CENTER', -1, 1)
	Indicator:SetJustifyH('CENTER')

	Parent = CreateFrame('Frame', 'MailNotifierFrame', MiniMapMailFrame)
	Parent:SetAlpha(0)
	Flasher = Parent:CreateAnimationGroup()

	Shine = Parent:CreateTexture('MailNotifierShine', 'OVERLAY', 8)
	Shine:SetTexture('Interface\\Calendar\\EventNotificationGlow')
	Shine:SetPoint('CENTER', MiniMapMailFrame, 'CENTER', -2, 2)
	Shine:SetHeight(35) Shine:SetWidth(35)
	Shine:SetBlendMode('ADD')

	for i = 1,4 do
		local fadeIn = Flasher:CreateAnimation('Alpha')
		fadeIn:SetDuration(1)
		fadeIn:SetFromAlpha(0)
		fadeIn:SetToAlpha(1)
		fadeIn:SetOrder(i*2)

		local fadeOut = Flasher:CreateAnimation('Alpha')
		fadeOut:SetDuration(1)
		fadeOut:SetFromAlpha(0)
		fadeOut:SetToAlpha(1)
		fadeOut:SetOrder(i*2+1)
	end
	
	self:SetScript('OnEvent', function(self, event, ...) self[event](self, ...) end)
	self:RegisterEvent('UPDATE_PENDING_MAIL')
	self:RegisterEvent('PLAYER_LOGOUT')
	self.Startup = nil
end

function MailNotifier:UPDATE_PENDING_MAIL()
	StartDelay = GetTime() + 5
	GetLatestThreeSenders() -- Query the server
	MiniMapMailFrame:SetShown(HasNewMail()) -- Query the server

	self:SetScript('OnUpdate', self.Initialize)
	self:SetNumMails()
end

function MailNotifier:Initialize()
	local time = GetTime()
	if time > StartDelay then
		if HasNewMail() and not AtInbox then
			local newMails = 0
			for newI, sender in pairs({GetLatestThreeSenders()}) do
				local oldI, off = MailNotifier_Senders[sender] or 0
				if newI >= oldI then
					off = newI - oldI
				else
					off = 3 - oldI + newI
				end
					
				newMails = max(newMails, off)
			end
			
			self:AddNewMail(newMails)
		else
			self:SetNumMails()
		end
		
		self:RegisterEvent('PLAYER_ENTERING_WORLD')
		self:RegisterEvent('MAIL_INBOX_UPDATE')
		self:RegisterEvent('CHAT_MSG_SYSTEM')
		self:RegisterEvent('MAIL_CLOSED')
		self:SetScript('OnUpdate', nil)
		self.Initialize = nil
		
		function self:UPDATE_PENDING_MAIL()
			MiniMapMailFrame:SetShown(HasNewMail())

			if FakeEvent or AtInbox then
				FakeEvent = nil
			elseif HasNewMail() then
				self:AddNewMail(1)
			end
		end
	end
end


--[[ Inbox ]]--

function MailNotifier:MAIL_INBOX_UPDATE()
	local newMails = 0
	for i = 1, GetInboxNumItems() do
		if not select(9, GetInboxHeaderInfo(i)) then
			newMails = newMails + 1
		end
	end
	self:SetNumMails(newMails)
	
	if not AtInbox then
		NewMails = self:GetNumMails()
		AtInbox = true
	elseif self:GetNumMails() ~= NewMails then
		FakeEvent = true
	end
end

function MailNotifier:MAIL_CLOSED()
	AtInbox = nil
end


--[[ Other Events ]]--

function MailNotifier:PLAYER_ENTERING_WORLD()
	FakeEvent = true
end

function MailNotifier:CHAT_MSG_SYSTEM(message)
	if strmatch(message, AUCTION_OUTBID) then
		self:UPDATE_PENDING_MAIL()
	elseif message == ERR_AUCTION_REMOVED or strmatch(message, AUCTION_WON) then
		FakeEvent = true
	end
end  

function MailNotifier:PLAYER_LOGOUT()
	local s1, s2, s3 = GetLatestThreeSenders()
	MailNotifier_Senders = {
		[s1 or ''] = 1,
		[s2 or ''] = 2,
		[s3 or ''] = 3,
	}
end


--[[ API ]]--

function MailNotifier:AddNewMail(new)
	local time = GetTime()
	if new > 0 and time > LastAlert then
		if not MailNotifier_DisableSound then
			PlaySoundFile('Interface\\AddOns\\MailNotifier\\NewMail.mp3')
		end
		
		LastAlert = time + 15
		Flasher:Play()
	end

	self:SetNumMails(self:GetNumMails() + new)
end

function MailNotifier:SetNumMails(value)
	MailNotifier_Count = max(value or MailNotifier_Count or 0, HasNewMail() and 1 or 0 , select('#', GetLatestThreeSenders()))
	Indicator:SetText(MailNotifier_Count or '')

	if GameTooltip:IsOwned(MiniMapMailFrame) then
		self:UpdateTip()
	end
end

function MailNotifier:GetNumMails()
	return MailNotifier_Count
end


--[[ Tootlip ]]--

function MailNotifier:OnEnter()
	GameTooltip:SetOwner(self, 'ANCHOR_BOTTOMLEFT')
	MailNotifier:UpdateTip()
end

function MailNotifier:UpdateTip()
	local numMails = MailNotifier:GetNumMails()
	local senders = {GetLatestThreeSenders()}
	local title
	
	if numMails ~= 1 then
		title = L.HaveMails
	else
		title = L.HaveMail
	end
			
	if #senders > 0 then
		title = title .. L.From
	end
	
	GameTooltip:SetText(format(title, numMails))
	
	for i,sender in pairs(senders) do
		GameTooltip:AddLine(' - ' .. sender, 1, 1, 1)
	end
	
	GameTooltip:Show()
end


--[[ Start Addon ]]--

MailNotifier:Startup()