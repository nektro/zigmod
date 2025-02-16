const std = @import("std");
const gpa = std.heap.c_allocator;

const zigmod = @import("../lib.zig");
const u = @import("./../util/index.zig");
const common = @import("./../common.zig");

//
//

pub fn execute(self_name: []const u8, args: [][:0]u8) !void {
    _ = self_name;
    _ = args;

    const cachepath = try u.find_cachepath();
    const dir = std.fs.cwd();

    var options = common.CollectOptions{
        .log = false,
        .update = false,
        .alloc = gpa,
    };
    const top_module = try common.collect_deps_deep(cachepath, dir, &options);

    //
    const f = try dir.createFile("zigmod.sum", .{});
    defer f.close();
    const w = f.writer();

    //
    var module_list = std.ArrayList(zigmod.Module).init(gpa);
    try common.collect_pkgs(top_module, &module_list);

    for (module_list.items) |m| {
        if (m.clean_path.len == 0) {
            continue;
        }
        if (std.mem.eql(u8, m.clean_path, "../..")) {
            continue;
        }
        if (m.type.isLocal()) continue;
        const hash = try m.get_hash(gpa, cachepath);
        try w.print("{s} {s}\n", .{ hash, m.clean_path });
    }
}
