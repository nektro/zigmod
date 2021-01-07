const std = @import("std");
const builtin = @import("builtin");

const u = @import("./util/index.zig");

//
//

const commands = struct {
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
        u.print("zigmod {} {} {} {}", .{
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
    std.debug.panic("Error: unknown command \"{}\" for \"zigmod\"", .{args[0]});
}
