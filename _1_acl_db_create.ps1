# Пути к директориям, которые нужно просканировать
#$directoryPaths = @("C:\Users", "D:\")
$directoryPaths = @(".\test2",".\test3")

cls

# Подгрузка функций из файла functions.ps1
. ".\___acl_functuons.ps1"

# Функция для проверки, являются ли права доступа унаследованными
function AreAccessRulesInherited($acl) {
    foreach ($ace in $acl.GetAccessRules($true, $true, [System.Security.Principal.SecurityIdentifier])) {
        if (-not $ace.IsInherited) {
            return $false
        }
    }
    return $true
}

# Инициализация массива для хранения элементов
$elements = @()

Write-host "Поиск элементов:`n"

# Вызов функции для сканирования каждой директории
foreach ($directoryPath in $directoryPaths) {

    #Получить нолный путь к элементу
    $directoryPath = Get-Item $directoryPath | Select-Object -ExpandProperty FullName

    # Получить информацию о правах доступа к самой директории test2
    $acl = [System.IO.Directory]::GetAccessControl($directoryPath)

    $elements += Get-AclInfo -Acl $acl -Path $directoryPath

    # Рекурсивно просканировать директорию, начиная с самой папки test2, и получить информацию о правах доступа для элементов
    Get-ChildItem -Path $directoryPath -Recurse -ErrorAction SilentlyContinue | ForEach-Object {
        $item = $_
        $acl = $null
        if ($item.Attributes -eq 'Directory') {
            $acl = [System.IO.Directory]::GetAccessControl($item.FullName)
        } else {
            $acl = [System.IO.File]::GetAccessControl($item.FullName)
        }

        $elements += Get-AclInfo -Acl $acl -Path $item.FullName
    }

}

# Убираем дублирующиеся SID в каждом элементе
$uniqueElements = @{}
foreach ($element in $elements) {   
    if ($element.name -and $element.SID) {
        $uniqueElements[$element.name] = @($uniqueElements[$element.name] + $element.SID | Select-Object -Unique)
    }
}

# Формируем новый массив элементов без дублирующихся SID
$uniqueElementsArray = foreach ($name in $uniqueElements.Keys) {
    New-Object PSObject -Property @{
        name = $name
        SID  = $uniqueElements[$name]
    }
}

#$uniqueElementsArray

# Сохраняем $uniqueElementsArray в файл JSON
#Write-JsonFile -Object $uniqueElementsArray -Path "elements.json"
Write-Csv -Object $uniqueElementsArray -Path "elements.csv"

Write-Host "`nПоиск завершен."