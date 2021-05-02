id: 89ujp8gq842x6mzok8feypwze138n2d96zpugw44hcq7406r
name: zigmod
main: src/lib.zig
license: MIT
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

  - src: git https://github.com/nektro/zig-ansi commit-25039ca

  # Entries above this line are needed to bootstrap and kept as git submodules
  # --------
  # Entries below this line are only fetched with zigmod itself 

  - src: git https://github.com/ziglibs/known-folders commit-f0f4188

  - src: git https://github.com/nektro/zig-licenses commit-1a19e4b

  - src: git https://github.com/truemedian/zfetch commit-5b9d6a2

  - src: git https://github.com/nektro/zig-json commit-ad4232e

dev_dependencies:
  - src: git https://github.com/nektro/zig-ansi commit-25039ca
