const std = @import("std");
const gpa = std.heap.c_allocator;
const extras = @import("extras");

const zpm = @import("./../zpm.zig");

//
//

pub fn execute(self_name: []const u8, args: [][:0]u8) !void {
    _ = self_name;
    _ = args;

    const out = std.io.getStdOut().writer();

    const url = try std.mem.join(gpa, "/", &.{ zpm.server_root, "packages" });
    const list = try zpm.server_fetchArray(url);

    const name_col_width = blk: {
        var w: usize = 4;
        for (list) |pkg| {
            const len = pkg.name.len;
            if (len > w) {
                w = len;
            }
        }
        break :blk w + 2;
    };

    const author_col_width = blk: {
        var w: usize = 6;
        for (list) |pkg| {
            const len = pkg.author.len;
            if (len > w) {
                w = len;
            }
        }
        break :blk w + 2;
    };

    try out.writeAll("NAME");
    try print_c_n(out, ' ', name_col_width - 4);
    try out.writeAll("AUTHOR");
    try print_c_n(out, ' ', author_col_width - 6);
    try out.writeAll("DESCRIPTION\n");

    for (list) |pkg| {
        try out.writeAll(pkg.name);
        try print_c_n(out, ' ', name_col_width - pkg.name.len);

        try out.writeAll(pkg.author);
        try print_c_n(out, ' ', author_col_width - pkg.author.len);

        try out.writeAll(pkg.description);
        try out.writeAll("\n");
    }
}

fn print_c_n(out: anytype, c: u8, n: usize) !void {
    for (0..n) |_| {
        try out.writeAll(&.{c});
    }
}
