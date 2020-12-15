const std = @import("std");
const gpa = std.heap.c_allocator;

const u = @import("./util/index.zig");

//
//

pub fn execute(args: [][]u8) !void {
    const name = try detect_pkgname(u.try_index([]const u8, args, 0, ""));
    const mainf = try detct_mainfile(u.try_index([]const u8, args, 1, ""));

    const file = try std.fs.cwd().createFile("zig.mod", .{});
    defer file.close();

    const fwriter = file.writer();
    try fwriter.print("id: {}\n", .{u.random_string(48)});
    try fwriter.print("name: {}\n", .{name});
    try fwriter.print("main: {}\n", .{mainf});
    try fwriter.print("dependencies:\n", .{});

    u.print("Initialized a new package named {} with entry point {}", .{name, mainf});
}

fn detect_pkgname(def: []const u8) ![]const u8 {
    if (def.len > 0) {
        return def;
    }
    const dpath = try std.fs.cwd().realpathAlloc(gpa, ".");
    const split = try u.split(dpath, std.fs.path.sep_str);
    var name = split[split.len-1];
    name = u.trim_prefix(name, "zig-");
    u.assert(name.len > 0, "package name must not be an empty string", .{});
    return name;
}

fn detct_mainfile(def: []const u8) ![]const u8 {
    if (def.len > 0) {
        if (try u.does_file_exist(def)) {
            if (std.mem.endsWith(u8, def, ".zig")) {
                return def;
            }
        }
    }
    if (try u.does_file_exist("./src/lib.zig")) {
        return "src/lib.zig";
    }
    if (try u.does_file_exist("./src/main.zig")) {
        return "src/main.zig";
    }
    u.assert(false, "unable to detect package entry point", .{});
    unreachable;
}
