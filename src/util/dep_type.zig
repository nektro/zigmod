const std = @import("std");
const gpa = std.heap.c_allocator;

const u = @import("./index.zig");

//
//

// zig fmt: off
pub const DepType = enum {
    system_lib, // std.build.LibExeObjStep.linkSystemLibrary
    git,        // https://git-scm.com/
    hg,         // https://www.mercurial-scm.org/
    http,       // https://en.wikipedia.org/wiki/Hypertext_Transfer_Protocol
    // svn,        // https://subversion.apache.org/
    // fossil,     // https://fossil-scm.org/
    // cvs,        // https://nongnu.org/cvs/
    // darcs,      // http://darcs.net/
    // //
    // bazaar,     // https://bazaar.canonical.com/en/
    // pijul,      // https://pijul.org/
    // //
    // ftp,        // https://en.wikipedia.org/wiki/File_Transfer_Protocol
    // ssh,        // https://www.ssh.com/ssh/
    // onion,      // https://www.torproject.org/
    // i2p,        // https://geti2p.net/en/
    // torrent,    // https://en.wikipedia.org/wiki/BitTorrent
    // magnet,     // https://en.wikipedia.org/wiki/BitTorrent
    // dat,        // https://www.datprotocol.com/
    // ipfs,       // https://www.ipfs.com/
    // hypercore,  // https://hypercore-protocol.org/

    pub fn pull(self: DepType, rpath: []const u8, dpath: []const u8) !void {
        switch (self) {
            .system_lib => {},
            .git => {
                u.assert((try u.run_cmd(null, &.{ "git", "clone", "--recurse-submodules", rpath, dpath })) == 0, "git clone {s} failed", .{rpath});
            },
            .hg => {
                u.assert((try u.run_cmd(null, &.{ "hg", "clone", rpath, dpath })) == 0, "hg clone {s} failed", .{rpath});
            },
            .http => {
                try std.fs.cwd().makePath(dpath);
                u.assert((try u.run_cmd(dpath, &.{ "wget", rpath })) == 0, "wget {s} failed", .{rpath});
                const f = rpath[std.mem.lastIndexOf(u8, rpath, "/").? + 1 ..];
                if (std.mem.endsWith(u8, f, ".zip")) {
                    u.assert((try u.run_cmd(dpath, &.{ "unzip", f, "-d", "." })) == 0, "unzip {s} failed", .{f});
                }
                if (std.mem.endsWith(u8, f, ".tar") or std.mem.endsWith(u8, f, ".tar.gz") or std.mem.endsWith(u8, f, ".tar.xz") or std.mem.endsWith(u8, f, ".tar.zst")) {
                    u.assert((try u.run_cmd(dpath, &.{ "tar", "-xf", f, "-C", "." })) == 0, "un-tar {s} failed", .{f});
                }
            },
        }
    }

    pub fn update(self: DepType, dpath: []const u8, rpath: []const u8) !void {
        switch (self) {
            .system_lib => {},
            .git => {
                u.assert((try u.run_cmd(dpath, &.{ "git", "fetch" })) == 0, "git fetch failed", .{});
                u.assert((try u.run_cmd(dpath, &.{ "git", "pull" })) == 0, "git pull failed", .{});
            },
            .hg => {
                u.assert((try u.run_cmd(dpath, &.{ "hg", "pull" })) == 0, "hg pull failed", .{});
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
