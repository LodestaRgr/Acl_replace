# !!! Обязательно !!! указать в формате "Имя компьютера или имя домена\Имя пользователя"
# пример: $SourceUser = "User-PC\user" - это локальный пользователь 
# пример: $TargetUser = "domain\user"     - это доменный пользователь (или "user@domain")

$SourceUser = "wsy07\kiosk"
$TargetUser = "wsy07\it"

cls

# Подгрузка функций из файла functions.ps1
. ".\___acl_functuons.ps1"

# Чтение содержимого файла JSON
#$elements = Read-JsonFile -Path "elements.json"
$elements = Read-CsvFile -Path "elements.csv"

# Получение SID пользователя
$SID = Get-SID -Username $SourceUser
$SIDnew = Get-SID -Username $TargetUser

if ($SID -eq $false -or $SIDnew -eq $false) {
    Write-Output "Пользователь отсутствует!"
    exit 1
}
write-host "Старый пользователь:`t$SID`t$SourceUser"
write-host "Новый  пользователь:`t$SIDnew`t$TargetUser`n"

# Поиск элементов, содержащих указанную строку в SID
$matchingElements = $elements | Where-Object { $_.SID -match $SID }

# Вывод соответствующих элементов на экран
#$matchingElements

if ($matchingElements -ne $null) {

    Write-Host "Найдено " $matchingElements.Count " элементa(ов).`n"

    # Проходим по каждому найденному элементу и заменяем $SourceUser на $TargetUser
    foreach ($matchingElement in $matchingElements) {
    
        $currentAcl = Get-Acl -Path $matchingElement.name
        $currentAccessRules = $currentAcl.Access | Where-Object { -not $_.IsInherited } # получить только не наследуемые права

        $count = 1 # счетчик правил в элементе

        foreach ($currentRule in $currentAccessRules) {
            if ($currentRule.IdentityReference.Value -eq $SourceUser) { # если в правах найден пользователь

                $updatedIdentity = $currentRule.IdentityReference.Value -replace [regex]::Escape($SourceUser), $TargetUser

                $rule = New-Object System.Security.AccessControl.FileSystemAccessRule($updatedIdentity, $currentRule.FileSystemRights, $currentRule.InheritanceFlags, $currentRule.PropagationFlags, $currentRule.AccessControlType)

                if ($currentAcl.RemoveAccessRule($currentRule)) { # удаления старого правила к текущему ACL
                    $currentAcl.AddAccessRule($rule) # добавляем новое правило к текущему ACL
                } else {
                    Write-host "Ошибка при удалении старого правила в " $matchingElement.name
                }

                # Пытаемся установить новые права доступа
                try {
                    Set-Acl -Path $matchingElement.name -AclObject $currentAcl -ErrorAction Stop
                    Write-Host "Обновлено правило - $count : `t" $matchingElement.name

                    # Обновляем информацию в базе $SID на $SIDnew
                    $elements | Where-Object { $_.name -eq $matchingElement.name } | ForEach-Object { $_.SID = $_.SID -replace $SID, $SIDnew }

                } catch {
                    Write-Host "Ошибка правила - $count : `t" $matchingElement.name " : $_"
                }

                $count += 1
            }
        }
    }
} else {
    Write-Host "Не найдены элементы с пользователем."
    exit 1
}
# Сохраняем $elements в файл JSON
#Write-JsonFile -Object $elements -Path "elements.json"
Write-Csv -Object $elements -Path "elements.csv"

Write-Host "`nОбновление завершено."