#!/bin/bash

if [ -z "$1" ]; then
    echo "Usage: $0 <qubes-release>" >&2
    exit 1
fi

LOCALDIR="$(readlink -f "$(dirname "$0")")"

REPO="$(basename "$0")"
REPO=${REPO%.sh}
REPO=${REPO#*-}

REPOS_TO_UPDATE="$1/$REPO"

# shellcheck source=update_repo.sh
. "$LOCALDIR/update_repo.sh"

if [ "$AUTOMATIC_UPLOAD" = 1 ]; then
    "$(dirname "$0")/sync_qubes-os.org_repo.sh" "$1"
fi

