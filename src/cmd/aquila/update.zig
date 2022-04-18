const std = @import("std");
const string = []const u8;
const gpa = std.heap.c_allocator;
const knownfolders = @import("known-folders");

const zigmod = @import("../../lib.zig");
const u = @import("./../../util/index.zig");
const common = @import("./../../common.zig");

pub fn execute(args: [][]u8) !void {
    const home = try knownfolders.getPath(gpa, .home);
    const homepath = home.?;
    const homedir = try std.fs.cwd().openDir(homepath, .{});

    if (!(try u.does_file_exist(homedir, "zigmod.yml"))) {
        const f = try homedir.createFile("zigmod.yml", .{});
        defer f.close();
        const w = f.writer();
        const init = @import("../init.zig");
        try init.writeExeManifest(w, try u.random_string(gpa, 48), "zigmod_installation", null, null);
    }
    u.assert(args.len == 0, "zigmod aq update accepts no parameters", .{});

    // get modfile and dep
    const m = try zigmod.ModFile.from_dir(gpa, homedir);
    for (m.rootdeps) |dep| {
        //
        const cache = try knownfolders.getPath(gpa, .cache);
        const cachepath = try std.fs.path.join(gpa, &.{ cache.?, "zigmod", "deps" });

        // fetch singular pkg
        var fetchoptions = common.CollectOptions{
            .log = true,
            .update = false,
            .alloc = gpa,
        };
        try fetchoptions.init();
        const modpath = try common.get_modpath(cachepath, dep, &fetchoptions);
        const moddir = try std.fs.cwd().openDir(modpath, .{});
        std.log.info("{s}", .{dep.path});

        // git update
        u.assert((try u.run_cmd(gpa, modpath, &.{ "git", "fetch" })) == 0, "git fetch failed", .{});
        u.assert((try u.run_cmd(gpa, modpath, &.{ "git", "pull" })) == 0, "git pull failed", .{});

        // zigmod ci
        const ci = @import("../ci.zig");
        try ci.do(gpa, modpath, moddir);

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
            .Signal => |v| std.log.info("zig build was interrupted with signal: {d}", .{v}),
            .Stopped => |v| std.log.info("zig build was stopped with code: {d}", .{v}),
            .Unknown => |v| std.log.info("zig build encountered unknown: {d}", .{v}),
        }
    }
}
