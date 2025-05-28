const std = @import("std");
const string = []const u8;
const gpa = std.heap.c_allocator;
const extras = @import("extras");
const git = @import("git");
const ansi = @import("ansi");

//
//

pub const b = 1;
pub const kb = b * 1024;
pub const mb = kb * 1024;
pub const gb = mb * 1024;

pub fn assert(ok: bool, comptime fmt: string, args: anytype) void {
    if (!ok) {
        std.debug.print(ansi.color.Fg(.Red, fmt) ++ "\n", args);
        std.process.exit(1);
    }
}

pub fn fail(comptime fmt: string, args: anytype) noreturn {
    assert(false, fmt, args);
    unreachable;
}

pub fn try_index(comptime T: type, array: []const T, n: usize, def: T) T {
    if (array.len <= n) {
        return def;
    }
    return array[n];
}

pub fn split(alloc: std.mem.Allocator, in: string, delim: u8) ![]string {
    var list = std.ArrayList(string).init(alloc);
    errdefer list.deinit();

    var iter = std.mem.splitScalar(u8, in, delim);
    while (iter.next()) |str| {
        try list.append(str);
    }
    return list.toOwnedSlice();
}

pub fn file_list(alloc: std.mem.Allocator, dpath: string) ![]const string {
    var dir = try std.fs.cwd().openDir(dpath, .{ .iterate = true });
    defer dir.close();
    return try extras.fileList(alloc, dir);
}

pub fn run_cmd_raw(alloc: std.mem.Allocator, dir: ?string, args: []const string) !std.process.Child.RunResult {
    return std.process.Child.run(.{ .allocator = alloc, .cwd = dir, .argv = args, .max_output_bytes = std.math.maxInt(usize) }) catch |e| switch (e) {
        error.FileNotFound => {
            fail("\"{s}\" command not found", .{args[0]});
        },
        else => |ee| return ee,
    };
}

pub fn run_cmd(alloc: std.mem.Allocator, dir: ?string, args: []const string) !u32 {
    const result = try run_cmd_raw(alloc, dir, args);
    alloc.free(result.stdout);
    alloc.free(result.stderr);
    return result.term.Exited;
}

pub fn list_remove(alloc: std.mem.Allocator, input: []string, search: string) ![]string {
    var list = std.ArrayList(string).init(alloc);
    errdefer list.deinit();
    for (input) |item| {
        if (!std.mem.eql(u8, item, search)) {
            try list.append(item);
        }
    }
    return list.toOwnedSlice();
}

pub fn last(in: []string) ?string {
    if (in.len == 0) return null;
    return in[in.len - 1];
}

const alphabet = "0123456789abcdefghijklmnopqrstuvwxyz";

pub fn random_string(comptime len: usize) [len]u8 {
    const now: u64 = @intCast(std.time.nanoTimestamp());
    var rand = std.Random.DefaultPrng.init(now);
    var r = rand.random();
    var buf: [len]u8 = undefined;
    var i: usize = 0;
    while (i < len) : (i += 1) {
        buf[i] = alphabet[r.int(usize) % alphabet.len];
    }
    return buf;
}

pub fn parse_split(comptime T: type, comptime delim: u8) type {
    return struct {
        const Self = @This();

        id: T,
        string: string,

        pub fn do(input: string) !Self {
            var iter = std.mem.splitScalar(u8, input, delim);
            const start = iter.next() orelse return error.IterEmpty;
            const id = std.meta.stringToEnum(T, start) orelse return error.NoMemberFound;
            return Self{
                .id = id,
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

pub fn validate_hash(alloc: std.mem.Allocator, input: string, file_path: string) !bool {
    const hash = parse_split(HashFn, '-').do(input) catch return false;
    const file = try std.fs.cwd().openFile(file_path, .{});
    defer file.close();
    const data = try file.reader().readAllAlloc(alloc, gb);
    const expected = hash.string;
    const actual = switch (hash.id) {
        .blake3 => &try do_hash(std.crypto.hash.Blake3, data),
        .sha256 => &try do_hash(std.crypto.hash.sha2.Sha256, data),
        .sha512 => &try do_hash(std.crypto.hash.sha2.Sha512, data),
    };
    const result = std.mem.startsWith(u8, actual, expected);
    if (!result) {
        std.log.info("expected: {s}, actual: {s}", .{ expected, actual });
    }
    return result;
}

pub fn do_hash(comptime algo: type, data: string) ![algo.digest_length * 2]u8 {
    return extras.to_hex(extras.hashBytes(algo, data));
}

/// Returns the result of running `git rev-parse HEAD`
pub fn git_rev_HEAD(alloc: std.mem.Allocator, dir: std.fs.Dir) !string {
    var dirg = try dir.openDir(".git", .{});
    defer dirg.close();
    const commitid = try git.getHEAD(alloc, dirg);
    return if (commitid) |_| commitid.?.id else error.NotAGitRepo;
}

pub fn slice(comptime T: type, input: []const T, from: usize, to: usize) []const T {
    const f = @max(from, 0);
    const t = @min(to, input.len);
    return input[f..t];
}

pub fn detect_pkgname(alloc: std.mem.Allocator, override: string, dir: string) !string {
    if (override.len > 0) {
        return override;
    }
    const dirO = if (dir.len == 0) std.fs.cwd() else try std.fs.cwd().openDir(dir, .{});
    if (!(try extras.doesFileExist(dirO, "build.zig"))) {
        return error.NoBuildZig;
    }
    const dpath = try std.fs.realpathAlloc(alloc, try std.fs.path.join(alloc, &.{ dir, "build.zig" }));
    const splitP = try split(alloc, dpath, std.fs.path.sep);
    var name = splitP[splitP.len - 2];
    name = extras.trimPrefix(name, "zig-");
    assert(name.len > 0, "package name must not be an empty string", .{});
    return name;
}

pub fn detct_mainfile(alloc: std.mem.Allocator, override: string, dir: ?std.fs.Dir, name: string) !string {
    if (override.len > 0) {
        if (try extras.doesFileExist(dir, override)) {
            if (std.mem.endsWith(u8, override, ".zig")) {
                return override;
            }
        }
    }
    const namedotzig = try std.mem.concat(alloc, u8, &.{ name, ".zig" });
    if (try extras.doesFileExist(dir, namedotzig)) {
        return namedotzig;
    }
    if (try extras.doesFileExist(dir, try std.fs.path.join(alloc, &.{ "src", "lib.zig" }))) {
        return "src/lib.zig";
    }
    if (try extras.doesFileExist(dir, try std.fs.path.join(alloc, &.{ "src", "main.zig" }))) {
        return "src/main.zig";
    }
    return error.CantFindMain;
}

pub fn indexOfN(haystack: string, needle: u8, n: usize) ?usize {
    var i: usize = 0;
    var c: usize = 0;
    while (c < n) {
        i = indexOfAfter(haystack, needle, i) orelse return null;
        c += 1;
    }
    return i;
}

pub fn indexOfAfter(haystack: string, needle: u8, after: usize) ?usize {
    for (haystack, 0..) |c, i| {
        if (i <= after) continue;
        if (c == needle) return i;
    }
    return null;
}

pub fn find_cachepath() !string {
    const haystack = try std.fs.cwd().realpathAlloc(gpa, ".");
    const needle = "/.zigmod/deps";

    if (std.mem.indexOf(u8, haystack, needle)) |index| {
        return haystack[0 .. index + needle.len];
    }
    return try std.fs.path.join(gpa, &.{ haystack, ".zigmod", "deps" });
}
