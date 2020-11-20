# TwistUP (For TwisterOS)
## The new, simple Twister OS patcher
AKA TwisterOS Patcher 2.0!
![](https://media.discordapp.net/attachments/738534235194916884/759921733825462322/TwisterOSPatcherLogo.png?width=960&height=186)<br>

### To download: 
```
git clone https://github.com/Botspot/TwistUP
```
### To run:
```
~/TwistUP/twistup.sh
```
### CLI flags:
```
#CLI mode (default)
~/TwistUP/twistup.sh cli
#CLI mode, but it automatically applies the next patch without asking for confirmation
~/TwistUP/twistup.sh cli-yes
#Update mode. Uses a YAD dialog to display available patches and asks for confirmation. Also, this version opens a new terminal when installing a patch.
~/TwistUP/twistup.sh gui-update
#GUI mode. Uses a YAD dialog to display local version and latest version. If an update is available, this displays a Details button to install the patch.
~/TwistUP/twistup.sh gui
```
