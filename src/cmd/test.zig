const std = @import("std");
const nio = @import("nio");
const nfs = @import("nfs");
const root = @import("root");

const zigmod = @import("../lib.zig");
const u = @import("./../util/funcs.zig");
const common = @import("./../common.zig");

//
//

pub fn execute(self_name: []const u8, args: []const [:0]const u8) !void {
    _ = self_name;
    if (!std.process.can_replace) u.fail("The target OS does not support execv", .{});

    const gpa = std.heap.c_allocator;
    const cachepath = try u.find_cachepath();
    const dir = nfs.cwd();
    const should_lock = args.len >= 1 and std.mem.eql(u8, args[0], "--locked");

    var options = common.CollectOptions{
        .log = false,
        .update = false,
        .alloc = gpa,
        .lock = if (should_lock) try common.parse_lockfile(gpa, dir) else null,
    };
    const top_module = try common.collect_deps_deep(cachepath, dir, &options);

    var argv = std.array_list.Managed([]const u8).init(gpa);
    defer argv.deinit();

    var seencache = std.array_list.Managed([48]u8).init(gpa);
    defer seencache.deinit();

    try argv.append(root.environ.get("ZIG") orelse "zig");
    try argv.append("test");
    try argv.append("--name");
    try argv.append("test");
    try argv.append("--test-execve"); // requires >= https://codeberg.org/ziglang/zig/pulls/30811 or 0.16
    try argv.append("-lc");
    try addArgv(gpa, &argv, cachepath, top_module, &seencache);

    const io = root.io;
    return std.process.replace(io, .{ .argv = argv.items });
}

fn addArgv(allocator: std.mem.Allocator, argv: *std.array_list.Managed([]const u8), cachepath: []const u8, module: zigmod.Module, seencache: *std.array_list.Managed([48]u8)) !void {
    for (seencache.items) |item| {
        if (std.mem.eql(u8, &module.id, &item)) {
            return;
        }
    }
    try seencache.append(module.id);

    for (module.deps) |d| {
        if (d.type == .system_lib) {
            try argv.append(try nio.fmt.allocPrint(allocator, "-l{s}", .{d.name}));
            continue;
        }
        if (d.main.len == 0) {
            continue;
        }
        try argv.append("--dep");
        try argv.append(d.name);
    }
    if (module.type == .system_lib or module.main.len == 0) {
        //
    } else if (std.mem.eql(u8, module.name, "root")) {
        try argv.append(try nio.fmt.allocPrint(allocator, "-M{s}=test.zig", .{module.name}));
    } else if (module.clean_path.len == 0 or std.mem.eql(u8, module.clean_path, "../..")) {
        try argv.append(try nio.fmt.allocPrint(allocator, "-M{s}={s}", .{ module.name, module.main }));
    } else {
        try argv.append(try nio.fmt.allocPrint(allocator, "-M{s}={s}/{s}/{s}", .{ module.name, cachepath, module.clean_path, module.main }));
    }
    for (module.deps) |dep| {
        try addArgv(allocator, argv, cachepath, dep, seencache);
    }
}
