const std = @import("std");

//
//

pub const sources = struct {
    pub const zpm = @import("./add/zpm.zig");
    pub const aq  = @import("./add/aquila.zig");
    pub const git = @import("./add/git.zig");
};

pub fn execute(args: [][]u8) !void {
    if (args.len == 0) {
        std.debug.warn("{s}\n", .{
            \\This is a subcommand to add a package from a given source, it requires the source type as a flag and the path as argument.
            \\
            \\The available sources are:
            \\  --zpm       Add a package from a zpm server instance using its name (defaults to https://zpm.random-projects.net/)
            \\  --aq        Add a package from an aquila instance using its path (defaults to https://aquila.red)
            \\  --git       Add a package from a git repository using its URL
            \\
            \\Examples:
            \\  zigmod add --aq 1/truemedian/zfetch
            \\  zigmod add --zpm apple_pie
            \\  zigmod add --git https://github.com/zenith391/zgt
        });
        return;
    }

    inline for (std.meta.declarations(sources)) |decl| {
        if (std.mem.eql(u8, args[0], "--" ++ decl.name)) {
            const cmd = @field(sources, decl.name);
            try cmd.execute(args[1..]);
            return;
        }
    }
}
