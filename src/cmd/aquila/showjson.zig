const std = @import("std");
const gpa = std.heap.c_allocator;

const aq = @import("./../aq.zig");

//
//

pub fn execute(args: [][]u8) !void {
    const out = std.io.getStdOut().writer();

    const url = try std.mem.join(gpa, "/", &.{ aq.server_root, args[0] });
    const val = try aq.server_fetch(url);

    try out.print("{}\n", .{val});
}
