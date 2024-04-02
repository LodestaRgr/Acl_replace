param(
    # Пути к директориям, которые нужно просканировать

    [string[]]$directoryPaths = @(".\test-0", ".\test-1"),

    # ------------------------------------------------

    [string]$BaseName = "elements",       # имя файла с базой
    [ValidateSet("csv", "json")]
    [string]$BaseType = "csv"             # формат базы "csv" или "json" - PowerShell v2.0 поддерживается только CSV!
)

cls

# Подгрузка функций из файла functions.ps1
. ".\acl_functuons.ps1"

# Инициализация массива для хранения элементов
$elements = @()

Write-host "Поиск элементов:`n"

# Вызов функции для сканирования каждой директории
foreach ($directoryPath in $directoryPaths) {

    if (Test-Path $directoryPath) {

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
    } else {
        Write-Warning "Элемент $directoryPath не существует и будет пропущена."
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

# Сохраняем $uniqueElementsArray в базу
Write-Base -Object $uniqueElementsArray -Path $BaseName

Write-Host "`nПоиск завершен."