## `fetch` command
```
zigmod fetch
```

- This command takes no parameters and will generate a `deps.zig` in the root of your project. This is the file that you will then import into your `build.zig` to automatically add all the necessary packages and (any) C code that may be in your dependencies.
- `deps.zig` is not typically checked into your source control.
- This command will also produce a `zigmod.lock` which you can use to easily generate [reproducible builds](https://reproducible-builds.org/) using the [`ci`](./ci.md) command.

For a full reference on the fields available in `deps.zig` you can check [here](../deps.zig.md).

### Adding `deps.zig` to your `build.zig`
```diff
 const std = @import("std");
+const deps = @import("./deps.zig");
 
 pub fn build(b: *std.build.Builder) void {
     const target = b.standardTargetOptions(.{});
 
     const mode = b.standardReleaseOptions();
 
     const exe = b.addExecutable("hello", "src/main.zig");
     exe.setTarget(target);
     exe.setBuildMode(mode);
+    deps.addAllTo(exe);
     exe.install();
```

## Screenshot
![image](https://user-images.githubusercontent.com/5464072/127753849-53d4f4df-d9de-459a-a9db-6b61e5fb0d17.png)

In addition to fetching your dependencies `fetch` will help you track any updates.

In the event you are using Git, `fetch` will parse the diff of your committed `zigmod.lock` with the new one it just printed and give you a status update on new packages, removed packages, or updated packages. If a dependency happens to be hosted on a major Git provider, then it will also reformat the updates section to print a compare URL so you may visit it in a browser and view the changes directly. Else, it will still print the "from" and "to" commits.
