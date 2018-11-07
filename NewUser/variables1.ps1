[string]$curDir = Split-Path -Path $myInvocation.MyCommand.Path -Parent

[string]$fullName = "Гребенёв Олег Евгеньевич"

[string]$emailMAIL = "tmn-goe@tmn.apkbank.ru"
[string]$textMAIL = "Прошу предоставить доступ ко внутренней почте пользователю <b>$fullName</b>, согласно приведенной заявке."

[string]$emailQUORUM = "tmn-goe@tmn.apkbank.ru"
[string]$copyUser =  "Назаренко Владимир Анатольевич"
[string]$textQUORUM = "Прошу предоставить доступ ко внутренней почте пользователю <b>$fullName</b>, согласно приведенной заявке.<br>Права можно скопировать с пользователя <b>$copyUser</b>."

[string]$emailRETAIL = "tmn-goe@tmn.apkbank.ru"
[string]$textRETAIL = "Прошу предоставить доступ пользователю <b>$fullName</b>, согласно приведенной заявке."

[string]$emailSUVD = "tmn-goe@tmn.apkbank.ru"
[string]$textSUVD = "Прошу предоставить доступ пользователю <b>$fullName</b> к СУВД, согласно приведенной заявке."

[string]$emailCRM = "tmn-goe@tmn.apkbank.ru"
[string]$textCRM = "Прошу предоставить доступ пользователю <b>$fullName</b>, согласно приведенной заявке."

[string]$emailWAY = "tmn-goe@tmn.apkbank.ru"
[string]$textWAY = "Прошу предоставить доступ новому пользователю <b>$fullName</b>, согласно приведенным заявкам. Прошу дать доступ к <b>WAY4</b> и к <b>sftp</b>."

[string]$mailSMTP = "191.168.6.50"
[string]$mailFrom = "tmn-goe@tmn.apkbank.ru"
[string]$mailCC = "tmn-goe@tmn.apkbank.ru"