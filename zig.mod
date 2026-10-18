id: 89ujp8gq842x6mzok8feypwze138n2d96zpugw44hcq7406r
name: zigmod
main: src/lib.zig
license: MIT
description: A package manager for the Zig programming language.
min_zig_version: 0.17.0
min_zigmod_version: r96
dependencies:
  - src: git https://github.com/nektro/zig-yaml
  - src: git https://github.com/nektro/zig-ansi
  - src: git https://github.com/ziglibs/known-folders
    id: 2ta738wrqbaqzl3iwzoo8nj35k9ynwz5p5iyz80ryrpp4ttf
    name: known-folders
    main: known-folders.zig
    license: MIT
    version: commit-6da0d0c41b78b9ed2d34fa364fcb81b5ebece6c4
  - src: git https://github.com/nektro/zig-licenses
  - src: git https://github.com/nektro/zig-detect-license
  - src: git https://github.com/nektro/zig-inquirer
  - src: git https://github.com/nektro/arqv-ini
  - src: git https://github.com/nektro/zig-time
  - src: git https://github.com/nektro/zig-extras
  - src: git https://github.com/nektro/zig-git
  - src: git https://github.com/nektro/zig-json
  - src: git https://github.com/nektro/zig-nio
  - src: git https://github.com/nektro/zig-nfs

root_dependencies:
  - src: git https://github.com/marlersoft/zigwin32
    id: o6ogpor87xc23o863qaqfciqqdnt48nlj0395dk1xt4m9b34
    keep: true
    name: win32
    main: win32.zig
    license: MIT
  - src: git https://github.com/nektro/zig-extras
  - src: git https://github.com/nektro/zig-ansi
  - src: git https://github.com/nektro/zig-nio
  - src: git https://github.com/nektro/zig-nfs
