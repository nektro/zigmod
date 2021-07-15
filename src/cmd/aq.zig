const std = @import("std");
const gpa = std.heap.c_allocator;

const zfetch = @import("zfetch");
const json = @import("json");

const u = @import("./../util/index.zig");

//
//

pub const commands = struct {
    pub const update = @import("./aquila/update.zig");
    pub const modfile = @import("./aquila/modfile.zig");
    pub const showjson = @import("./aquila/showjson.zig");
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
            \\  - update    Check your zig.mod dependencies for new versions
            \\  - modile    Print the zig.mod text for a new version
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
    u.assert(false, "unknown command \"{s}\" for \"zigmod aq\"", .{args[0]});
}

pub fn server_fetch(url: []const u8) !json.Value {
    const req = try zfetch.Request.init(gpa, url, null);
    defer req.deinit();

    var headers = zfetch.Headers.init(gpa);
    defer headers.deinit();
    try headers.set("accept", "application/json");

    try req.do(.GET, headers, null);

    const r = req.reader();
    const body_content = try r.readAllAlloc(gpa, std.math.maxInt(usize));
    const val = try json.parse(gpa, body_content);

    if (val.get("message")) |msg| {
        std.log.err("server: {s}", .{msg.String});
        return error.AquilaBadResponse;
    }
    return val;
}
