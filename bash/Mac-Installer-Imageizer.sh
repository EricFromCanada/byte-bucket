#!/bin/bash

# Mac-Installer-Imageizer.sh
# @EricFromCanada
#
# Creates a bootable disk image in the current directory from the given macOS or OS X installer app.
# More info: https://ericfromcanada.github.io/output/2022/macos-installer-disk-images-for-virtualization.html
#
# Supports Mac OS X 10.7 Lion through macOS 12 Monterey (and beyond, probably).

# disk image output format
OUTPUT="dmg" # VMware Fusion and ESXi can read DMG disk images; other apps may require "iso"

# convert destination disk image to final format and clean up
function finalizeDiskImage()
{
    # resize and compact destination disk image to minimize empty space
    hdiutil resize -size min /tmp/"${MACOS}".sparseimage
    hdiutil compact /tmp/"${MACOS}".sparseimage

    # convert destination disk image to DMG or ISO
    DESTINATION="${PWD}/${VERSION} ${MACOS}"
    if [ "${OUTPUT}" == "iso" ]; then
        hdiutil convert /tmp/"${MACOS}".sparseimage -format UDTO -ov -o /tmp/"${MACOS}"
        mv -fv /tmp/"${MACOS}".cdr "${DESTINATION}.${OUTPUT}"
    else
        hdiutil convert /tmp/"${MACOS}".sparseimage -format UDZO -ov -o "${DESTINATION}"
    fi

    # remove original destination disk image
    if [ -s "${DESTINATION}.${OUTPUT}" ]; then
        rm /tmp/"${MACOS}".sparseimage
    else
        echo "Error creating final image, leaving ${MACOS}.sparseimage in /tmp"
        exit 1
    fi
}

# check input
if [ $# -eq 1 ]; then
    INSTALLER=${1%/}
    if [ ! -e "${INSTALLER}"/Contents/SharedSupport/InstallESD.dmg ] &&
       [ ! -e "${INSTALLER}"/Contents/SharedSupport/SharedSupport.dmg ]; then
        echo 'Path is not valid: cannot find file "InstallESD.dmg" or "SharedSupport.dmg".'
        exit 1
    elif [ -e "${INSTALLER}"/Contents/SharedSupport/SharedSupport.dmg ]; then
        echo 'Running "createinstallmedia" command; your password will be necessary.'
        sudo -v
        USE_CREATEINSTALLMEDIA=1
    fi
else
    echo "Pass the path to the source installer app as the first argument."
    exit 1
fi

# grab OS name from the installer app filename
MACOS=$( echo "${INSTALLER%.app*}" | sed -E 's:.*Install (macOS|(Mac )?OS X) ::' )

# create blank destination disk image with single partition
hdiutil create -size 16g -type SPARSE -layout SPUD -fs HFS+J -ov /tmp/"${MACOS}"

# mount destination disk image
hdiutil attach /tmp/"${MACOS}".sparseimage -noverify -nobrowse -mountpoint /Volumes/install_build

# for macOS 11+, run `createinstallmedia`, then skip to disk image finalization
if [ -n "${USE_CREATEINSTALLMEDIA}" ]; then
    sudo "${INSTALLER}"/Contents/Resources/createinstallmedia --nointeraction --volume /Volumes/install_build

    # grab full OS version
    VERSION=$( defaults read /Volumes/"Install macOS ${MACOS}"/System/Library/CoreServices/SystemVersion ProductVersion )

    # detach destination disk image
    hdiutil detach -force /Volumes/"Install macOS ${MACOS}"

    finalizeDiskImage
    exit 0
fi

# mount source disk image
hdiutil attach "${INSTALLER}"/Contents/SharedSupport/InstallESD.dmg -noverify -nobrowse -mountpoint /Volumes/install_app

# restore boot disk image to destination disk image
case "${MACOS}" in
    "Lion" | "Mountain Lion")
        asr restore -source "${INSTALLER}"/Contents/SharedSupport/InstallESD.dmg -target /Volumes/install_build -noprompt -noverify -erase
        ;;
    "Mavericks" | "Yosemite" | "El Capitan" | "Sierra")
        asr restore -source /Volumes/install_app/BaseSystem.dmg -target /Volumes/install_build -noprompt -noverify -erase
        ;;
    "High Sierra" | "Mojave" | "Catalina")
        asr restore -source "${INSTALLER}"/Contents/SharedSupport/BaseSystem.dmg -target /Volumes/install_build -noprompt -noverify -erase || :
        ;;
esac
sleep 2

# remount restored disk image with original mount point
echo "Umounting: $(ls -ht /Volumes/ | head -n 1)"
hdiutil detach /Volumes/"$(ls -ht /Volumes/ | head -n 1)"
hdiutil attach /tmp/"${MACOS}".sparseimage -noverify -nobrowse -mountpoint /Volumes/install_build

# grab full OS version
VERSION=$( defaults read /Volumes/install_build/System/Library/CoreServices/SystemVersion ProductVersion )

# replace Packages link with actual files
case "${MACOS}" in
    "Mavericks" | "Yosemite" | "El Capitan" | "Sierra")
        rm -v /Volumes/install_build/System/Installation/Packages
        rsync -av --exclude "EFIPayloads/*" --exclude "SMCPayloads/*/" /Volumes/install_app/Packages /Volumes/install_build/System/Installation/
        ;;
    "High Sierra" | "Mojave" | "Catalina")
        ditto -V /Volumes/install_app/Packages /Volumes/install_build/System/Installation/
        ;;
    *)
        ;;
esac

# copy installer dependencies
case "${MACOS}" in
    "Yosemite" | "El Capitan" | "Sierra")
        ditto -V /Volumes/install_app/BaseSystem.{chunklist,dmg} /Volumes/install_build/
        ;;
    *)
        ;;
esac

# detach source and destination disk images
hdiutil detach /Volumes/install_app
hdiutil detach /Volumes/install_build

finalizeDiskImage
