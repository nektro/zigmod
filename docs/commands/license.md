## `license` command
```
zigmod license
```

This will print a listing of all of your dependencies (deeply)' licenses. Any code is valid for the `license` field in `zig.mod` but should it match a valid SPDX identifier, a URL to learn more about the license will also be printed so the user can learn more about it.

Should one of your dependencies not have a `license` field in their `zig.mod` manifest, an `Unspecified:` list will appear at the bottom of the output.

Running this command on Zigmod itself (as of this writing) produces such output:
```
MIT:
= https://opensource.org/licenses/MIT
- This
- v/git/github.com/yaml/libyaml/tag-0.2.5
- v/git/github.com/nektro/zig-ansi/commit-25039ca
- v/git/github.com/ziglibs/known-folders/commit-f0f4188
- v/git/github.com/Vexu/zuri/commit-41bcd78
- v/git/github.com/alexnask/iguanaTLS/commit-58f72f6
- v/git/github.com/nektro/zig-licenses/commit-a15ef9b
```
