## `fetch` command
```
zigmod fetch
```

- This command takes no parameters and will generate a `deps.zig` in the root of your project.
- `deps.zig` is not typically checked into your source control.

For a full reference on the fields available in `deps.zig` you can check [here](../deps.zig.md).

### Adding `deps.zig` to your `build.zig`
```diff
 const std = @import("std");
 const Builder = std.build.Builder;
+const deps = @import("./deps.zig");
 
 pub fn build(b: *Builder) void {
     const target = b.standardTargetOptions(.{});
 
     const mode = b.standardReleaseOptions();
 
     const exe = b.addExecutable("hello", "src/main.zig");
     exe.setTarget(target);
     exe.setBuildMode(mode);
+    deps.addAllTo(exe);
     exe.install();
```
