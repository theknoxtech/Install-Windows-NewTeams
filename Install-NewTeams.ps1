<#
.SYNOPSIS

This script installs New Teams to the system using the Teams Bootstrapper


.DESCRIPTION

Script checks if New Teams is installed and if not,  it will download the Teams Bootstrapper. Script will use the bootrapper to install New Teams

Author: Jon Witherspoon
Last Modified: 5/5/25


.PARAMETER Name

N/A

.INPUTS

None. You cannot pipe objects to this script.


.OUTPUTS
Logs to console

.EXAMPLE
Install-NewTeams.ps1

.EXAMPLE
N/A
#>



# Global Variables
$Global:LTSvc = "C:\Windows\LTSvc\packages"
$Global:TimeStamp = (Get-Date).ToString("MM/dd/yyyy HH:mm:ss")


# Outputs logs to the console
function Out-ConsoleLog {
    param(
        [Logs]$Type,
        [string]$Message,
        [string]$Recommendations
    )
    enum Logs {
        Info
        Success
        Failure
    }

    $console_logs = @{
        Info = "Line: $($MyInvocation.ScriptLineNumber) : $TimeStamp : $message"
        Success = "Line: $($MyInvocation.ScriptLineNumber) : $TimeStamp : SUCCESS: Teams has been uninstalled"
        Failure =  "FAILURE: Script Halted at Line: $($MyInvocation.ScriptLineNumber)"
        RecommendedAction = $Recommendations
    }

    switch ($Type) {
        ([Logs]::Info) {Write-Host $console_logs.Info ; break}
        ([Logs]::Success) {Write-Host $console_logs.Success ; break }
        ([Logs]::Failure) {Write-Error "$($console_logs.Failure) $Recommendations" -ErrorAction Stop ; break }
    }
    
}

# Check TeamsInstallStatus - Return PublisherId, Name, InstallLocation
# Scriptmethod - IsNewTeamsInstalled - Return [bool]
function Get-TeamsInstallStatus {

    $NewTeams = Get-AppxPackage  -AllUsers | Where-Object {$_.Name -contains "MSTeams"}

    $InstallStatus = New-Object psobject
    $InstallStatus | Add-Member -MemberType NoteProperty -Name "PublisherId" -Value $NewTeams.PublisherId
    $InstallStatus | Add-Member -MemberType NoteProperty -Name "Name" -Value $NewTeams.Name
    $InstallStatus | Add-Member -MemberType NoteProperty -Name "InstallLocation" -Value $NewTeams.InstallLocation

    return $InstallStatus

}

# Download Teams Bootstrapper
function Get-BootStrapperCheck {
    
    if (Get-Item -Path "$LTSvc\teamsbootstrapper.exe" -ErrorAction SilentlyContinue){

        return $true

    }else {

        return $false
    }

}



#############
#SCRIPT START
#############


Out-ConsoleLog -Type Info -Message "Checking Teams install status"

If (!(Get-TeamsInstallStatus).Name){

    Out-ConsoleLog -Type Info -Message "Checking for Teams bootstrapper"
 
    try {
        if (Get-BootStrapperCheck) {

            Out-ConsoleLog -Type Info -Message "Bootstrapper found, starting install"
         
            Start-Process $LTSvc\teamsbootstrapper.exe -ArgumentList "-x" -WindowStyle Hidden -Wait -ErrorAction Stop

        }elseif(!(Get-BootStrapperCheck)){

            $BootStrapper_URL = "https://go.microsoft.com/fwlink/?linkid=2243204&clcid=0x409/"

            Out-ConsoleLog -Type Info -Message "Downloading bootstrapper"
           
            Invoke-WebRequest -Uri $BootStrapper_URL -OutFile "$LTSvc\teamsbootstrapper.exe"

            Out-ConsoleLog -Type Info -Message "Installing Teams"
            
            Start-Process $LTSvc\teamsbootstrapper.exe -ArgumentList "-p" -WindowStyle Hidden -Wait -ErrorAction Stop
        }
    }
    catch {

        Out-ConsoleLog -Type Failure -Message -Recommendations "Manual intervention required: Teams was NOT installed"
    }
    Out-ConsoleLog -Type Success
    
}else{

    Out-ConsoleLog -Type Failure -Message -Recommendations "Teams is already installed on this device"
}
