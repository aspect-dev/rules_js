#!/usr/bin/env bash
set -o errexit -o nounset -o pipefail

BZLMOD_FLAG="${BZLMOD_FLAG:---enable_bzlmod=1}"

if ! bazel test "$BZLMOD_FLAG" --nobuild_runfile_links //...; then
    echo "ERROR: expected 'bazel test $BZLMOD_FLAG --nobuild_runfile_links //...' to pass"
    exit 1
fi
