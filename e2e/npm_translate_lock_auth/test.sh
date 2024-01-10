#!/usr/bin/env bash
set -o errexit -o nounset -o pipefail

# Integration test for use_home_npmrc

BZLMOD_FLAG="${BZLMOD_FLAG:---enable_bzlmod=1}"

# sedi makes `sed -i` work on both OSX & Linux
# See https://stackoverflow.com/questions/2320564/i-need-my-sed-i-command-for-in-place-editing-to-work-with-both-gnu-sed-and-bsd
_sedi() {
    case $(uname) in
    Darwin*) sedi=('-i' '') ;;
    *) sedi=('-i') ;;
    esac

    sed "${sedi[@]}" "$@"
}

cp -f .npmrc ~/.npmrc
rm .npmrc
touch .npmrc

# update .aspect/rules/external_repository_action_cache/npm_translate_lock_<HASH>
unset ASPECT_RULES_JS_FROZEN_PNPM_LOCK
if [[ "$BZLMOD_FLAG" == "--enable_bzlmod=1" ]]; then
    _sedi 's#npmrc = "//:.npmrc",#use_home_npmrc = True,#' MODULE.bazel
else
    _sedi 's#npmrc = "//:.npmrc",#use_home_npmrc = True,#' WORKSPACE
fi

bazel run "$BZLMOD_FLAG" @npm//:sync
export ASPECT_RULES_JS_FROZEN_PNPM_LOCK=1

bazel test "$BZLMOD_FLAG" //...
