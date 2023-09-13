#!/bin/bash
# Run this script without any param for a dry run
# Run the script with root and with exec param for removing all nvidia packages currently installed.
# It is recommended to completely remove all previous NVIDIA installed packages and then reboot before upgrading the nvidia drivers.

uname -a
IN_USE=$(uname -r | sed "s/-generic//g")
echo "Your in use kernel is $IN_USE"
nvidia-smi

pkg_to_remove=$(
    dpkg --list |
        grep -Ei 'nvidia' |
        awk '{ print $2 }'
)
echo "Packages to be removed:"
echo "${pkg_to_remove}"

if [ "$1" == "exec" ]; then
    for PACKAGE in ${pkg_to_remove}; do
        yes | apt purge "$PACKAGE"
        apt autoremove -y
        apt autoclean -y
    done
else
    echo "If all looks good, run it again like this: sudo $0 exec"
fi
