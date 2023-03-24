#Script de la CAF de seine et marne (77).
#Réalisé par Théo PAYEN

<#
                Info script

Ce script permet de modifier les mots de passe BIOS et de désactiver le démarrage sur le port USB sur une liste de PC dans le fichier Liste_PC.cvs .
Les mots de passe BIOS doivent être connus avant de pouvoir être modifier.
Le script est réservé aux ordinateurs HP.
Le script ne fonctionne pas sur des postes en connexion VPN.
Le Mdp de l'ordinateur ne peut être changé que 3 fois au maximum, pour faire une nouvelle tentative il faut redémarrer le PC.

* dans notre cas nous testons les MDP suivant voir ligne 23, 25, 28

Le script désactive le démarage sur le port USB.
il modifiera aussi le mots de passe de l'admistrateur local voir ligne 36

un dossier avec la date du jour sera créé avec dedans plusieurs fichiers en fonction du résultat du script 
rapport/*datedujour*/***.cvs

le fichier avec toutes les erreurs sera copié et renommé en Liste_PC.csv à la racine du script *
pour permettre d'exécuter le script toute les 24 h sans prendre en compte les PC avec le MDP BIOS à jour
#>

# new = Nouveau mot de passe BIOS à Définir
$newpassword = "your_new_password"
# old = l'ancien mot de passe BIOS à remplacer
$oldpassword = "your_old_password"
# fail = 2 ème mdp possible a remplacer 
# dans notre cas le MDP BIOS a été mal taper (les nombre tel que 1234567890 par &é"'(-èè_çà )
$failpassword = "your_old_2_password"
# Fichier excel avec la liste des ordinateurs
$file_Excel = ".\Liste_PC.csv"
#Mdp administrateur local
#/!\ne pas changer les guillemets sinon le script ne prendra pas correctement en compte le mdp
$password_adm_local = 'your_password_local_admin_PC'
$i = 0
##################
# Les tableaux
###################
$MDP_GOOD = @()
$MDP_ERROR = @()
$USB_GOOD = @()
$USB_ERROR = @()
$PXE_GOOD = @()
$PXE_ERROR = @()
$WOL_GOOD = @()
$WOL_ERROR = @()
$MDP_LOCAL_GOOD = @()
$MDP_LOCAL_ERROR = @()
$ip = @()
$ALL_ERROR = @()
##################
# Les tableaux pour l'export fichier CSV
###################
$CSV_MDP_GOOD = @()
$CSV_MDP_ERROR = @()
$CSV_USB_GOOD = @()
$CSV_USB_ERROR = @()
$CSV_PXE_GOOD = @()
$CSV_PXE_ERROR = @()
$CSV_WOL_GOOD = @()
$CSV_WOL_ERROR = @()
$CSV_IP_ERROR = @()
$CSV_ALL_ERROR = @()
$CSV_MDP_LOCAL_GOOD = @()
$CSV_MDP_LOCAL_ERROR = @()

if (([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) 
{
    Write-Host -ForegroundColor green "##########################"
    Write-Host -ForegroundColor green "#Tu as les droits admins #"
    Write-Host -ForegroundColor green "##########################"

    Set-Location "Your_folder"

    Import-Csv $file_Excel | ForEach-Object {
        $computerName = $($_.PC)
        write-host "$($i++) $computerName"
        #test connexion
        # ping 2 tentative /!\ attention les tests de ping vont ralentir fortement le script
        $testconnection = Test-Connection $computerName -Count 2

        if ($testconnection -ne $null) 
        {
            Write-Host "$computerName connecter"

            #################################
            # Connexion au BIOS $computerName 
            #################################

            $Interface = Get-WmiObject -computername $computerName -Namespace root/hp/InstrumentedBIOS -Class HP_BIOSSettingInterface

            ########################
            #Changement des mdp BIOS
            ########################

            $Execute_Change_Action = $Interface.SetBIOSSetting("Setup Password","<utf-16/>" + $newpassword,"<utf-16/>" + $oldpassword)
            $Execute_Change_Action2 = $Interface.SetBIOSSetting("Setup Password","<utf-16/>" + $newpassword,"<utf-16/>" + $newpassword)
            $Execute_Change_Action3 = $Interface.SetBIOSSetting("Setup Password","<utf-16/>" + $newpassword,"<utf-16/>" + $failpassword)
        
            $Return_Code = $Execute_Change_Action.return
            $Return_Code2 = $Execute_Change_Action2.return
            $Return_Code3 = $Execute_Change_Action3.return

            ##
            #si l'execution du script n'a pas rencontré de problème ( CODE 0 )
            ##
            If(($Return_Code) -eq 0)        
            {
                $Export_CSV_MDP_GOOD = 1
                $MDP_GOOD += (,@("$computerName") | Out-String).Trim()
                Write-host -FORE green "$computerName OK ==> CODE : $Return_Code"

                #désactiver le boot sur le port USB
                $BIOSPassword = "<utf-16/>"+$newpassword
                $Execute_Change_Action_USB = $Interface.SetBIOSSetting('USB Storage Boot','Disable',$BIOSPassword)
                $Return_Code_USB = $Execute_Change_Action_USB.return
                    
                If(($Return_Code_USB) -eq 0)
                {
                    Write-host -FORE green "BIOS USB BOOT $computerName OK ==> CODE : $Return_Code"
                    $USB_GOOD += (,@("$computerName") | Out-String).Trim()
                    $Export_CSV_USB_GOOD = 1
                        
                    #modification mdp admin local 
                    $objAdminUser = [ADSI]"WinNT://$computerName/Administrateur,user"
                    $objAdminUser.SetPassword($password_adm_local)
                
                    if ($?)
                    {
                        $Export_CSV_MDP_LOCAL_GOOD = 1
                        $MDP_LOCAL_GOOD += (,@("$computerName") | Out-String).Trim()
                        Write-Host -ForegroundColor green "$computerName : Le mot de passe a été changé"
                    }
                    else 
                    {
                        $Export_CSV_MDP_LOCAL_ERROR = 1
                        $MDP_LOCAL_ERROR += (,@("$computerName") | Out-String).Trim()
                        $ALL_ERROR += (,@("$computerName") | Out-String).Trim()
                        Write-Host -ForegroundColor red "$computerName : Le mot de passe n'a pas été changé"
                    }
                }
                Else
                {
                    $Export_CSV_USB_ERROR = 1
                    $USB_ERROR += (,@("$computerName") | Out-String).Trim()
                    $ALL_ERROR += (,@("$computerName") | Out-String).Trim()
                    write-host "Error - (Return code $Return_Code_USB)" -Foreground Red
                }
            }
        
        ##
        #si l'execution du script à rencontré des problèmes ( CODE 1 à 5 )
        ##

            elseif(($Return_Code) -eq 1 -and ($Return_Code) -eq 2 -and ($Return_Code) -eq 3 -and ($Return_Code) -eq 4 -and ($Return_Code) -eq 5) 
            {
                $Export_CSV_MDP_ERROR = 1
                $MDP_ereur += (,@("$computerName") | Out-String).Trim()
                $ALL_ERROR += (,@("$computerName") | Out-String).Trim()
                Write-host -FORE Yellow "$computerName fail ==> CODE : $Return_Code"
            }
        ##
        # si l'execution du script à rencontré des problèmes ( CODE 6 )
        # alors une 2ème tentative va être testé
        ##

            elseif(($Return_Code) -eq 6) 
            {
                Write-host -FORE Yellow "$computerName fail ==> CODE : $Return_Code"
                Write-host "------2ème tentative------"
                if(($Return_Code2) -eq 0)       
                {
                    $Export_CSV_MDP_GOOD = 1
                    $MDP_GOOD += (,@("$computerName") | Out-String).Trim()
                    Write-host -FORE green "$computerName OK ==> CODE : $Return_Code2"

                    #désactiver le boot sur le port USB
                    $BIOSPassword = "<utf-16/>"+$newpassword
                    $Execute_Change_Action_USB = $Interface.SetBIOSSetting('USB Storage Boot','Disable',$BIOSPassword)
                    $Return_Code_USB = $Execute_Change_Action_USB.return
        
                    If(($Return_Code_USB) -eq 0)
                    {
                        $Export_CSV_USB_GOOD = 1
                        $USB_GOOD += (,@("$computerName") | Out-String).Trim()
                        Write-host -FORE green "BIOS USB BOOT $computerName OK ==> CODE : $Return_Code"

                        #modification mdp admin local 
                        $objAdminUser = [ADSI]"WinNT://$computerName/Administrateur,user"
                        $objAdminUser.SetPassword($password_adm_local)
                        if ($?)
                        {
                            $Export_CSV_MDP_LOCAL_GOOD = 1
                            $MDP_LOCAL_GOOD += (,@("$computerName") | Out-String).Trim()
                            Write-Host -ForegroundColor green "$computerName : Le mot de passe a été changé"
                        }
                        else 
                        {
                            $Export_CSV_MDP_LOCAL_ERROR = 1
                            $MDP_LOCAL_ERROR += (,@("$computerName") | Out-String).Trim()
                            $ALL_ERROR += (,@("$computerName") | Out-String).Trim()
                            Write-Host -ForegroundColor red "$computerName : Le mot de passe n'a pas été changé"
                        }
                        
                    }
                    Else
                    {
                        $Export_CSV_USB_ERROR = 1
                        $USB_ERROR += (,@("$computerName") | Out-String).Trim()
                        $ALL_ERROR += (,@("$computerName") | Out-String).Trim()
                        write-host "Error - (Return code $Return_Code_USB)" -Foreground Red
                    }
                }
                else
                {
                
                    if(($Return_Code3) -eq 0)       
                    {
                        $Export_CSV_MDP_GOOD = 1
                        $MDP_GOOD += (,@("$computerName") | Out-String).Trim()
                        Write-host -FORE green "$computerName OK ==> CODE : $Return_Code3"
                    
                        #désactiver le boot sur le port USB
                        $BIOSPassword = "<utf-16/>"+$newpassword
                        $Execute_Change_Action_USB = $Interface.SetBIOSSetting('USB Storage Boot','Disable',$BIOSPassword)
                        $Return_Code_USB = $Execute_Change_Action_USB.return
        
                        If(($Return_Code_USB) -eq 0)
                        {
                            $Export_CSV_USB_GOOD = 1
                            $USB_GOOD += (,@("$computerName") | Out-String).Trim()
                            Write-host -FORE green "BIOS USB BOOT $computerName OK ==> CODE : $Return_Code"

                            #désactiver le boot via PXE
                            $Execute_Change_Action_PXE = $Interface.SetBIOSSetting('Network (PXE) Boot','Disable',$BIOSPassword)
                            $Return_Code_PXE = $Execute_Change_Action_PXE.return
                        
                            If(($Return_Code_PXE) -eq 0)
                            {
                                $Export_CSV_PXE_GOOD = 1
                                $PXE_GOOD += (,@("$computerName") | Out-String).Trim()
                                Write-host -FORE green "BIOS PXE BOOT $computerName OK ==> CODE : $Return_Code"
                            
                                #activer le boot via WOL
                                $Execute_Change_Action_WOL = $Interface.SetBIOSSetting('Wake On LAN','Boot to Hard Drive',$BIOSPassword)
                                $Return_Code_WOL = $Execute_Change_Action_WOL.return
                            
                                If(($Return_Code_WOL) -eq 0)
                                {
                                    $Export_CSV_WOL_GOOD = 1
                                    $WOL_GOOD += (,@("$computerName") | Out-String).Trim()
                                    Write-host -FORE green "BIOS WOL BOOT $computerName OK ==> CODE : $Return_Code"                                                             
                                }
                                else 
                                {
                                    $Export_CSV_WOL_ERROR = 1
                                    $WOL_ERROR += (,@("$computerName") | Out-String).Trim()
                                    $ALL_ERROR += (,@("$computerName") | Out-String).Trim()
                                    write-host "Error - (Return code $Return_Code_WOL)" -Foreground Red
                                }
                            }
                            else 
                            {
                                $Export_CSV_PXE_ERROR = 1
                                $PXE_ERROR += (,@("$computerName") | Out-String).Trim()
                                $ALL_ERROR += (,@("$computerName") | Out-String).Trim()
                                write-host "Error - (Return code $Return_Code_PXE)" -Foreground Red
                            }

                            #modification mdp admin local 
                            $objAdminUser = [ADSI]"WinNT://$computerName/Administrateur,user"
                            $objAdminUser.SetPassword($password_adm_local)
                            if ($?)
                            {
                                $Export_CSV_MDP_LOCAL_GOOD = 1
                                $MDP_LOCAL_GOOD += (,@("$computerName") | Out-String).Trim()
                                Write-Host -ForegroundColor green "$computerName : Le mot de passe a été changé"

                            }
                            else 
                            {
                                $Export_CSV_MDP_LOCAL_ERROR = 1
                                $MDP_LOCAL_ERROR += (,@("$computerName") | Out-String).Trim()
                                $ALL_ERROR += (,@("$computerName") | Out-String).Trim()
                                Write-Host -ForegroundColor red "$computerName : Le mot de passe n'a pas été changé"
                            }
                        }
                        Else
                        {
                            $Export_CSV_USB_ERROR = 1
                            $USB_ERROR += (,@("$computerName") | Out-String).Trim()
                            $ALL_ERROR += (,@("$computerName") | Out-String).Trim()
                            write-host "Error - (Return code $Return_Code_USB)" -Foreground Red
                        }
                    }
                    else
                    {
                        $Export_CSV_MDP_ERROR = 1
                        $MDP_ERROR += (,@("$computerName") | Out-String).Trim()
                        $ALL_ERROR += (,@("$computerName") | Out-String).Trim()
                        Write-host -FORE Red "$computerName fail ==> CODE : $Return_Code3"
                    }
                }
            }
 
        ########################
        #si test connexion faux
        ########################

        }
        Else
        {
            $Export_CSV_IP = 1
            $ip += (,@("$computerName") | Out-String).Trim()
            $ALL_ERROR += (,@("$computerName") | Out-String).Trim()
            Write-Host "$computerName n'est pas connecter"
        }

    }


    # création du nouveau dossier avec la date du jour pour permettre un suivi du script // des données exploitables en statistique
    $date = Get-Date -Format "dd-MM-yyyy"
    mkdir .\rapport\$date
    $file = ".\rapport\"+$date


    ##
    # Export retour de commande en CSV 
    ##

    #MDP GOOD
    if ($Export_CSV_MDP_GOOD -eq 1){
        (0..$i) |foreach {
            $CSV_MDP_GOOD += New-Object psobject -Property @{PC=$MDP_GOOD[$_]}
        }
        $CSV_MDP_GOOD |ConvertTo-Csv
        $file_Export = $file+"\MDP_GOOD.csv"
        $CSV_MDP_GOOD | Export-Csv -Path $file_Export -notypeinformation
    }

    #MDP ERROR
    if ($Export_CSV_MDP_ERROR -eq 1){
        (0..$i) |foreach {
            $CSV_MDP_ERROR += New-Object psobject -Property @{PC=$MDP_ERROR[$_]}
        }
        $CSV_MDP_ERROR |ConvertTo-Csv
        $file_Export = $file+"\MDP_ERROR.csv"
        $CSV_MDP_ERROR | Export-Csv -Path $file_Export -notypeinformation
    }

    #USB GOOD
    if ($Export_CSV_USB_GOOD -eq 1){
        (0..$i) |foreach {
            $CSV_USB_GOOD += New-Object psobject -Property @{PC=$USB_GOOD[$_]}
        }
        $CSV_USB_GOOD |ConvertTo-Csv
        $file_Export = $file+"\USB_GOOD.csv"
        $CSV_USB_GOOD | Export-Csv -Path $file_Export -notypeinformation
    }

    #USB ERROR
    if ($Export_CSV_USB_ERROR -eq 1){
        (0..$i) |foreach {
            $CSV_USB_ERROR += New-Object psobject -Property @{PC=$USB_ERROR[$_]}
        }
        $CSV_USB_ERROR |ConvertTo-Csv
        $file_Export = $file+"\USB_ERROR.csv"
        $CSV_USB_ERROR | Export-Csv -Path $file_Export -notypeinformation
    }

    #PXE GOOD
    if ($Export_CSV_PXE_GOOD -eq 1){
        (0..$i) |foreach {
            $CSV_PXE_GOOD += New-Object psobject -Property @{PC=$PXE_GOOD[$_]}
        }
        $CSV_PXE_GOOD |ConvertTo-Csv
        $file_Export = $file+"\PXE_GOOD.csv"
        $CSV_PXE_GOOD | Export-Csv -Path $file_Export -notypeinformation
    }

    #PXE ERROR
    if ($Export_CSV_PXE_ERROR -eq 1){
        (0..$i) |foreach {
            $CSV_PXE_ERROR += New-Object psobject -Property @{PC=$PXE_ERROR[$_]}
        }
        $CSV_PXE_ERROR |ConvertTo-Csv
        $file_Export = $file+"\PXE_ERROR.csv"
        $CSV_PXE_ERROR | Export-Csv -Path $file_Export -notypeinformation
    }

    #WOL GOOD
    if ($Export_CSV_WOL_GOOD -eq 1){
        (0..$i) |foreach {
            $CSV_WOL_GOOD += New-Object psobject -Property @{PC=$WOL_GOOD[$_]}
        }
        $CSV_WOL_GOOD |ConvertTo-Csv
        $file_Export = $file+"\WOL_GOOD.csv"
        $CSV_WOL_GOOD | Export-Csv -Path $file_Export -notypeinformation
    }

    #USB ERROR
    if ($Export_CSV_WOL_ERROR -eq 1){
        (0..$i) |foreach {
            $CSV_WOL_ERROR += New-Object psobject -Property @{PC=$WOL_ERROR[$_]}
        }
        $CSV_WOL_ERROR |ConvertTo-Csv
        $file_Export = $file+"\WOL_ERROR.csv"
        $CSV_WOL_ERROR | Export-Csv -Path $file_Export -notypeinformation
    }

    #MDP admin local GOOD
    if ($Export_CSV_MDP_LOCAL_GOOD -eq 1){
        (0..$i) |foreach {
            $CSV_MDP_LOCAL_GOOD += New-Object psobject -Property @{PC=$MDP_LOCAL_GOOD[$_]}
        }
        $CSV_MDP_LOCAL_GOOD |ConvertTo-Csv
        $file_Export = $file+"\MDP_LOCAL_GOOD.csv"
        $CSV_MDP_LOCAL_GOOD | Export-Csv -Path $file_Export -notypeinformation
    }

    #MDP admin local ERROR
    if ($Export_CSV_MDP_LOCAL_ERROR -eq 1){
        (0..$i) |foreach {
            $CSV_MDP_LOCAL_ERROR += New-Object psobject -Property @{PC=$MDP_LOCAL_ERROR[$_]}
        }
        $CSV_MDP_LOCAL_ERROR |ConvertTo-Csv
        $file_Export = $file+"\MDP_LOCAL_ERROR.csv"
        $CSV_MDP_LOCAL_ERROR | Export-Csv -Path $file_Export -notypeinformation
    }


    #ERROR PING
    if ($Export_CSV_IP -eq 1){
        (0..$i) |foreach {
            $CSV_IP_ERROR += New-Object psobject -Property @{PC=$ip[$_]}
        }
        $CSV_IP_ERROR |ConvertTo-Csv
        $file_Export = $file+"\IP_ERROR.csv"
        $CSV_IP_ERROR | Export-Csv -Path $file_Export -notypeinformation
    }

    #ALL ERROR 
    (0..$i) |foreach {
        $CSV_ALL_ERROR += New-Object psobject -Property @{PC=$ALL_ERROR[$_]}
    }
    $CSV_ALL_ERROR |ConvertTo-Csv
    $file_Export = $file+"\ALL_ERROR.csv"
    $CSV_ALL_ERROR | Export-Csv -Path $file_Export -notypeinformation

    # copier en Liste_PC dans le dossier date pour avoir un suivi
    mv .\Liste_PC.csv .\rapport\$date\Liste_PC.csv
    # Pour l'automatisation du script le fichier ALL ERRER est copié et renommé en Liste_PC
    cp .\rapport\$date\ALL_ERROR.csv .\Liste_PC.csv
}
else
{
    Write-Host -ForegroundColor red "##########################"
    Write-Host -ForegroundColor red "#Tu n'as les droits admins #"
    Write-Host -ForegroundColor red "##########################"
}