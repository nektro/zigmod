const std = @import("std");
const gpa = std.heap.c_allocator;

const u = @import("index.zig");

//
//

pub const ascii = enum(u8) {
    NUL,
    SOH,
    STX,
    ETX,
    EOT,
    ENQ,
    ACK,
    BEL,
    BS,
    TAB,
    LF,
    VT,
    FF,
    CR,
    SO,
    SI,
    DLE,
    DC1,
    DC2,
    DC3,
    DC4,
    NAK,
    SYN,
    ETB,
    CAN,
    EM,
    SUB,
    ESC,
    FS,
    GS,
    RS,
    US,

    pub fn s(self: ascii) []const u8 {
        return &[_]u8{@enumToInt(self)};
    }
};
