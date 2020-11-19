#!/bin/bash

# list of patch versions: https://twisteros.com/Patches/latest.txt
# version checker: https://twisteros.com/Patches/checkversion.sh
# simple bash updater script: https://github.com/setLillie/Twister-OS-Patcher/blob/master/patch.sh
# View everything under /Patches/: https://github.com/phoenixbyrd/TwisterOS/tree/master/Patches
# file containing all the patch notes: https://twisteros.com/Patches/message.txt

#example patch url: https://twisteros.com/Patches/TwisterOSv1-9-1Patch.zip

#twistver format: "Twister OS version 1.8.5"

DIRECTORY="$(dirname "$0")"

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
  messagetxt="$(wget -qO- https://twisteros.com/Patches/message.txt)"
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
  URL="$(wget -qO- https://raw.githubusercontent.com/Botspot/TwistUP/main/URLs | grep "$1" | awk '{print $2}')"
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
      echo "$availablepatches" | yad --title='Twister OS Patcher' --list --separator='\n' \
        --text='The following Twister OS patches are available:' \
        --window-icon="${DIRECTORY}/icons/logo.png" \
        --column=Patch --no-headers --no-selection --borders=4 --text-align=left --buttons-layout=spread --width=372 \
        --button="$patch Details"!"${DIRECTORY}/icons/info.png"!"View thge changelog of the $patch patch.":2 \
        --button="Install $patch"!"${DIRECTORY}/icons/update.png"!'This may take a long time.:0' \
        --button="Later"!"${DIRECTORY}/icons/pause.png":1
      button=$?
      if [ "$button" == 0 ];then
        break #exit the loop and install the patch
      elif [ "$button" == 2 ];then
        #patch details
        showchangelog "$patch"
      else
        #WM X , ESC, killed, etc.
        exit 0
      fi
    done
  else
    #cli
    echo -n "Install the $patch patch now? This will take a while. [Y/n] "
    read answer
    if [ "$answer" == 'n' ];then
      exit 0
    fi
  fi

  dashpatch="$(patch2dash "$patch")"

  URL="$(patch2url "$patch")"
  #download
  #support for .zip formats and .run formats
  if [[ "$URL" = *.run ]];then
    echo "Patch is in .run format."
    rm -f ./patch.run 2>/dev/null
    script="cd "\""$DIRECTORY"\""
      wget "\""$URL"\"" -O $(pwd)/patch.run
      chmod +x $(pwd)/patch.run
      $(pwd)/patch.run"
  elif [[ "$URL" = *.zip ]];then
    echo "Patch is in .zip format."
    rm -f ./*patchinstall.sh 2>/dev/null
    rm -rf ./patch 2>/dev/null
    script="cd "\""$DIRECTORY"\""
      wget "\""$URL"\"" -O $(pwd)/patch.zip
      unzip $(pwd)/patch.zip
      rm $(pwd)/patch.zip
      chmod +x $(pwd)/${dashpatch}patchinstall.sh
      $(pwd)/${dashpatch}patchinstall.sh"
  else
    error "URL $URL does not end with .zip or .run!"
  fi
  #install
  if [[ "$runmode" == gui* ]];then
    echo "Running in a terminal."
    x-terminal-emulator -e /bin/bash -c "trap 'echo '\''Close this terminal to exit.'\'' ; sleep infinity' EXIT
      $script"
    #x-terminal-emulator -e "bash -c 'echo y | "./${dashpatch}patchinstall.sh"'"
  else
    #if already running in a terminal, don't open another terminal
    bash -c "$script"
  fi
}
cd "$DIRECTORY"

#clean up old patches on exit

rm -f ./*patchinstall.sh 2>/dev/null
rm -rf ./patch 2>/dev/null
rm -f ./patch.run 2>/dev/null

#operation mode of the whole script. Allowed values: gui, gui-update, cli, cli-yes
runmode="$1"

if [ -z "$runmode" ];then
  runmode=cli
fi

#ensure yad dialog is installed
if [ "$runmode" == 'gui' ] && [ ! -f '/usr/bin/yad' ];then
  error "YAD is required but not installed. Please run 'sudo apt install yad' in a terminal."
elif [ "$runmode" == 'gui' ] && [ -z "$DISPLAY" ];then
  error "Are you in the console? You are trying to run this script in GUI mode, but the DISPLAY variable is not set."
fi

#ensure twistver exists
if [ ! -f /usr/local/bin/twistver ];then
  error "twistver not found!"
fi
localversion="$(twistver | awk 'NF>1{print $NF}')"
echo "current version: $localversion"

patchlist="$(wget -qO- https://raw.githubusercontent.com/Botspot/TwistUP/main/URLs)"
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

if [ "$1" != 'gui' ] && [ "$latestversion" == "$localversion" ];then
  #no update available, and if any mode but gui
  echo -e "Your version of Twister OS is fully up to date already.\nExiting now."
  exit 0
elif [ "$1" != 'gui' ] && [ "$latestversion" != "$localversion" ];then
  #update is available, and if any mode but gui
  update
  exit 0
elif [ "$1" == 'gui' ];then
  #updates available or not, it doesn't matter. This will open the main dialog.
  
  if [ "$latestversion" != "$localversion" ];then
    updatebutton="--button=See update:0"
    updateline="--field=Update available!:LBL"
  fi
  
  bodytext="--field=Current version: $localversion
Latest version: $latestversion:LBL"
  
  yad --title='TwistUP' --form --separator='\n' \
    --window-icon="${DIRECTORY}/icons/logo.png" \
    --borders=4 --buttons-layout=spread --width=300 \
    "$bodytext" \
    "$updateline" \
    "$updatebutton" \
    --button="Close!${DIRECTORY}/icons/exit.png:1" || exit 0
  update
fi


