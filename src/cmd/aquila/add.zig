const std = @import("std");
const gpa = std.heap.c_allocator;

const u = @import("./../../util/index.zig");
const aq = @import("./../aq.zig");

//
//

pub fn execute(args: [][]u8) !void {
    const pkg_id = args[0];

    const url = try std.mem.join(gpa, "/", &.{ aq.server_root, pkg_id });
    const val = try aq.server_fetch(url);

    const file = try std.fs.cwd().openFile("zig.mod", .{ .read = true, .write = true });
    try file.seekTo(try file.getEndPos());

    const file_w = file.writer();
    try file_w.print("  - src: git https://{s}/{s}\n", .{
        val.get(.{ "repo", "domain" }).?.String,
        val.get(.{ "pkg", "remote_name" }).?.String,
    });

    std.log.info("Successfully added package {s}", .{pkg_id});
}
