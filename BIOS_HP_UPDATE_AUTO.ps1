param (
$computerName,
$folder,
$date
)
Set-Location $folder
$newpassword_BIOS = (Get-Content "modifier_moi.txt" -Encoding UTF8)[1]
$oldpassword_BIOS = (Get-Content "modifier_moi.txt" -Encoding UTF8)[3]
$old2password_BIOS = (Get-Content "modifier_moi.txt" -Encoding UTF8)[5]
$password_LOCAL_ADMIN = (Get-Content "modifier_moi.txt" -Encoding UTF8)[7]

function export_csv{
    param (
    $computerName,
    $code,
    $date
    )
    Write-Host $computerName $code
    $date
    $fileCSV = "rapport\$date\All_PC.csv"
    $NewLine = "{0},{1}" -f $computerName,$code
    $NewLine | add-content -path $fileCSV
}
function error_export_csv
{
    param (
        $computerName,
        $date
    )
    $fileCSV_Error = "rapport\$date\All_error.csv"
    $NewLine = "{0}" -f $computerName
    $NewLine | add-content -path $fileCSV_Error
}

function admin {
    param (
        $computerName,
        $date
    )    
    if (([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    }else{
        Write-Host "$computerName : --Tu n'as les droits admins"
        export_csv -computerName $computerName -date $date -code "ErrorAdmin"
        error_export_csv -computerName $computerName -date $date 
        Exit
    }
}

function Ping_Computer {
    param (
        $computerName,
        $date
    )
    Test-Connection $computerName -Count 1
    if ($?) {
        Write-Host "$computerName : ping Ok"
    }else{
        Write-Host "$computerName : --Error ping"
        export_csv -computerName $computerName -date $date -code "ErrorPing"
        error_export_csv -computerName $computerName -date $date
        Exit
    }
}

function VPN_status {
    param (
        $computerName,
        $date
    )


    VPN = Get-WmiObject win32_networkadapter -Filter "ServiceName='vna_ap'"
    $network = Get-WmiObject win32_networkadapter -Filter "netconnectionstatus = 2"

    if ($network -contains $VPN) 
    {
        Write-Host "$computerName : --Error VPN activer"
        export_csv -computerName $computerName -date $date -code "ErrorVPN"
        error_export_csv -computerName $computerName -date $date 
        Exit
       
    }else {
        Write-Host "$computerName : VPN dessactiver"
    }
}

function password_administrator_local {
    param (
        $computerName,
        $localpassword,
        $date
    )
    $objAdminUser = [ADSI]"WinNT://$computerName/Administrateur,user"
    $objAdminUser.setPassword($localpassword)
    if ($?)
    {
        Write-Host "$computerName : Le mot de passe a été changé"
    }else{
        Write-Host "$computerName : Le mot de passe n'a pas été changé"
        export_csv -computerName $computerName -date $date -code "ErrorAdmLocal"
        error_export_csv -computerName $computerName -date $date
        Exit
    }
}

function password_BIOS {
    param (
        $computerName,
        $newpassword,
        $oldpassword
    )
    $Interface = Get-WmiObject -computername $computerName -Namespace root/hp/InstrumentedBIOS -Class HP_BIOSSettingInterface
    $Execute_Change_Action = $Interface.SetBIOSSetting("Setup Password","<utf-16/>" + $newpassword,"<utf-16/>" + $oldpassword)
    $Return_Code = $Execute_Change_Action.return
    If(($Return_Code) -eq 0) {
        Write-Host "mdp ok"
        return $true
    }else {
        Write-Host "mdp error"
        return $false
    }
}

function password_BIOS_2 {
    param (
        $computerName,
        $newpassword
    )
    $Interface = Get-WmiObject -computername $computerName -Namespace root/hp/InstrumentedBIOS -Class HP_BIOSSettingInterface
    $Execute_Change_Action2 = $Interface.SetBIOSSetting("Setup Password","<utf-16/>" + $newpassword,"<utf-16/>" + $newpassword)
    $Return_Code2 = $Execute_Change_Action2.return
    If(($Return_Code2) -eq 0) {
        Write-Host "mdp ok"
        return $true
    }else {
        Write-Host "mdp error"
        return $false
    }
}

function password_BIOS_3 {
    param (
        $computerName,
        $newpassword,
        $old2password
    )
    $Interface = Get-WmiObject -computername $computerName -Namespace root/hp/InstrumentedBIOS -Class HP_BIOSSettingInterface
    $Execute_Change_Action3 = $Interface.SetBIOSSetting("Setup Password","<utf-16/>" + $newpassword,"<utf-16/>" + $old2password)
    $Return_Code3 = $Execute_Change_Action3.return
    If(($Return_Code3) -eq 0) {
        Write-Host "mdp ok"
        return $true
    }else {
        Write-Host "mdp error"
        return $false

    }
}

function BIOS_setting {
    param (
        $computerName,
        $newpassword,
        $date
    )
    $Interface = Get-WmiObject -computername $computerName -Namespace root/hp/InstrumentedBIOS -Class HP_BIOSSettingInterface
    $BIOSPassword = "<utf-16/>"+$newpassword
    $Execute_Change_Action_USB = $Interface.SetBIOSSetting('USB Storage Boot','Disable',$BIOSPassword)
    $Return_Code_USB = $Execute_Change_Action_USB.return
    $Execute_Change_Action_WOL = $Interface.SetBIOSSetting('Wake On LAN','Boot to Hard Drive',$BIOSPassword)
    $Return_Code_WOL = $Execute_Change_Action_WOL.return
    $Execute_Change_Action_PXE = $Interface.SetBIOSSetting('Network (PXE) Boot','Disable',$BIOSPassword)
    $Return_Code_PXE = $Execute_Change_Action_PXE.return
    If(($Return_Code_USB) -eq 0 -and ($Return_Code_WOL) -eq 0 -and ($Return_Code_PXE) -eq 0){
        Write-Host "BIOS setting ok"
    }else{
        Write-Host "BIOS setting errro"
        export_csv -computerName $computerName -date $date -code "ErrorSettingBIOS"
        error_export_csv -computerName $computerName -date $date
        Exit
    }
}


$ErrorActionPreference= 'silentlycontinue'
admin -computerName $computerName
Ping_Computer -computerName $computerName -date $date
VPN_status -computerName $computerName -date $date
password_administrator_local -computerName $computerName -localpassword $password_LOCAL_ADMIN -date $date

update_password_bios = password_BIOS -computerName $computerName -newpassword $newpassword_BIOS -oldpassword $oldpassword_BIOS
if (update_password_bios -eq $false){
    update_password_bios2 = password_BIOS_2 -computerName $computerName -newpassword $newpassword_BIOS
    if (update_password_bios2 -eq $false){
        update_password_bios3 = password_BIOS_3 -computerName $computerName -newpassword $newpassword_BIOS -old2password $old2password_BIOS
        if (update_password_bios3 -eq $false){
            export_csv -computerName $computerName -date $date -code "ErrorPwdBIOS"
            error_export_csv -computerName $computerName -date $date
            Exit
        }

    }
}
BIOS_setting -computerName $computerName -newpassword $newpassword_BIOS -date $date
export_csv -computerName $computerName -date $date -code "GOOD"