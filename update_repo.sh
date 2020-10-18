#!/bin/bash

set -e
if [ "$VERBOSE" -ge 2 ] || [ "$DEBUG" -gt 0 ]; then
    set -x
fi

[ -z "$REPOS_TO_UPDATE" ] && exit 1

exit_update() {
    local exit_code=$?
    sudo umount "$chroot_dir/tmp/qubes-archlinux" || true
    exit $exit_code
}

localdir="$(readlink -f "$(dirname "$0")")"
name=vm-archlinux
archlinux_directory="$localdir/$REPOS_TO_UPDATE"
package_directory=$archlinux_directory/pkgs
db=qubes.db
chroot_dir="$localdir/../../chroot-$name/"

trap 'exit_update' 0 1 2 3 6 15

sudo mkdir -p "$chroot_dir/tmp/qubes-archlinux"
if ! [ -d "$chroot_dir/tmp/qubes-archlinux/pkgs" ]; then
    sudo mount --bind "$archlinux_directory" "$chroot_dir/tmp/qubes-archlinux"
fi
sudo chroot "$chroot_dir" su user -c 'cd /tmp/qubes-archlinux/pkgs; for pkg in $(ls -v qubes*.pkg.tar.zst) ; do repo-add '"$db"'.tar.gz "$pkg";done;'

rm -rf $package_directory/*.tar.gz.old
rm $package_directory/$db
cp $package_directory/$db.tar.gz $package_directory/$db

# Sign the package database
${GNUPG:-gpg} --yes --local-user "${SIGN_ARCHLINUX_KEY}" --detach-sign -o "$package_directory/$db.sig" "$package_directory/$db"

for filename in "$package_directory"/qubes*.pkg.tar.zst ; do
    if ! [ -f "$filename.sig" ] ; then
        echo "ERROR: unsigned package found: $filename"
		exit 1
    fi
done
