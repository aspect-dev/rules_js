"""Providers for building derivative rules"""

load(
    "//npm/private:npm_package_info.bzl",
    _NpmPackageInfo = "NpmPackageInfo",
)
load(
    "//npm/private:npm_package_store_info.bzl",
    _NpmPackageStoreInfo = "NpmPackageStoreInfo",
)

NpmPackageInfo = _NpmPackageInfo
NpmPackageStoreInfo = _NpmPackageStoreInfo
