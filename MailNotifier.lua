--[[
Copyright 2007-2025 João Cardoso
All Rights Reserved
--]]

local MailNotifier = CreateFrame('Frame', 'MailNotifier')
local FakeEvent, NewMails, AtInbox
local LastAlert = 0

local AUCTION_OUTBID = ERR_AUCTION_OUTBID_S:gsub('%%s', '%.+')
local AUCTION_WON = ERR_AUCTION_WON_S:gsub('%%s', '%.+')
local IS_CLASSIC = MiniMapMailFrame and true
local L = MailNotifier_Locals


--[[ Startup ]]--

function MailNotifier:OnLoad()
	MailNotifier_Senders = MailNotifier_Senders or {}
	MailNotifier_Count = MailNotifier_Count or 0

	self.Frame = MiniMapMailFrame or MinimapCluster.IndicatorFrame.MailFrame
	self.Frame:SetScript('OnEnter', self.OnEnter)

	self.Indicator = self.Frame:CreateFontString(nil, 'OVERLAY')
	self.Indicator:SetPoint('CENTER', self.Frame, 'CENTER', IS_CLASSIC and -1 or 0, IS_CLASSIC and 1 or 0)
	self.Indicator:SetFontObject(IS_CLASSIC and 'NumberFontNormal' or 'NumberFontNormalSmall')
	self.Indicator:SetJustifyH('CENTER')

	local flashParent = CreateFrame('Frame', nil, self.Frame)
	flashParent:SetAlpha(0)

	local shine = flashParent:CreateTexture(nil, 'OVERLAY', nil, 7)
	shine:SetTexture('Interface\\Calendar\\EventNotificationGlow')
	shine:SetPoint('CENTER', self.Frame, 'CENTER', -2, 2)
	shine:SetHeight(35) shine:SetWidth(35)
	shine:SetBlendMode('ADD')

	self.Flasher = flashParent:CreateAnimationGroup()

	for i = 1,4 do
		local fadeIn = self.Flasher:CreateAnimation('Alpha')
		fadeIn:SetDuration(1)
		fadeIn:SetFromAlpha(0)
		fadeIn:SetToAlpha(1)
		fadeIn:SetOrder(i*2)

		local fadeOut = self.Flasher:CreateAnimation('Alpha')
		fadeOut:SetDuration(1)
		fadeOut:SetFromAlpha(0)
		fadeOut:SetToAlpha(1)
		fadeOut:SetOrder(i*2+1)
	end
	
	self:SetScript('OnEvent', function(self, event, ...) self[event](self, ...) end)
	self:RegisterEvent('PLAYER_LOGOUT')
	self.Startup = nil

	EventUtil.RegisterOnceFrameEventAndCallback('UPDATE_PENDING_MAIL', function()
		GetLatestThreeSenders() -- Query the server
		HasNewMail() -- Query the server

		C_Timer.After(5, function()
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
			self:RegisterEvent('UPDATE_PENDING_MAIL')
			self:RegisterEvent('MAIL_INBOX_UPDATE')
			self:RegisterEvent('CHAT_MSG_SYSTEM')
			self:RegisterEvent('MAIL_CLOSED')
		end)
	end)
end


--[[ Inbox ]]--

function MailNotifier:UPDATE_PENDING_MAIL()
	if FakeEvent or AtInbox then
		FakeEvent = nil
	elseif HasNewMail() then
		self:AddNewMail(1)
	end
end

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
			PlaySoundFile('Interface/AddOns/MailNotifier/Media/NewMail.mp3')
		end
		
		LastAlert = time + 15
		self.Flasher:Play()
	end

	self:SetNumMails(self:GetNumMails() + new)
end

function MailNotifier:SetNumMails(value)
	MailNotifier_Count = max(value or MailNotifier_Count or 0, HasNewMail() and 1 or 0 , select('#', GetLatestThreeSenders()))
	self.Indicator:SetText(MailNotifier_Count or '')

	if GameTooltip:IsOwned(self.Frame) then
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

MailNotifier:OnLoad()