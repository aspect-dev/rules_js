"NpmPackageStoreInfo provider"

NpmPackageStoreInfo = provider(
    doc = """Provides information about an npm package within the package store of a pnpm-style
    symlinked node_modules tree.

    See https://pnpm.io/symlinked-node-modules-structure for more information about
    symlinked node_modules trees.""",
    fields = {
        "root_package": "package that this npm package store is linked at",
        "package": "name of this npm package",
        "version": "version of this npm package",
        "ref_deps": "dictionary of dependency npm_package_store ref targets",
        "package_store_directory": "the TreeArtifact of this npm package's package store location",
        "dev": "whether or not this npm package is a dev dependency",
    },
)
