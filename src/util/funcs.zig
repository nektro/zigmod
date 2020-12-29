const std = @import("std");
const gpa = std.heap.c_allocator;

const ansi = @import("ansi");
const u = @import("index.zig");

//
//

pub const b = 1;
pub const kb = b * 1024;
pub const mb = kb * 1024;
pub const gb = mb * 1024;

pub fn print(comptime fmt: []const u8, args: anytype) void {
    std.debug.print(fmt++"\n", args);
}

pub fn assert(ok: bool, comptime fmt: []const u8, args: anytype) void {
    if (!ok) {
        print(comptime ansi.color.Fg(.Red, "error: " ++ fmt), args);
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
    const file = std.fs.cwd().openFile(fpath, .{}) catch |e| switch (e) {
        error.FileNotFound => return false,
        else => return e,
    };
    defer file.close();
    return true;
}

pub fn does_folder_exist(fpath: []const u8) !bool {
    const file = std.fs.cwd().openFile(fpath, .{}) catch |e| switch (e) {
        error.FileNotFound => return false,
        else => return e,
    };
    defer file.close();
    const s = try file.stat();
    if (s.kind != .Directory) {
        return false;
    }
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

pub fn list_remove(input: [][]const u8, search: []const u8) ![][]const u8 {
    const list = &std.ArrayList([]const u8).init(gpa);
    for (input) |item| {
        if (!std.mem.eql(u8, item, search)) {
            try list.append(item);
        }
    }
    return list.items;
}

pub fn last(in: [][]const u8) ![]const u8 {
    if (in.len == 0) {
        return error.EmptyArray;
    }
    return in[in.len - 1];
}

pub fn mkdir_all(dpath: []const u8) anyerror!void {
    const d = if (dpath[dpath.len-1] == std.fs.path.sep) dpath[0..dpath.len-1] else dpath;
    const ps = std.fs.path.sep_str;
    const e = dpath[0..std.mem.lastIndexOf(u8, dpath, ps).?];
    if (std.mem.indexOf(u8, e, ps)) |_| {} else {
        return;
    }
    try mkdir_all(e);
    if (!try does_folder_exist(d)) {
        try std.fs.makeDirAbsolute(d);
    }
}

pub fn rm_recv(path: []const u8) anyerror!void {
    const abs_path = std.fs.realpathAlloc(gpa, path) catch |e| switch (e) {
        error.FileNotFound => return,
        else => return e,
    };
    const file = try std.fs.openFileAbsolute(abs_path, .{});
    defer file.close();
    const s = try file.stat();
    if (s.kind == .Directory) {
        const dir = std.fs.cwd().openDir(abs_path, .{ .iterate=true, }) catch unreachable;
        var iter = dir.iterate();
        while (try iter.next()) |item| {
            try rm_recv(try std.fs.path.join(gpa, &[_][]const u8{abs_path, item.name}));
        }
        try std.fs.deleteDirAbsolute(abs_path);
    }
    else {
        try std.fs.deleteFileAbsolute(abs_path);
    }
}

const alphabet = "0123456789abcdefghijklmnopqrstuvwxyz";

pub fn random_string(len: usize) ![]const u8 {
    const now = @intCast(u64, std.time.nanoTimestamp());
    var rand = std.rand.DefaultPrng.init(now);
    const r = &rand.random;
    var buf = try gpa.alloc(u8, len);
    var i: usize = 0;
    while (i < len) : (i += 1) {
        buf[i] = alphabet[r.int(usize)%alphabet.len];
    }
    return buf;
}

pub fn parse_split(comptime T: type, delim: []const u8) type {
    return struct {
        const Self = @This();

        id: T,
        string: []const u8,

        pub fn do(input: []const u8) !Self {
            const iter = &std.mem.split(input, delim);
            return Self{
                .id = std.meta.stringToEnum(T, iter.next() orelse return error.IterEmpty) orelse return error.NoMemberFound,
                .string = iter.rest(),
            };
        }
    };
}

pub const HashFn = enum {
    blake3,
    sha256,
    sha512,
};

pub fn validate_hash(input: []const u8, file_path: []const u8) !bool {
    const hash = parse_split(HashFn, "-").do(input) catch return false;
    const file = try std.fs.cwd().openFile(file_path, .{});
    defer file.close();
    const data = try file.reader().readAllAlloc(gpa, gb);
    return std.mem.eql(u8, hash.string, switch (hash.id) {
        .blake3 => blk: {
            const h = &std.crypto.hash.Blake3.init(.{});
            var out: [32]u8 = undefined;
            h.update(data);
            h.final(&out);
            break :blk try std.fmt.allocPrint(gpa, "{x}", .{out});
        },
        .sha256 => blk: {
            const h = &std.crypto.hash.sha2.Sha256.init(.{});
            var out: [32]u8 = undefined;
            h.update(data);
            h.final(&out);
            break :blk try std.fmt.allocPrint(gpa, "{x}", .{out});
        },
        .sha512 => blk: {
            const h = &std.crypto.hash.sha2.Sha512.init(.{});
            var out: [64]u8 = undefined;
            h.update(data);
            h.final(&out);
            break :blk try std.fmt.allocPrint(gpa, "{x}", .{out});
        },
    });
}
