const std = @import("std");
const string = []const u8;
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
    links: []const ?string,
};

pub fn execute(args: [][]u8) !void {
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
            try cmd.execute(args[1..]);
            return;
        }
    }
    u.fail("unknown command \"{s}\" for \"zigmod zpm\"", .{args[0]});
}

pub fn server_fetch(url: string) !json.Value {
    const req = try zfetch.Request.init(gpa, url, null);
    defer req.deinit();
    try req.do(.GET, null, null);
    const r = req.reader();
    const body_content = try r.readAllAlloc(gpa, std.math.maxInt(usize));
    const val = try json.parse(gpa, body_content);
    return val;
}

pub fn server_fetchArray(url: string) ![]const Package {
    const val = try server_fetch(url);
    var list = std.ArrayList(Package).init(gpa);
    errdefer list.deinit();

    for (val.Array) |item| {
        if (item.getT("root_file", .String) == null) continue;
        try list.append(Package{
            .name = item.getT("name", .String).?,
            .author = item.getT("author", .String).?,
            .description = item.getT("description", .String).?,
            .tags = try valueStrArray(item.getT("tags", .Array).?),
            .git = item.getT("git", .String).?,
            .root_file = item.getT("root_file", .String).?,
            .source = @intCast(u32, item.getT("source", .Int).?),
            .links = try valueLinks(item.get("links").?),
        });
    }
    return list.toOwnedSlice();
}

fn valueStrArray(vals: []json.Value) ![]string {
    var list = std.ArrayList(string).init(gpa);
    errdefer list.deinit();

    for (vals) |item| {
        if (item != .String) continue;
        try list.append(item.String);
    }
    return list.toOwnedSlice();
}

fn valueLinks(vals: json.Value) ![]?string {
    var list = std.ArrayList(?string).init(gpa);
    errdefer list.deinit();

    try list.append(vals.getT("github", .String));
    try list.append(vals.getT("aquila", .String));
    try list.append(vals.getT("astrolabe", .String));
    return list.toOwnedSlice();
}
