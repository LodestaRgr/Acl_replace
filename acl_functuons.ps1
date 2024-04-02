# Функция для чтения содержимого файла JSON и преобразования его в объект PowerShell
function Read-JsonFile {
    param (
        [string]$Path
    )
    Get-Content -Raw -Path $Path | ConvertFrom-Json
}

# Функция для чтения содержимого файла CSV и преобразования его в объект PowerShell
function Read-CsvFile {
    param (
        [string]$Path
    )
    Import-Csv -Path $Path
}

# Функция для записи объекта PowerShell в базу
function Read-Base {
    param (
        [object]$Object,
        [string]$Path  
    )
    switch ($BaseType) {
        "csv" {
            Read-CsvFile -Path "$BaseName.csv"
        }
        "json" {
            Read-JsonFile -Path "$BaseName.json"
        }
    }

}

# Функция для записи объекта PowerShell в файл JSON
function Write-JsonFile {
    param (
        [object]$Object,
        [string]$Path
    )
    $Object | ConvertTo-Json -Depth 2 -Compress | Set-Content -Path $Path
}

# Функция для записи объекта PowerShell в файл Csv
function Write-Csv {
    param (
        [object]$Object,
        [string]$Path
    )
    $Object | ForEach-Object {
        New-Object PSObject -Property @{
            name = $_.name
            SID  = $_.SID -join ', '
        }
    } | Export-Csv -Path $Path -Encoding UTF8 -NoTypeInformation
}

# Функция для записи объекта PowerShell в базу
function Write-Base {
    param (
        [object]$Object,
        [string]$Path  
    )
    switch ($BaseType) {
        "csv" {
            Write-Csv -Object $Object -Path "$Path.csv"
        }
        "json" {
            Write-JsonFile -Object $Object -Path "$Path.json"
        }
    }

}

# Функция для получения SID пользователя через вызов WinAPI
function Get-SID {
    param (
        [string]$Username
    )

    try {
        $NTAccount = New-Object System.Security.Principal.NTAccount($Username)
        $sid = $NTAccount.Translate([System.Security.Principal.SecurityIdentifier]).Value
        return $sid
    } catch {
        return $false
    }
}

# Функция для проверки, являются ли права доступа унаследованными
function AreAccessRulesInherited($acl) {
    foreach ($ace in $acl.GetAccessRules($true, $true, [System.Security.Principal.SecurityIdentifier])) {
        if (-not $ace.IsInherited) {
            return $false
        }
    }
    return $true
}

# Получить информацию о правах доступа к элементу
function Get-AclInfo {
    param (
        [object]$Acl,
        [string]$Path
    )
    $elements = @()

    # Проверить, если права доступа не наследуются
    if (-not (AreAccessRulesInherited $Acl)) {
        Write-Host $($Path)
        foreach ($Ace in $Acl.GetAccessRules($true, $true, [System.Security.Principal.SecurityIdentifier])) {
            $elements += @{
                name = $($Path)
                SID  = @($($Ace.IdentityReference))
            }
        }
    }

    return $elements
}