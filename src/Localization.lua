MailNotifier_Locals = {}
local L = MailNotifier_Locals
local Language = GetLocale()

-- Simplified Chinese --
if Language == 'zhCN' then
	L.HaveMail = '你有大约 %s 封未读邮件'
	L.HaveMails = '你有大约 %s 封未读邮件'
	L.From = ' 来自:'

-- Traditional Chinese --
elseif Language == 'zhTW' then
	L.HaveMail = '你有大約 %s 封未讀郵件'
	L.HaveMails = '你有大約 %s 封未讀郵件'
	L.From = ' 來自:'

-- Korean --
elseif Language == 'koKR' then
	L.From = '.'
	L.HaveMail = '%s개의 신규 우편이 있습니다'
	L.HaveMails = '%s개의 신규 우편이 있습니다'

-- German --
elseif Language == 'deDE' then
	L.HaveMail = 'Du hast %s ungelesenen Brief'
	L.HaveMails = 'Du hast %s ungelesene Briefe'
	L.From = 'von:'
	
-- Spanish --
elseif Language == 'esES' or Language == 'esMX' then
	L.HaveMail = 'Tienes %s mensaje sin leer'
	L.HaveMails = 'Tienes %s mensajes sin leer'
	L.From = ' de:'
	
-- French --
elseif Language == 'frFR' then
	L.HaveMail = 'Vous avez %s message non lu' 
	L.HaveMails = 'Vous avez %s messages non lus' 
	L.From = ' de:' 
	
-- Russian -- ZamestoTV
elseif Language == 'ruRU' then
	L.HaveMail = 'У вас примерно %s непрочитанное письмо'
	L.HaveMails = 'У вас примерно %s непрочитанных писем'
	L.From = ' от:'
	
-- English --
else
	L.HaveMail = 'You have about %s unread mail'
	L.HaveMails = 'You have about %s unread mails'
	L.From = ' from:'
end
