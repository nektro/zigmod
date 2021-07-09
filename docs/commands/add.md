## `add` command

```
zigmod add --<type> <path>
```

This commands takes `<type>` and `<path>` to add a package to your `zig.mod`.

This command will append the details to the end of your `zig.mod` file. If your project is using both `dependencies` and `dev_dependencies` you may need to move the appended text up manually to the correct section. This step will be unnecessary in the next manifest format version.

The available services are:

- [`add --aq <path>`](./add_aq.md)
- [`add --zpm <path>`](./add_zpm.md)
- [`add --git <path>`](./add_git.md)
