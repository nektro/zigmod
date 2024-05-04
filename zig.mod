id: 89ujp8gq842x6mzok8feypwze138n2d96zpugw44hcq7406r
name: zigmod
main: src/lib.zig
license: MIT
description: A package manager for the Zig programming language.
min_zig_version: 0.11.0
dependencies:
  - src: git https://github.com/nektro/zig-yaml
  - src: git https://github.com/nektro/zig-ansi
  - src: git https://github.com/ziglibs/known-folders
  - src: git https://github.com/nektro/zig-licenses
  - src: git https://github.com/nektro/zfetch
  - src: git https://github.com/nektro/zig-detect-license
  - src: git https://github.com/nektro/zig-inquirer
  - src: git https://github.com/nektro/arqv-ini
  - src: git https://github.com/nektro/zig-time
  - src: git https://github.com/nektro/zig-extras

root_dependencies:
  - src: git https://github.com/marlersoft/zigwin32
    id: zg4wbiyyfn2fdpmia0jjh2d5k0xb7v1l7zn3xcyv
    keep: true
  - src: git https://github.com/nektro/zig-extras
  - src: git https://github.com/nektro/zig-ansi
