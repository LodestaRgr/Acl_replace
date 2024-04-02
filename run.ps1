#Создание базы для проверки
. ".\acl_create_db.ps1" -directoryPaths ".\test2", ".\test3"

sleep 10

#Смена пользователя kiosk на it
. ".\acl_replace.ps1" -SourceUser "wsy07\kiosk" -TargetUser "wsy07\it"

sleep 10

#Смена пользователя it на kiosk
. ".\acl_replace.ps1" -SourceUser "wsy07\it" -TargetUser "wsy07\kiosk"