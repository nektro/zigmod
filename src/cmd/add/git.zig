const std = @import("std");
const gpa = std.heap.c_allocator;

const zfetch = @import("zfetch");

const u = @import("./../../util/index.zig");

//
//

pub fn execute(args: [][]u8) !void {
    const url = args[0];

    const has_zigdotmod = blk: {
        const _url = try std.mem.join(gpa, "/", &.{ url, "blob", "HEAD", "zig.mod" });
        const _req = try zfetch.Request.init(gpa, _url, null);
        defer _req.deinit();
        try _req.do(.GET, null, null);
        break :blk _req.status.code == 200;
    };

    const file = try std.fs.cwd().openFile("zig.mod", .{ .read = true, .write = true });
    defer file.close();
    try file.seekTo(try file.getEndPos());

    const file_w = file.writer();
    try file_w.print("\n", .{});
    try file_w.print("  - src: git {s}\n", .{std.mem.trimRight(u8, url, ".git")});
    if (!has_zigdotmod) {
        const stdin = std.io.getStdIn().reader();
        u.print("The given git repository does not have a zigmod file, information will have to be entered manually:", .{});

        std.debug.print("    Name: ", .{});
        const name = try stdin.readUntilDelimiterAlloc(gpa, '\n', std.math.maxInt(usize));
        try file_w.print("    name: {s}\n", .{name});

        std.debug.print("    Root file: ", .{});
        const main = try stdin.readUntilDelimiterAlloc(gpa, '\n', std.math.maxInt(usize));
        try file_w.print("    main: {s}\n", .{main});
    }

    std.log.info("Successfully added git repository {s}", .{ url });
}
