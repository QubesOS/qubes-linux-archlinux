#!/bin/bash

pushd "$(dirname "$0")" || exit 1

[ "x$HOST" == "x" ] && HOST=archlinux.qubes-os.org
[ "x$HOST_BASEDIR" == "x" ] && HOST_BASEDIR=/pub/qubes/repo/archlinux

REPO="$(basename "$0")"
REPO=${REPO%.sh}
REPO=${REPO#*-}

RELS_TO_SYNC=${1:-"r4.0 r4.1"}
if [ "$REPO" != "unstable" ]; then
    REPOS_TO_SYNC="current current-testing security-testing"
fi

for rel in $RELS_TO_SYNC; do
    for repo in $REPOS_TO_SYNC
    do
        echo "Syncing $rel/$repo/vm/archlinux..."
        rsync --partial --progress --hard-links -air "$rel/$repo/"  "$HOST:$HOST_BASEDIR/$rel/$repo/"
    done
done

popd || exit 1
