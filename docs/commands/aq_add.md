## `aq add` command
```
zigmod aq add <package>
```

This command takes `<package>` and adds its most recent version to your `zigmod.yml`.

If you're on the details page for a package, the string this command is expecting is the path of the url after the domain name. So for example for the package https://aquila.red/1/truemedian/zfetch, you would add it using `zigmod aq add 1/truemedian/zfetch`.

It will append the details to the end of your `zigmod.yml` file. If you're project is using both `dependencies` and `dev_dependencies` you may need to move the appended text up manually to the correct section. This step will be unnecessary in the next manifest format version.
