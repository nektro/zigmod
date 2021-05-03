const std = @import("std");
const gpa = std.heap.c_allocator;

const u = @import("./../util/index.zig");

//
//

pub const commands = struct {
    pub const add = @import("./aquila/add.zig");
};

pub const server_root = "https://aquila.red";

pub fn execute(args: [][]u8) !void {
    if (args.len == 0) {
        std.debug.warn("{s}\n", .{
            \\This is a subcommand for use with https://github.com/nektro/aquila instances but has no default behavior on its own aside from showing you this nice help text.
            \\
            \\The default remote is https://aquila.red.
            \\
            \\The subcommands available are:
            \\  - add       Append this package to your dependencies
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
    std.debug.panic("error: unknown command \"{s}\" for \"zigmod aq\"", .{args[0]});
}
