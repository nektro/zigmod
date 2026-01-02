const std = @import("std");
const string = []const u8;
const gpa = std.heap.c_allocator;
const zfetch = @import("zfetch");
const json = @import("json");

const u = @import("./../util/funcs.zig");

//
//

pub const commands = struct {
    pub const add = @import("./aquila/add.zig");
    pub const showjson = @import("./aquila/showjson.zig");
    pub const install = @import("./aquila/install.zig");
    pub const update = @import("./aquila/update.zig");
};

pub const server_root = "https://aquila.red";

pub fn execute(self_name: []const u8, args: [][:0]u8) !void {
    if (args.len == 0) {
        std.debug.print("{s}\n", .{
            \\This is a subcommand for use with https://github.com/nektro/aquila instances but has no default behavior on its own aside from showing you this nice help text.
            \\
            \\The default remote is https://aquila.red.
            \\
            \\The subcommands available are:
            \\  - add       Append this package to your dependencies
            \\  - showjson  Print debug api data to stdout
            \\  - install   Install a package
        });
        return;
    }

    inline for (comptime std.meta.declarations(commands)) |decl| {
        if (std.mem.eql(u8, args[0], decl.name)) {
            const cmd = @field(commands, decl.name);
            try cmd.execute(self_name, args[1..]);
            return;
        }
    }
    u.fail("unknown command \"{s}\" for \"zigmod aq\"", .{args[0]});
}

pub fn server_fetch(url: string) !json.Document {
    const req = try zfetch.Request.init(gpa, url, null);
    defer req.deinit();

    var headers = zfetch.Headers.init(gpa);
    defer headers.deinit();
    try headers.set("accept", "application/json");

    try req.do(.GET, headers, null);

    const doc = try json.parse(gpa, "", req.reader(), .{ .support_trailing_commas = true, .maximum_depth = 100 });
    doc.acquire();
    defer doc.release();

    if (doc.root.object().getS("message")) |msg| {
        std.log.err("server: {s}", .{msg});
        return error.AquilaBadResponse;
    }
    return doc;
}
