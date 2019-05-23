##############################################################################################################################################
#
# Name:  Digium_PostDL_Process.PS1
# Author:  Stephen Rushton
# Date:    11/12/2018
#
# Description:
#  Digium downloads call recordings to our file server through SFTP.  Randomly their process will want to create subfolders
#  that already exist thereby failing until the folder is renamed.  This is a workaround because Digium is reluctant to update their code.
#  Takes contents of the OLD_ folders and moves them back to the main folders created by the digim download process.  
#  This is meant to run only after the daily digium download currently scheduled for 7pm each night.
#
#
# Prerequisites:
#    A domain user account is needed with correct permissions to rename subfolders in the 'G:\share\Call recordings' folder
# 
# Limitations:
#    None
# 
# To use:
#    script is in a scheduled task that runs each night at 8:00pm
#
# How it works:
#   Checks for existing folder names that match what Digium wants to download them as.
#   Checks for existing OLD_ folders
#   If both are found then the contents of the OLD_ folder is copied to the corrosponding main folder
# 
# Output:
#   Email to administrator notifying him of change
#
# Change Log:
# V1.00, 11/12/2018 - Initial version
# V1.01, 11/13/2018 - Modified functionality and variables to streamline process.  Added email notice.
# V1.02, 11/14/2018 - Added error checking for the file moves and folder deletes.  Corrected 2 variable mispellings in the email body.  Enhanced email information.
# v2.00, 01/08/2019 - Updated email function to use generic sender, removed Scheduler portion, 

##############################################################################################################################################

$PatResult = ""
$problem=$False

$PatFolder = Get-ChildItem "G:\Data\Share\Call Recording\Patient_Services_Recordings*" | Where { $_.PSIsContainer } | Select-Object FullName

$OLDPatFolder = Get-ChildItem "G:\Data\Share\Call Recording\OLD_Patient_Services_Recordings*" | Where { $_.PSIsContainer } | Select-Object FullName

#If a Patient recording folder exists, append the date to the folder name
If ($OLDPatFolder) {
    If ($PatFolder) {
        move-item -path "$($OLDPatFolder.FullName)\*" -Destination $PatFolder.FullName
        If (!$?) {
            $PatResult += "There was a problem moving Patient Services recordings back to the main directory."
            $Problem = $true
        } else {
            remove-item $OLDPatFolder.fullname
        }
        If (!$?) {
            $PatResult += "There was a problem removing the OLD_Patient_Services_Recordings folder."
            $Problem = $true
        }
        If (!$problem) {
            $PatResult = "Patient Recordings files moved successfully."
        }
    } Else {
        $PatResult = "No Patient_services_recordings Folder exists."
        $Problem = $true
    }
} Else {
    $PatResult = "No OLD_Patient_Services_Recordings Folder exists."
    $Problem = $true
}

#Archive folders older than 30 days on the main server
$Archive = "H:\Call Recordings\"
$AllPatFiles = Get-ChildItem "G:\Data\Share\Call Recording\Patient_Services_Recordings\*" | ?{ $_.LastWriteTime -lt (Get-Date).AddDays(-31)}
$Problem=$False
Foreach ($PatFile in $AllPatFiles) {
    Move-item -Path "G:\Data\Share\Call Recording\Patient_Services_Recordings\$($PatFile.Name)" -Destination "$($archive)\Patient_Services_Recordings"
    If (!$?) {
        $Problem=$True
    }
}

If (!$Problem) {
    $PatArchResult="$($AllPatFiles.count) Patient Service Recordings were archived"
    #Keep 60 days on secondary servers
    Get-ChildItem "\\AHCDIXDC01\E$\Data\Share\Call Recording\Patient_Services_Recordings\*" | Where { $_.LastWriteTime -lt (Get-Date).AddDays(-60)} | Remove-Item
    Get-ChildItem "\\AHCHQDC01\E$\Data\Share\Call Recording\Patient_Services_Recordings\*" | Where { $_.LastWriteTime -lt (Get-Date).AddDays(-60)} | Remove-Item
} else {
    $PatArchResult="There was a problem archiving the Patient service Recordings!"
}

#Send Email
If ($problem) {
    $Subject = 'PROBLEM! - AHC Digium CR Post-DL Status'
} else {
    $Subject = 'SUCCESS! - AHC Digium CR Post-DL Status'
}
$SMTPServer = 'alanahealthcare-com.mail.protection.outlook.com'
$From = 'DigiumPostProcess@AlanaHealthCare.com'
$Body = "$PatResult <br><br> $PatArchResult"
#$To = ‘AHCITManager@AlanaHealthCare.com’
$To = ‘Stephen.Rushton@AlanaHealthCare.com’
Send-MailMessage –From $From –To $To –Subject $Subject –Body $Body -SmtpServer $SMTPServer -Port 25