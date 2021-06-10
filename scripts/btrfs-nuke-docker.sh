#!/bin/sh
set -e

dir="$1"

if [ -z "$dir" ]; then
    {
        echo 'This script is for destroying old /var/lib/docker directories more safely than'
        echo '  "rm -rf", which can cause data loss or other serious issues.'
        echo
        echo "usage: $0 directory"
        echo "   ie: $0 /var/lib/docker"
    } >&2
    exit 1
fi

if [ "$(id -u)" != 0 ]; then
    echo >&2 "error: $0 must be run as root"
    exit 1
fi

if [ ! -d "$dir" ]; then
    echo >&2 "error: $dir is not a directory"
    exit 1
fi

btrfs filesystem show

dir="$(readlink -f "$dir")"

echo
echo "Nuking $dir ..."
echo '  (if this is wrong, press Ctrl+C NOW!)'
echo

( set -x; sleep 3 )
echo

dir_in_dir() {
    inner="$1"
    outer="$2"
    [ "${inner#$outer}" != "$inner" ]
}

# let's start by unmounting any submounts in $dir
#   (like -v /home:... for example - DON'T DELETE MY HOME DIRECTORY BRU!)
for mount in $(awk '{ print $5 }' /proc/self/mountinfo); do
    mount="$(readlink -f "$mount" || true)"
    if dir_in_dir "$mount" "$dir"; then
        ( set -x; umount -f "$mount" )
    fi
done

# now, let's go destroy individual btrfs subvolumes, if any exist
if command -v btrfs >/dev/null 2>&1; then
    root="$(df "$dir" | awk 'NR>1 { print $NF }')"
    if [[ $root = "/" ]]; then root=""; fi # if root is "/", we want it to become ""
    echo "root=$root"
    for subvol in $(btrfs subvolume list -o "$root/" 2>/dev/null | awk -F' path ' '{ print $2 }' | sort -r); do
        subvolDir="$root/$subvol"
        subvolDir=$(echo $subvolDir | sed 's:/@/:/:g')
        echo "subvolDir=$subvolDir"
        if dir_in_dir "$subvolDir" "$dir"; then
            ( set -x; btrfs subvolume delete "$subvolDir" )
        fi
    done
fi

# finally, DESTROY ALL THINGS
( set -x; rm -rf "$dir" )

btrfs fi df $dir
btrfs fi usage $dir
btrfs balance start -dusage=80 $dir
btrfs scrub start -d $dir
btrfs fi df $dir
btrfs fi usage $dir

btrfs filesystem show

