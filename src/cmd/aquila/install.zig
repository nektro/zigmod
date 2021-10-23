const std = @import("std");
const string = []const u8;
const gpa = std.heap.c_allocator;

const knownfolders = @import("known-folders");

const u = @import("./../../util/index.zig");
const common = @import("./../../common.zig");

pub fn execute(args: [][]u8) !void {
    const home = try knownfolders.getPath(gpa, .home);
    const homepath = home.?;
    const homedir = try std.fs.cwd().openDir(homepath, .{});

    if (!(try u.does_file_exist("zig.mod", homedir))) {
        const f = try homedir.createFile("zig.mod", .{});
        defer f.close();
        const w = f.writer();
        const init = @import("../init.zig");
        try init.writeExeManifest(w, try u.random_string(48), "zigmod_installation", null, null);
    }

    // add to ~/zig.mod for later
    const aqadd = @import("./add.zig");
    const pkgurl = aqadd.do(homedir, args[0]) catch |err| switch (err) {
        error.AquilaBadResponse => return,
        else => return err,
    };

    // get modfile and dep
    const m = try u.ModFile.from_dir(gpa, homedir);
    var dep: u.Dep = undefined;
    for (m.devdeps) |d| {
        if (std.mem.eql(u8, d.path, pkgurl)) {
            dep = d;
            break;
        }
    }

    //
    const cache = try knownfolders.getPath(gpa, .cache);
    const cachepath = try std.fs.path.join(gpa, &.{ cache.?, "zigmod", "deps" });

    // fetch singular pkg
    var fetchoptions = common.CollectOptions{
        .log = true,
        .update = false,
    };
    try fetchoptions.init();
    const modpath = try common.get_modpath(cachepath, dep, &fetchoptions);
    const moddir = try std.fs.cwd().openDir(modpath, .{});

    // zigmod ci
    const ci = @import("../ci.zig");
    try ci.do(modpath, moddir);

    // zig build
    const argv: []const string = &.{
        "zig",         "build",
        "--prefix",    try std.fs.path.join(gpa, &.{ homepath, ".zigmod" }),
        "--cache-dir", try std.fs.path.join(gpa, &.{ cache.?, "zigmod", "zig" }),
    };
    const proc = try std.ChildProcess.init(argv, gpa);
    proc.cwd = modpath;
    const term = try proc.spawnAndWait();
    switch (term) {
        .Exited => |v| u.assert(v == 0, "zig build failed with exit code: {d}", .{v}),
        .Signal => |v| std.log.info("zig build was stopped with signal: {d}", .{v}),
        .Stopped => |v| std.log.info("zig build was stopped with code: {d}", .{v}),
        .Unknown => |v| std.log.info("zig build encountered unknown: {d}", .{v}),
    }
}
