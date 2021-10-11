function admin {
    if (([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    }else{
        Write-Host "$computerName : --Tu n'as les droits admins"
        pause
    }
}
function fichier_existe {
    param (
    $file
    )
    
    if (Test-Path -Path $file){
    }
    else{
        Write-Host "erreur le fichier $file exite pas"
        pause
    }
}

function excel_statistiques {
    param(
    $statistiques,
    $All_PC_liste
    )
    $Liste = Import-Csv -Path $All_PC_liste
    $objExcel = New-Object -com Excel.Application
    $objExcel.Visible = $false
    $WorkBook = $objExcel.Workbooks.Open($statistiques)
    $?
    $WorkSheet = $WorkBook.Sheets.Item(2)
    $?
    $i = 2 
    foreach($Ligne in $Liste) { 
        Write-Host $Ligne
        $Ligne.PC
        $WorkSheet.cells.item($i,1) = $Ligne.PC
        $WorkSheet.cells.item($i,2) = $Ligne.Code
        $i++ 
    }

    $WorkBook.Save()
    $WorkBook.Close()
    $objExcel.Quit()
}

$ErrorActionPreference= 'silentlycontinue'
admin
$folder = "[YOUR_FOLDER]"
Set-Location $folder
fichier_existe -file "modifier_moi.txt"
$Liste_PC = ".\Liste_PC.csv"
fichier_existe -file $Liste_PC
$script = "$folder.\BIOS_HP_UPDATE_AUTO.ps1"
fichier_existe -file $script
$date = Get-Date -Format "dd-MM-yyyy"
if (Test-Path -Path ".\rapport\$date" ){
}else{
    Remove-Item ".\rapport\$date" -Force
}
mkdir ".\rapport\$date"
Copy-Item ".\rapport\model\*" ".\rapport\$date\"

Import-Csv $Liste_PC | ForEach-Object {
    $i ++
    $PC = $($_.PC)
    Start-Job -ScriptBlock {
        PowerShell.exe -Command $args[0] -computerName $args[1] -folder $args[2] -date $args[3]
    } -ArgumentList $script, $PC, $folder, $date
}

Get-Job | Wait-Job
Set-Location "rapport\$date"
$statistiques = "statistiques.xlsx"
$All_PC = "All_PC.csv"

excel_statistiques -statistiques "$folder\rapport\$date\$statistiques" -All_PC_liste $All_PC
Move-Item "..\..\Liste_PC.csv" "Liste_PC.csv" -Force
Copy-Item "All_error.csv" "..\..\Liste_PC.csv"
Set-Location "..\.."
Get-Job | Receive-Job