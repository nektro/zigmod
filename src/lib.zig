const std = @import("std");
const zfetch = @import("zfetch");
const extras = @import("extras");
const root = @import("root");
const build_options = root.build_options;

pub const commands = struct {
    pub const version = @import("./cmd/version.zig");
    pub const fetch = @import("./cmd/fetch.zig");
    pub const ci = @import("./cmd/ci.zig");
    pub const init = @import("./cmd/init.zig");
    pub const sum = @import("./cmd/sum.zig");
    pub const zpm = @import("./cmd/zpm.zig");
    pub const license = @import("./cmd/license.zig");
    pub const aq = @import("./cmd/aq.zig");
    pub const generate = @import("./cmd/generate.zig");
};

pub fn init() !void {
    try zfetch.init();
}

pub fn deinit() void {
    zfetch.deinit();
}

pub const Dep = @import("./util/dep.zig").Dep;
pub const ModFile = @import("./util/modfile.zig").ModFile;
pub const Module = @import("./util/module.zig").Module;

pub const version: u16 = blk: {
    var version_s = build_options.version;
    version_s = extras.trimPrefixEnsure(version_s, "r").?;
    version_s = version_s[0 .. std.mem.indexOfScalar(u8, version_s, '-') orelse version_s.len];
    var version_i = std.fmt.parseInt(u16, version_s, 10) catch unreachable;
    if (std.mem.indexOfScalar(u8, version_s, '-')) |_| version_i += 1;
    break :blk version_i;
};

pub fn meetsMinimumVersion(min_zigmod_version_raw: []const u8) ?bool {
    var min_zigmod_version_s = min_zigmod_version_raw;
    min_zigmod_version_s = extras.trimPrefixEnsure(min_zigmod_version_s, "r") orelse return null;
    min_zigmod_version_s = min_zigmod_version_s[0 .. std.mem.indexOfScalar(u8, min_zigmod_version_s, '-') orelse min_zigmod_version_s.len];
    const min_zigmod_version = std.fmt.parseInt(u16, min_zigmod_version_s, 10) catch return null;
    return min_zigmod_version <= version;
}
