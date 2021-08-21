const std = @import("std");
const gpa = std.heap.c_allocator;

const u = @import("./../util/index.zig");
const common = @import("./../common.zig");

// Inspired by:
// https://docs.npmjs.com/cli/v7/commands/npm-ci

pub fn execute(args: [][]u8) !void {
    _ = args;

    const cachepath = try std.fs.path.join(gpa, &.{ ".zigmod", "deps" });
    const dir = std.fs.cwd();

    var options = common.CollectOptions{
        .log = true,
        .update = false,
        .lock = try common.parse_lockfile(dir),
    };
    const top_module = try common.collect_deps_deep(cachepath, dir, &options);

    var list = std.ArrayList(u.Module).init(gpa);
    try common.collect_pkgs(top_module, &list);

    try @import("./fetch.zig").create_depszig(cachepath, top_module, &list);
}
