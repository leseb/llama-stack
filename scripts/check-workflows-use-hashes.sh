#!/usr/bin/env bash
# Copyright (c) Meta Platforms, Inc. and affiliates.
# All rights reserved.
#
# This source code is licensed under the terms described in the LICENSE file in
# the root directory of this source tree.
#
# Fails if any GitHub Actions workflow uses an external action without a full SHA pin.

set -euo pipefail

failed=0

# Find all workflow YAML files
for file in $(find .github/workflows/ -type f \( -name "*.yml" -o -name "*.yaml" \)); do
    IFS=$'\n'
    # Grep for `uses:` lines that look like actions with line numbers
    while IFS=: read -r line_num line_content; do
        # Extract the ref part after the last @
        ref=$(echo "$line_content" | sed -E 's/.*@([A-Za-z0-9._-]+).*/\1/')
        # Check if ref is a 40-character hex string (full SHA).
        #
        # Note: strictly speaking, this could also be a tag or branch name, but
        # we'd have to pull this info from the remote. Meh.
        if ! [[ $ref =~ ^[0-9a-fA-F]{40}$ ]]; then
            echo "::error title=Non-SHA action ref file=$file line=$line_num:: uses non-SHA action ref: $line_content"
            failed=1
        fi
    done < <(grep -n -E '^.*uses:[^@]+@[^ ]+' "$file")
done

exit $failed
