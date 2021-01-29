id: 89ujp8gq842x6mzok8feypwze138n2d96zpugw44hcq7406r
name: zigmod
main: src/main.zig
dependencies:
  - src: git https://github.com/yaml/libyaml
    version: tag-0.2.5
    c_include_dirs:
      - include
    c_source_flags:
      - -DYAML_VERSION_MAJOR=0
      - -DYAML_VERSION_MINOR=2
      - -DYAML_VERSION_PATCH=5
      - -DYAML_VERSION_STRING="0.2.5"
      - -DYAML_DECLARE_STATIC=1
    c_source_files:
      - libs/yaml/src/dumper.c
      - libs/yaml/src/emitter.c
      - libs/yaml/src/loader.c
      - libs/yaml/src/parser.c
      - libs/yaml/src/reader.c
      - libs/yaml/src/scanner.c
      - libs/yaml/src/writer.c

  - src: git https://github.com/ziglibs/known-folders
    version: commit-e1193f9ef5b3aad7a6071e9f5721934fe04a020e

  - src: git https://github.com/nektro/zig-ansi
    version: commit-876c32c42044a5e1554f4662b4b9bdfad7ee5086
