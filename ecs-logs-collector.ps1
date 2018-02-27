<# 
    Copyright 2017 Amazon.com, Inc. or its affiliates. All Rights Reserved.
    Licensed under the Apache License, Version 2.0 (the "License"). You may not use this file except in compliance with the License. A copy of the License is located at

        http://aws.amazon.com/apache2.0/

    or in the "license" file accompanying this file. 
    This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.

.SYNOPSIS 
    Collects ECS Agent Logs
.DESCRIPTION 
    Run the script to collect ECS Logs
    Run without parameters to Gather basic operating system, Docker daemon, and Amazon ECS container agent logs. 
    Run with -RunMode Debug to Collect 'brief' logs and also enables debug mode for the Docker daemon and the Amazon ECS container agent.
    Run with -RunMode DebugOnly to enable debug mode for the Docker daemon and the Amazon ECS container agent without collecting logs
    Run with -RunMode DisableDebugOnly to disable debug mode for the Docker daemon and the Amazon ECS container agent without collecting logs
	Default script RunMode is Brief mode.
.NOTES
    You need to run this script with Elevated permissions to allow for the collection of the installed applications list
.EXAMPLE 
    ecs-log-collector.ps1
    Gathers basic OS System, Docker daemon and Amazon ECS container agent logs
.EXAMPLE 
    ecs-log-collector.ps1 -RunMode Debug
    Collects 'brief' logs and also enables debug mode for the Docker daemon and the Amazon ECS container agent.
.PARAMETER RunMode
    Defines what type of collection will be run(Brief, Debug, DebugOnly or DisableDebugOnly) default mode is Brief.
#>

param(
    [Parameter(Mandatory=$False)][string]$RunMode = "Brief"   
    )

# Common options
$curdir=(Get-Item -Path ".\" -Verbose).FullName
$infodir="$curdir\collect"
$info_system="$infodir\system"



# Common functions
# ---------------------------------------------------------------------------------------

Function is_elevated{
    If (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(`
    [Security.Principal.WindowsBuiltInRole] "Administrator")) {
	Write-warning "This script requires elevated privileges to copy registry keys to the ECS logs collector folder."
	Write-Host "Please re-launch as Administrator." -foreground "red" -background "black"
	break
    }
}


Function create_working_dir{
    try {
        Write-Host "Creating temporary directory"
        New-Item -type directory -path $info_system -Force >$null
        New-Item -type directory -path $info_system\docker -Force >$null
        New-Item -type directory -path $info_system\firewall -Force >$null
        New-Item -type directory -path $info_system\ecs -Force >$null
        New-Item -type directory -path $info_system\docker_log -Force >$null
        Write-Host "OK" -ForegroundColor "green"
    }
    catch {
        Write-Host "Unable to create temporary directory"
        Write-Host "Please ensure you have enough permissions to create directories"
        Write-Error "Failed to create temporary directory"
        Break
    }
}

Function get_sysinfo{
    try {
        Write-Host "Collecting System information"
        systeminfo.exe > $info_system\sysinfo
        Write-Host "OK" -ForegroundColor "green"
    }
    catch {
        Write-Error "Unable to collect system information" 
        Break
    }  
        
}

Function is_diskfull{
    $threshold = 30
    try {
        Write-Host "Checking free disk space"
        $drive = Get-WmiObject Win32_LogicalDisk -Filter "DeviceID='C:'"
        $percent = ([math]::round($drive.FreeSpace/1GB, 0) / ([math]::round($drive.Size/1GB, 0)) * 100)
        Write-Host "C: drive has $percent% free space"
        Write-Host "OK" -ForegroundColor "green"
    }
    catch {
        Write-Error "Unable to Determine Free Disk Space" 
        Break
    }
    if ($percent -lt $threshold){
        Write-Error "C: drive only has $percent% free space, please ensure there is at least $threshold% free disk space to collect and store the log files" 
        Break
    }
}

Function get_system_logs{
    try {
        Write-Host "Collecting System Logs"
        Get-WinEvent -LogName System | Select-Object timecreated,leveldisplayname,machinename,message | export-csv -Path $info_system\system-eventlogs.csv
        Write-Host "OK" -foregroundcolor "green"
    }
    catch {
        Write-Error "Unable to Collect System Logs"
        break
    }
}

Function get_application_logs{
    try {
        Write-Host "Collecting Application Logs"
        Get-WinEvent -LogName Application | Select-Object timecreated,leveldisplayname,machinename,message | export-csv -Path $info_system\application-eventlogs.csv
        Write-Host "OK" -foregroundcolor "green"
    }
    catch {
        Write-Error "Unable to Collect Application Logs"
        break
    }
}

Function get_volumes_info{
    try {
        Write-Host "Collecting Volume info"
        Get-psdrive -PSProvider 'FileSystem' | Out-file $info_system\volumes
        Write-Host "OK" -foregroundcolor "green"
    }
    catch {
        Write-Error "Unable to Collect Volume information"
        break
    }
}

Function get_firewall_info{
    try {
        Write-Host "Collecting Windows Firewall info"
        $fw = Get-NetFirewallProfile
        foreach ($f in $fw){
            if ($f.Enabled -eq "True"){
                $file = $f.name
                Write-Host "Collecting Rules for" $f.name "profile"
                Get-NetFirewallProfile -Name $f.name | Get-NetFirewallRule | Out-file $info_system\firewall\firewall-$file
                }
            }
        Write-Host "OK" -foregroundcolor "green"
    }
    catch {
        Write-Error "Unable to Collect Windows Firewall information"
        break
    }
}

Function get_softwarelist{
    try {
        Write-Host "Collecting installed applications list"
        gp HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* |Select DisplayName, DisplayVersion, Publisher, InstallDate, HelpLink, UninstallString | out-file $info_system\installed-64bit-apps.txt
        gp HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* |Select DisplayName, DisplayVersion, Publisher, InstallDate, HelpLink, UninstallString | out-file $info_system\installed-32bit-apps.txt
        Write-Host "OK" -foregroundcolor "green"
    }
    catch {
        Write-Error "Unable to collect installed applications list"
        break
    }
}

Function get_system_services{
    try {
        Write-Host "Collecting Services list"
        get-service | fl | out-file $info_system\services
        Write-Host "OK" -foregroundcolor "green"
    }
    catch {
        Write-Error "Unable to collect Services list"
        break
    }
}

Function get_docker_info{
    try {
        Write-Host "Collecting Docker daemon information"
        docker info > $info_system\docker\docker-info.txt 2>&1
        docker ps --all --no-trunc > $info_system\docker\docker-ps.txt 2>&1
        docker images > $info_system\docker\docker-images.txt 2>&1
        docker version > $info_system\docker\docker-version.txt 2>&1
        Write-Host "OK" -foregroundcolor "green"
    }
    catch{
        Write-Error "Unable to collect Docker daemon information"
        Break
    }
}

Function get_ecs_agent_logs{
    try {
        Write-Host "Collecting ECS Agent logs"
        copy C:\programdata\amazon\ecs\log\* $info_system\ecs\
        Write-Host "OK" -foregroundcolor "green"
    }
    catch{
        Write-Error "Unable to collect ECS Agent logs"
        Break
    }
}

Function get_containers_info{
    try {
        Write-Host "Inspect running Docker containers and gather Amazon ECS container agent data"
        $containers = docker ps -q
        foreach ($c in $containers){
            docker inspect $c > $info_system/docker/container-$c.txt
            if (Get-Content $info_system/docker/container-$c.txt |where-object {$_ -like 'ECS_ENGINE_AUTH_DATA'} ) {
                (Get-Content $info_system/docker/container-$c.txt) | ForEach-Object {$_ -replace 'ECS_ENGINE_AUTH_DATA*.+$', 'ECS_ENGINE_AUTH_DATA: OBFUSCATED'} | Set-Content $info_system/docker/container-$c.txt
            }
        }
        Write-Host "OK" -foregroundcolor "green"
    }
    catch {
        Write-Error "Unable to collect Docker containers data"
        Break
    }
}

Function get_docker_logs{
    try {
        Write-Host "Collecting Docker daemon logs"
        Get-EventLog -LogName Application -Source Docker | Sort-Object Time | Export-CSV $info_system/docker_log/docker-daemon.csv
        Write-Host "OK" -foregroundcolor "green"
    }
    catch {
        Write-Error "Unable to collect Docker daemon logs"
        Break
    }
}

Function enable_docker_debug{
    try {
        Write-Host "Enabling debug mode for the Docker Service"
        if (sc.exe qc docker | where-object {$_ -like '*-D*'}){
            Write-Host "Debug mode already enabled" -foregroundcolor "yellow"
        }
        else {
            sc.exe config docker binPath= "C:\Program Files\Docker\dockerd.exe --run-service -D"
            Write-Host "OK" -foregroundcolor "green" 
        } 
    }
    catch {
        Write-Error "Failed to enable debug mode"
        Break
    }
}

Function disable_docker_debug{
    try {
        Write-Host "Disabling debug mode for the Docker Service"
        if (sc.exe qc docker | where-object {$_ -like '*-D*'}){
            sc.exe config docker binPath= "C:\Program Files\Docker\dockerd.exe --run-service"
            Write-Host "OK" -foregroundcolor "green"    
        }
        else {
            Write-Host "Debug mode already disabled" -foregroundcolor "yellow"
        } 
    }
    catch {
        Write-Error "Failed to disable debug mode"
        Break
    }
}

Function enable_ecs_agent_debug{
    try {
        Write-Host "Enabling debug mode for the Amazon ECS container agent"
        if ($Env:ECS_LOGLEVEL -eq "debug"){
            Write-Host "Debug mode already enabled" -foregroundcolor "yellow"
        }
        else {
            [Environment]::SetEnvironmentVariable("ECS_LOGLEVEL", "debug")
            Write-Host "Restarting the Amazon ECS container agent to enable debug mode"
            Restart-Service AmazonECS
            Write-Host "OK" -foregroundcolor "green" 
        }     
    }
    catch {
        Write-Error "Failed to enable debug mode"
        Break
    }
}

Function disable_ecs_agent_debug{
    try {
        Write-Host "Disabling debug mode for the Amazon ECS container agent"
        if ($Env:ECS_LOGLEVEL -ne "debug"){
            Write-Host "Debug mode already disabled" -foregroundcolor "yellow"
        }
        else {
            [Environment]::SetEnvironmentVariable("ECS_LOGLEVEL", "info")
            Write-Host "Restarting the Amazon ECS container agent to disable debug mode"
            Restart-Service AmazonECS
            Write-Host "OK" -foregroundcolor "green" 
        } 
    }
    catch {
        Write-Error "Failed to enable debug mode"
        Break
    }
}

Function cleanup{
    Write-Host "Cleaning up directory"
    Remove-Item -Recurse -Force $infodir -ErrorAction Ignore
    Remove-Item -Force $curdir\collect.zip -ErrorAction Ignore
    Write-Host "OK" -foregroundcolor green
}

Function pack{
    try {
        Write-Host "Archiving gathered data"
        Compress-Archive -Path $infodir -CompressionLevel Optimal -DestinationPath $curdir\collect.zip
        Write-Host "OK" -foregroundcolor "green"
    }
    catch {
        Write-Error "Unable to archive data"
        Break
    }
}

Function init{
    is_elevated
    create_working_dir
    get_sysinfo
}
    

Function collect_brief{
    init
    is_diskfull
    get_system_logs
    get_application_logs
    get_volumes_info
    get_firewall_info
    get_softwarelist
    get_system_services
    get_docker_info
    get_ecs_agent_logs
    get_containers_info
    get_docker_logs
}

Function collect_debug{
    init
    enable_debug
    collect_brief
        
}

Function enable_debug{
    enable_docker_debug
    enable_ecs_agent_debug
}

Function disable_debug{
    disable_docker_debug
    disable_ecs_agent_debug
}

    

    
if ($RunMode -eq "Brief"){
    Write-Host "Running Default(Brief) Mode" -foregroundcolor "blue"
    cleanup
    collect_brief
    pack 
} elseif ($RunMode -eq "Debug"){
    Write-Host "Running Debug Mode" -foregroundcolor "blue"
    cleanup
    enable_debug
    collect_brief
    pack
} elseif ($RunMode -eq "DebugOnly"){
    Write-Host "Enabling Debug for ECS and Docker" -foregroundcolor "blue"
    enable_debug
} elseif ($RunMode -eq "DisableDebugOnly"){
    Write-Host "Disabling Debug for ECS and Docker" -foregroundcolor "blue"
    disable_debug
} else {
    Write-Host "You need to specify either Brief, Debug, DebugOnly, or DisableDebugOnly RunMode" -ForegroundColor "red" 
    Break
}
