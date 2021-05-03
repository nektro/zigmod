const std = @import("std");
const gpa = std.heap.c_allocator;

const zfetch = @import("zfetch");
const json = @import("json");

const u = @import("./../../util/index.zig");

//
//

pub fn execute(args: [][]u8) !void {
    const pkg_id = args[0];

    const url = try std.mem.join(gpa, "/", &.{ "https://aquila.red", pkg_id });

    const req = try zfetch.Request.init(gpa, url, null);
    defer req.deinit();

    var headers = zfetch.Headers.init(gpa);
    defer headers.deinit();
    try headers.set("accept", "application/json");

    try req.do(.GET, headers, null);

    const r = req.reader();
    const body_content = try r.readAllAlloc(gpa, std.math.maxInt(usize));
    const val = try json.parse(gpa, body_content);

    if (val.get("message")) |msg| {
        std.log.err("server: {s}", .{msg.String});
        return;
    }

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
    try file_w.print("  - src: http https://aquila.red/{s}/v{d}.{d}.tar.gz _ {d} {d}\n", .{ pkg_id, v_maj, v_min, v_maj, v_min });
    try file_w.print("    version: {s}\n", .{v_hash});

    std.log.info("Successfully added package {s}", .{pkg_id});
}
