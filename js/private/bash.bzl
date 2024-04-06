"Bash snippets for js rules"

# TODO: Instead of setting a new RUNFILES env; just set RUNFILES_DIR if it is not set;
#       needs testing to know if RUNFILES_DIR is set always set to the same value as RUNFILES
#       when it is set.
# Bash snipped to initialize the RUNFILES environment variable.
# Depends on there being a logf_fatal function defined.
# NB: If this can be generalized fully in the future and not depend on logf_fatal
# then it could be hoisted to bazel-lib where we have other bash snippets.
BASH_INITIALIZE_RUNFILES = r"""
# It helps to determine if we are running on a Windows environment (excludes WSL as it acts like Unix)
case "$(uname -s)" in
CYGWIN*) _IS_WINDOWS=1 ;;
MINGW*) _IS_WINDOWS=1 ;;
MSYS_NT*) _IS_WINDOWS=1 ;;
*) _IS_WINDOWS=0 ;;
esac

# It helps to normalizes paths when running on Windows.
#
# Example:
# C:/Users/XUser/_bazel_XUser/7q7kkv32/execroot/A/b/C -> /c/Users/XUser/_bazel_XUser/7q7kkv32/execroot/A/b/C
function _normalize_path {
    if [ "$_IS_WINDOWS" -eq "1" ]; then
        # Apply the followings paths transformations to normalize paths on Windows
        # -process driver letter
        # -convert path separator
        sed -e 's#^\(.\):#/\L\1#' -e 's#\\#/#g' <<<"$1"
    else
        echo "$1"
    fi
    return
}

# Set a RUNFILES environment variable to the root of the runfiles tree
# since RUNFILES_DIR is not set by Bazel in all contexts.
# For example, `RUNFILES=/path/to/my_js_binary.sh.runfiles`.
#
# Call this program X. X was generated by a genrule and may be invoked
# in many ways:
#   1a) directly by a user, with $0 in the output tree
#   1b) via 'bazel run' (similar to case 1a)
#   2) directly by a user, with $0 in X's runfiles
#   3) by another program Y which has a data dependency on X, with $0 in Y's
#      runfiles
#   4a) via 'bazel test'
#   4b) case 3 in the context of a test
#   5a) by a genrule cmd, with $0 in the output tree
#   6a) case 3 in the context of a genrule
#
# For case 1, $0 will be a regular file, and the runfiles will be
# at $0.runfiles.
# For case 2 or 3, $0 will be a symlink to the file seen in case 1.
# For case 4, $TEST_SRCDIR should already be set to the runfiles by
# blaze.
# Case 5a is handled like case 1.
# Case 6a is handled like case 3.
if [ "${TEST_SRCDIR:-}" ]; then
    # Case 4, bazel has identified runfiles for us.
    RUNFILES=$(_normalize_path "$TEST_SRCDIR")
elif [ "${RUNFILES_MANIFEST_FILE:-}" ]; then
    RUNFILES=$(_normalize_path "$RUNFILES_MANIFEST_FILE")
    if [[ "${RUNFILES}" == *.runfiles_manifest ]]; then
        # Newer versions of Bazel put the manifest besides the runfiles with the suffix .runfiles_manifest.
        # For example, the runfiles directory is named my_binary.runfiles then the manifest is beside the
        # runfiles directory and named my_binary.runfiles_manifest
        RUNFILES=${RUNFILES%_manifest}
    elif [[ "${RUNFILES}" == */MANIFEST ]]; then
        # Older versions of Bazel put the manifest file named MANIFEST in the runfiles directory
        RUNFILES=${RUNFILES%/MANIFEST}
    else
        logf_fatal "Unexpected RUNFILES_MANIFEST_FILE value $RUNFILES_MANIFEST_FILE"
        exit 1
    fi
else
    case "$0" in
    /*) self="$0" ;;
    *) self="$PWD/$0" ;;
    esac
    while true; do
        if [ -e "$self.runfiles" ]; then
            RUNFILES="$self.runfiles"
            break
        fi

        if [[ "$self" == *.runfiles/* ]]; then
            RUNFILES="${self%%.runfiles/*}.runfiles"
            # don't break; this is a last resort for case 6b
        fi

        if [ ! -L "$self" ]; then
            break
        fi

        readlink="$(readlink "$self")"
        if [[ "$readlink" == /* ]]; then
            self="$readlink"
        else
            # resolve relative symlink
            self="${self%%/*}/$readlink"
        fi
    done

    if [ -z "${RUNFILES:-}" ]; then
        logf_fatal "RUNFILES environment variable is not set"
        exit 1
    fi

    RUNFILES=$(_normalize_path "$RUNFILES")
fi
if [ "${RUNFILES:0:1}" != "/" ]; then
    # Ensure RUNFILES set above is an absolute path. It may be a path relative
    # to the PWD in case where RUNFILES_MANIFEST_FILE is used above.
    RUNFILES="$PWD/$RUNFILES"
fi
"""
