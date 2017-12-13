# Fiddlefigners-cast_xmr-hashrate-monitor-and-restart-tool
Fiddlefingers Cast-xmr Hash rate monitor and restart Tool.
Version 0.2

Created due to the stability issue with the Vega GPU's and Cast-XMR and not wanting to constantly
monitor the system manually.

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
				
***IMPORTANT NOTE *** The script will close all command prompt windows when restarting the
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
