const std = @import("std");
const gpa = std.heap.c_allocator;

const zfetch = @import("zfetch");

const u = @import("./../../util/index.zig");
const zpm = @import("./../zpm.zig");

//
//

pub fn execute(args: [][]u8) !void {
    const url = "https://zpm.random-projects.net/api/packages";

    const req = try zfetch.Request.init(gpa, url, null);
    defer req.deinit();

    try req.do(.GET, null, null);
    const r = req.reader();

    const body_content = try r.readAllAlloc(gpa, std.math.maxInt(usize));
    var stream = std.json.TokenStream.init(body_content);
    const val = try std.json.parse([]zpm.Package, &stream, .{ .allocator = gpa });

    const found = blk: {
        for (val) |pkg| {
            if (std.mem.eql(u8, pkg.name, args[0])) {
                break :blk pkg;
            }
        }
        u.assert(false, "no package with name '{s}' found", .{args[0]});
        unreachable;
    };

    u.assert(found.root_file != null, "package must have an entry point to be able to be added to your dependencies", .{});

    const self_module = try u.ModFile.init(gpa, "zig.mod");
    for (self_module.deps) |dep| {
        if (std.mem.eql(u8, dep.name, found.name)) {
            std.log.warn("dependency with name '{s}' already exists in your dependencies", .{found.name});
        }
    }
    for (self_module.devdeps) |dep| {
        if (std.mem.eql(u8, dep.name, found.name)) {
            std.log.warn("dependency with name '{s}' already exists in your dev_dependencies", .{found.name});
        }
    }

    const has_zigdotmod = blk: {
        const _url = try std.mem.join(gpa, "/", &.{ found.git, "blob", "HEAD", "zig.mod" });
        const _req = try zfetch.Request.init(gpa, _url, null);
        defer _req.deinit();
        try _req.do(.GET, null, null);
        break :blk _req.status.code == 200;
    };

    const file = try std.fs.cwd().openFile("zig.mod", .{ .read = true, .write = true });
    try file.seekTo(try file.getEndPos());

    const file_w = file.writer();
    try file_w.print("\n", .{});
    try file_w.print("  - src: git {s}\n", .{std.mem.trimRight(u8, found.git, ".git")});
    if (!has_zigdotmod) {
        try file_w.print("    name: {s}\n", .{found.name});
        try file_w.print("    main: {s}\n", .{found.root_file.?[1..]});
    }

    std.log.info("Successfully added package {s} by {s}", .{ found.name, found.author });
}
