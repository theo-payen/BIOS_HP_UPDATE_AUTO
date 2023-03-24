# BIOS_HP_UPDATE_SETTING
BIOS_HP_UPDATE_SETTING
_(Powershell)_

Ce script permet de modifier les mots de passe BIOS, de désactiver le démarrage sur le port USB, désactiver le démarrage par pxe, d'activer le Wol et de changer le mdp administrateur local sur une liste de PC dans le fichier Liste PC Cvs.

## Pour commencer
Ce script est prévue pour un execution automatique toute les 24h
voici la liste des fichier donc vous aller avoir besoin
BIOS_HP_UPDATE_AUTO.ps1
rapport (Le dossier) a la racine du script
Liste_PC.csv
Export_AD_all_computer.ps1

### Pré-requis

Configuration du script
modifier le fichier "BIOS_HP_UPDATE_AUTO.ps1"
a la ligne 26 entrée votre nouveau Mot de passe BIOS
a la ligne 28 entrée votre ancien Mot de passe BIOS
a la ligne 31 entrée votre 2ème ancien Mot de passe BIOS dans mon cas e MDP BIOS a été mal taper (les nombre tel que 1234567890 par &é"'(-èè_çà )
a la ligne 36 entrée votre mdp de passe administrateur local
a la ligne 75 entrée le chemain de votre script

executer le script Export_AD_all_computer.ps1 pour extraire la liste des machine dans l'active directory
/!\ veillez verrifer qu'elle ordinateur est dans cette liste pour ne pas lancer le script sur un serveur 
ouvré le fichier CSV qui viens d'être généré modifier la ligne A:1 "Name" par "PC"
deplacer le fichier a la racine du script "BIOS_HP_UPDATE_AUTO.ps1" et renomer le en "Liste_PC.csv"
vous pouvez désormette executer le script

un rapport sera généré apres l'execution du script pour suivre son évolution
toute les machine avec une erreur seron retester le lendemain

1200 PC - temps moyen d'execution pour la première fois 3h30 


## Auteurs
Théo PAYEN CAF77

