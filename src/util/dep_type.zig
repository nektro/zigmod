const std = @import("std");
const string = []const u8;

const u = @import("./index.zig");

//
//

// zig fmt: off
pub const DepType = enum {
    local,      // A 'package' derived from files in the same repository.
    system_lib, // std.build.LibExeObjStep.linkSystemLibrary
    framework,  // std.build.LibExeObjStep.linkFramework
    git,        // https://git-scm.com/
    hg,         // https://www.mercurial-scm.org/
    http,       // https://en.wikipedia.org/wiki/Hypertext_Transfer_Protocol

    // zig fmt: on
    pub fn pull(self: DepType, alloc: std.mem.Allocator, rpath: string, dpath: string) !void {
        switch (self) {
            .local => {},
            .system_lib => {},
            .framework => {},
            .git => {
                u.assert((try u.run_cmd(alloc, null, &.{ "git", "clone", "--recurse-submodules", rpath, dpath })) == 0, "git clone {s} failed", .{rpath});
            },
            .hg => {
                u.assert((try u.run_cmd(alloc, null, &.{ "hg", "clone", rpath, dpath })) == 0, "hg clone {s} failed", .{rpath});
            },
            .http => {
                try std.fs.cwd().makePath(dpath);
                u.assert((try u.run_cmd(alloc, dpath, &.{ "wget", rpath })) == 0, "wget {s} failed", .{rpath});
                const f = rpath[std.mem.lastIndexOf(u8, rpath, "/").? + 1 ..];
                if (std.mem.endsWith(u8, f, ".zip")) {
                    u.assert((try u.run_cmd(alloc, dpath, &.{ "unzip", f, "-d", "." })) == 0, "unzip {s} failed", .{f});
                }
                if (std.mem.endsWith(u8, f, ".tar") or std.mem.endsWith(u8, f, ".tar.gz") or std.mem.endsWith(u8, f, ".tar.xz") or std.mem.endsWith(u8, f, ".tar.zst")) {
                    u.assert((try u.run_cmd(alloc, dpath, &.{ "tar", "-xf", f, "-C", "." })) == 0, "un-tar {s} failed", .{f});
                }
            },
        }
    }

    pub fn update(self: DepType, alloc: std.mem.Allocator, dpath: string, rpath: string) !void {
        _ = rpath;

        switch (self) {
            .local => {},
            .system_lib => {},
            .framework => {},
            .git => {
                u.assert((try u.run_cmd(alloc, dpath, &.{ "git", "fetch" })) == 0, "git fetch failed", .{});
                u.assert((try u.run_cmd(alloc, dpath, &.{ "git", "pull" })) == 0, "git pull failed", .{});
            },
            .hg => {
                u.assert((try u.run_cmd(alloc, dpath, &.{ "hg", "pull" })) == 0, "hg pull failed", .{});
            },
            .http => {
                //
            },
        }
    }

    pub fn exact_version(self: DepType, alloc: std.mem.Allocator, mpath: string) !string {
        var mdir = try std.fs.cwd().openDir(mpath, .{});
        defer mdir.close();
        return switch (self) {
            .local => "",
            .system_lib => "",
            .framework => "",
            .git => try std.fmt.allocPrint(alloc, "commit-{s}", .{(try u.git_rev_HEAD(alloc, mdir))}),
            .hg => "",
            .http => "",
        };
    }

    pub fn isLocal(self: DepType) bool {
        return switch (self) {
            .local => true,
            .system_lib => true,
            .framework => true,
            .git => false,
            .hg => false,
            .http => false,
        };
    }

    pub const Version = union(DepType) {
        local: void,
        system_lib: void,
        framework: void,
        git: Git,
        hg: void,
        http: void,

        pub const Git = enum {
            branch,
            tag,
            commit,

            pub fn frozen(self: Git) bool {
                return switch (self) {
                    .branch => false,
                    .tag => true,
                    .commit => true,
                };
            }
        };
    };
};
