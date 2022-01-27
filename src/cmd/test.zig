const std = @import("std");
const string = []const u8;
const gpa = std.heap.c_allocator;
const range = @import("range").range;
const zfetch = @import("zfetch");
const ansi = @import("ansi");

//
//

// https://www.thinkbroadband.com/download

const Progress = struct {
    const Item = struct {
        max: usize,
        current: usize,
        done: bool,
    };
};

var progress: std.ArrayList(Progress.Item) = undefined;
var left: usize = 0;

pub fn execute(args: [][]u8) !void {
    _ = args;
    // progress = std.ArrayList(Progress.Item).init(gpa);
    // std.debug.print("\n", .{});

    // for (range(3)) |_, i| {
    //     try progress.append(.{ .max = 1, .current = 0, .done = false });
    //     left += 1;
    //     try download("http://ipv4.download.thinkbroadband.com/100MB.zip", i);
    // }

    // while (left > 0) {
    //     for (progress.items) |it, i| {
    //         std.debug.print("{d}\t{d}\t{d}\t{d}%\n", .{ i, it.current, it.max, @divExact(it.current, it.max) });
    //     }
    //     std.debug.print("\n", .{});
    // }
    // for (progress.items) |it, i| {
    //     std.debug.print("{d}\t{d}\t{d}\t{d}%\n", .{ i, it.current, it.max, @divExact(it.current, it.max) });
    // }
}

fn download(url: string, index: usize) void {
    const req = zfetch.Request.init(gpa, url, null) catch {};
    defer req.deinit();

    req.do(.GET, null, null) catch {};

    var buf: [std.mem.page_size]u8 = undefined;
    const r = req.reader();
    while (true) {
        const len = r.readAll(&buf) catch {};
        progress.items[index].current += len;
        if (len < buf.len) break;
    }
    progress.items[index].done = true;
    left -= 1;
}
