const std = @import("std");
const string = []const u8;
const gpa = std.heap.c_allocator;

const zigmod = @import("../lib.zig");
const u = @import("./../util/index.zig");
const common = @import("./../common.zig");

// Inspired by:
// https://docs.npmjs.com/cli/v7/commands/npm-ci

pub fn execute(args: [][]u8) !void {
    _ = args;

    const cachepath = try std.fs.path.join(gpa, &.{ ".zigmod", "deps" });
    const dir = std.fs.cwd();
    try do(cachepath, dir);
}

pub fn do(cachepath: string, dir: std.fs.Dir) !void {
    var options = common.CollectOptions{
        .log = true,
        .update = false,
        .lock = try common.parse_lockfile(dir),
    };
    const top_module = try common.collect_deps_deep(cachepath, dir, &options);

    var list = std.ArrayList(zigmod.Module).init(gpa);
    try common.collect_pkgs(top_module, &list);

    const fetch = @import("./fetch.zig");
    try fetch.create_depszig(cachepath, dir, top_module, &list);
}
