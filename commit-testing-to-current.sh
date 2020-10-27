#!/bin/bash

if [ -n "$3" ]; then
    RELS_TO_UPDATE=$(basename "$3")
else
    RELS_TO_UPDATE="$(readlink current-release | tr -d /)"
fi
MIN_AGE=7
#DRY=echo
REPO_CHROOT_DIR=$BUILDER_DIR/chroot-vm-archlinux

if [ -z "$1" ]; then
    echo "Usage: $0 <path-to-current-testing-repo-snapshot> [\"<component list>\" [<release-name>]]"
    exit 1
fi

if ! [ -d "$REPO_CHROOT_DIR" ]; then
    echo "Archlinux chroot $REPO_CHROOT_DIR does not exists"
    exit 1
fi

repo_snapshot_dir="$1"
components="$2"

touch -t "$(date -d "$MIN_AGE days ago" +%Y%m%d%H%M)" age-compare-file

# $1 - snapshot file
# $2 - source dir
# $3 - destination dir
process_snapshot_file() {
    if ! [ -r "$1" ]; then
        if [ "$VERBOSE" -ge 1 ]; then
            echo "Not existing snapshot, ignoring: $(basename "$1")"
        fi
        return
    fi
    if [ "$1" -nt age-compare-file ]; then
        echo "Packages wasn't in current-testing for at least $MIN_AGE days, ignoring: $(basename "$1")"
        return
    fi
    while read -r f;
    do
        f="$(basename "$f")"
        if ! [ -e "$2/$f" ]; then
            echo "Not existing package, ignoring: $2/$f"
            continue
        fi
        if ! [ -e "$2/$f.sig" ]; then
            echo "Not signed package: $2/$f"
            continue
        fi
        $DRY ln -f "$2/$f" "$3/"
    done < "$1"
}

for rel in $RELS_TO_UPDATE; do
    if [ -n "$components" ]; then
        for component in $components; do
            process_snapshot_file "$repo_snapshot_dir/current-testing-vm-archlinux-$component" archlinux-testing archlinux
        done
    else
        for snapshot_file in "$repo_snapshot_dir"/current-testing-vm-archlinux-*; do
            process_snapshot_file "$snapshot_file" archlinux-testing archlinux
        done
    fi
    ./update_repo-current.sh "$rel"
done

rm -f age-compare-file

if [ "$AUTOMATIC_UPLOAD" = 1 ]; then
    "$(dirname "$0")"/sync_qubes-os.org_repo.sh "$3"
fi

echo Done.
