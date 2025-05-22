const std = @import("std");
const gpa = std.heap.c_allocator;
const builtin = @import("builtin");

const u = @import("./../util/funcs.zig");

//
//

pub fn execute(self_name: []const u8, args: [][:0]u8) !void {
    _ = self_name;
    _ = args;

    const root = @import("root");
    const build_options = if (@hasDecl(root, "build_options")) root.build_options else struct {};
    const version = build_options.version;

    var gitversion = u.git_rev_HEAD(gpa, std.fs.cwd()) catch "";
    gitversion = if (gitversion.len > 0) gitversion[0..9] else gitversion;

    const stdout = std.io.getStdOut();
    const w = stdout.writer();

    try w.writeAll("zigmod");

    try w.print(" {s}", .{version});
    if (std.mem.eql(u8, version, "dev") and gitversion.len > 0) {
        try w.print("-{s}", .{gitversion});
    }

    try w.print(" {s}", .{@tagName(builtin.os.tag)});
    try w.print(" {s}", .{@tagName(builtin.cpu.arch)});
    try w.print(" {s}", .{@tagName(builtin.abi)});

    try w.writeAll("\n");
}
