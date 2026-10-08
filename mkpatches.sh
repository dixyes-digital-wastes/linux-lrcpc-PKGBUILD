#!/usr/bin/env bash
# SPDX-License-Identifier: ISC
#
# Regenerates the patch series out of the kernel tree
#
#	./mkpatches.sh [tree]
#
# The patches come from the backport branch, because that is what the tarball
# this package builds is based on; each of its commits says which commit on the
# source branch (lse-emul) it was cherry picked from
set -euo pipefail

here=$(cd "$(dirname "$0")" && pwd)
tree=${1:?usage: mkpatches.sh <kernel tree with both branches>}
base=${BASE:-v7.2}

git -C "$tree" format-patch "$base"..lse-emul-backport-v7.2 -o "$here" --no-signature >/dev/null

set -- "$here"/000*.patch
names=(patch-0001-RCpc-loads.patch patch-0002-RCpc-rewrite.patch \
       patch-0003-shared-primitives.patch patch-0004-LSE-emulation.patch \
       patch-0005-LSE-blocks.patch patch-0006-stale-fetch.patch \
       patch-0007-mmap-lock.patch patch-0008-block-hook.patch)
for i in "${!names[@]}"; do
	mv -f "$1" "$here/${names[$i]}"
	shift
done

ls -la "$here"/patch-*.patch
