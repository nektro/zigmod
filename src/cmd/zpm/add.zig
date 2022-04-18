const std = @import("std");
const gpa = std.heap.c_allocator;
const zfetch = @import("zfetch");

const zigmod = @import("../../lib.zig");
const u = @import("./../../util/index.zig");
const zpm = @import("./../zpm.zig");

//
//

pub fn execute(args: [][]u8) !void {
    const url = try std.mem.join(gpa, "/", &.{ zpm.server_root, "packages" });
    const val = try zpm.server_fetchArray(url);

    const found = blk: {
        for (val) |pkg| {
            if (std.mem.eql(u8, pkg.name, args[0])) {
                break :blk pkg;
            }
        }
        u.fail("no package with name '{s}' found", .{args[0]});
    };

    const self_module = try zigmod.ModFile.init(gpa);
    for (self_module.deps) |dep| {
        if (std.mem.eql(u8, dep.name, found.name)) {
            std.log.warn("dependency with name '{s}' already exists in your dependencies", .{found.name});
        }
    }
    for (self_module.rootdeps) |dep| {
        if (std.mem.eql(u8, dep.name, found.name)) {
            std.log.warn("dependency with name '{s}' already exists in your root_dependencies", .{found.name});
        }
    }
    for (self_module.builddeps) |dep| {
        if (std.mem.eql(u8, dep.name, found.name)) {
            std.log.warn("dependency with name '{s}' already exists in your build_dependencies", .{found.name});
        }
    }

    const has_zigdotmod = blk: {
        const _url = try std.mem.join(gpa, "/", &.{ found.git, "blob", "HEAD", "zig.mod" });
        const _req = try zfetch.Request.init(gpa, _url, null);
        defer _req.deinit();
        try _req.do(.GET, null, null);
        break :blk _req.status.code == 200;
    };
    const has_zigmodyml = blk: {
        const _url = try std.mem.join(gpa, "/", &.{ found.git, "blob", "HEAD", "zigmod.yml" });
        const _req = try zfetch.Request.init(gpa, _url, null);
        defer _req.deinit();
        try _req.do(.GET, null, null);
        break :blk _req.status.code == 200;
    };

    const file = try zigmod.ModFile.openFile(std.fs.cwd(), .{ .mode = .read_write });
    defer file.close();
    try file.seekTo(try file.getEndPos());

    const file_w = file.writer();
    try file_w.writeAll("\n");
    try file_w.print("  - src: git {s}\n", .{u.trim_suffix(found.git, ".git")});
    if (!(has_zigdotmod or has_zigmodyml)) {
        try file_w.print("    name: {s}\n", .{found.name});
        try file_w.print("    main: {s}\n", .{found.root_file[1..]});
    }

    std.log.info("Successfully added package {s} by {s}", .{ found.name, found.author });
}
