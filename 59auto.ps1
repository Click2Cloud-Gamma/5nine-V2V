#-------------------------------
# AUTHOR: Sadik Tekin
# GIT: 	https://github.com/SuDT
#-------------------------------
CLS
# ensure 5nine is installed on current host
Add-PSSnapin 59v2v
$DT = Get-Date -UFormat '%d/%b/%Y @ %T'
$scriptPath = split-path -parent $MyInvocation.MyCommand.Definition
$LOG = "$scriptPath\Conversion.log"
cd $scriptPath

# check local admin rights
If (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(`
    [Security.Principal.WindowsBuiltInRole] "Administrator"))
{
    Write-Warning "Please run PowerShell as local Administrator!" | Out-File $LOG -Append
    Break
}

# get V2V config file
$xml = [xml](Get-Content "V2Vconfig.xml")
if ($xml -eq $null)
{
	"$DT - Can't load config file [$scriptpath\V2Vconfig.xml]" |% {Write-Host $_; Out-File $LOG -inputobject $_ -Append}
}

#Set 59V2V Params (only needed when using executable NOT PowerShell Module)
if (-NOT (test-path "$env:ProgramFiles\5nine Software, Inc\5nine EasyConverter\59V2V.exe")) `
	{throw "$env:ProgramFiles\5nine Software, Inc\5nine EasyConverter\59V2V.exe needed"} 
	set-alias V2V "$env:ProgramFiles\5nine Software, Inc\5nine EasyConverter\59V2V.exe"

try {
	ForEach ($VMHost in $xml.Config.ESXi.Host1) {
	#Declare variables from Config file and add log
	$DT = Get-Date -UFormat '%d/%b/%Y @ %T'
	"---------------------------------------------" |% {Write-Host $_; Out-File $LOG -inputobject $_ -Append}
	"$DT New Conversion started" |% {Write-Host $_; Out-File $LOG -inputobject $_ -Append}
	$source = $VMHost.Name; "Source = "+$source | % {Write-Host $_; Out-File $LOG -inputobject $_ -Append}
	$sourceUser = $VMHost.User
	$sourcePW = $VMHost.Password
	
	$target = $VMHost.Target.Name;  "Target = "+$target | % {Write-Host $_; Out-File $LOG -inputobject $_ -Append}
	$targetUser = $VMHost.Target.User
	$targetPW = $VMHost.Target.Password
	
	$vmName = $VMHost.VM.Name; "VM Name = "+$vmName | % {Write-Host $_; Out-File $LOG -inputobject $_ -Append}
	$vmPath = $VMHost.Target.vmpath; "Config Path = "+$vmPath | % {Write-Host $_; Out-File $LOG -inputobject $_ -Append}
	$vhdPath = $VMHost.Target.vhdpath + "$vmName"; "VHD Path = "+$vhdPath | % {Write-Host $_; Out-File $LOG -inputobject $_ -Append}
	
	$cpu = $VMHost.VM.cpu -as [int]; "CPU = "+$cpu | % {Write-Host $_; Out-File $LOG -inputobject $_ -Append}
	$mem = $VMHost.VM.mem -as [int]; "MEM = "+$mem | % {Write-Host $_; Out-File $LOG -inputobject $_ -Append}
	$net = $VMHost.VM.net; "NET = "+$net | % {Write-Host $_; Out-File $LOG -inputobject $_ -Append}
	
	$tempPath = $xml.Config.Temp.path
	
	<# Start conversion(s)
	#5nine MODULE NOT CURRENTLY STABLE USE CMD (V2V) VERSION BELOW
	Convert-VM -verbose -s $source -su $sourceUser -sp $sourcePW -sv $vmName `
						-t $target -tu $targetUser -tp $targetPW -tv $vmName `
						-temp $tempPath -cpu $cpu -mem $mem -net $net -dynamic `
	#>
	V2V -s $source -su $sourceUser -sp $sourcePW -sv $vmName `
		-t $target -tu $targetUser -tp $targetPW -tv $vmName `
		-temp $tempPath -net $net -dynamic -shutdown `
	
	$DT = Get-Date -UFormat '%d/%b/%Y @ %T'
	"$DT $vmName Conversion Completed" |% {Write-Host $_; Out-File $LOG -inputobject $_ -Append}
	del $tempPath\*
		}
	}
catch {"$DT $_" |% {Write-Host $_; Out-File $LOG -inputobject $_ -Append}}
