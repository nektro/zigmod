const std = @import("std");
const gpa = std.heap.c_allocator;

const zuri = @import("zuri");
const iguanatls = @import("iguanatls");
const u = @import("./../util/index.zig");

//
//

pub const Zpm = struct {
    pub const Package = struct {
        author: []const u8,
        name: []const u8,
        tags: [][]const u8,
        git: []const u8,
        root_file: ?[]const u8,
        description: []const u8,
    };
};

pub fn execute(args: [][]u8) !void {
    const url = try zuri.Uri.parse("https://zpm.random-projects.net:443/api/packages", true);

    const sock = try std.net.tcpConnectToHost(gpa, url.host.name, url.port.?);
    defer sock.close();

    var client = try iguanatls.client_connect(.{
        .reader = sock.reader(),
        .writer = sock.writer(),
        .cert_verifier = .none,
        .temp_allocator = gpa,
        .ciphersuites = iguanatls.ciphersuites.all,
    }, url.host.name);
    defer client.close_notify() catch {};

    const w = client.writer();
    try w.print("GET {s} HTTP/1.1\r\n", .{url.path});
    try w.print("Host: {s}:{}\r\n", .{url.host.name, url.port.?});
    try w.writeAll("Accept: application/json; charset=UTF-8\r\n");
    try w.writeAll("Connection: close\r\n");
    try w.writeAll("\r\n");

    const r = client.reader();
    var buf: [1]u8 = undefined;
    const data = &std.ArrayList(u8).init(gpa);
    while (true) {
        const len = try r.read(&buf);
        if (len == 0) {
            break;
        }
        try data.appendSlice(buf[0..len]);
    }

    const index = std.mem.indexOf(u8, data.items, "\r\n\r\n").?;
    const html_contents = data.items[index..];

    var stream = std.json.TokenStream.init(html_contents[4..]);
    const res = try std.json.parse([]Zpm.Package, &stream, .{ .allocator = gpa, });

    const found = blk: {
        for (res) |pkg| {
            if (std.mem.eql(u8, pkg.name, args[0])) {
                break :blk pkg;
            }
        }
        u.assert(false, "no package with name '{s}' found", .{args[0]});
        unreachable;
    };

    u.assert(found.root_file != null, "package must have an entry point to be able to be added to your dependencies", .{});

    const self_module = try u.ModFile.init(gpa, "zig.mod");
    for (self_module.deps) |dep| {
        if (std.mem.eql(u8, dep.name, found.name)) {
            u.assert(false, "dependency with name '{s}' already exists in your dependencies", .{found.name});
        }
    }

    const file = try std.fs.cwd().openFile("zig.mod", .{ .read=true, .write=true });
    try file.seekTo(try file.getEndPos());
    
    const file_w = file.writer();
    try file_w.print("\n", .{});
    try file_w.print("  - src: git {s}\n", .{found.git});
    try file_w.print("    name: {s}\n", .{found.name});
    try file_w.print("    main: {s}\n", .{found.root_file.?[1..]});

    std.log.info("Successfully added package {s} by {s}", .{found.name, found.author});
}
