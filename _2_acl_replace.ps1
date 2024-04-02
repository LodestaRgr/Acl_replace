# !!! ����������� !!! ������� � ������� "��� ���������� ��� ��� ������\��� ������������"
# ������: $SourceUser = "User-PC\user" - ��� ��������� ������������ 
# ������: $TargetUser = "domain\user"     - ��� �������� ������������ (��� "user@domain")

$SourceUser = "wsy07\kiosk"
$TargetUser = "wsy07\it"

cls

# ��������� ������� �� ����� functions.ps1
. ".\___acl_functuons.ps1"

# ������ ����������� ����� JSON
#$elements = Read-JsonFile -Path "elements.json"
$elements = Read-CsvFile -Path "elements.csv"

# ��������� SID ������������
$SID = Get-SID -Username $SourceUser
$SIDnew = Get-SID -Username $TargetUser

if ($SID -eq $false -or $SIDnew -eq $false) {
    Write-Output "������������ �����������!"
    exit 1
}
write-host "������ ������������:`t$SID`t$SourceUser"
write-host "�����  ������������:`t$SIDnew`t$TargetUser`n"

# ����� ���������, ���������� ��������� ������ � SID
$matchingElements = $elements | Where-Object { $_.SID -match $SID }

# ����� ��������������� ��������� �� �����
#$matchingElements

if ($matchingElements -ne $null) {

    Write-Host "������� " $matchingElements.Count " �������a(��).`n"

    # �������� �� ������� ���������� �������� � �������� $SourceUser �� $TargetUser
    foreach ($matchingElement in $matchingElements) {
    
        $currentAcl = Get-Acl -Path $matchingElement.name
        $currentAccessRules = $currentAcl.Access | Where-Object { -not $_.IsInherited } # �������� ������ �� ����������� �����

        $count = 1 # ������� ������ � ��������

        foreach ($currentRule in $currentAccessRules) {
            if ($currentRule.IdentityReference.Value -eq $SourceUser) { # ���� � ������ ������ ������������

                $updatedIdentity = $currentRule.IdentityReference.Value -replace [regex]::Escape($SourceUser), $TargetUser

                $rule = New-Object System.Security.AccessControl.FileSystemAccessRule($updatedIdentity, $currentRule.FileSystemRights, $currentRule.InheritanceFlags, $currentRule.PropagationFlags, $currentRule.AccessControlType)

                if ($currentAcl.RemoveAccessRule($currentRule)) { # �������� ������� ������� � �������� ACL
                    $currentAcl.AddAccessRule($rule) # ��������� ����� ������� � �������� ACL
                } else {
                    Write-host "������ ��� �������� ������� ������� � " $matchingElement.name
                }

                # �������� ���������� ����� ����� �������
                try {
                    Set-Acl -Path $matchingElement.name -AclObject $currentAcl -ErrorAction Stop
                    Write-Host "��������� ������� - $count : `t" $matchingElement.name

                    # ��������� ���������� � ���� $SID �� $SIDnew
                    $elements | Where-Object { $_.name -eq $matchingElement.name } | ForEach-Object { $_.SID = $_.SID -replace $SID, $SIDnew }

                } catch {
                    Write-Host "������ ������� - $count : `t" $matchingElement.name " : $_"
                }

                $count += 1
            }
        }
    }
} else {
    Write-Host "�� ������� �������� � �������������."
    exit 1
}
# ��������� $elements � ���� JSON
#Write-JsonFile -Object $elements -Path "elements.json"
Write-Csv -Object $elements -Path "elements.csv"

Write-Host "`n���������� ���������."