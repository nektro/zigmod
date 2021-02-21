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
                _ = try u.run_cmd(null, &.{"git", "clone", "--recurse-submodules", rpath, dpath});
            },
            .hg => {
                _ = try u.run_cmd(null, &.{"hg", "clone", rpath, dpath});
            },
            .http => {
                try u.mkdir_all(dpath);
                _ = try u.run_cmd(dpath, &.{"wget", rpath});
                const f = rpath[std.mem.lastIndexOf(u8, rpath, "/").?+1..];
                if (std.mem.endsWith(u8, f, ".zip")) {
                    _ = try u.run_cmd(dpath, &.{"unzip", f, "-d", "."});
                }
                if (
                    std.mem.endsWith(u8, f, ".tar")
                    or std.mem.endsWith(u8, f, ".tar.gz")
                    or std.mem.endsWith(u8, f, ".tar.xz")
                    or std.mem.endsWith(u8, f, ".tar.zst")
                ) {
                    _ = try u.run_cmd(dpath, &.{"tar", "-xf", f, "-C", "."});
                }
            },
        }
    }

    pub fn update(self: DepType, dpath: []const u8, rpath: []const u8) !void {
        switch (self) {
            .system_lib => {},
            .git => {
                _ = try u.run_cmd(dpath, &.{"git", "fetch"});
                _ = try u.run_cmd(dpath, &.{"git", "pull"});
            },
            .hg => {
                _ = try u.run_cmd(dpath, &.{"hg", "pull"});
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
