const std = @import("std");
const gpa = std.heap.c_allocator;
const extras = @import("extras");
const range = extras.range;

const zpm = @import("./../zpm.zig");

//
//

pub fn execute(args: [][]u8) !void {
    _ = args;

    const out = std.io.getStdOut().writer();

    const url = try std.mem.join(gpa, "/", &.{ zpm.server_root, "tags" });
    const val = try zpm.server_fetch(url);

    const name_col_width = blk: {
        var w: usize = 4;
        for (val.Array) |tag| {
            const len = tag.getT("name", .String).?.len;
            if (len > w) {
                w = len;
            }
        }
        break :blk w + 2;
    };

    try out.writeAll("NAME");
    try print_c_n(out, ' ', name_col_width - 4);
    try out.writeAll("DESCRIPTION\n");

    for (val.Array) |tag| {
        const name = tag.getT("name", .String).?;
        try out.writeAll(name);
        try print_c_n(out, ' ', name_col_width - name.len);
        try out.writeAll(tag.getT("description", .String).?);
        try out.writeAll("\n");
    }
}

fn print_c_n(out: anytype, c: u8, n: usize) !void {
    for (range(n)) |_| {
        try out.writeAll(&.{c});
    }
}
