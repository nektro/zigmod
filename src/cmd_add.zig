const std = @import("std");
const gpa = std.heap.c_allocator;

const u = @import("./util/index.zig");

//
//

pub fn execute(args: [][]u8) !void {
    //
    u.assert(args.len >= 1, "missing package <type> parameter", .{});
    u.assert(args.len >= 2, "missing package <path> parameter", .{});

    const dept = args[0];
    const path = args[1];

    const dep_type = std.meta.stringToEnum(u.DepType, dept);
    u.assert(dep_type != null, "provided <type> parameter \"{}\" is not a valid dependency type", .{dept});

    const m = try u.ModFile.init(gpa, "./zig.mod");
    for (m.deps) |d| {
        u.assert(!(d.type == dep_type.? and std.mem.eql(u8, d.path, path)), "dependency already added, skipping!", .{});
    }

    const ndl = &std.ArrayList(u.Dep).init(gpa);
    for (m.deps) |d| {
        try ndl.append(d);
    }
    try ndl.append(u.Dep{
        .type = dep_type.?,
        .path = path,
    });

    //
    const f = try std.fs.cwd().createFile("./zig.mod", .{});
    defer f.close();

    const w = f.writer();
    try w.print("name: {}\n", .{m.name});
    try w.print("main: {}\n", .{m.main});
    try w.print("dependencies:\n", .{});

    for (ndl.items) |d| {
        try w.print("- type: {}\n", .{@tagName(d.type)});
        try w.print("  path: {}\n", .{d.path});
    }

    u.print("Successfully added {}", .{path});
}
