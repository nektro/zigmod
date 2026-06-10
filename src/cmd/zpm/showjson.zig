const std = @import("std");
const gpa = std.heap.c_allocator;
const nfs = @import("nfs");

const zpm = @import("./../zpm.zig");

//
//

pub fn execute(self_name: []const u8, args: []const [:0]const u8) !void {
    _ = self_name;

    const out = nfs.stdout();

    const url = try std.mem.join(gpa, "/", &.{ zpm.server_root, args[0] });
    const doc = try zpm.server_fetch(url);
    doc.acquire();
    defer doc.release();

    try out.print("{}\n", .{doc});
}
