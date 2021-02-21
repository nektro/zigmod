## `zig.mod` Reference
| Name | Type | Note | Description |
|------|------|------|-------------|
| `name` | `string` | required | The value users will put into `@import` |
| `main` | `string` | required | The `.zig` entry point into your package |
| `c_include_dirs` | `[]string` | | A list of relative paths to directories with `.h` files |
| `c_source_flags` | `[]string` | | A list of clang flags to pass to each of the `.c` files in `c_source_files` |
| `c_source_files` | `[]string` | | A list of relative paths to `.c` files to compile along with project |
| `license` | `string` | | A SPDX License Identifier specifying the license covering the code in this package. |
| `dependencies` | `[]Dep` | | An array of dependency objects |

### Dep object
| Name | Type | Note | Description |
|------|------|------|-------------|
| `type` | `string` | required, enum | One of `system_lib`, `git`, `hg`, `http` |
| `path` | `string` | required | URL/path to this dependency. depends on the type |
| `src` | `string` | Shorthand for the format `type path`. |
| `version` | `string` | only on some types | pin this dependency at a specific version |
| `only_os` | `string` | | comma separated list of OS names to add this Dep to |
| `except_os` | `string` | | comma separated list of OS names to exclude this Dep from |

Note:
- `name`, `main`, `c_include_dirs`, `c_source_flags`, `c_source_files`, can be overwritten as well.

### Versioning
- `type.git` supports version pinning by `branch-XX`, `tag-XX`, and `commit-XX`.
- `type.http` supports version checking by `blake3-XX`, `sha256-XX`, and `sha512-XX`.
