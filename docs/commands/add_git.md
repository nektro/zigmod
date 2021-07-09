## `add --git` command
```
zigmod add --git <url>
```

This command takes `<url>` and adds its most recent version to your `zig.mod`. `<url>` must be an URL to a git repository, with or without the `.git` at the end of the path.

If the git repository does not contains a `zig.mod` file, the command will prompt you to manually enter the `name` and `main` attributes.
