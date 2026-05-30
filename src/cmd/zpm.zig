const std = @import("std");
const string = []const u8;
const gpa = std.heap.c_allocator;
const extras = @import("extras");
const json = @import("json");
const nio = @import("nio");

const u = @import("./../util/funcs.zig");

//
//

pub const commands = struct {
    pub const add = @import("./zpm/add.zig");
    pub const showjson = @import("./zpm/showjson.zig");
    pub const tags = @import("./zpm/tags.zig");
    pub const search = @import("./zpm/search.zig");
};

pub const server_root = "https://zig.pm/api";

pub const Package = struct {
    author: string,
    name: string,
    tags: []const string,
    git: string,
    root_file: string,
    description: string,
    source: u32,
    links: []const string,
};

pub fn execute(self_name: []const u8, args: [][:0]u8) !void {
    if (args.len == 0) {
        std.debug.print("{s}\n", .{
            \\This is a subcommand for use with https://github.com/zigtools/zpm-server instances but has no default behavior on its own aside from showing you this nice help text.
            \\
            \\The default remote is https://zig.pm/.
            \\
            \\The subcommands available are:
            \\  - add       Append this package to your dependencies
            \\  - showjson  Print raw json from queried API responses
            \\  - tags      Print the list of tags available on the server.
            \\  - search    Search the api for available packages and print them.
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
    u.fail("unknown command \"{s}\" for \"zigmod zpm\"", .{args[0]});
}

pub fn server_fetch(url: string) !json.Document {
    var buf: [4096]u8 = @splat(0);
    var client: std.http.Client = .{ .allocator = gpa };
    defer client.deinit();

    var req = try client.open(.GET, try std.Uri.parse(url), .{
        .server_header_buffer = &buf,
    });
    defer req.deinit();
    try req.send();
    try req.finish();
    try req.wait();
    if (req.response.status != .ok) u.fail("expected: 200 from '{s}' got: {s}", .{ url, @tagName(req.response.status) });
    return json.parse(gpa, "", nio.AnyReadable.fromStd(&req.reader()), .{ .support_trailing_commas = true, .maximum_depth = 100 });
}

pub fn server_fetchArray(url: string) ![]const Package {
    const doc = try server_fetch(url);
    doc.acquire();
    defer doc.release();
    var list = std.ArrayList(Package).init(gpa);
    errdefer list.deinit();

    for (doc.root.array()) |item| {
        const obj = item.object();
        if (obj.getS("root_file") == null) continue;
        try list.append(Package{
            .name = obj.getS("name").?,
            .author = obj.getS("author").?,
            .description = obj.getS("description").?,
            .tags = try valueStrArray(obj.getA("tags").?),
            .git = obj.getS("git").?,
            .root_file = obj.getS("root_file").?,
            .source = obj.getN("source").?.get(u32),
            .links = try valueLinks(obj.getO("links").?),
        });
    }
    return list.toOwnedSlice();
}

fn valueStrArray(vals: json.Array) ![]string {
    var list = std.ArrayList(string).init(gpa);
    errdefer list.deinit();

    for (vals) |item| {
        if (item.v() != .string) continue;
        try list.append(item.string());
    }
    return list.toOwnedSlice();
}

fn valueLinks(vals: json.ObjectIndex) ![]string {
    var list = std.ArrayList(string).init(gpa);
    errdefer list.deinit();

    if (vals.getS("github")) |x| try list.append(x);
    if (vals.getS("aquila")) |x| try list.append(x);
    if (vals.getS("astrolabe")) |x| try list.append(x);
    return list.toOwnedSlice();
}
