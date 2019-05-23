$Send = $False
$PatientFile = get-ChildItem "G:\Data\Share\Call Recording\Patient_Services_Recordings\*.wav" | sort LastWriteTime | select -last 1

#Check during the week
If (($patientfile.LastWriteTime) -lt ((get-date).Addhours(-24)) -and ((get-date).dayofweek -ne "Sunday") -and ((get-date).dayofweek -ne "Monday")) {
    $Send = $True
    $Subject = '!PROBLEM! Digium Call Downloads did not occur'
}
#Compensate for the weekend
If (($patientfile.LastWriteTime) -lt ((get-date).Addhours(-72)) -and ((get-date).dayofweek -eq "Sunday") -and ((get-date).dayofweek -eq "Monday")) {
    $Send = $True
    $Subject = '!PROBLEM! Digium Call Downloads did not occur'
}

#Send monthly check
if ((Get-Date).Day -lt 7 -and (get-date).DayOfWeek -eq "Monday") {
    $Send = $true
    $Subject = 'Monthly Digium Call Downloads Remiinder'
}

If ($Send -eq $True) {    
    $From = 'Digium-DLChecker@AlanaHealthCare.com'
    $To = 'AHCITManager@AlanaHealthCare.com'
    $SMTPServer = 'alanahealthcare-com.mail.protection.outlook.com'
    $Body = "The last Digium recording download was:  $($PatientFile.Name) at $($PatientFile.LastWriteTime)."

    Send-MailMessage –From $From –To $To –Subject $Subject –Body $Body -SmtpServer $SMTPServer -Port 25
}