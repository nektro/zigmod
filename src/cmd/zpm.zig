const std = @import("std");
const string = []const u8;
const gpa = std.heap.c_allocator;
const zfetch = @import("zfetch");
const extras = @import("extras");

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

pub fn server_fetch(url: string) !std.json.Parsed(std.json.Value) {
    const req = try zfetch.Request.init(gpa, url, null);
    defer req.deinit();
    try req.do(.GET, null, null);
    const r = req.reader();
    const body_content = try r.readAllAlloc(gpa, std.math.maxInt(usize));
    return extras.parse_json(gpa, body_content);
}

pub fn server_fetchArray(url: string) ![]const Package {
    const val = try server_fetch(url);
    var list = std.ArrayList(Package).init(gpa);
    errdefer list.deinit();

    for (val.value.array.items) |item| {
        if (get(item, "root_file") == null) continue;
        try list.append(Package{
            .name = item.object.get("name").?.string,
            .author = item.object.get("author").?.string,
            .description = item.object.get("description").?.string,
            .tags = try valueStrArray(item.object.get("tags").?.array.items),
            .git = item.object.get("git").?.string,
            .root_file = item.object.get("root_file").?.string,
            .source = @intCast(item.object.get("source").?.integer),
            .links = try valueLinks(item.object.get("links").?),
        });
    }
    return list.toOwnedSlice();
}

fn valueStrArray(vals: []std.json.Value) ![]string {
    var list = std.ArrayList(string).init(gpa);
    errdefer list.deinit();

    for (vals) |item| {
        if (item != .string) continue;
        try list.append(item.string);
    }
    return list.toOwnedSlice();
}

fn valueLinks(vals: std.json.Value) ![]?string {
    var list = std.ArrayList(?string).init(gpa);
    errdefer list.deinit();

    if (get(vals, "github")) |x| try list.append(x.string);
    if (get(vals, "aquila")) |x| try list.append(x.string);
    if (get(vals, "astrolabe")) |x| try list.append(x.string);
    return list.toOwnedSlice();
}

fn get(obj: std.json.Value, key: string) ?std.json.Value {
    const v = obj.object.get(key);
    if (v == null) return null;
    if (v.? == .null) return null;
    return v.?;
}
