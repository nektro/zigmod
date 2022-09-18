const zfetch = @import("zfetch");

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
