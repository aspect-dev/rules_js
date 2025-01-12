"""Our "development" dependencies

Users should *not* need to install these. If users see a load()
statement from these, that's a bug in our distribution.
"""

# buildifier: disable=bzl-visibility
load("//js/private:maybe.bzl", http_archive = "maybe_http_archive")

def rules_js_dev_dependencies():
    "Fetch repositories used for developing the rules"
    http_archive(
        name = "bazel_skylib",
        sha256 = "bc283cdfcd526a52c3201279cda4bc298652efa898b10b4db0837dc51652756f",
        urls = ["https://github.com/bazelbuild/bazel-skylib/releases/download/1.7.1/bazel-skylib-1.7.1.tar.gz"],
    )

    http_archive(
        name = "io_bazel_stardoc",
        sha256 = "0e1ed4a98f26e718776bd64d053d02bb34d98572ccd03d6ba355112a1205706b",
        urls = ["https://github.com/bazelbuild/stardoc/releases/download/0.7.2/stardoc-0.7.2.tar.gz"],
    )

    http_archive(
        name = "bazel_features",
        sha256 = "8b1c9b7558498000f5adebbc584b7bf15b6b2bf181448a66f6b2fc5b4c84231c",
        strip_prefix = "bazel_features-1.23.0",
        url = "https://github.com/bazel-contrib/bazel_features/releases/download/v1.23.0/bazel_features-v1.23.0.tar.gz",
    )

    http_archive(
        name = "buildifier_prebuilt",
        sha256 = "7f85b688a4b558e2d9099340cfb510ba7179f829454fba842370bccffb67d6cc",
        strip_prefix = "buildifier-prebuilt-7.3.1",
        urls = ["http://github.com/keith/buildifier-prebuilt/archive/7.3.1.tar.gz"],
    )

    http_archive(
        name = "aspect_rules_lint",
        sha256 = "7d5feef9ad85f0ba78cc5757a9478f8fa99c58a8cabc1660d610b291dc242e9b",
        strip_prefix = "rules_lint-1.0.2",
        url = "https://github.com/aspect-build/rules_lint/releases/download/v1.0.2/rules_lint-v1.0.2.tar.gz",
    )

    http_archive(
        name = "com_grail_bazel_toolchain",
        sha256 = "a9fc7cf01d0ea0a935bd9e3674dd3103766db77dfc6aafcb447a7ddd6ca24a78",
        strip_prefix = "toolchains_llvm-c65ef7a45907016a754e5bf5bfabac76eb702fd3",
        urls = ["https://github.com/bazel-contrib/toolchains_llvm/archive/c65ef7a45907016a754e5bf5bfabac76eb702fd3.tar.gz"],
    )

    http_archive(
        name = "org_chromium_sysroot_linux_arm64",
        build_file_content = _SYSROOT_LINUX_BUILD_FILE,
        sha256 = "cf2fefded0449f06d3cf634bfa94ffed60dbe47f2a14d2900b00eb9bcfb104b8",
        urls = ["https://commondatastorage.googleapis.com/chrome-linux-sysroot/toolchain/80fc74e431f37f590d0c85f16a9d8709088929e8/debian_bullseye_arm64_sysroot.tar.xz"],
    )

    http_archive(
        name = "org_chromium_sysroot_linux_x86_64",
        build_file_content = _SYSROOT_LINUX_BUILD_FILE,
        sha256 = "04b94ba1098b71f8543cb0ba6c36a6ea2890d4d417b04a08b907d96b38a48574",
        urls = ["https://commondatastorage.googleapis.com/chrome-linux-sysroot/toolchain/f5f68713249b52b35db9e08f67184cac392369ab/debian_bullseye_amd64_sysroot.tar.xz"],
    )

    http_archive(
        name = "sysroot_darwin_universal",
        build_file_content = _SYSROOT_DARWIN_BUILD_FILE,
        # The ruby header has an infinite symlink that we need to remove.
        patch_cmds = ["rm System/Library/Frameworks/Ruby.framework/Versions/Current/Headers/ruby/ruby"],
        sha256 = "71ae00a90be7a8c382179014969cec30d50e6e627570af283fbe52132958daaf",
        strip_prefix = "MacOSX11.3.sdk",
        urls = ["https://s3.us-east-2.amazonaws.com/static.aspect.build/sysroots/MacOSX11.3.sdk.tar.xz"],
    )

_SYSROOT_LINUX_BUILD_FILE = """
filegroup(
    name = "sysroot",
    srcs = glob(["*/**"]),
    visibility = ["//visibility:public"],
)
"""

_SYSROOT_DARWIN_BUILD_FILE = """
filegroup(
    name = "sysroot",
    srcs = glob(
        include = ["**"],
        exclude = ["**/*:*"],
    ),
    visibility = ["//visibility:public"],
)
"""
