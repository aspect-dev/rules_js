"""
Test utils for lockfiles
"""

load("@aspect_bazel_lib//lib:copy_file.bzl", "copy_file")
load("@aspect_bazel_lib//lib:write_source_files.bzl", "write_source_files")
load("@aspect_rules_js//js:defs.bzl", "js_test")
load("@bazel_skylib//rules:build_test.bzl", "build_test")

# Each version being tested
PNPM_LOCK_VERSIONS = [
    "v54",
    "v60",
    "v61",
    "v90",
]

BZL_FILES = {
    # global
    "defs.bzl": "@REPO_NAME//:defs.bzl",

    # hasBin, optional deps, deps
    # "rollup_links_defs.bzl": "@REPO_NAME__rollup__2.79.1__links//:defs.bzl",
    # "rollup_package_json.bzl": "@REPO_NAME__rollup__2.79.1//VERSION:package_json.bzl",

    # TODO: inconsistent across versions
    # peers
    # "aspect_test_d_defs.bzl": "@REPO_NAME__@aspect-test+d__2.0.0_@aspect-test+c__2.0.2//:defs.bzl",
}

def lockfile_test(name = None):
    """
    Tests for a lockfile and associated targets + files generated by rules_js.

    Args:
        name: the lockfile version name
    """

    lock_version = name if name else native.package_name()
    lock_repo = "lock-%s" % lock_version

    # Copy each test to this lockfile dir
    for test in ["patched-dependencies-test.js", "aliases-test.js"]:
        copy_file(
            name = "copy-{}".format(test),
            src = "//:base/{}".format(test),
            out = test,
        )

    js_test(
        name = "patch-test",
        data = [
            ":node_modules/meaning-of-life",
        ],
        entry_point = "patched-dependencies-test.js",
    )

    js_test(
        name = "aliases-test",
        data = [
            ":node_modules/@aspect-test/a",
            ":node_modules/@aspect-test/a2",
            ":node_modules/@types/node",
            ":node_modules/alias-only-sizzle",
            ":node_modules/alias-types-node",
            ":node_modules/is-odd",
            ":node_modules/is-odd-alt-version",
            ":node_modules/@isaacs/cliui",
        ],
        entry_point = "aliases-test.js",
    )

    build_test(
        name = "targets",
        targets = [
            # The full node_modules target
            ":node_modules",

            # Direct 'dependencies'
            ":node_modules/@aspect-test/a",

            # Direct 'devDependencies'
            ":node_modules/@aspect-test/b",
            ":node_modules/@types/node",

            # Direct 'optionalDependencies'
            ":node_modules/@aspect-test/c",

            # rollup has a 'optionalDependency' (fsevents)
            ":node_modules/rollup",

            # rollup plugin that has many peers
            ":node_modules/rollup-plugin-with-peers",

            # uuv 'hasBin'
            ":node_modules/uvu",

            # a package with various `npm:` cases
            ":node_modules/@isaacs/cliui",

            # link:, workspace:, file:, ./rel/path
            ":node_modules/@scoped/a",
            ":node_modules/@scoped/b",
            ":node_modules/@scoped/c",
            ":node_modules/@scoped/d",

            # Packages involving overrides
            ":node_modules/is-odd",
            ":.aspect_rules_js/node_modules/is-odd@3.0.1",
            ":.aspect_rules_js/node_modules/is-number@0.0.0",

            # Odd git/http versions
            ":node_modules/debug",
            ":node_modules/hello",
            ":node_modules/jsonify",

            # npm: alias
            ":node_modules/@aspect-test/a2",
            # npm: alias to registry-scoped packages
            ":node_modules/alias-types-node",
            # npm: alias to alternate versions
            ":node_modules/is-odd-alt-version",
            ":.aspect_rules_js/node_modules/is-odd@2.0.0",

            # npm: alias to package not listed elsewhere
            ":node_modules/alias-only-sizzle",
            ":.aspect_rules_js/node_modules/@types+sizzle@2.3.8",

            # Targets within the virtual store...
            # Direct dep targets
            ":.aspect_rules_js/node_modules/@aspect-test+a@5.0.2",
            ":.aspect_rules_js/node_modules/@aspect-test+a@5.0.2/dir",
            ":.aspect_rules_js/node_modules/@aspect-test+a@5.0.2/pkg",
            ":.aspect_rules_js/node_modules/@aspect-test+a@5.0.2/ref",

            # Direct deps with lifecycles
            ":.aspect_rules_js/node_modules/@aspect-test+c@2.0.2/lc",
            ":.aspect_rules_js/node_modules/@aspect-test+c@2.0.2/pkg_lc",

            # link:, workspace:, file:, ./rel/path
            ":.aspect_rules_js/node_modules/@scoped+a@0.0.0",
            ":.aspect_rules_js/node_modules/@scoped+b@0.0.0",
            ":.aspect_rules_js/node_modules/@scoped+c@0.0.0",
            ":.aspect_rules_js/node_modules/@scoped+d@0.0.0",

            # Patched dependencies
            ":.aspect_rules_js/node_modules/meaning-of-life@1.0.0_o3deharooos255qt5xdujc3cuq",

            # Direct deps from custom registry
            ":.aspect_rules_js/node_modules/@types+node@16.18.11",

            # Direct deps with peers
            ":.aspect_rules_js/node_modules/@aspect-test+d@2.0.0_at_aspect-test_c_2.0.2",
        ],
    )

    # The generated bzl files (standard non-workspace)
    # buildifier: disable=no-effect
    [
        native.genrule(
            name = "extract-%s" % out,
            srcs = [what.replace("VERSION", lock_version).replace("REPO_NAME", lock_repo)],
            outs = ["snapshot-extracted-%s" % out],
            cmd = 'sed "s/{}/<LOCKVERSION>/g" "$<" > "$@"'.format(lock_version),
            visibility = ["//visibility:private"],
        )
        for (out, what) in BZL_FILES.items()
    ]

    write_source_files(
        name = "repos",
        files = dict(
            [
                (
                    "snapshots/%s" % f,
                    ":extract-%s" % f,
                )
                for f in BZL_FILES.keys()
            ],
        ),
        target_compatible_with = select({
            "@aspect_bazel_lib//lib:bzlmod": [],
            "//conditions:default": ["@platforms//:incompatible"],
        }),
    )
