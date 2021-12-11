# TwistUP
## The new, simple Twister OS patcher
AKA TwisterOS Patcher 2.0!
![](https://media.discordapp.net/attachments/738534235194916884/759921733825462322/TwisterOSPatcherLogo.png?width=960&height=186)  

## To download to the ~/TwistUP folder
```
git clone https://github.com/Botspot/TwistUP
```
## To download to ~/patcher
```
gio trash ~/patcher
git clone https://github.com/Botspot/TwistUP patcher
```
## Enter directory:
```
cd ~/patcher
#or
cd ~/TwistUP
```
## To run:
```
./patch.sh
```
## Flags:
### Lists available patches in the terminal and asks permission to update.
Intended **for users who prefer patching "manually"**.
```
./patch.sh cli
```
### Just like above, but automatically applies the patch.
Intended to be **used in non-interactive scripts**.
```
./patch.sh cli-yes
```
### GUI Update mode.
Uses a YAD dialog to display a list of available patches and asks for confirmation. If no updates available, no window appears.  
Intended for... **I don't know**. Someone might prefer this over `gui`.
```
./patch.sh gui-update
```
### GUI mode.
Uses a YAD dialog to display local version and latest version. If an update is available, this displays a Details button to install the patch.
Intended to be **launched from the Menu**.
```
./patch.sh gui
```
### GUI autostart mode.
If updates are available, this displays a notification on the bottom-right of the screen to let you know.  
Intended to be **run on start-up**.
```
./patch.sh gui-autostart
```

## Auto updating:
As of commit [c8e8c15](https://github.com/Botspot/TwistUP/commit/ab4a41750c26918f5753946e89d3d9b9d701d430), **TwistUP automatically keeps itself updated** whenever `patch.sh` is executed.  
To disable this, create a file in your `~/TwistUP` folder (or `~/patcher` folder) named `no-update-patcher`. The file can be empty.
