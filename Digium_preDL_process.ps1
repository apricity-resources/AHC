##############################################################################################################################################
#
# Name:  Digium_PreDL_Process.PS1
# Author:  Stephen Rushton
# Date:    11/12/2018

#
# Description:
#  Renames the 2 Digium download folders so the next download from them will be successful.  After several iterations of successful
#  downloads the Digium process will decide it needs to recreate the folder even though it exists and still has space.
#
#
# Prerequisites:
#    A domain user account is needed with correct permissions to rename subfolders in the 'G:\share\Call recordings' folder
# 
# Limitations:
#    None
# 
# To use:
#    script is in a scheduled task that runs each night at 6:45
#
# How it works:
#   Checks for existing folder names that match what Digium wants to download them as.
#   Renames the folders by prepending OLD_ to the front
# 
# Output:
#   Email to administrator notifying him of change
#
# Change Log:
# V1.00, 11/12/2018 - Initial version
# V1.01, 11/13/2018 - Modified timing and variables to streamline process.  Added email notice.
# V2.00, 01/08/2019 - Removed Scheduler status, updated email process.  Added error checking for folder rename.

##############################################################################################################################################


$Subject = "AHC Digium CR Pre-DL-Directory doesn't exist"
$Body = "No Patient_Patient_Services_Recordings folder exists"

# $SchedStatus = "No Scheduler_Recordings folder exists"

#Get Current Days Folders
$PatientFolder = Get-ChildItem "G:\Data\Share\Call Recording\Patient*" | ?{ $_.PSIsContainer } | Select-Object FullName
# $SchedulerFolder = Get-ChildItem "G:\Data\Share\Call Recording\Scheduler*" | ?{ $_.PSIsContainer } | Select-Object FullName

#If a Patient recording folder exists, append the date to the folder name
If ($PatientFolder) {
    Rename-item -path $PatientFolder.FullName -NewName "G:\Data\Share\Call Recording\OLD_Patient_Services_Recordings"
    If ($?) { #If the last command successfully ran
        $Body = "Patient Services Recordings folder successfully renamed"
        $Subject = 'AHC Digium CR Pre-DL Successful'
    } else {
        $Body = "There was a problem renaming the Patient Services Recordings folder!"
        $Subject = 'AHC Digium CR Pre-DL Failure!!!'
    }
}
#If a Scheduler recording folder exists, append the date to the folder name
#If ($SchedulerFolder) {
#    $NewSchedName = "G:\Data\Share\Call Recording\OLD_Scheduler_Recordings"
#    Rename-item -path $SchedulerFolder.FullName -NewName $NewSchedName
#    $Schedstatus = "Scheduler_Recordings folder successfully renamed"
#}

#Send Email
$SMTPServer = 'alanahealthcare-com.mail.protection.outlook.com'
$From = 'DigiumPreProcess@AlanaHealthCare.com'
# $To‘AHCITManager@AlanaHealthCare.com’
$To=‘stephen.rushton@AlanaHealthCare.com’
Send-MailMessage –From $From –To $To –Subject $Subject –Body $Body -SmtpServer $SMTPServer -Port 25