id: 89ujp8gq842x6mzok8feypwze138n2d96zpugw44hcq7406r
name: zigmod
main: src/lib.zig
license: MIT
description: A package manager for the Zig programming language.
min_zig_version: 0.10.0-dev.3998+c25ce5bba
dependencies:
  - src: git https://github.com/yaml/libyaml tag-0.2.5
    id: 8mdbh0zuneb0i3hs5jby5je0heem1i6yxusl7c8y8qx68hqc
    license: MIT
    c_include_dirs:
      - include
    c_source_flags:
      - -DYAML_VERSION_MAJOR=0
      - -DYAML_VERSION_MINOR=2
      - -DYAML_VERSION_PATCH=5
      - -DYAML_VERSION_STRING="0.2.5"
      - -DYAML_DECLARE_STATIC=1
    c_source_files:
      - src/api.c
      - src/dumper.c
      - src/emitter.c
      - src/loader.c
      - src/parser.c
      - src/reader.c
      - src/scanner.c
      - src/writer.c

  - src: git https://github.com/nektro/zig-ansi
  - src: git https://github.com/ziglibs/known-folders
  - src: git https://github.com/nektro/zig-licenses
  - src: git https://github.com/truemedian/zfetch
  - src: git https://github.com/nektro/zig-json
  - src: git https://github.com/nektro/zig-range
  - src: git https://github.com/nektro/zig-detect-license
  - src: git https://github.com/nektro/zig-inquirer
  - src: git https://github.com/nektro/arqv-ini
  - src: git https://github.com/nektro/zig-time

root_dependencies:
  - src: git https://github.com/marlersoft/zigwin32
