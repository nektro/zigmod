## `add --aq` command
```
zigmod add --aq <package>
```

This command takes `<package>` and adds its most recent version to your `zig.mod`.

If you're on the details page for a package, the string this command is expecting is the path of the url after the domain name. So for example for the package https://aquila.red/1/truemedian/zfetch, you would add it using `zigmod add --aq 1/truemedian/zfetch`.
