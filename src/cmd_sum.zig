const std = @import("std");
const gpa = std.heap.c_allocator;

const known_folders = @import("known-folders");
const u = @import("./util/index.zig");
const common = @import("./common.zig");

//
//

pub fn execute(args: [][]u8) !void {
    //
    const home = try known_folders.getPath(gpa, .home);
    const dir = try std.fs.path.join(gpa, &[_][]const u8{home.?, ".cache", "zigmod", "deps"});
    const top_module = try common.collect_deps(dir, "./zig.mod");
    
    //
    const f = try std.fs.cwd().createFile("./zig.sum", .{});
    defer f.close();
    const w = f.writer();

    //
    const module_list = &std.ArrayList(u.Module).init(gpa);
    try dedupe_mod_list(module_list, top_module);

    for (module_list.items) |m| {
        const hash = try m.get_hash(dir);
        try w.print("{} {}\n", .{m.clean_path, hash});
    }
}

fn dedupe_mod_list(list: *std.ArrayList(u.Module), module: u.Module) anyerror!void {
    if (u.list_contains_gen(u.Module, list, module)) {
        return;
    }
    if (module.clean_path.len > 0) {
        try list.append(module);
    }
    for (module.deps) |m| {
        try dedupe_mod_list(list, m);
    }
}
