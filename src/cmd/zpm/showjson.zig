const std = @import("std");
const gpa = std.heap.c_allocator;

const zfetch = @import("zfetch");
const json = @import("json");

const u = @import("./../util/index.zig");
const zpm = @import("./../zpm.zig");

//
//

pub fn execute(args: [][]u8) !void {
    const url = try std.mem.join(gpa, "/", &.{ zpm.server_root, args[0] });
    const val = try zpm.server_fetch(url);

    const out = std.io.getStdOut().writer();
    try out.print("{}\n", .{val});
}
