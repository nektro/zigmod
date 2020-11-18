const std = @import("std");

const u = @import("index.zig");

//
//

pub const DepType = enum {
    git,        // https://git-scm.com/
    hg,         // https://www.mercurial-scm.org/
};
