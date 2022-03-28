"Convert package-lock.json into starlark Bazel fetches"

_DOC = """Repository rule to generate npm_import rules from package-lock.json file.

The npm lockfile format includes all the information needed to define npm_import rules,
including the integrity hash, as calculated by the package manager.

Instead of manually declaring the `npm_imports`, this helper generates an external repository
containing a helper starlark module `repositories.bzl`, which supplies a loadable macro
`npm_repositories`. This macro creates an `npm_import` for each package.

The generated repository also contains BUILD files declaring targets for the packages
listed as `dependencies` or `devDependencies` in `package.json`, so you can declare
dependencies on those packages without having to repeat version information.

Bazel will only fetch the packages which are required for the requested targets to be analyzed.
Thus it is performant to convert a very large package-lock.json file without concern for
users needing to fetch many unnecessary packages.

**Setup**

In `WORKSPACE`, call the repository rule pointing to your package-lock.json file:

```starlark
load("@aspect_rules_js//js:npm_import.bzl", "translate_package_lock")

# Read the package-lock.json file to automate creation of remaining npm_import rules
translate_package_lock(
    # Creates a new repository named "@npm_deps"
    name = "npm_deps",
    package_lock = "//:package-lock.json",
)
```

Next, there are two choices, either load from the generated repo or check in the generated file.
The tradeoffs are similar to
[this rules_python thread](https://github.com/bazelbuild/rules_python/issues/608).

1. Immediately load from the generated `repositories.bzl` file in `WORKSPACE`.
This is similar to the 
[`pip_parse`](https://github.com/bazelbuild/rules_python/blob/main/docs/pip.md#pip_parse)
rule in rules_python for example.
It has the advantage of also creating aliases for simpler dependencies that don't require
spelling out the version of the packages.
However it causes Bazel to eagerly evaluate the `translate_package_lock` rule for every build,
even if the user didn't ask for anything JavaScript-related.

```starlark
load("@npm_deps//:repositories.bzl", "npm_repositories")

npm_repositories()
```

In BUILD files, declare dependencies on the packages using the same external repository.

Following the same example, this might look like:

```starlark
nodejs_test(
    name = "test_test",
    data = ["@npm_deps//@types/node"],
    entry_point = "test.js",
)
```

2. Check in the `repositories.bzl` file to version control, and load that instead.
This makes it easier to ship a ruleset that has its own npm dependencies, as users don't
have to install those dependencies. It also avoids eager-evaluation of `translate_package_lock`
for builds that don't need it.
This is similar to the [`update-repos`](https://github.com/bazelbuild/bazel-gazelle#update-repos)
approach from bazel-gazelle.

In a BUILD file, use a rule like
[write_source_files](https://github.com/aspect-build/bazel-lib/blob/main/docs/write_source_files.md)
to copy the generated file to the repo and test that it stays updated:

```starlark
write_source_files(
    name = "update_repos",
    files = {
        "repositories.bzl": "@npm_deps//:repositories.bzl",
    },
)
```

Then in `WORKSPACE`, load from that checked-in copy or instruct your users to do so.
In this case, the aliases are not created, so you get only the `npm_import` behavior
and must depend on packages with their versioned label like `@npm__types_node-15.12.2`.
"""

_ATTRS = {
    "package_lock": attr.label(
        doc = """The package-lock.json file.
        
        It should use the lockfileVersion 2, which is produced from npm 7 or higher.""",
        mandatory = True,
    ),
}

# TODO: if useful, add a comment giving a source reference to the object in package-lock.json
# that was used to derive this npm_import
_NPM_IMPORT_TMPL = """\
    npm_import(
        name = "{name}",
        integrity = "{integrity}",
        package = "{package}",
        version = "{version}",
        deps = {deps},
    )
"""

def _escape(package_name):
    "Make a package name into a valid label without slash or at-sign"
    return package_name.replace("/", "_").replace("@", "_")

def _repo_name(package_name, version):
    "Make an external repository name from a package name and a version"
    return "npm_%s-%s" % (_escape(package_name), version)

def _import_dependencies(lockfile, bzl_out = None):
    lock_version = lockfile["lockfileVersion"]

    # We don't test this program with spec versions other than 2, so just error.
    # If users hit this we can add test coverage and expand the supported range.
    if lock_version != 2:
        fail("translate_package_lock only works with npm 7 lockfiles (lockfileVersion == 2), found %s" % lock_version)

    # To allow recursion, accept an optional accumulator
    # If it's not present, we need to start with the header of the file
    bzl_out = bzl_out or ["""
load("@aspect_rules_js//js:npm_import.bzl", "npm_import")

def npm_repositories():
    "Define external repositories to fetch each tarball individually from npm on-demand."
"""]
    for (name, dep) in lockfile["dependencies"].items():
        if "resolved" not in dep.keys():
            continue
        deps = []
        if "requires" in dep.keys():
            for n in dep["requires"].keys():
                deps.append("@" + _repo_name(n, [d["version"] for (p, d) in lockfile["dependencies"].items() if p == n][0]))
        bzl_out.extend([_NPM_IMPORT_TMPL.format(
            name = _repo_name(name, dep["version"]),
            package = name,
            version = dep["version"],
            url = dep["resolved"],
            integrity = dep["integrity"],
            deps = deps,
        )])
    return bzl_out

def _define_aliases(repository_ctx, lockfile):
    # The lockfile format refers to the context as the package with empty name.
    # This gives us a way to know which deps the user declared in their package.json
    # (the direct dependencies).
    direct = lockfile["packages"][""]
    direct_names = []
    direct_names.extend(direct.get("devDependencies", {}).keys())
    direct_names.extend(direct.get("dependencies", {}).keys())

    for (direct_name, direct_dep) in lockfile["dependencies"].items():
        if not direct_name in direct_names:
            continue
        dep_build_content = """# @generated by package_lock.bzl

alias(name = "{package}", actual = "{actual}", visibility = ["//visibility:public"])
""".format(
            package = direct_name.split("/")[-1],
            actual = "@" + _repo_name(direct_name, direct_dep["version"]),
        )
        repository_ctx.file(direct_name + "/BUILD.bazel", dep_build_content)

def _translate_package_lock(repository_ctx):
    lock_content = json.decode(repository_ctx.read(repository_ctx.attr.package_lock))
    header = """\"\"\"npm repositories for {name}
@generated by translate_package_lock.bzl from
{source}
\"\"\"
""".format(
        name = lock_content["name"],
        source = str(repository_ctx.attr.package_lock),
    )
    repository_ctx.file("repositories.bzl", header + "\n".join(_import_dependencies(lock_content)))

    # Allow users to refer to the generated file, e.g. from write_source_files
    repository_ctx.file("BUILD.bazel", """exports_files(["repositories.bzl"])""")
    _define_aliases(repository_ctx, lock_content)

translate_package_lock = struct(
    doc = _DOC,
    implementation = _translate_package_lock,
    attrs = _ATTRS,
    repository_name = _repo_name,
    testonly_import_dependencies = _import_dependencies,
    testonly_define_aliases = _define_aliases,
)
