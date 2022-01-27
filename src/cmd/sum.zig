const std = @import("std");
const gpa = std.heap.c_allocator;

const zigmod = @import("../lib.zig");
const common = @import("./../common.zig");

//
//

pub fn execute(args: [][]u8) !void {
    _ = args;

    const cachepath = try std.fs.path.join(gpa, &.{ ".zigmod", "deps" });
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
        if (m.is_sys_lib) continue;
        const hash = try m.get_hash(cachepath);
        try w.print("{s} {s}\n", .{ hash, m.clean_path });
    }
}
