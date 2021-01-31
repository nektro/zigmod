const std = @import("std");
const builtin = @import("builtin");

const u = @import("./util/index.zig");

//
//

pub const commands = struct {
    const init = @import("./cmd_init.zig");
    // const add = @import("./cmd_add.zig");
    const fetch = @import("./cmd_fetch.zig");
    const sum = @import("./cmd_sum.zig");
};

pub fn main() !void {

    const gpa = std.heap.c_allocator;

    const proc_args = try std.process.argsAlloc(gpa);
    const args = proc_args[1..];

    if (args.len == 0) {
        u.print("zigmod {s} {s} {s} {s}", .{
            @import("build_options").version,
            @tagName(builtin.os.tag),
            @tagName(builtin.arch),
            @tagName(builtin.abi)
        });
        return;
    }

    inline for (std.meta.declarations(commands)) |decl| {
        if (std.mem.eql(u8, args[0], decl.name)) {
            const cmd = @field(commands, decl.name);
            try cmd.execute(args[1..]);
            return;
        }
    }

    var sub_cmd_args = &std.ArrayList([]const u8).init(gpa);
    try sub_cmd_args.append(try std.fmt.allocPrint(gpa, "zigmod-{s}", .{args[0]}));
    for (args[1..]) |item| {
        try sub_cmd_args.append(item);
    }
    const result = std.ChildProcess.exec(.{ .allocator = gpa, .argv = sub_cmd_args.items, }) catch |e| switch(e) {
        else => return e,
        error.FileNotFound => {
            u.assert(false, "unknown command \"{s}\" for \"zigmod\"", .{args[0]});
            unreachable;
        },
    };
    try std.io.getStdOut().writeAll(result.stdout);
    try std.io.getStdErr().writeAll(result.stderr);
}
