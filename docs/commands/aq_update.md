## `aq update` command
```
zigmod aq update
```

This command takes no arguments and will check your `zig.mod` file for direct dependencies that have new versions available. If found it will print the respective version ID string that you can then pass to [`aq modfile`](aq_modfile.md) to get the relevant yaml text to update in your `zig.mod`.

In the next version of the manifest format, this process will be done automatically without the need for `aq modfile`.
