const std = @import("std");
const string = []const u8;

const zigmod = @import("../lib.zig");
const common = @import("./../common.zig");

// Inspired by:
// https://docs.npmjs.com/cli/v7/commands/npm-ci

pub fn execute(self_name: []const u8, args: [][]u8) !void {
    _ = self_name;
    _ = args;

    const gpa = std.heap.c_allocator;
    const cachepath = try std.fs.path.join(gpa, &.{ ".zigmod", "deps" });
    const dir = std.fs.cwd();
    try do(gpa, cachepath, dir);
}

pub fn do(alloc: std.mem.Allocator, cachepath: string, dir: std.fs.Dir) !void {
    var options = common.CollectOptions{
        .log = true,
        .update = false,
        .lock = try common.parse_lockfile(alloc, dir),
        .alloc = alloc,
    };
    const top_module = try common.collect_deps_deep(cachepath, dir, &options);

    var list = std.ArrayList(zigmod.Module).init(alloc);
    try common.collect_pkgs(top_module, &list);

    const fetch = @import("./fetch.zig");
    try fetch.create_depszig(alloc, cachepath, dir, top_module, &list);
}
