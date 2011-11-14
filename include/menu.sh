#!/bin/bash

# Read Config File
source include/config

# Text color variables
txtund=$(tput sgr 0 1)    # Underline
txtbld=$(tput bold)       # Bold
txtred=$(tput setaf 1)    # Red
txtgrn=$(tput setaf 2)    # Green
txtylw=$(tput setaf 3)    # Yellow
txtblu=$(tput setaf 4)    # Blue
txtpur=$(tput setaf 5)    # Purple
txtcyn=$(tput setaf 6)    # Cyan
txtwht=$(tput setaf 7)    # White
txtrst=$(tput sgr0)       # Text reset

# Find PID of the screen session for the menu.
menuscreenpid=`screen -ls |grep bukkitmenu |cut -f 1 -d .`

# Find PID of Bukkit Server.
checkServer () {
	MCPID=`ps -ef |grep -i craftbukkit-0.0.1-SNAPSHOT.jar |grep -v grep |awk '{ print $2 }'`
}

# Update Bukkit to Latest Recommended.
update () {
	stopServer
	# Download Latest, overwrite existing.
	wget -m -nd --progress=dot:mega -P $bukkitdir http://ci.bukkit.org/job/dev-CraftBukkit/promotion/latest/Recommended/artifact/target/craftbukkit-0.0.1-SNAPSHOT.jar
	cat /dev/null > $bukkitdir/server.log
	startServer
}

# Install MineQuery Plugin. Restart Server.
installmq () {
	clear
	wget -m -nd --progress=dot:mega -P $bukkitdir/plugins https://github.com/downloads/vexsoftware/minequery/Minequery-1.5.zip
	unzip -o $bukkitdir/plugins/Minequery-1.5.zip -d $bukkitdir/plugins/
	rm $bukkitdir/plugins/Minequery-1.5.zip
	stopServer
	startServer
}

# Start Bukkit Server
startServer () {
	clear
	checkServer
	# Need to recheck for screen PID for bukket-server session. In case it has been stopped.
	serverscreenpid=`screen -ls |grep bukkit-server |cut -f 1 -d .`
	if [[ -z $MCPID ]]; then
		logrotate -f -s include/rotate.state include/rotate.conf
		rm include/rotate.state
		cd $bukkitdir
		if [[ -z $serverscreenpid ]]; then
			screen -d -m -S bukkit-server
		fi

		#if using ramdisk copy from local to ramdisk.
        	if [ $ramdisk = true ]; then
                	for x in ${worlds[*]}
                  	do
                    	[ "$(ls -A $bukkitdir/$x-offline/)" ] && cp -rfv "$bukkitdir/$x-offline/"* "$bukkitdir/$x/" >>  "$bukkitdir/server.log" || echo "Nothing to Copy..."
                    	find "$bukkitdir/$x" -type f -print0 | xargs -0 md5sum | cut -f 1 -d " " | sort -rn  > "$x.md5" 
                    	find "$bukkitdir/$x-offline" -type f -print0 | xargs -0 md5sum | cut -f 1 -d " " | sort -rn > "$x-offline.md5"
                    	md5=`diff "$x.md5" "$x-offline.md5"`
                      	  if [ -n "$md5" ]; then
                            echo $txtred "#### Warning! #### Warning! ####" $txtrst
                            echo "MD5 Check Failed for $x"
                            echo "Please investigate."
                            read -p "Hit any key to continue..."
                            clear
                            elif [ -z "$md5" ]; then
                            echo $txtgrn "Copied $x from Localdisk to Ramdisk Sucessully!" $txtrst
                            sleep 2 
                            clear
                           fi
                        rm -f "$x.md5" "$x-offline.md5"
                  	done
        	fi
		# Start craftbukkit on existing screen session.
		screen -S bukkit-server -p 0 -X exec java $jargs -jar $bukkitdir/craftbukkit-0.0.1-SNAPSHOT.jar nogui
		cd -
	elif [[ $MCPID ]]; then
			echo -e "Server Already Running.."
			sleep 1
	fi
}

# Stop Bukkit Server
stopServer () {
	clear
	checkServer
	if [[ -z $MCPID ]]; then
		clear
		echo "Bukkit Not Running.."
		sleep 1
	else
		screen -S bukkit-server -p 0 -X eval 'stuff "save-all"\015'
		screen -S bukkit-server -p 0 -X eval 'stuff "stop"\015'
		while [[ $MCPID ]]; do
			echo "Bukkit Shutdown in Progress.."
			checkServer
      		clear
		done
                if [ $ramdisk = true ]; then
                  for x in ${worlds[*]}
                    do
                      cp -rfv "$bukkitdir/$x/"* "$bukkitdir/$x-offline/"  >>  "$bukkitdir/server.log"
                    find "$bukkitdir/$x" -type f -print0 | xargs -0 md5sum | cut -f 1 -d " " | sort -rn > "$x.md5"
                    find "$bukkitdir/$x-offline" -type f -print0 | xargs -0 md5sum | cut -f 1 -d " " | sort -rn > "$x-offline.md5"
                    md5=`diff "$x.md5" "$x-offline.md5"`
                      if [ -n "$md5" ]; then
                        echo $txtred "#### Warning! #### Warning! ####" $txtrst
                        echo "MD5 Check Failed for $x"
                        echo "Please investigate."
                        read -p "Hit any key to continue..."
			clear
                        elif [ -z "$md5" ]; then
			clear
			echo $txtgrn "Copied $x from Ramdisk to Localdisk Sucessully!" $txtrst
                        sleep 2 
			clear
                        fi
                        rm -f "$x.md5" "$x-offline.md5"
                    done
                fi
		screen -S bukkit-server -X quit
	fi
}


# Send Server Commands 
serverCommands () {
	clear
	echo -e "Send Server Command: \c"
	read command
	screen -S bukkit-server -p 0 -X eval 'stuff '"\"$command\""'\015'
}

# Quit Function
quitFucntion () {
	clear
	echo "Bye"
	$txtrst
	clear
	screen -d -S bukkit-server
	kill $menuscreenpid
	exit 0
}


# Menu Structure.
showMenu () {
        echo "1:$txtgrn Start"$txtrst
        echo "2:$txtred Stop"$txtrst
        echo "3:$txtylw Restart"$txtrst
	echo "4:$txtwht Send Server Command"$txtrst
	echo "5:$txtwht Update Bukkit"$txtrst
	  if [[ ! -f "$bukkitdir/plugins/Minequery.jar" ]]; then
	    echo "6:$txtwht Install Minequery"$txtrst
	    echo "    -Adds Functionality"
	    echo "    -Will Restart Bukkit"
	  fi
	echo " "
        echo "0:$txtred Quit ABM"$txtrst
}

# Display Menu and wait for choice.
while [ 1 ]
do
	clear
	showMenu
	echo
	echo -e "Enter Choice: \c"	
	read CHOICE
	case "$CHOICE" in
		"1")
			echo "Starting Server.."
			startServer	
			sleep 1
			;;

		"2")
			echo "Stopping Server.."
            		stopServer 
			;;

		"3")
			echo "Restarting Server.."
			stopServer
			startServer
			;;
		"4")
			serverCommands
			;;
		"5")
			update
			;;
		"6")
			installmq
			;;
		"0")
			quitFucntion
                        ;;
		"q")	
			quitFucntion
			;;
                *) echo "\"$CHOICE\" is not valid "; sleep 2 ;;
        esac
done
