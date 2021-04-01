#!/bin/bash

# list of patch versions: https://twisteros.com/Patches/latest.txt
# version checker: https://twisteros.com/Patches/checkversion.sh
# simple bash updater script: https://github.com/setLillie/Twister-OS-Patcher/blob/master/patch.sh
# View everything under /Patches/: https://github.com/phoenixbyrd/TwisterOS/tree/master/Patches
# file containing all the patch notes: https://twisteros.com/Patches/message.txt

#example patch url: https://twisteros.com/Patches/TwisterOSv1-9-1Patch.zip

#twistver format: "Twister OS version 1.8.5"

DIRECTORY="$(dirname "$(readlink -f "$0")")"
echo "$DIRECTORY"
function error {
  echo -e "\e[91m$1\e[39m"
  if [ "$runmode" == 'gui' ];then
    zenity --error --text="TwistUP error:\n$1" --no-wrap
  fi
  exit 1
}

getchangelog() {
  #downloads the changelog for a specified patch.
  #usage: getchangelog 1.9.1
  #outputs the full changelog in plain-text
  messagetxt="$(wget -qO- https://twisteros.com/Patches/messageUI.txt)"
  changelog="$(echo "$messagetxt" | sed -e "0,/Version $1 patch notes:/d" | sed -e "/patch notes:/q" | head -n -2)"
  firstline="$(echo "$messagetxt" | grep "Version $1 patch notes:")"
  echo -e "${firstline}\n${changelog}"
}

showchangelog() {
  #displays the changelog in a YAD window.
  #usage: showchangelog 1.9.1
  #does not produce any output.
  getchangelog "$1" | yad --title="Changelog of $1" --text-info --wrap \
    --center --width=700 --height=400 --fontname=12 \
    --window-icon="${DIRECTORY}/icons/logo.png" \
    --button="Back"!"${DIRECTORY}/icons/back.png":0
}

patch2url() {
  #get URL to download, when given a patch number
  #usage: patch2url 1.9.1
  #outputs the full URL to the patch
  URL="$(wget -qO- https://twisteros.com/Patches/URLsUI | grep "$1" | awk '{print $2}')"
  if [ $? != 0 ] || [ -z "$URL" ];then
    error "Failed to determine URL for patch ${1}!"
  fi
  echo "$URL"
}

patch2dash() {
  #convert patch version from '1.9.1' to '1-9-1' format
  echo "$1" | tr '.' '-'
}

update() {
  #
  
  #what line in the text file is the current local patch version?
  nextpatchnumber="$(echo "$patchlist" | grep -nx "$localversion" | cut -f1 -d:)"
  if [ -z "$nextpatchnumber" ];then
    error "Failed to determine the patch number!"
  fi
  #subtract 1 from it, to determine the line number for the next available patch
  nextpatchnumber="$((nextpatchnumber-1))"

  availablepatches="$(echo "$patchlist" | head -n "$nextpatchnumber")"
  echo -n "Available new patch(es): $availablepatches" | tr '\n' ' '
  echo ''

  #get oldest patch to be applied first
  patch="$(echo "$availablepatches" | tail -1 )"

  #confirmation dialog
  if [ "$runmode" == 'cli-yes' ];then
    echo "This patch will be applied now: $patch"
  elif [[ "$runmode" == gui* ]];then
    while true;do
      echo "$availablepatches" | yad --title='Twister UI Patcher' --list --separator='\n' \
        --text='The following Twister UI patches are available:' \
        --window-icon="${DIRECTORY}/icons/logo.png" \
        --column=Patch --no-headers --no-selection --borders=4 --text-align=left --buttons-layout=spread --width=372 \
        --button="$patch Details"!"${DIRECTORY}/icons/info.png"!"View the changelog of the $patch patch.":2 \
        --button="Install $patch"!"${DIRECTORY}/icons/update.png"!'This may take a long time.:0' \
        --button="Close!${DIRECTORY}/icons/exit.png:1"
      button=$?
      if [ "$button" == 0 ];then
        break #exit the loop and install the patch
      elif [ "$button" == 2 ];then
        #patch details
        showchangelog "$patch"
      else
        #WM X, ESC, killed, etc.
        exit 0
      fi
    done
  else
    #cli
    echo -n "Install the $patch patch now? This may take a while. [Y/n] "
    read answer
    if [ "$answer" == 'n' ];then
      exit 0
    fi
  fi
  
  dashpatch="$(patch2dash "$patch")"
  
  rm -f ./*patchinstall.sh 2>/dev/null
  rm -rf ./patch 2>/dev/null
  rm -f ./patch.run 2>/dev/null
  
  URL="$(patch2url "$patch")"
  #download
  #support for .zip formats and .run formats
  if [[ "$URL" = *.run ]];then
    echo "Patch is in .run format."
    rm -f ./patch.run 2>/dev/null
    script="wget "\""$URL"\"" -O $(pwd)/patch.run
      chmod +x $(pwd)/patch.run
      $(pwd)/patch.run --noexec --target $(pwd)/patch
      cat $(pwd)/patch/*patchinstall.sh | grep -vE ' reboot| restart|clear' > $(pwd)/patch/twistup-patchinstall.sh
      chmod +x $(pwd)/patch/twistup-patchinstall.sh
      cd $(pwd)/patch/
      $(pwd)/patch/twistup-patchinstall.sh
      echo -e '\e[42mPatching complete.\e[49m'"
  elif [[ "$URL" = *.zip ]];then
    echo "Patch is in .zip format."
    rm -f ./*patchinstall.sh 2>/dev/null
    rm -rf ./patch 2>/dev/null
    script="wget "\""$URL"\"" -O $(pwd)/patch.zip
      unzip $(pwd)/patch.zip
      rm $(pwd)/patch.zip
      chmod +x $(pwd)/*patchinstall.sh
      $(pwd)/*patchinstall.sh"
  else
    error "URL $URL does not end with .zip or .run!"
  fi
  #install
  if [[ "$runmode" == gui* ]];then
    echo "Running in a terminal."
    "$DIRECTORY/terminal-run" "trap 'echo '\''Close this terminal to exit.'\'' ; sleep infinity' EXIT
      cd "\""$DIRECTORY"\""
      $script
      yad --title='Twister OS Patcher' \
      --text="\""$patch patch complete. Reboot now?"\"" \
      --window-icon="\""${DIRECTORY}/icons/logo.png"\"" \
      --button="\""Reboot!${DIRECTORY}/icons/power.png"\"":0 \
      --button="\""Later!${DIRECTORY}/icons/exit.png"\"":1 && sudo reboot"
  else
    #if already running in cli mode, don't open another terminal
    bash -c "$script"
    #ask to reboot if cli mode
    if [ "$runmode" == cli ];then
      read -p "Would you like to reboot now? [Y/n] " answer
      if [ "$answer" == 'n' ];then
        exit 0
      else
        sudo reboot
        exit 0
      fi
    fi
  fi
}
cd "$DIRECTORY"

#clean up old patches

rm -f ./*patchinstall.sh 2>/dev/null
rm -rf ./patch 2>/dev/null
rm -f ./patch.run 2>/dev/null

#operation mode of the whole script. Allowed values: gui, gui-update, cli, cli-yes
runmode="$1"

if [ -z "$runmode" ];then
  runmode=cli
fi

#ensure yad dialog is installed
if [[ "$runmode" == gui* ]] && [ ! -f '/usr/bin/yad' ];then
  error "YAD is required but not installed. Please run 'sudo apt install yad' in a terminal."
elif [[ "$runmode" == gui* ]] && [ -z "$DISPLAY" ];then
  error "Are you in the console? You are trying to run this script in GUI mode, but the DISPLAY variable is not set."
fi

#create autostart file
if [ ! -f ~/.config/autostart/twistup.desktop ];then
  echo "[Desktop Entry]
Type=Application
Name=TwistUP
Comment=Twister OS Patcher (TwistUP)
Exec=twistpatch gui-autostart
OnlyShowIn=XFCE;
StartupNotify=false
Terminal=false
Hidden=false" > ~/.config/autostart/twistup.desktop
fi

if [ "$(readlink -f /usr/local/bin/twistpatch)" == '/home/pi/patcher/src/start.sh' ] || [ ! -f /usr/local/bin/twistpatch ];then
  echo "Created /usr/local/bin/twistpatch."
  sudo rm -f /usr/local/bin/twistpatch 2>/dev/null
  sudo ln -s "$0" /usr/local/bin/twistpatch
fi

#ensure twistver exists
if [ ! -f /usr/local/bin/twistver ];then
  error "twistver not found!"
fi
localversion="$(twistver | awk 'NF>1{print $NF}')"
echo "current version: $localversion"

patchlist="$(wget -qO- https://twisteros.com/Patches/URLsUI)"
if [ $? != 0 ] || [ -z "$patchlist" ];then
  error "Failed to download the patch list! Are you connected to the Internet?"
fi
#remove URLs from each line in the patchlist, only leave patch numbers
patchlist="$(echo "$patchlist" | awk '{print $1}')"
#add local version to patch list in case local version is not mentioned in patch list
patchlist="$(echo -e "${patchlist}\n${localversion}" | sort -r | uniq)"
#echo "Patch list: $patchlist"

#get the first line - that's the latest patch
latestversion="$(echo "$patchlist" | head -n1)"
if [ -z "$latestversion" ];then
  error "Failed to determine latest version!"
fi

echo "latest version: $latestversion"

runmode="$1"
if [ -z "$runmode" ];then
  runmode=gui
fi

if [ ! -f "${DIRECTORY}/no-update-patcher" ];then
  localhash="$(git rev-parse HEAD)"
  latesthash="$(git ls-remote https://github.com/Botspot/TwistUP HEAD | awk '{print $1}')"
  if [ "$localhash" != "$latesthash" ] && [ ! -z "$latesthash" ] && [ ! -z "$localhash" ];then
    echo "TwistUP is out of date. Downloading new version..."
    gio trash "$DIRECTORY"
    git clone https://github.com/Botspot/TwistUP "$DIRECTORY"
  fi
fi

if [[ "$runmode" == cli* ]] || [ "$runmode" == gui-update ];then
  if [ "$latestversion" == "$localversion" ];then
    #no update available
    echo -e "\nYour version of Twister UI is fully up to date already.\nExiting now."
    exit 0
  elif [ "$latestversion" != "$localversion" ];then
    #update is available
    update
    exit 0
  fi
elif [ "$runmode" == 'gui-autostart' ] && [ "$latestversion" != "$localversion" ];then
  nextcheck="$(cat "${DIRECTORY}/nextcheck")"
  if [ -z $nextcheck ];then
    echo "Warning: ${DIRECTORY}/nextcheck does not exist."
    nextcheck=0
  fi
  
  if [ "$nextcheck" == 'never' ];then
    echo "${DIRECTORY}/nextcheck prevents TwistUP from ever checking for updates. Goodbye!"
    exit 0
  fi
  
  #update interval check
  if [ ! "$(date +%j)" -ge "$nextcheck" ];then
    #fix for the end of the year, and situations where nextcheck is 365+, but it's Jan 1st or later
    if [ "$((nextcheck-7))" -gt "$(date +%j)" ];then
      rm "${DIRECTORY}/nextcheck"
    fi
    echo "${DIRECTORY}/nextcheck says to skip update checks for today. Goodbye!"
    exit 0
  fi
  
  #update interval allows a dialog to open
  screen_width="$(xdpyinfo | grep 'dimensions:' | tr 'x' '\n' | tr ' ' '\n' | sed -n 7p)"
  screen_height="$(xdpyinfo | grep 'dimensions:' | tr 'x' '\n' | tr ' ' '\n' | sed -n 8p)"
  
  output="$(yad --form --text='Twister OS can be updated.' \
    --on-top --skip-taskbar --undecorated --close-on-unfocus \
    --geometry=260+$((screen_width-262))+$((screen_height-150)) \
    --field="Never show this again:CHK" --image="${DIRECTORY}/icons/logo.png" \
    --button="Details!${DIRECTORY}/icons/info.png":0 --button="Later!${DIRECTORY}/icons/exit.png!We"\'"ll remind you in a week.":2)"
  button=$?
  echo "output is '$output'"
  
  if [ $button == 0 ];then
    update
    exit 0
  elif [ $button == 2 ];then
    echo "$(($(date +%j)+7))" > "${DIRECTORY}/nextcheck"
  fi
  if [[ "$output" == TRUE* ]];then
    echo 'never' > "${DIRECTORY}/nextcheck"
  fi
elif [ "$runmode" == 'gui' ];then
  #updates available or not, it doesn't matter. This will open the main dialog.
  
  twistsite() {
    chromium-browser https://twisteros.com
  }
  export -f twistsite
  site="bash -c twistsite"
  if [ "$latestversion" != "$localversion" ];then
    updatebutton="--button=See update:0"
    updateline="--field=Update available!:LBL"
  else
    updatebutton="--button=TwisterOS site":"bash -c twistsite"
    updateline="--field=You are up to date.:LBL"
  fi
  bodytext="--field=Current version: $localversion
Latest version: $latestversion:LBL"
  
  yad --title='TwistUP' --form --separator='\n' --center \
    --window-icon="${DIRECTORY}/icons/logo.png" \
    --borders=4 --buttons-layout=spread --width=300 \
    "$bodytext" \
    "$updateline" \
    "$updatebutton" \
    --button="Close!${DIRECTORY}/icons/exit.png:1" || exit 0
  unset twistsite
  update
fi


