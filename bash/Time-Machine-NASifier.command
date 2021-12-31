#!/bin/bash

# Time-Machine-NASifier.command
# Copy to & run this script from the NAS volume your Time Machine backups will go.

# Creates a Time Machine bundle for this Mac in the same directory as the script.
# Band size is set to 128MB to improve performance, up from the default of 8MB.
# Spotlight will be disabled on the volume, but it can be re-enabled with mdutil.
# Time Machine will resize the backup volume to have up to twice the capacity of
# the source volume while starting the first backup, unless the "user immutable"
# flag is set on the bundle's Info.plist file using chflags.

# set our working dir to where the current script is, which is where the bundle will be created
HERE=$(cd "${BASH_SOURCE[0]%/*}" && echo "$PWD/${0##*/}")
cd "$(dirname "${HERE}")"

# shortcut for the tab character
TAB="$(printf '\t')"

# name of the backup volume when mounted
VOLNAME="Time Machine Backups"

# hardware UUID
HWUUID=$( system_profiler SPHardwareDataType | grep 'Hardware UUID:' | sed s/\ \*Hardware\ UUID:\ //g )

# hardware model
HWMODEL=$( system_profiler SPHardwareDataType | grep 'Model Identifier:' | sed s/\ \*Model\ Identifier:\ //g )

# hardware name (as set in the Sharing prefpane)
HWNAME=$( system_profiler SPSoftwareDataType | grep 'Computer Name:' | sed s/\ \*Computer\ Name:\ //g )

# disk image suffix (use "backupbundle" since 10.15 Catalina)
SUFFIX=$([ `uname -r | cut -d . -f 1` -ge 19 ] && echo "backupbundle" || echo "sparsebundle")

echo -e "\nGenerating Time Machine disk image on $( basename "$PWD" )..."
hdiutil create \
-size 8g \
-type SPARSEBUNDLE \
-layout GPTSPUD \
-fs "Journaled HFS+" \
-volname "${VOLNAME}" \
-tgtimagekey sparse-band-size=262144 \
-nospotlight \
-attach \
"${HWUUID}.sparsebundle"
sleep 1

echo -e "\nDisabling Spotlight for volume..."
mdutil -i off /Volumes/"${VOLNAME}"
hdiutil detach /Volumes/"${VOLNAME}"
sleep 1

echo -e "\nAdding metadata to disk image file..."
cd "${HWUUID}.sparsebundle"
cat << EOF > com.apple.TimeMachine.MachineID.plist
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
${TAB}<key>VerificationDate</key>
${TAB}<date>$( date -u +%FT%TZ )</date>
${TAB}<key>VerificationExtendedSkip</key>
${TAB}<false/>
${TAB}<key>VerificationState</key>
${TAB}<integer>1</integer>
${TAB}<key>com.apple.backupd.HostUUID</key>
${TAB}<string>${HWUUID}</string>
${TAB}<key>com.apple.backupd.ModelID</key>
${TAB}<string>${HWMODEL}</string>
</dict>
</plist>
EOF
cp com.apple.TimeMachine.MachineID.plist com.apple.TimeMachine.MachineID.bckup
cat << EOF > com.apple.TimeMachine.SnapshotHistory.plist
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
${TAB}<key>Snapshots</key>
${TAB}<array/>
</dict>
</plist>
EOF
cd ..
mv "${HWUUID}.sparsebundle" "${HWNAME}.${SUFFIX}"

echo -e "\nDone!"
