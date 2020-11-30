const u = @import("./index.zig");

//
//

pub const DepType = enum {
    system_lib, // std.build.LibExeObjStep.linkSystemLibrary
    git,        // https://git-scm.com/
    hg,         // https://www.mercurial-scm.org/

    pub fn pull(self: DepType, rpath: []const u8, dpath: []const u8) !void {
        switch (self) {
            .system_lib => {},
            .git => {
                _ = try u.run_cmd(null, &[_][]const u8{"git", "clone", rpath, dpath});
            },
            .hg => { _ = try u.run_cmd(null, &[_][]const u8{"hg", "clone", rpath, dpath}); },
        }
    }

    pub fn update(self: DepType, dpath: []const u8, rpath: []const u8) !void {
        switch (self) {
            .system_lib => {},
            .git => {
                _ = try u.run_cmd(dpath, &[_][]const u8{"git", "fetch"});
                _ = try u.run_cmd(dpath, &[_][]const u8{"git", "pull"});
            },
            .hg => { _ = try u.run_cmd(dpath, &[_][]const u8{"hg", "pull"}); },
        }
    }
};

pub const GitVersionType = enum {
    branch,
    tag,
    commit,
};
