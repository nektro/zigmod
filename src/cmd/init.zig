const std = @import("std");
const gpa = std.heap.c_allocator;

const u = @import("./../util/index.zig");

//
//

pub fn execute(args: [][]u8) !void {
    const name = u.detect_pkgname(u.try_index([]const u8, args, 0, ""), null) catch |err| switch (err) {
        error.NoBuildZig => {
            u.assert(false, "init requires a build.zig file", .{});
            unreachable;
        },
        else => return err,
    };
    const mainf = u.detct_mainfile(u.try_index([]const u8, args, 1, ""), null, name) catch |err| switch (err) {
        error.CantFindMain => {
            u.assert(false, "unable to detect package entry point", .{});
            unreachable;
        },
        else => return err,
    };

    const file = try std.fs.cwd().createFile("zig.mod", .{});
    defer file.close();

    const fwriter = file.writer();
    try fwriter.print("id: {s}\n", .{u.random_string(48)});
    try fwriter.print("name: {s}\n", .{name});
    try fwriter.print("main: {s}\n", .{mainf});
    try fwriter.print("dependencies:\n", .{});

    u.print("Initialized a new package named {s} with entry point {s}", .{ name, mainf });
}
