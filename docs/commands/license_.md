## `license` command
```
zigmod license
```

This will print a listing of all of your dependencies (deeply)' licenses. Any code is valid for the `license` field in `zig.mod` but should it match a valid SPDX identifier, a URL to learn more about the license will also be printed so the user can learn more about it.

Should one of your dependencies not have a `license` field in their `zig.mod` manifest, an `Unspecified:` list will appear at the bottom of the output.

Running this command on Zigmod itself (as of this writing) produces such output:
```
MIT:
= https://spdx.org/licenses/MIT
- This
- git https://github.com/yaml/libyaml
- git https://github.com/nektro/zig-ansi
- git https://github.com/ziglibs/known-folders
- git https://github.com/nektro/zig-licenses
- git https://github.com/truemedian/zfetch
- git https://github.com/truemedian/hzzp
- git https://github.com/alexnask/iguanaTLS
- git https://github.com/MasterQ32/zig-network
- git https://github.com/MasterQ32/zig-uri
- git https://github.com/nektro/zig-json
- git https://github.com/nektro/zig-range
- git https://github.com/nektro/zig-detect-license
- git https://github.com/nektro/zig-licenses-text
- git https://github.com/nektro/zig-leven
- git https://github.com/nektro/zig-fs-check
- git https://github.com/nektro/zig-inquirer
- git https://github.com/arqv/ini
- git https://github.com/marlersoft/zigwin32
```
