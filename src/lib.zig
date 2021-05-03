pub const commands_to_bootstrap = struct {
    pub const fetch = @import("./cmd/fetch.zig");
};

pub const commands = struct {
    pub const init = @import("./cmd/init.zig");
    pub const fetch = @import("./cmd/fetch.zig");
    pub const sum = @import("./cmd/sum.zig");
    pub const zpm = @import("./cmd/zpm.zig");
    pub const license = @import("./cmd/license.zig");
    pub const aq = @import("./cmd/aq.zig");
};
