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
      - src/api.c
      - src/dumper.c
      - src/emitter.c
      - src/loader.c
      - src/parser.c
      - src/reader.c
      - src/scanner.c
      - src/writer.c

  - src: git https://github.com/nektro/zig-ansi
    version: commit-25039ca

  #

  - src: git https://github.com/ziglibs/known-folders
    version: commit-f0f4188

  - src: git https://github.com/Vexu/zuri
    version: commit-0f9cec8

  - src: git https://github.com/alexnask/iguanaTLS
    version: commit-58f72f6
  
  # - src: git https://github.com/nektro/zig-licenses
  #   version: commit-a15ef9b
