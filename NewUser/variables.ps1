[string]$curDir = Split-Path -Path $myInvocation.MyCommand.Path -Parent

[string]$fullName = "Поварницина Оксана Анатольевна"

[string]$emailMAIL = "DEP-OI@apkbank.apk"
[string]$textMAIL = "Прошу предоставить доступ ко внутренней почте пользователю <b>$fullName</b>, согласно приведенной заявке."

[string]$emailQUORUM = "quorum@apkbank.ru"
[string]$copyUser =  "Морозова Елена Александровна"
[string]$textQUORUM = "Прошу предоставить доступ пользователю <b>$fullName</b>, согласно приведенной заявке.<br>Права можно скопировать с пользователя <b>$copyUser</b>."

[string]$emailRETAIL = "retail@apkbank.ru"
[string]$textRETAIL = "Прошу предоставить доступ пользователю <b>$fullName</b>, согласно приведенной заявке."

[string]$emailCRM = "cred-fo@apkbank.ru"
[string]$textCRM = "Прошу предоставить доступ пользователю <b>$fullName</b>, согласно приведенной заявке."

[string]$emailKK = "cred-fo@apkbank.ru"
[string]$textKK = "Прошу предоставить доступ пользователю <b>$fullName</b> к системе 'Кредитный конвейер', согласно приведенной заявке."

[string]$emailSUVD = "cred-fo@apkbank.ru"
[string]$textSUVD = "Прошу предоставить доступ пользователю <b>$fullName</b> к СУВД, согласно приведенной заявке."

[string]$emailWAY = "plc-kov@apkbank.ru"
[string]$textWAY = "Прошу предоставить доступ новому пользователю <b>$fullName</b>, согласно приведенным заявкам. Прошу дать доступ к <b>WAY4</b> и к <b>sftp</b>."

[string]$mailSMTP = "191.168.6.50"
[string]$mailFrom = "tmn-goe@tmn.apkbank.ru"
[string]$mailCC = "tmn_oit@tmn.apkbank.apk"