# ������� ��� ������ ����������� ����� JSON � �������������� ��� � ������ PowerShell
function Read-JsonFile {
    param (
        [string]$Path
    )
    Get-Content -Raw -Path $Path | ConvertFrom-Json
}

# ������� ��� ������ ����������� ����� CSV � �������������� ��� � ������ PowerShell
function Read-CsvFile {
    param (
        [string]$Path
    )
    Import-Csv -Path $Path
}

# ������� ��� ������ ������� PowerShell � ���� JSON
function Write-JsonFile {
    param (
        [object]$Object,
        [string]$Path
    )
    $Object | ConvertTo-Json -Depth 2 -Compress | Set-Content -Path $Path
}

# ������� ��� ������ ������� PowerShell � ���� Csv
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

# ������� ��� ��������� SID ������������ ����� ����� WinAPI
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

# �������� ���������� � ������ ������� � ��������
function Get-AclInfo {
    param (
        [object]$Acl,
        [string]$Path
    )
    $elements = @()

    # ���������, ���� ����� ������� �� �����������
    if (-not (AreAccessRulesInherited $Acl)) {
        #Write-Host $($Path)
        foreach ($Ace in $Acl.GetAccessRules($true, $true, [System.Security.Principal.SecurityIdentifier])) {
            $elements += @{
                name = $($Path)
                SID  = @($($Ace.IdentityReference))
            }
        }
    }

    return $elements
}