#!/bin/bash

# ====================================================================
# tigerbrew-node-config.command
#
# Configure an OS X system as a Tigerbrew test node.
# Assumes that Developer Tools & Remote Desktop Client are installed.
# Only tested on 10.4 and 10.5 so far.
#
# @EricFromCanada
# ====================================================================

# close System Preferences if open
osascript -e 'tell application "System Preferences" to quit'

# ask for admin password
sudo -v

# get current CPU and OS
CPU=$(system_profiler SPHardwareDataType | sed -nE 's/ *(CPU Type|Processor Name): (( ?[[:alnum:]]+)+).*/\2/p' | sed 's/ 750/ G3/')
[ -z "$CPU" ] && CPU="Intel"
CPU_ARCH="${CPU%% *}"
CPU_NAME="${CPU#* }"
OSX=$(sw_vers -productVersion | sed -nE 's/([[:digit:]]+\.[[:digit:]]+).*/\1/p')
case $OSX in
    10.4) OSX_NAME="Tiger" ;;
    10.5) OSX_NAME="Leopard" ;;
    10.6) OSX_NAME="Snow Leopard" ;;
    10.7) OSX_NAME="Lion" ;;
    10.8) OSX_NAME="Mountain Lion" ;;
    *) echo "This system does not meet the requirements for Tigerbrew." && exit 1 ;;
esac

# set node name, e.g. "Tiger G4" or "Leopard Intel"
[ $CPU_ARCH = "Intel" ] && NAME="$OSX_NAME $CPU_ARCH" || NAME="$OSX_NAME $CPU_NAME"

# locate commands
[ -x /usr/sbin/networksetup ] && NETWORKSETUP="/usr/sbin/networksetup" || NETWORKSETUP="/System/Library/CoreServices/RemoteManagement/ARDAgent.app/Contents/Support/networksetup"
[ -x /usr/sbin/systemsetup ] && SYSTEMSETUP="/usr/sbin/systemsetup" || SYSTEMSETUP="/System/Library/CoreServices/RemoteManagement/ARDAgent.app/Contents/Support/systemsetup"
[ -x /usr/libexec/PlistBuddy ] && PLISTBUDDY="/usr/libexec/PlistBuddy" || PLISTBUDDY="/Library/Receipts/DeveloperTools.pkg/Contents/Resources/PlistBuddy"


# =======================
echo "- System"
# =======================

# set network name
sudo scutil --set ComputerName "${NAME}"
sudo scutil --set LocalHostName "${NAME/ /-}"
sudo scutil --set HostName "${NAME/ /-}"

# disable AirPort
# http://osxdaily.com/2011/05/31/enable-disable-airport-wireless-connections-command-line/
sudo $NETWORKSETUP -setairportpower off
## did not work for Macmini2,1 running Tiger, i.e. the `-getairportpower` flag always returns "Off"

# disable Bluetooth keyboard/mouse prompt
# https://managingosx.wordpress.com/2006/02/10/managing-bluetooth-or-pesky-apple-preferences/
if [[ $(system_profiler SPBluetoothDataType) ]]; then
    ## for 10.5 and later
    if [ -f /Library/Preferences/com.apple.Bluetooth.plist ]; then
        sudo defaults write /Library/Preferences/com.apple.Bluetooth BluetoothAutoSeekHIDDevices -bool false
    ## for 10.4
    else
        sudo defaults write blued BluetoothAutoSeekHIDDevices -bool false
    fi
    sudo killall -HUP blued
fi

# disable screen saver
defaults -currentHost write com.apple.screensaver moduleName "Computer Name"
defaults -currentHost write com.apple.screensaver modulePath "/System/Library/Frameworks/ScreenSaver.framework/Resources/Computer Name.saver"
defaults -currentHost write com.apple.screensaver idleTime -int 0

# set desktop to solid colour
case $OSX-$CPU_NAME in
    10.4-G3) FILE="Solid Gray Dark" ;;
    10.4-G4) FILE="Solid Gray Medium" ;;
    10.4-G5) FILE="Solid Aqua Graphite" ;;
    10.4-*) FILE="Solid Gray Light" ;;
    10.5-G4) FILE="Solid Aqua Dark Blue" ;;
    10.5-G5) FILE="Solid Aqua Blue" ;;
    10.5-*) FILE="Solid Mint" ;;
    10.6-*) FILE="Solid Kelp" ;;
    10.7-*) FILE="Solid Lavender" ;;
    *) FILE="Solid White" ;;
esac
osascript -e 'tell application "Finder" to set desktop picture to POSIX file "/Library/Desktop Pictures/Solid Colors/'"$FILE"'.png"'

# enable wake-on-LAN
sudo pmset -a womp 1

# disable sleep
$SYSTEMSETUP -setcomputersleep Never

# enable remote login
$SYSTEMSETUP -setremotelogin on

# enable remote management
## unset all existing Remote Management settings and prefs
sudo /System/Library/CoreServices/RemoteManagement/ARDAgent.app/Contents/Resources/kickstart -quiet -uninstall -settings -prefs
## enable Remote Management, add privileges for current user
sudo /System/Library/CoreServices/RemoteManagement/ARDAgent.app/Contents/Resources/kickstart -quiet -configure -access -on -privs -all -users $USER
## restrict access to specific user (10.5 and later)
sudo /System/Library/CoreServices/RemoteManagement/ARDAgent.app/Contents/Resources/kickstart -quiet -configure -allowAccessFor -specifiedUsers
## set other options
sudo /System/Library/CoreServices/RemoteManagement/ARDAgent.app/Contents/Resources/kickstart -quiet -configure -clientopts -setmenuextra -menuextra no -setreqperm -reqperm no -setvnclegacy -vnclegacy no
## restart the ARD service
sudo /System/Library/CoreServices/RemoteManagement/ARDAgent.app/Contents/Resources/kickstart -quiet -activate -restart -agent -console

# disable automatic update check
sudo softwareupdate --schedule off

# set sound levels and mute output
osascript -e 'set volume output volume 100'
osascript -e 'set volume alert volume 75'
osascript -e 'set volume input volume 50'
## this also silences the startup chime
osascript -e 'set volume output muted true'


# =======================
echo "- Dock"
# =======================

# add TextEdit, Terminal, Console, Activity Monitor if not present
defaults read com.apple.dock | grep -q "TextEdit.app" || defaults write com.apple.dock persistent-apps -array-add '<dict><key>tile-data</key><dict><key>file-data</key><dict><key>_CFURLString</key><string>/Applications/TextEdit.app</string><key>_CFURLStringType</key><integer>0</integer></dict></dict></dict>'
defaults read com.apple.dock | grep -q "Terminal.app" || defaults write com.apple.dock persistent-apps -array-add '<dict><key>tile-data</key><dict><key>file-data</key><dict><key>_CFURLString</key><string>/Applications/Utilities/Terminal.app</string><key>_CFURLStringType</key><integer>0</integer></dict></dict></dict>'
defaults read com.apple.dock | grep -q "Console.app" || defaults write com.apple.dock persistent-apps -array-add '<dict><key>tile-data</key><dict><key>file-data</key><dict><key>_CFURLString</key><string>/Applications/Utilities/Console.app</string><key>_CFURLStringType</key><integer>0</integer></dict></dict></dict>'
defaults read com.apple.dock | grep -q "Activity Monitor.app" || defaults write com.apple.dock persistent-apps -array-add '<dict><key>tile-data</key><dict><key>file-data</key><dict><key>_CFURLString</key><string>/Applications/Utilities/Activity Monitor.app</string><key>_CFURLStringType</key><integer>0</integer></dict></dict></dict>'

# set tile size
defaults write com.apple.dock tilesize -int 60

# make hidden app icons translucent
defaults write com.apple.dock showhidden -bool true

# disable Dashboard
defaults write com.apple.dashboard mcx-disabled -bool true

killall Dock


# =======================
echo "- Finder"
# =======================

# set hard disk name
diskutil rename / "${NAME}"

# show full POSIX path as Finder window title
[ $OSX = "10.4" ] || defaults write com.apple.finder _FXShowPosixPathInTitle -bool true

# show status bar
[ $OSX = "10.4" ] || defaults write com.apple.finder ShowStatusBar -bool true

# show path bar
[ $OSX = "10.5" ] && defaults write com.apple.finder ShowPathBar -bool true
## later versions use "ShowPathbar"

# icons on desktop: all
defaults write com.apple.finder ShowExternalHardDrivesOnDesktop -bool true
defaults write com.apple.finder ShowHardDrivesOnDesktop -bool true
defaults write com.apple.finder ShowMountedServersOnDesktop -bool true
defaults write com.apple.finder ShowRemovableMediaOnDesktop -bool true

# new window shows: home
defaults write com.apple.finder NewWindowTarget "PfHm"

# default view: column
defaults write com.apple.finder FXPreferredViewStyle "clmv"

# default search scope: current folder
defaults write com.apple.finder FXDefaultSearchScope "SCcf"

# remove iDisk from sidebar
[ $OSX = "10.4" ] || $PLISTBUDDY -c "Add :systemitems:VolumesList:2:Visibility string NeverVisible" ~/Library/Preferences/com.apple.sidebarlists.plist

# disable Empty Trash warning
defaults write com.apple.finder WarnOnEmptyTrash -bool false

# disable window animations and Get Info animations
defaults write com.apple.finder DisableAllAnimations -bool true

# disable the warning when changing a file extension
defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false

# enable snap-to-grid for icons on the desktop
if [ $OSX = "10.5" ]; then
    $PLISTBUDDY -c "Set :DesktopViewOptions:IconViewOptions:ArrangeBy grid" ~/Library/Preferences/com.apple.finder.plist
elif [ $OSX = "10.4" ]; then
    $PLISTBUDDY -c "Set :DesktopViewOptions:ArrangeBy grid" ~/Library/Preferences/com.apple.finder.plist
fi
## doesn't work if the Desktop's view options are untouched

killall Finder


# =======================
echo "- Activity Monitor"
# =======================

# show main window on launch
defaults write com.apple.ActivityMonitor OpenMainWindow -bool true

# set window size
defaults write com.apple.ActivityMonitor "NSWindow Frame main window" "0 129 800 617 0 0 1024 746 "

# show all processes
defaults write com.apple.ActivityMonitor ShowCategory -int 0

# sort by CPU usage
defaults write com.apple.ActivityMonitor SortColumn "CPUUsage"
defaults write com.apple.ActivityMonitor SortDirection -int 0

# show System Memory tab
defaults write com.apple.ActivityMonitor SelectedTab -int 1

# set Dock icon to CPU history
defaults write com.apple.ActivityMonitor IconType -int 6


# =======================
echo "- Terminal"
# =======================

if [ $OSX = "10.4" ]; then
    # set window size
    defaults write com.apple.Terminal Columns -int 150
    defaults write com.apple.Terminal Rows -int 40
    defaults write com.apple.Terminal WinLocX -int 0
    defaults write com.apple.Terminal WinLocY -int 0
    defaults write com.apple.Terminal WinLocULY -int 746

    # set colour scheme to black on yellow
    defaults write com.apple.Terminal TextColors "0.000 0.000 0.000 1.000 1.000 0.714 0.000 0.000 0.000 0.000 0.000 0.000 1.000 1.000 0.714 0.000 0.000 0.000 0.667 0.667 0.667 0.333 0.333 0.333 "

    # enable option-click to move cursor
    defaults write com.apple.Terminal OptionClickToMoveCursor "YES"

    # fix forward delete
    echo '"\e[3~": delete-char' > ~/.inputrc
elif [ $OSX = "10.5" ]; then
    open "/Applications/Utilities/Terminal.app"
    osascript -e 'tell application "Terminal" to quit'
    sleep 2
    $PLISTBUDDY -c "Set :'Default Window Settings' Basic" ~/Library/Preferences/com.apple.Terminal.plist
    $PLISTBUDDY -c "Set :'NSWindow Frame TTWindow Basic' '0 155 925 591 0 0 1024 746 '" ~/Library/Preferences/com.apple.Terminal.plist
    $PLISTBUDDY -c "Set :'Startup Window Settings' Basic" ~/Library/Preferences/com.apple.Terminal.plist
    $PLISTBUDDY -c "Add :'Window Settings':Basic:columnCount integer 150" ~/Library/Preferences/com.apple.Terminal.plist
    $PLISTBUDDY -c "Add :'Window Settings':Basic:rowCount integer 40" ~/Library/Preferences/com.apple.Terminal.plist
fi

# set some helpful bash defaults
touch ~/.bash_profile
grep -q ".bashrc" ~/.bash_profile || cat >> ~/.bash_profile <<EOF
## if shell is interactive, also apply options for non-login shells
case "\$-" in *i*) if [ -r ~/.bashrc ]; then . ~/.bashrc; fi;; esac
EOF
cat > ~/.bashrc <<EOF
# aliases
alias ll='ls -lhH'
alias la='ls -lhHA'
alias tedit='open -e'
# ignore case during tab completion
bind 'set completion-ignore-case 1'
# cycle through autocomplete options instead of listing all
bind TAB:menu-complete
# enable command completion following sudo
complete -c -f command sudo
# fix spelling errors for cd
shopt -s cdspell
# don't logout with Control-D
set -o ignoreeof
# set editor
export EDITOR=nano
# colourize grep output
export GREP_OPTIONS='--color=auto'
export GREP_COLOR="1;33;40"
# colourize ls output
# http://geoff.greer.fm/lscolors/
export CLICOLOR=1
export LSCOLORS=GxdxhxDxfxHxHxBxFxcxCx
# colourize prompt
PS1="\[\e[1m\]\[\e[33m\]\h\[\e[0m\]\[\e[2m\]:\[\e[22m\]\[\e[1m\]\[\e[36m\]\w\[\e[0m\] \$ "
EOF


# =======================
echo "- Safari"
# =======================

# show status bar
defaults write com.apple.Safari ShowStatusBar -bool true

# new windows & tabs open with: Empty Page
defaults write com.apple.Safari NewWindowBehavior -int 1
defaults write com.apple.Safari NewTabBehavior -int 1

# disable opening 'safe' files after downloading
defaults write com.apple.Safari AutoOpenSafeDownloads -bool false


# =======================
echo "- TextEdit"
# =======================

# Use plain text mode for new TextEdit documents
defaults write com.apple.TextEdit RichText -int 0

# Open and save files as UTF-8 in TextEdit
defaults write com.apple.TextEdit PlainTextEncoding -int 4
defaults write com.apple.TextEdit PlainTextEncodingForWrite -int 4


# =======================
echo "- Misc."
# =======================

# avoid creating .DS_Store files on network and USB volumes
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true

# show scrollbars: always
defaults write NSGlobalDomain AppleShowScrollBars "Always"

# save panel default: expanded
defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode -bool true

# disable Time Machine prompt for new hard disks
[ $OSX = "10.4" ] || defaults write com.apple.TimeMachine DoNotOfferNewDisksForBackup -bool true

# disable Directory Utility looking for new servers on launch
[ $OSX = "10.5" ] && defaults write com.apple.DirectoryUtility "No SBS Assistant" -bool true

# set menu extras (requires logout)
defaults write com.apple.systemuiserver menuExtras -array \
"/System/Library/CoreServices/Menu Extras/Bluetooth.menu" \
"/System/Library/CoreServices/Menu Extras/AirPort.menu" \
"/System/Library/CoreServices/Menu Extras/Volume.menu" \
"/System/Library/CoreServices/Menu Extras/Clock.menu"
[[ $(system_profiler SPAirPortDataType) ]] || $PLISTBUDDY -c "Delete :menuExtras:1" ~/Library/Preferences/com.apple.systemuiserver.plist
[[ $(system_profiler SPBluetoothDataType) ]] || $PLISTBUDDY -c "Delete :menuExtras:0" ~/Library/Preferences/com.apple.systemuiserver.plist

echo "-- building 'locate' database..."
sudo periodic weekly

echo "-- repairing permissions..."
diskutil repairPermissions /

echo "done. Some changes require re-login to take effect."
