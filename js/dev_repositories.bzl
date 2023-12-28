"""Our "development" dependencies

Users should *not* need to install these. If users see a load()
statement from these, that's a bug in our distribution.
"""

# buildifier: disable=bzl-visibility
load("//js/private:maybe.bzl", http_archive = "maybe_http_archive")

def rules_js_dev_dependencies():
    "Fetch repositories used for developing the rules"
    http_archive(
        name = "io_bazel_rules_go",
        sha256 = "278b7ff5a826f3dc10f04feaf0b70d48b68748ccd512d7f98bf442077f043fe3",
        urls = ["https://github.com/bazelbuild/rules_go/releases/download/v0.41.0/rules_go-v0.41.0.zip"],
    )

    http_archive(
        name = "bazel_gazelle",
        sha256 = "d3fa66a39028e97d76f9e2db8f1b0c11c099e8e01bf363a923074784e451f809",
        urls = ["https://github.com/bazelbuild/bazel-gazelle/releases/download/v0.33.0/bazel-gazelle-v0.33.0.tar.gz"],
    )

    http_archive(
        name = "bazel_skylib",
        sha256 = "66ffd9315665bfaafc96b52278f57c7e2dd09f5ede279ea6d39b2be471e7e3aa",
        urls = ["https://github.com/bazelbuild/bazel-skylib/releases/download/1.4.2/bazel-skylib-1.4.2.tar.gz"],
    )

    http_archive(
        name = "bazel_skylib_gazelle_plugin",
        sha256 = "3327005dbc9e49cc39602fb46572525984f7119a9c6ffe5ed69fbe23db7c1560",
        urls = ["https://github.com/bazelbuild/bazel-skylib/releases/download/1.4.2/bazel-skylib-gazelle-plugin-1.4.2.tar.gz"],
    )

    http_archive(
        name = "io_bazel_stardoc",
        sha256 = "3fd8fec4ddec3c670bd810904e2e33170bedfe12f90adf943508184be458c8bb",
        urls = ["https://github.com/bazelbuild/stardoc/releases/download/0.5.3/stardoc-0.5.3.tar.gz"],
    )

    http_archive(
        name = "buildifier_prebuilt",
        sha256 = "72b5bb0853aac597cce6482ee6c62513318e7f2c0050bc7c319d75d03d8a3875",
        strip_prefix = "buildifier-prebuilt-6.3.3",
        urls = ["https://github.com/keith/buildifier-prebuilt/archive/6.3.3.tar.gz"],
    )

    http_archive(
        name = "aspect_rules_lint",
        sha256 = "6e32df708b40ea8c6d4482eeaf8fd6afaa8798d0028654ba25b667b5aee5707c",
        strip_prefix = "rules_lint-0.7.0",
        url = "https://github.com/aspect-build/rules_lint/releases/download/v0.7.0/rules_lint-v0.7.0.tar.gz",
    )

    for (arch, sha256) in [
        ("macos13-arm64", "6876ae26c25288ebdd914c7757cd355b1667eb5c8c83a6cd395dfaa3522af706"),
        ("macos13-x86_64", "2d1f06ab923c5283d0e25ed396d24cfc9053c5e992191e262468f9e3e2cd97bb"),
        ("linux-glibc2.28-aarch64", "9159bd3e1ad66dd2ca09f1f7cdaf5458596dccaa44ab0cd7e3cdb071e79a6f9b"),
        ("linux-glibc2.28-x86_64", "491efad3cfbe7230ff1c6aef8d2f3d529b193b1d709eecc8566632f3fca391fd"),
    ]:
        http_archive(
            name = "mysql_8_0_34_" + arch,
            build_file_content = """
filegroup(
    name = "files",
    srcs = glob(["**/*"]),
    visibility = ["//visibility:public"],
)
""",
            urls = ["https://dev.mysql.com/get/Downloads/MySQL-8.0/mysql-8.0.34-" + arch + ".tar.gz"],
            sha256 = sha256,
            strip_prefix = "mysql-8.0.34-" + arch,
        )
