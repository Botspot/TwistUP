#!/bin/bash

# list of patch versions https://twisteros.com/Patches/latest.txt
# version checker https://twisteros.com/Patches/checkversion.sh
# simple bash updater script https://github.com/setLillie/Twister-OS-Patcher/blob/master/patch.sh
# View everything under /Patches/ https://github.com/phoenixbyrd/TwisterOS/tree/master/Patches

#example patch url https://twisteros.com/Patches/TwisterOSv1-9-1Patch.zip

#twistver format: "Twister OS version 1.8.5"

DIRECTORY="$(dirname "$0")"

function error {
  echo -e "\e[91m$1\e[39m"
  if [ "$runmode" == 'gui' ];then
    zenity --error --text="TwistUP error:\n$1" --no-wrap
  fi
  exit 1
}

cd "$DIRECTORY"

#clean up old patches on exit
trap "cd "\""$DIRECTORY"\""
rm -f ./*patchinstall.sh 2>/dev/null
rm -rf ./patch 2>/dev/null
rm -f ./patch.run 2>/dev/null" EXIT

#operation mode fo the whole script. Allowed values: gui, cli, cli-yes
runmode="$1"

if [ -z "$runmode" ];then
  runmode=cli
fi

if [ "$runmode" == 'gui' ] && [ ! -f '/usr/bin/yad' ];then
  error "YAD is required but not installed. Please run 'sudo apt install yad' in a terminal."
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
#remove "Twister OS version " from each line in the patchlist
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

if [ "$latestversion" == "$localversion" ];then
  echo -e "Your version of Twister OS is fully up to date already.\nExiting now."
  exit 0
fi

#what line in the text file is the current local patch version?
nextpatchnumber="$(echo "$patchlist" | grep -nx "$localversion" | cut -f1 -d:)"
if [ -z "$nextpatchnumber" ];then
  error "Failed to determine the patch number!"
fi
#subtract 1 from it, to determine the line number for the next available patch
nextpatchnumber="$((nextpatchnumber-1))"

availablepatches="$(echo "$patchlist" | head -n "$nextpatchnumber")"
echo "Available new patch(es): $availablepatches"

#get oldest patch to be applied first
patch="$(echo "$availablepatches" | tail -1 )"

#confirmation dialog
if [ "$runmode" == 'cli-yes' ];then
  echo "This patch will be applied now: $patch"
elif [ "$runmode" == 'gui' ];then
  echo "$availablepatches" | yad --title='Twister OS Patcher' --list --separator='\n' \
    --text='The following TwisterOS patches are available:' \
    --window-icon="${DIRECTORY}/icons/logo.png" \
    --column=Patch --no-headers --no-selection --borders=4 --buttons-layout=spread --width=372 \
    --button="Install $patch now"!"${DIRECTORY}/icons/update-16.png"!'This may take a long time.:0' \
    --button="Later"!"${DIRECTORY}/icons/pause.png"!:1 || exit 0
else
  #cli
  echo -n "Apply the $patch now? This will take a while. [Y/n] "
  read answer
  if [ "$answer" == 'n' ];then
    exit 0
  fi
fi

#convert patch version from '1.9.1' to '1-9-1' format
dashpatch="$(echo "$patch" | tr '.' '-')"

#get URL to download
URL="$(cat "${DIRECTORY}/URLs" | grep "$patch" | awk '{print $2}')"
echo "URL is $URL"
if [ -z "$URL" ];then
  error "Failed to determine URL to download patch ${patch}!"
fi

rm -f ./*patchinstall.sh 2>/dev/null
rm -rf ./patch 2>/dev/null
rm -f ./patch.run 2>/dev/null

#support for .zip formats and .run formats
if [[ "$URL" = *.run ]];then
  echo "Patch is in .run format."
  script="cd "\""$DIRECTORY"\""
    wget "\""$URL"\"" -O ./patch.run
    chmod +x ./patch.run
    ./patch.run"
elif [[ "$URL" = *.zip ]];then
  echo "Patch is in .zip format."
  script="cd "\""$DIRECTORY"\""
    wget "\""$URL"\"" -O ./patch.zip
    unzip ./patch.zip
    rm ./patch.zip
    chmod +x ./${dashpatch}patchinstall.sh
    ./${dashpatch}patchinstall.sh"
else
  error "URL $URL does not end with .zip or .run!"
fi

if [ "$runmode" == 'gui' ];then
  echo "Running in a terminal."
  x-terminal-emulator -e /bin/bash -c "$script"
  #x-terminal-emulator -e "bash -c 'echo y | "./${dashpatch}patchinstall.sh"'"
else
  #if already running in a terminal, don't open another terminal
  bash -c "$script"
fi
