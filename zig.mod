id: 89ujp8gq842x6mzok8feypwze138n2d96zpugw44hcq7406r
name: zigmod
main: src/lib.zig
license: MIT
description: A package manager for the Zig programming language.
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

  # Entries above this line are needed to bootstrap and kept as git submodules
  # --------
  # Entries below this line are only fetched with zigmod itself 

  - src: git https://github.com/ziglibs/known-folders

  - src: git https://github.com/nektro/zig-licenses

  - src: git https://github.com/truemedian/zfetch

  - src: git https://github.com/nektro/zig-json

  - src: http https://aquila.red/1/nektro/range/v0.1.tar.gz sha256-d2f72fdd8cdb8 0 1

dev_dependencies:
  - src: git https://github.com/nektro/zig-ansi
