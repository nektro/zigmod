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

pub fn does_file_exist(fpath: []const u8) !bool {
    const abs_path = std.fs.realpathAlloc(gpa, fpath) catch |e| switch (e) {
        error.FileNotFound => return false,
        else => return e,
    };
    const file = std.fs.openFileAbsolute(abs_path, .{}) catch |e| switch (e) {
        error.FileNotFound => return false,
        else => return e,
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

pub fn trim_suffix(comptime T: type, in: []const T, suffix: []const T) []const T {
    if (std.mem.endsWith(T, in, suffix)) {
        return in[0..in.len-suffix.len];
    }
    return in;
}

pub fn repeat(s: []const u8, times: i32) ![]const u8 {
    const list = &std.ArrayList([]const u8).init(gpa);
    var i: i32 = 0;
    while (i < times) : (i += 1) {
        try list.append(s);
    }
    return join(list.items, "");
}

pub fn join(xs: [][]const u8, delim: []const u8) ![]const u8 {
    var res: []const u8 = "";
    for (xs) |x, i| {
        res = try std.fmt.allocPrint(gpa, "{}{}{}", .{res, x, if (i < xs.len-1) delim else ""});
    }
    return res;
}

pub fn concat(items: [][]const u8) ![]const u8 {
    var buf: []const u8 = "";
    for (items) |x| {
        buf = try std.fmt.allocPrint(gpa, "{}{}", .{buf, x});
    }
    return buf;
}

pub fn print_all(w: std.fs.File.Writer, items: anytype, ln: bool) !void {
    inline for (items) |x, i| {
        if (i == 0) {
            try w.print("{}", .{x});
        } else {
            try w.print(" {}", .{x});
        }
    }
    if (ln) {
        try w.print("\n", .{});
    }
}

pub fn list_contains(haystack: [][]const u8, needle: []const u8) bool {
    for (haystack) |item| {
        if (std.mem.eql(u8, item, needle)) {
            return true;
        }
    }
    return false;
}

pub fn open_dir_absolute(dpath: []const u8) !std.fs.Dir {
    return std.fs.Dir{
        .fd = (try std.fs.openFileAbsolute(dpath, .{})).handle,
    };
}

pub fn list_contains_gen(comptime T: type, haystack: *std.ArrayList(T), needle: T) bool {
    for (haystack.items) |item| {
        if (item.eql(needle)) {
            return true;
        }
    }
    return false;
}

pub fn file_list(dpath: []const u8, list: *std.ArrayList([]const u8)) !void {
    var walk = try std.fs.walkPath(gpa, dpath);
    while (true) {
        if (try walk.next()) |entry| {
            if (entry.kind != .File) {
                continue;
            }
            try list.append(try gpa.dupe(u8, entry.path));
        }
        else {
            break;
        }
    }
}

pub fn run_cmd(dir: ?[]const u8, args: []const []const u8) !u32 {
    const result = std.ChildProcess.exec(.{ .allocator = gpa, .cwd = dir, .argv = args, }) catch |e| switch(e) {
        error.FileNotFound => {
            u.assert(false, "\"{}\" command not found", .{args[0]});
            unreachable;
        },
        else => return e,
    };
    return result.term.Exited;
}
