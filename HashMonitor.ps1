<#
	.NOTES
	Fiddlefingers Cast-xmr Hash rate monitor and restart Tool.
	Version 0.2
	
	Created due to the stability issue with the Vega GPU's and Cast-XMR and not wanting to constantly
    	monitor the system manually.
	
	Code idea derived from @JerichoJones "JJ-s-XMR-Stack-HashRate-Monitor-and-Restart-Tool"
	--> https://github.com/JerichoJones/JJ-s-XMR-STAK-HashRate-Monitor-and-Restart-Tool.
	
	Cast-xmr has the tendency to crash, hang, or fail at times. Over time the program tends to drop
	in hash rate or a card stops working.  This leads to losing valuble mining time until you notice
	and restart Cast-xmr.  Cast also does not have a log system which can lead to one wondering
	how long cast has not been working or why it stopped.
	
	I created this program to monitor cast and restart if certain criteria are not met.
	Hopefully this give users some peace of mind that their mining rigs are running correctly.
	This program will also create a log file if allowing one to go back and see what
	the miner was doing.
	
	If you feel this program has helped you I would apreaciate a donation which will allow me to
	update and improve the program.  Possibly, even add more functions over time. 
	
	XMR: 47LXCiTehW18h3QZW4rSdt5ticGN7L3iKY9vYjFJMk5LZm2TUh27sBtDRAcotru8AoKW57bxhBUdJDk1ZceBh89YVaY73si
	
	Purpose:	To monitor Cast-xmr hashrate.  If it drops below a preset value or stops responding
				the script is resarted.
	
	Fetures:	Script will evaluate itself to run as Admin
				Logging
				Disabling/Enabling the Radeon Vega 64 drivers.
				Running of overdriveNTool
				Running of Cast-xmr
				
	*** IMPORTANT NOTE *** 	The script will close all command prompt windows when restarting the
							miner.  This is a known bug and may be addressed in futer release.
							
	Requirements:	Power Shell must be run as Administrator
					Enable PowerShell Scripts to run.
					
	Software Requirements:	cast_xmr-vega.exe - must be in the same folder else it will fail to run.
							devcon.exe - installed to the windows/System32 foulder.
							OverdriveNTool - must be in the same folder else it will fail to run.
							
	Please read the User Variables section carefully.
	
	Autor: Fiddlefingers
	
	Version 0.2
	Relase Date 2017-Dec-07
	
	Copyrite (C) 2017 Fiddlefingers
	
	Licence:
	This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <https://www.gnu.org/licenses/>.
#>

$ver = "0.2"
$Host.UI.RawUI.WindowTitle = "Fiddlefingers Cast-xmr HashRate Monitor and Restart Tool v $ver"
$Host.UI.RawUI.BackgroundColor = "DarkBlue"

Clear-Host

Push-Location $PSScriptRoot

###################################################
################## UserVeriables ##################
###################################################

#all commands to run the programs are found in this section.

$logFile = "LOGS/XMR_monitor_$(get-date -f yyyy-MM-dd).log"	#if you do not want a log file comment this out. (Add # to the begining of the line)

$castIP = '127.0.0.1'	#IP address of Cast-xmr.  Usually 127.0.0.1 for local machine.
$castPort = '7777'		#port of cast-xmr.  Default 7777
$checkPeriod = 60		#how often to check cast-xmr in seconds
$maxFail = 3			#how many times the hash rate can be under a set vaule before restart
$restartHashRate = 15500000 	#if total hash rate drops below this value cast-xmr will restart (Adjust to approximately 01500000 LESS than your reported average as this value is good for 8 cards)
$sleepBeforeCheck = 5	#number of seconds to wait before trying to connect to cast ip.

#command to start overdrive.  Overdrive should be in the same folder to start. Comment out if you do not want to use overdriveNTool
$overdriveStart = "-p1MINING1 -p2MINING2 -p3MINING3 -p4MINING4 -p5MINING5 -p6MINING6 -p7MINING7-1 -p8MINING8" #Adjust "-p1MINING1" to "-p1(Your OverdriveNTool config name)"

#command to start cast.  Cast must be in the same folder to start. (Make sure to change the wallet address to your own, it's the long string of text just after the -u Also, specify how many cards you are using after the -G (0,1,2,etc to number of cards you are using). -R is needed for monitoring)
$castStart = "cast_xmr-vega.exe -S xmr-us-west1.nanopool.org:14444 -u 47LXCiTehW18h3QZW4rSdt5ticGN7L3iKY9vYjFJMk5LZm2TUh27sBtDRAcotru8AoKW57bxhBUdJDk1ZceBh89YVaY73si -G 0 -R"


###################################################
############### End of UserVeriables ##############
######### MAKE NO CHANGES BELOW THIS LINE #########
###################################################


$global:Url = "http://$castIP`:$castPort"
$scriptDir = Split-Path $MyInvocation.MyCommand.Path -Parent
$scriptName = $MyInvocation.MyCommand.Name


########BEGIN FUNCTIONS########
#Test for Admin
function Force-Admin {
	Param(
	[Parameter(Position=0, Mandatory=$true, ValueFromPipeline=$true)]
	[System.Management.Automation.InvocationInfo]$MyInvocation)
	
	#Get current ID and security principal
	$windowsID = [System.Security.Principal.WindowsIdentity]::GetCurrent()
    $windowsPrincipal = new-object System.Security.Principal.WindowsPrincipal($windowsID)
	
	#Get the admin role security principal
	$adminRole = [System.Security.Principal.WindowsBuiltInRole]::Administrator
	
	#are we in an admin role?
	if (-NOT ($windowsPrincipal.IsInRole($adminRole))) {
		#get the script path
		$scriptPath = $MyInvocation.MyCommand.Path
		$scriptPath = Get-UNCFromPath -Path $scriptPath
		
		#need to quote the paths in case of spaces
		$scriptPath = '"' + $scriptPath + '"'
		
		#build base arguments for powershell.exe
		[string[]]$argList = @('-NoLogo -NoProfile', '-ExecutionPolicy Bypass', '-File', $scriptPath)
		
		#add 
		$argList += $MyInvocation.BoundParameters.GetEnumerator() | Foreach {"-$($_.Key)", "$($_.Value)"}
		$argList += $MyInvocation.UnboundArguments
		
		try
		{    
			$process = Start-Process PowerShell.exe -PassThru -Verb Runas -WorkingDirectory $pwd -ArgumentList $argList
			exit $process.ExitCode
		}
		catch {}
		
		# Generic failure code
		exit 1
	} #if (-NOT ($windowsPrincipal.IsInRole($adminRole)))
} #function Force-Admin

function Log-Write {
	Param ([string]$logstring)
	If ($Logfile)
	{
		Add-content $Logfile -value $logstring
	}
}

function restart_GPU {
	if (Test-Path devcon.exe) {
		#disabling gpu's
		Write-Host -fore Green "`nDisabling GPU's."
		$timeStamp = "{0:yyyy-MM-dd_HH:mm}" -f (Get-Date)
		Log-Write("$timeStamp Disabling GPU's")
		devcon.exe disable "PCI\VEN_1002&DEV_687F"
		Start-Sleep -s 5
		
		#enabling gpu's
		Write-Host -fore Green "`nEnabling GPU's."
		$timeStamp = "{0:yyyy-MM-dd_HH:mm}" -f (Get-Date)
		Log-Write("$timeStamp Enabling GPU's")
		devcon.exe enable "PCI\VEN_1002&DEV_687F"
		Start-Sleep -s 5
		
		Write-Host -fore Green "`nGPU's Reset."
		$timeStamp = "{0:yyyy-MM-dd_HH:mm}" -f (Get-Date)
		Log-Write("$timeStamp GPU's reset")
	} else {
		$timeStamp = "{0:yyyy-MM-dd_HH:mm}" -f (Get-Date)
		Log-Write("$timeStamp Devcon.exe not found. Unable to restart GPU's. continuing")
		Write-Host -fore Red "`nDevcon.exe not found. Unable to restart GPU's. continuing"
	}
}

function Run-Overdrive {
	if (Test-Path overdriveNTool.exe) {
		$timeStamp = "{0:yyyy-MM-dd_HH:mm}" -f (Get-Date)
		Log-Write("$timeStamp Starting OverdriveNTool.exe with following command: %overdriveStart")
		Write-Host -fore Green "`nStarting OverdriveNTool.exe."
        
        $comandsplit = $overdriveStart -split ' '
        "$scriptDir\OverdriveNTool.exe $comandsplit"
        &"$scriptDir\OverdriveNTool.exe" $comandsplit

		Start-Sleep -s 5
		$timeStamp = "{0:yyyy-MM-dd_HH:mm}" -f (Get-Date)
		Log-Write("$timeStamp OverdriveNTool.exe started")
		Write-Host -fore Green "`nOverdriveNTool started."
	} else {
		$timeStamp = "{0:yyyy-MM-dd_HH:mm}" -f (Get-Date)
		Log-Write("$timeStamp OverdriveNTool.exe not found. Not critical. continuing")
		Write-Host -fore Red "`nOverdriveNTool.exe not found. Not critical. continuing"
	}
}

function Start-Mining {
	if (Test-Path cast_xmr-vega.exe) {
		start cmd "/k $castStart"
	} else {
		$timeStamp = "{0:yyyy-MM-dd_HH:mm}" -f (Get-Date)
		Log-Write("$timeStamp CAST_XMR-VEGA.EXE not found.  Cannot continue exiting")
		Write-Host -fore Red "`n`n!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
		Write-Host -fore Red "             cast_xmr-vega.exe not found."
		Write-Host -fore Red "        Can't mine without the mining software"
		Write-Host -fore Red "                     exiting...."
		Write-Host -fore Red "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
		Exit
	}
}

function Check-HashRate {
	
	#checks the current hash rate against $restartHashRate every $checkPeriod
	Clear-Host
	Write-Host -fore Green "`nHash monitoring has begun."
	$timeStamp = "{0:yyyy-MM-dd_HH:mm}" -f (Get-Date)
	Log-Write("$timeStamp Hash monitoring has begun")
	$attempt = 0
	$reason = ""
	$previousRateTot = 0
	
	DO {
		#sleep before checking
		Start-Sleep -s $checkPeriod
		
		Write-Host -fore Green "`nQuerying Cast-xmr...this can take a minute"
		$rawData = Invoke-WebRequest -UseBasicParsing -Uri $global:Url -TimeoutSec 60
		if ($rawData -eq $null){
			#if there is no data then the http request failed.
			$attempt = $attempt + 1
			$reason = "http request failed"
			$timeStamp = "{0:yyyy-MM-dd_HH:mm}" -f (Get-Date)
			Log-Write("$timeStamp Failed to connect to website")
		} else {
			#extract data and write to log files.
			$data = $rawData |ConvertFrom-Json
			$hashRateTot = $data.total_hash_rate
			$avgTot = $data.total_hash_rate_avg
			$sharesAccepted = $data.shares.num_accepted
			$sharesRejected = $data.shares.num_rejected
			$sharesInvalid = $data.shares.num_invalid
			
			$timeStamp = "{0:yyyy-MM-dd_HH:mm}" -f (Get-Date)
			$writedata = "$timeStamp  Hash Rate: $hashRateTot | Avg: $avgTot | Shares Accepted: $sharesAccepted | Shares Rejected: $sharesRejected | Shares Invalid: $sharesInvalid"
			Log-Write("$writedata")
			for ($i=0; $i -lt $data.devices.Length; $i++) {
				$device = $data.devices[$i].device
				$id = $data.devices[$i].device_id
				$hashRate = $data.devices[$i].hash_rate
				$avg = $data.devices[$i].hash_rate_avg
				$gpuTemp = $data.devices[$i].gpu_temperature
				$fanRPM = $data.devices[$i].gpu_fan_rpm
				
				$writedata = "      $device | ID: $id | Hash Rate: $hashRate | Avg: $avg | Temp: $gpuTemp | Fan RPM: $fanRPM"
				Log-Write("$writedata")
			} #for ($i=0; $i -lt $data.devices.Length; $i++)
			
			#check if hashRate has changed.
			if ($hashRateTot -eq $previousRateTot) {
				$attempt = $attempt +1
				$reason = "HashRate hasn't changed.  Cast may be fozen"
				Log-Write("$timeStamp $reason")
				Write-Host -fore Red "`nHash Rate hasn't changed.  Cast may be frozen."
            } else {
                #check if hashRate has dropped.
			    if ($hashRateTot -lt $restartHashRate) {
				    $attempt = $attempt +1
				    $reason = "HashRate is below expected value."
				    Log-Write("$timeStamp $reason")
	    			Write-Host -fore Red "`nHash Rate is below expected value."
                    Write-Host -fore Red "HashRate = $hashrateTot.   expected value = $restartHashRate"
			    } else {
				    $attempt = 0
					Write-Host -fore Green "`nHash Rate approved."
					Write-Host -fore Green "`nHashRate = $hashrateTot"
				} # else ($hashRateTot -lt $restartHashRate)
			} # else ($hashRateTot -eq $previousRateTot)
            
            #update previouse hashRateTotal
            $previousRateTot = $hashRateTot

		} #	else ($rawData -eq $null)
	} while ($attempt -lt $maxFail)
	
	Write-Host -fore Red "`n$reason restarting in 10 seconds"
	$timeStamp = "{0:yyyy-MM-dd_HH:mm}" -f (Get-Date)
	Log-Write("$timeStamp Hash rate below expexted value for too long.  Restarting script in 10 seconds")
	
}

function Kill-Cast {
	Stop-Process -processname cast_xmr-vega
    Stop-Process -processname cmd
}

function Call-Self {
	Start-Process -FilePath "C:\WINDOWS\system32\WindowsPowerShell\v1.0\Powershell.exe" -ArgumentList .\$scriptName -WorkingDirectory $PSScriptRoot -NoNewWindow
	EXIT
}
#########END FUNCTIONS#########

$timeStamp = "{0:yyyy-MM-dd_HH:mm}" -f (Get-Date)
Log-Write("$timeStamp ========== Script Started ==========")

#relaunch if not admin
Force-Admin $script:MyInvocation

restart_GPU

if ($overdriveStart) { #if overdriveStart is defined run it.
	Run-Overdrive
}

Start-Mining

Start-Sleep -s $sleepBeforeCheck

Check-HashRate

Kill-Cast

$timeStamp = "{0:yyyy-MM-dd_HH:mm}" -f (Get-Date)
Log-Write("$timeStamp ========== Script Ended ==========")

Call-Self


##### If we reach this point we have failed #####
Exit
