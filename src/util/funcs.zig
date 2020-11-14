const std = @import("std");
const gpa = std.heap.c_allocator;

const u = @import("index.zig");

//
//

pub fn print(comptime fmt: []const u8, args: anytype) void {
    std.debug.print(fmt++"\n", args);
}

pub fn assert(ok: bool, comptime fmt: []const u8, args: anytype) void {
    if (!ok) {
        print(comptime u.ansi.color.Fg(.Red, "error: " ++ fmt), args);
        std.os.exit(1);
    }
}

pub fn try_index(comptime T: type, array: []T, n: usize, def: T) T {
    if (array.len <= n) {
        return def;
    }
    return array[n];
}

pub fn split(in: []const u8, delim: []const u8) ![][]const u8 {
    const list = &std.ArrayList([]const u8).init(gpa);
    const iter = &std.mem.split(in, delim);
    while (iter.next()) |str| {
        try list.append(str);
    }
    return list.items;
}

pub fn trim_prefix(in: []const u8, prefix: []const u8) []const u8 {
    if (std.mem.startsWith(u8, in, prefix)) {
        return in[prefix.len..];
    }
    return in;
}

pub fn does_file_exist(fpath: []const u8) bool {
    const abs_path = std.fs.realpathAlloc(gpa, fpath) catch unreachable;
    const file = std.fs.openFileAbsolute(abs_path, .{}) catch |e| switch (e) {
        error.FileNotFound => return false,
        else => unreachable,
    };
    file.close();
    return true;
}

pub fn _join(comptime delim: []const u8, comptime xs: [][]const u8) []const u8 {
    var buf: []const u8 = "";
    for (xs) |x,i| {
        buf = buf ++ x;
        if (i < xs.len-1) buf = buf ++ delim;
    }
    return buf;
}
