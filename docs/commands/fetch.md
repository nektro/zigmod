## `fetch` command
```
zigmod fetch
```

- This command takes no parameters and will generate a `deps.zig` in the root of your project. This is the file that you will then import into your `build.zig` to automatically add all the necessary packages and (any) C code that may be in your dependencies.
- `deps.zig` is not typically checked into your source control.

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
