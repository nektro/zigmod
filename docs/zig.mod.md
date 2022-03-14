## `zigmod.yml` Reference

`zigmod.yml` is the main manifest that Zigmod will read to learn all about your application or package.

`zig.mod` is a valid legacy alternative.

### `id`
- Type: `string`
- Required
`id` is a randomly generated string used to identify your package coming from multiple sources. Sources here meaning various git repositories, http archive downloads, etc.

### `name`
- Type: `string`
- Required
This is the value that users of your package will [`@import`](https://ziglang.org/documentation/master/#import) you by.

### `main`
- Type: `string`
The is the local path to the entry point of your package and the file that will be returned when users run [`@import`](https://ziglang.org/documentation/master/#import) on your package.

### `license`
- Type: `string`
This is an optional field that may be set to specify the license that your package code is covered by. This field is read by the [`zigmod license`](commands/license_.md) command to show the licenses used by all of a project's dependencies. If the value of `license` is set to a [SPDX Identifier](https://spdx.org/licenses/) then a link to the license will also be printed for the user to learn more about it. Check the command reference for more info.

### `c_include_dirs`
- Type: `[]string`
This is a list of relative paths to folders which are a root search path for `.h` files when compiling C code in a project.

### `c_source_flags`
- Type: `[]string`
This is a list of [`clang`](https://clang.llvm.org/docs/UsersManual.html#command-line-options) C source flags that will be passed to all of the C files listed under the `c_source_files` for this project.

### `c_source_files`
- Type: `[]string`
This is a list of relative paths to C source files to compile along with this project. This will be required if you use Zig's [`@cImport`](https://ziglang.org/documentation/master/#cImport), `extern`, etc.

### `files`
- Type: `[]string`
This accepts a list of local directories to embed static assets. These files will be provided through a `self/files` package to `@import(main)`.

### `root_files`
- Type: `[]string`
This accepts a list of local directories to embed static assets. These files will be provided through a `self/files` package to `@import("root")`.

### `dependencies`
- Type: `[]Dep`
This is a list of `Dep` objects. `Dep` objects are how you include the other people's code in your project. See the `Dep` documentation below to learn more about the attributes available here.

### `root_dependencies`
- Type: `[]Dep`
Similar to `dependencies` but will only get added to the project if the current `zigmod.yml` is the root module.

### `build_dependencies`
- Type: `[]Dep`
Similar to `dependencies` but will only get added to the project if the current `zigmod.yml` is the root module. Exposed in `deps.zig` through the `deps.imports` decl.

### `min_zig_version`
- Type: `string`
Parsed as a `std.SemanticVersion`, this attribute refers to the minimum compatible Zig version for this package/application and will cause `zig build` to panic if violated.

#### `vcpkg`
- Type: `bool`
- Example: `true`|any
This attribute is a flag to call `try exe.addVcpkgPaths(.static);` when on Windows. Likely used in conjunction with adding system libraries/C code. `true` is the only value that will enable this flag.

----

### Dep Object
This is the object used in the top-level `dependencies` attribute and used to add external code to your project.

#### Dep `src`
- Type: `type path ?version`
- Example: `git https://github.com/Hejsil/zig-clap`
- Required
This is the base attribute used to reference external code for use in your project. `type` is an enum and only allows certain values. `path` is the URL or other identifier used to locate the contents of this package based on the `type`.

The available `type`s are:
- `local`
- `system_lib`
- `framework`
- `git`
- `hg`
- `http`
- `pijul`

For the full details on `Dep` types, you can check out the source where the enum is defined: https://github.com/nektro/zigmod/blob/master/src/util/dep_type.zig.

> Note: the `local` type modifies the input behavior to be shorthand for `<name> <main>` rather than `path version` since the latter fields don't make sense for local files.

#### Dep `version`
- Type: `string-string`
- Example: `commit-2c21764`
- Example: `sha256-8ff0b79fd9118af7a760f1f6a98cac3e69daed325c8f9f0a581ecb62f797fd64`
This attribute is used to reference the `type`/`path` combo by a specific revision, specific to the `type`. Specifying a `version` is ideal when possible because it ensures the immutability of the package contents being referenced, and thus Zigmod can skip going to the network if the package is already located on disk.

Version types available to each Dep type:
- `system_lib`
    - Not affected by `version`.
- `framework`
    - Not affected by `version`.
- `git`
    - `commit`
    - `tag`
    - `branch`
- `hg`
    - Not currently affected by `version`.
- `http`
    - `blake3`
    - `sha256`
    - `sha512`
- `pijul`
    - `channel`

#### Dep `only_os`
- Type: `comma-split string[]`
- Example: `windows`
- Example: `macos,tvos,ios`
This attribute specifies a way to filter when the dependency will be generated into the contents of `deps.zig`. `only_os` is an inclusive filter in which the dependency will only be in the output if the host target operating system is in the list specified or if this field is ommitted.

#### Dep `except_os`
- Type: `comma-split string[]`
- Example: `linux`
This attribute specifies a way to filter when the dependency will be generated into the contents of `deps.zig`. `except_os` is an exlusive filter in which the dependency will only be in the output if the host target operating is \*not\* in the list specified or if the field is ommitted.

#### Dep `keep`
- Type: `string`
- Example: `true`|any
This attribute is a manual override for having an external repo that contains no Zig or C code but other files be managed through Zigmod and `deps.zig`. `true` is the only value that will enable this flag.

#### Dep `vcpkg`
- Type: `string`
- Example: `true`|any
This attribute is a flag to call `try exe.addVcpkgPaths(.static);` when on Windows. Likely used in conjunction with adding system libraries/C code. `true` is the only value that will enable this flag.

#### Dep Overrides
There are a number of fields you can add to a `Dep` object that will override it's top-level value. This is most useful in the case where a project you want to use does not have a `zigmod.yml` manifest. You can then use overrides to define the values for them. The only top-level value you can not override is `dependencies`.
