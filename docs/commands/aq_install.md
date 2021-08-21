## `aq install` command
```
zigmod aq install <package>
```

This command takes `<package>` and installs it for use on your local machine.

If you're on the details page for a package, the string this command is expecting is the path of the url after the domain name. So for example for the package https://aquila.red/1/nektro/discord-archiver, you would add it using `zigmod aq install 1/nektro/discord-archiver`.

Adding `~/.zigmod/bin` to your `$PATH` will allow you to reference the commands by name instead of by absolute path.

The directory `~/.cache/zigmod` is a cache directory and may be deleted at any time.
