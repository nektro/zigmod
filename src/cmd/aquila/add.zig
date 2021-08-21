const std = @import("std");
const gpa = std.heap.c_allocator;

const u = @import("./../../util/index.zig");
const aq = @import("./../aq.zig");

//
//

pub fn execute(args: [][]u8) !void {
    const pkg_id = args[0];
    _ = try do(std.fs.cwd(), pkg_id);
    std.log.info("Successfully added package {s}", .{pkg_id});
}

pub fn do(dir: std.fs.Dir, pkg_id: []const u8) ![]const u8 {
    const url = try std.mem.join(gpa, "/", &.{ aq.server_root, pkg_id });
    const val = try aq.server_fetch(url);

    const pkg_url = try std.fmt.allocPrint(gpa, "https://{s}/{s}", .{
        val.get(.{ "repo", "domain" }).?.String,
        val.get(.{ "pkg", "RemoteName" }).?.String,
    });

    const m = try u.ModFile.from_dir(gpa, dir);
    for (m.devdeps) |d| {
        if (std.mem.eql(u8, d.path, pkg_url)) {
            return pkg_url;
        }
    }

    const file = try dir.openFile("zig.mod", .{ .read = true, .write = true });
    defer file.close();
    try file.seekTo(try file.getEndPos());

    const file_w = file.writer();
    try file_w.print("  - src: git {s}\n", .{pkg_url});

    return pkg_url;
}
