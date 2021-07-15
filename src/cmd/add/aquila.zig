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

    const name = val.get(.{ "pkg", "name" }).?.String;

    const versions = val.get("versions").?.Array;
    const to_add = versions[versions.len - 1];

    const self_module = try u.ModFile.init(gpa, "zig.mod");
    for (self_module.deps) |dep| {
        if (std.mem.eql(u8, dep.name, name)) {
            std.log.warn("dependency with name '{s}' already exists in your dependencies", .{name});
        }
    }
    for (self_module.devdeps) |dep| {
        if (std.mem.eql(u8, dep.name, name)) {
            std.log.warn("dependency with name '{s}' already exists in your dependencies", .{name});
        }
    }

    const file = try std.fs.cwd().openFile("zig.mod", .{ .read = true, .write = true });
    try file.seekTo(try file.getEndPos());

    const v_hash = to_add.get("tar_hash").?.String;
    const v_maj = to_add.get("real_major").?.Number;
    const v_min = to_add.get("real_minor").?.Number;

    const file_w = file.writer();
    try file_w.print("\n", .{});
    try file_w.print("  - src: http {s}/v{d}.{d}.tar.gz {s} {d} {d}\n", .{ url, v_maj, v_min, v_hash[0..20], v_maj, v_min });

    std.log.info("Successfully added package {s}", .{pkg_id});
}
