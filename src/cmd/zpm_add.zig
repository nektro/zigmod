const std = @import("std");
const gpa = std.heap.c_allocator;

const zfetch = @import("zfetch");
const json = @import("json");

const u = @import("./../util/index.zig");

//
//

pub const Zpm = struct {
    pub const Package = struct {
        author: []const u8,
        name: []const u8,
        tags: [][]const u8,
        git: []const u8,
        root_file: ?[]const u8,
        description: []const u8,
    };
};

pub fn execute(args: [][]u8) !void {
    const url = "https://zpm.random-projects.net/api/packages";

    const req = try zfetch.Request.init(gpa, url, null);
    defer req.deinit();

    try req.do(.GET, null, null);
    const r = req.reader();

    const body_content = try r.readAllAlloc(gpa, std.math.maxInt(usize));
    const val = try json.parse(gpa, body_content);

    const found = blk: {
        for (val.Array) |pkg| {
            if (std.mem.eql(u8, pkg.get("name").?.String, args[0])) {
                break :blk pkg;
            }
        }
        u.assert(false, "no package with name '{s}' found", .{args[0]});
        unreachable;
    };

    u.assert(found.get("root_file") != null, "package must have an entry point to be able to be added to your dependencies", .{});

    const self_module = try u.ModFile.init(gpa, "zig.mod");
    for (self_module.deps) |dep| {
        if (std.mem.eql(u8, dep.name, found.get("name").?.String)) {
            std.log.warn("dependency with name '{s}' already exists in your dependencies", .{found.get("name").?.String});
        }
    }

    const file = try std.fs.cwd().openFile("zig.mod", .{ .read = true, .write = true });
    try file.seekTo(try file.getEndPos());

    const file_w = file.writer();
    try file_w.print("\n", .{});
    try file_w.print("  - src: git {s}\n", .{found.get("git").?.String});
    try file_w.print("    name: {s}\n", .{found.get("name").?.String});
    try file_w.print("    main: {s}\n", .{found.get("root_file").?.String[1..]});

    std.log.info("Successfully added package {s} by {s}", .{ found.get("name").?.String, found.get("author").?.String });
}
