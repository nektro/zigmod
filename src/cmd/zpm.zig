const std = @import("std");
const gpa = std.heap.c_allocator;

const zfetch = @import("zfetch");
const json = @import("json");

const u = @import("./../util/index.zig");

//
//

pub const commands = struct {
    pub const add = @import("./zpm/add.zig");
    pub const showjson = @import("./zpm/showjson.zig");
    pub const tags = @import("./zpm/tags.zig");
};

pub const server_root = "https://zpm.random-projects.net/api";

pub const Package = struct {
    author: []const u8,
    name: []const u8,
    tags: [][]const u8,
    git: []const u8,
    root_file: ?[]const u8,
    description: []const u8,
};

pub fn execute(args: [][]u8) !void {
    if (args.len == 0) {
        std.debug.warn("{s}\n", .{
            \\This is a subcommand for use with https://github.com/zigtools/zpm-server instances but has no default behavior on its own aside from showing you this nice help text.
            \\
            \\The default remote is https://zpm.random-projects.net/.
            \\
            \\The subcommands available are:
            \\  - add       Append this package to your dependencies
            \\  - showjson  Print raw json from queried API responses
            \\  - tags      Print the list of tags available on the server.
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
    u.assert(false, "unknown command \"{s}\" for \"zigmod zpm\"", .{args[0]});
}

pub fn server_fetch(url: []const u8) !json.Value {
    const req = try zfetch.Request.init(gpa, url, null);
    defer req.deinit();
    try req.do(.GET, null, null);
    const r = req.reader();
    const body_content = try r.readAllAlloc(gpa, std.math.maxInt(usize));
    const val = try json.parse(gpa, body_content);
    return val;
}
