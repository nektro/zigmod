const std = @import("std");

const u = @import("index.zig");

//
//

pub const Dep = struct {
    const Self = @This();

    type: u.DepType,
    path: []const u8,
};
