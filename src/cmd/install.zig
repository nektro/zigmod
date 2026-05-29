const std = @import("std");
const string = []const u8;
const gpa = std.heap.c_allocator;
const knownfolders = @import("known-folders");
const extras = @import("extras");

const zigmod = @import("./../lib.zig");
const u = @import("./../util/funcs.zig");
const common = @import("./../common.zig");

pub fn execute(self_name: []const u8, args: [][:0]u8) !void {
    _ = self_name;

    if (args.len < 2) u.fail("usage: zigmod install [git|hg|http] [url]", .{});

    const homepath = try knownfolders.getPath(gpa, .home) orelse u.fail("failed to read HOME", .{});
    const cache = try knownfolders.getPath(gpa, .cache);
    const datapath = try knownfolders.getPath(gpa, .data) orelse u.fail("failed to read XDG_DATA_HOME", .{});

    const RemoteType = enum {
        git,
        hg,
        http,
    };
    const rty_s = args[0];
    const rty = std.meta.stringToEnum(RemoteType, rty_s) orelse u.fail("usage: zigmod install [git|hg|http] [url]", .{});
    const ty: zigmod.Dep.Type = switch (rty) {
        .git => .git,
        .hg => .hg,
        .http => .http,
    };
    const dep: zigmod.Dep = .{
        .type = ty,
        .path = args[1],
        .id = u.random_string(48),
        .name = "(name)",
        .main = "",
        .version = "",
        .c_include_dirs = &.{},
        .c_source_flags = &.{},
        .c_source_files = &.{},
        .only_os = &.{},
        .except_os = &.{},
        .yaml = null,
        .deps = &.{},
        .keep = false,
        .for_build = false,
    };
    const clean_path = try dep.clean_path(gpa);
    const cachepath = try std.fs.path.join(gpa, &.{ cache.?, "zigmod", "deps" });
    const modpath = try std.fs.path.join(gpa, &.{ cachepath, clean_path });
    std.log.debug("modpath: {s}", .{modpath});

    if (!try extras.doesFolderExist(null, modpath)) {
        try dep.type.pull(gpa, dep.path, modpath);
    } else {
        try dep.type.update(gpa, modpath, "");
    }

    const moddir = try std.fs.cwd().openDir(modpath, .{});
    const ci = @import("./ci.zig");
    try ci.do(gpa, cachepath, moddir);

    const modfile = try zigmod.ModFile.from_dir(gpa, moddir, modpath);
    const zigversion_sv = modfile.min_zig_version orelse u.fail("zigmod manifest requires min_zig_version field", .{});
    const zigversion = try std.fmt.allocPrint(gpa, "{}", .{zigversion_sv});
    const zigpath = try std.fs.path.join(gpa, &.{ datapath, "zig", zigversion, "zig" });

    // zig build
    const argv: []const string = &.{
        zigpath,    "build",
        "--prefix", try std.fs.path.join(gpa, &.{ homepath, ".zigmod" }),
    };
    std.log.debug("argv: {s}", .{argv});
    var proc = std.process.Child.init(argv, gpa);
    proc.cwd = modpath;
    const term = try proc.spawnAndWait();
    switch (term) {
        .Exited => |v| u.assert(v == 0, "zig build failed with exit code: {d}", .{v}),
        .Signal => |v| u.fail("zig build was stopped with signal: {d}", .{v}),
        .Stopped => |v| u.fail("zig build was stopped with code: {d}", .{v}),
        .Unknown => |v| u.fail("zig build encountered unknown: {d}", .{v}),
    }
    std.log.info("success!", .{});
}
