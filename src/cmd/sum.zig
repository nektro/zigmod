const std = @import("std");
const gpa = std.heap.c_allocator;

const u = @import("./../util/index.zig");
const common = @import("./../common.zig");

//
//

pub fn execute(args: [][]u8) !void {
    _ = args;

    const dir = try std.fs.path.join(gpa, &.{ ".zigmod", "deps" });

    var options = common.CollectOptions{
        .log = false,
        .update = false,
    };
    const top_module = try common.collect_deps_deep(dir, "zig.mod", &options);

    //
    const f = try std.fs.cwd().createFile("zigmod.sum", .{});
    defer f.close();
    const w = f.writer();

    //
    var module_list = std.ArrayList(u.Module).init(gpa);
    try common.collect_pkgs(top_module, &module_list);

    for (module_list.items) |m| {
        if (m.clean_path.len == 0) {
            continue;
        }
        if (std.mem.eql(u8, m.clean_path, "../..")) {
            continue;
        }
        if (m.is_sys_lib) continue;
        const hash = try m.get_hash(dir);
        try w.print("{s} {s}\n", .{ hash, m.clean_path });
    }
}
