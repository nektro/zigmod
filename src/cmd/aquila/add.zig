const std = @import("std");
const string = []const u8;
const gpa = std.heap.c_allocator;

const zigmod = @import("../../lib.zig");
const u = @import("./../../util/index.zig");
const aq = @import("./../aq.zig");

//
//

pub fn execute(args: [][]u8) !void {
    const pkg_id = args[0];
    _ = try do(std.fs.cwd(), pkg_id);
    std.log.info("Successfully added package {s}", .{pkg_id});
}

pub fn do(dir: std.fs.Dir, pkg_id: string) !string {
    const url = try std.mem.join(gpa, "/", &.{ aq.server_root, pkg_id });
    const val = try aq.server_fetch(url);

    const pkg_url = try std.fmt.allocPrint(gpa, "https://{s}/{s}", .{
        val.getT(.{ "repo", "domain" }, .String).?,
        val.getT(.{ "pkg", "RemoteName" }, .String).?,
    });

    const m = try zigmod.ModFile.from_dir(gpa, dir);
    for (m.rootdeps) |d| {
        if (std.mem.eql(u8, d.path, pkg_url)) {
            return pkg_url;
        }
    }
    for (m.builddeps) |d| {
        if (std.mem.eql(u8, d.path, pkg_url)) {
            return pkg_url;
        }
    }

    const file = try zigmod.ModFile.openFile(std.fs.cwd(), .{ .mode = .read_write });
    defer file.close();
    try file.seekTo(try file.getEndPos());

    const file_w = file.writer();
    try file_w.print("  - src: git {s}\n", .{pkg_url});

    return pkg_url;
}
