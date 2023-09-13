#!/bin/bash
# Run this script without any param for a dry run
# Run the script with root and with exec param for removing old kernels after checking
# the list printed in the dry run

uname -a
IN_USE=$(uname -r | sed "s/-generic//g")
echo "Your in use kernel is $IN_USE"

pkg_to_remove=$(
    dpkg --list |
        grep -v "$IN_USE" |
        grep -Ei 'linux-image|linux-headers|linux-modules|linux-objects-nvidia' |
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
