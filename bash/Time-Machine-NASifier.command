#!/bin/bash

# Time-Machine-NASifier.command
# Copy to & run this script from the NAS volume your Time Machine backups will go.
# Creates a Time Machine bundle for this Mac in the same directory as the script.
# Band size is set to 128MB to improve performance, up from the default of 8MB.
# Spotlight is disabled on the volume (or should be). Time Machine will resize the
# image to twice the capacity of the source volume, unless the user immutable flag
# is set on the bundle's Info.plist file using `chflags`.

# set our working dir to where the current script is, which is where the bundle will be created
HERE=$(cd "${BASH_SOURCE[0]%/*}" && echo "$PWD/${0##*/}")
cd "$(dirname "${HERE}")"

# set some values
TAB="$(printf '\t')"
VOLNAME="Time Machine Backups"
MACADDR=$( ifconfig en0 | grep ether | sed -e "s/.*ether //" | sed -e "s/ //g" )
HWUUID=$( system_profiler SPHardwareDataType | grep 'Hardware UUID:' | sed s/\ *Hardware\ UUID:\ //g )
HWNAME=$( system_profiler SPSoftwareDataType | grep 'Computer Name:' | sed s/\ *Computer\ Name:\ //g )
if [[ $( uname -r ) == 9* ]] # if running Leopard
then
	HWNAME="${HWNAME}_$( echo ${MACADDR} | sed s/://g )"
fi

echo "Generating backup disk image..."
hdiutil create \
-size 256g \
-type SPARSEBUNDLE \
-fs "Case-sensitive Journaled HFS+" \
-volname "${VOLNAME}" \
-layout SPUD \
-tgtimagekey sparse-band-size=262144 \
-nospotlight \
-attach \
"${HWNAME}.sparsebundle"
sleep 1

echo "Disabling Spotlight for volume..."
mdutil -i off /Volumes/"${VOLNAME}"
touch /Volumes/"${VOLNAME}"/.metadata_never_index /Volumes/"${VOLNAME}"/.fseventsd/no_log
chmod -r /Volumes/"${VOLNAME}"/.Trashes
hdiutil detach /Volumes/"${VOLNAME}"
sleep 1

echo "Adding metadata to disk image..."
cd "${HWNAME}.sparsebundle"
cat << EOF > com.apple.TimeMachine.MachineID.plist
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
${TAB}<key>com.apple.backupd.BackupMachineAddress</key>
${TAB}<string>${MACADDR}</string>
${TAB}<key>com.apple.backupd.HostUUID</key>
${TAB}<string>${HWUUID}</string>
</dict>
</plist>
EOF
chmod -R go+w .
chmod u+x token

echo -e "Done!\nRemember to unmount the NAS volume before selecting it in Time Machine."
