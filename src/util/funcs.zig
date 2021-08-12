const std = @import("std");
const gpa = std.heap.c_allocator;

const u = @import("index.zig");

//
//

pub const b = 1;
pub const kb = b * 1024;
pub const mb = kb * 1024;
pub const gb = mb * 1024;

pub fn print(comptime fmt: []const u8, args: anytype) void {
    std.debug.print(fmt ++ "\n", args);
}

const ansi_red = "\x1B[31m";
const ansi_reset = "\x1B[39m";

pub fn assert(ok: bool, comptime fmt: []const u8, args: anytype) void {
    if (!ok) {
        print(ansi_red ++ fmt ++ ansi_reset, args);
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
    defer list.deinit();
    const iter = &std.mem.split(u8, in, delim);
    while (iter.next()) |str| {
        try list.append(str);
    }
    return list.toOwnedSlice();
}

pub fn trim_prefix(in: []const u8, prefix: []const u8) []const u8 {
    if (std.mem.startsWith(u8, in, prefix)) {
        return in[prefix.len..];
    }
    return in;
}

pub fn does_file_exist(fpath: []const u8, dir: ?std.fs.Dir) !bool {
    const file = (dir orelse std.fs.cwd()).openFile(fpath, .{}) catch |e| switch (e) {
        error.FileNotFound => return false,
        error.IsDir => return true,
        else => return e,
    };
    defer file.close();
    return true;
}

pub fn does_folder_exist(fpath: []const u8) !bool {
    const file = std.fs.cwd().openFile(fpath, .{}) catch |e| switch (e) {
        error.FileNotFound => return false,
        error.IsDir => return true,
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
    for (xs) |x, i| {
        buf = buf ++ x;
        if (i < xs.len - 1) buf = buf ++ delim;
    }
    return buf;
}

pub fn trim_suffix(in: []const u8, suffix: []const u8) []const u8 {
    if (std.mem.endsWith(u8, in, suffix)) {
        return in[0 .. in.len - suffix.len];
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
        res = try std.fmt.allocPrint(gpa, "{s}{s}{s}", .{ res, x, if (i < xs.len - 1) delim else "" });
    }
    return res;
}

pub fn concat(items: [][]const u8) ![]const u8 {
    return std.mem.join(gpa, "", items);
}

pub fn print_all(w: std.fs.File.Writer, items: anytype, ln: bool) !void {
    inline for (items) |x, i| {
        if (i == 0) {
            try w.print("{s}", .{x});
        } else {
            try w.print(" {s}", .{x});
        }
    }
    if (ln) {
        try w.print("\n", .{});
    }
}

pub fn list_contains(haystack: []const []const u8, needle: []const u8) bool {
    for (haystack) |item| {
        if (std.mem.eql(u8, item, needle)) {
            return true;
        }
    }
    return false;
}

pub fn list_contains_gen(comptime T: type, haystack: []const T, needle: T) bool {
    for (haystack) |item| {
        if (item.eql(needle)) {
            return true;
        }
    }
    return false;
}

pub fn file_list(dpath: []const u8, list: *std.ArrayList([]const u8)) !void {
    const dir = try std.fs.cwd().openDir(dpath, .{ .iterate = true });
    var walk = try dir.walk(gpa);
    defer walk.deinit();
    while (true) {
        if (try walk.next()) |entry| {
            if (entry.kind != .File) {
                continue;
            }
            try list.append(try gpa.dupe(u8, entry.path));
        } else {
            break;
        }
    }
}

pub fn run_cmd_raw(dir: ?[]const u8, args: []const []const u8) !std.ChildProcess.ExecResult {
    return std.ChildProcess.exec(.{ .allocator = gpa, .cwd = dir, .argv = args, .max_output_bytes = std.math.maxInt(usize) }) catch |e| switch (e) {
        error.FileNotFound => {
            u.assert(false, "\"{s}\" command not found", .{args[0]});
            unreachable;
        },
        else => return e,
    };
}

pub fn run_cmd(dir: ?[]const u8, args: []const []const u8) !u32 {
    const result = try run_cmd_raw(dir, args);
    gpa.free(result.stdout);
    gpa.free(result.stderr);
    return result.term.Exited;
}

pub fn list_remove(input: [][]const u8, search: []const u8) ![][]const u8 {
    const list = &std.ArrayList([]const u8).init(gpa);
    defer list.deinit();
    for (input) |item| {
        if (!std.mem.eql(u8, item, search)) {
            try list.append(item);
        }
    }
    return list.toOwnedSlice();
}

pub fn last(in: [][]const u8) ![]const u8 {
    if (in.len == 0) {
        return error.EmptyArray;
    }
    return in[in.len - 1];
}

const alphabet = "0123456789abcdefghijklmnopqrstuvwxyz";

pub fn random_string(len: usize) ![]const u8 {
    const now = @intCast(u64, std.time.nanoTimestamp());
    var rand = std.rand.DefaultPrng.init(now);
    const r = &rand.random;
    var buf = try gpa.alloc(u8, len);
    var i: usize = 0;
    while (i < len) : (i += 1) {
        buf[i] = alphabet[r.int(usize) % alphabet.len];
    }
    return buf;
}

pub fn parse_split(comptime T: type, delim: []const u8) type {
    return struct {
        const Self = @This();

        id: T,
        string: []const u8,

        pub fn do(input: []const u8) !Self {
            const iter = &std.mem.split(u8, input, delim);
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
    const expected = hash.string;
    const actual = switch (hash.id) {
        .blake3 => try do_hash(std.crypto.hash.Blake3, data),
        .sha256 => try do_hash(std.crypto.hash.sha2.Sha256, data),
        .sha512 => try do_hash(std.crypto.hash.sha2.Sha512, data),
    };
    const result = std.mem.startsWith(u8, actual, expected);
    if (!result) {
        std.log.info("expected: {s}, actual: {s}", .{ expected, actual });
    }
    return result;
}

pub fn do_hash(comptime algo: type, data: []const u8) ![]const u8 {
    const h = &algo.init(.{});
    var out: [algo.digest_length]u8 = undefined;
    h.update(data);
    h.final(&out);
    const hex = try std.fmt.allocPrint(gpa, "{x}", .{std.fmt.fmtSliceHexLower(out[0..])});
    return hex;
}

/// Returns the result of running `git rev-parse HEAD`
pub fn git_rev_HEAD(alloc: *std.mem.Allocator, dir: std.fs.Dir) ![]const u8 {
    const max = std.math.maxInt(usize);
    const dirg = try dir.openDir(".git", .{});
    const h = std.mem.trim(u8, try dirg.readFileAlloc(alloc, "HEAD", max), "\n");
    const r = std.mem.trim(u8, try dirg.readFileAlloc(alloc, h[5..], max), "\n");
    return r;
}

pub fn slice(comptime T: type, input: []const T, from: usize, to: usize) []const T {
    const f = std.math.max(from, 0);
    const t = std.math.min(to, input.len);
    return input[f..t];
}

pub fn detect_pkgname(override: []const u8, dir: []const u8) ![]const u8 {
    if (override.len > 0) {
        return override;
    }
    const dirO = if (dir.len == 0) std.fs.cwd() else try std.fs.cwd().openDir(dir, .{});
    if (!(try does_file_exist("build.zig", dirO))) {
        return error.NoBuildZig;
    }
    const dpath = try std.fs.realpathAlloc(gpa, try std.mem.concat(gpa, u8, &.{ dir, "build.zig" }));
    const splitP = try split(dpath, std.fs.path.sep_str);
    var name = splitP[splitP.len - 2];
    name = trim_prefix(name, "zig-");
    assert(name.len > 0, "package name must not be an empty string", .{});
    return name;
}

pub fn detct_mainfile(override: []const u8, dir: ?std.fs.Dir, name: []const u8) ![]const u8 {
    if (override.len > 0) {
        if (try does_file_exist(override, dir)) {
            if (std.mem.endsWith(u8, override, ".zig")) {
                return override;
            }
        }
    }
    const namedotzig = try std.mem.concat(gpa, u8, &.{ name, ".zig" });
    if (try does_file_exist(namedotzig, dir)) {
        return namedotzig;
    }
    if (try does_file_exist(try std.fs.path.join(gpa, &.{ "src", "lib.zig" }), dir)) {
        return "src/lib.zig";
    }
    if (try does_file_exist(try std.fs.path.join(gpa, &.{ "src", "main.zig" }), dir)) {
        return "src/main.zig";
    }
    return error.CantFindMain;
}

pub fn indexOfN(haystack: []const u8, needle: u8, n: usize) ?usize {
    var i: usize = 0;
    var c: usize = 0;
    while (c < n) {
        i = indexOfAfter(haystack, needle, i) orelse return null;
        c += 1;
    }
    return i;
}

pub fn indexOfAfter(haystack: []const u8, needle: u8, after: usize) ?usize {
    for (haystack) |c, i| {
        if (i <= after) continue;
        if (c == needle) return i;
    }
    return null;
}
