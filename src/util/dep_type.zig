const std = @import("std");
const gpa = std.heap.c_allocator;

const u = @import("./index.zig");

//
//

pub const DepType = enum {
    system_lib, // std.build.LibExeObjStep.linkSystemLibrary
    git,        // https://git-scm.com/
    hg,         // https://www.mercurial-scm.org/
    http,       // https://en.wikipedia.org/wiki/Hypertext_Transfer_Protocol

    pub fn pull(self: DepType, rpath: []const u8, dpath: []const u8) !void {
        switch (self) {
            .system_lib => {},
            .git => {
                _ = try u.run_cmd(null, &[_][]const u8{"git", "clone", rpath, dpath});
                _ = try u.run_cmd(null, &[_][]const u8{"git", "submodule", "update", "--init", "--recursive"});
            },
            .hg => {
                _ = try u.run_cmd(null, &[_][]const u8{"hg", "clone", rpath, dpath});
            },
            .http => {
                try u.mkdir_all(dpath);
                _ = try u.run_cmd(dpath, &[_][]const u8{"wget", rpath});
                const f = rpath[std.mem.lastIndexOf(u8, rpath, "/").?+1..];
                if (std.mem.endsWith(u8, f, ".zip")) {
                    _ = try u.run_cmd(dpath, &[_][]const u8{"unzip", f, "-d", "."});
                    try std.fs.deleteFileAbsolute(try std.fs.path.join(gpa, &[_][]const u8{dpath, f}));
                }
                if (
                    std.mem.endsWith(u8, f, ".tar")
                    or std.mem.endsWith(u8, f, ".tar.gz")
                    or std.mem.endsWith(u8, f, ".tar.xz")
                    or std.mem.endsWith(u8, f, ".tar.zst")
                ) {
                    _ = try u.run_cmd(dpath, &[_][]const u8{"tar", "-xf", f, "-C", "."});
                    try std.fs.deleteFileAbsolute(try std.fs.path.join(gpa, &[_][]const u8{dpath, f}));
                }
            },
        }
    }

    pub fn update(self: DepType, dpath: []const u8, rpath: []const u8) !void {
        switch (self) {
            .system_lib => {},
            .git => {
                _ = try u.run_cmd(dpath, &[_][]const u8{"git", "fetch"});
                _ = try u.run_cmd(dpath, &[_][]const u8{"git", "pull"});
            },
            .hg => {
                _ = try u.run_cmd(dpath, &[_][]const u8{"hg", "pull"});
            },
            .http => {
                //
            },
        }
    }
};

pub const GitVersionType = enum {
    branch,
    tag,
    commit,
};
