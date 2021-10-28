const std = @import("std");
const gpa = std.heap.c_allocator;

const zfetch = @import("zfetch");
const json = @import("json");
const range = @import("range").range;

const u = @import("./../../util/index.zig");
const zpm = @import("./../zpm.zig");

//
//

pub fn execute(args: [][]u8) !void {
    _ = args;

    const out = std.io.getStdOut().writer();

    const url = try std.mem.join(gpa, "/", &.{ zpm.server_root, "packages" });
    const val = try zpm.server_fetch(url);

    var arr = std.ArrayList(zpm.Package).init(gpa);
    defer arr.deinit();

    for (val.Array) |item| {
        if (item.get("root_file")) |_| {} else {
            continue;
        }
        try arr.append(zpm.Package{
            .name = item.getT("name", .String).?,
            .author = item.getT("author", .String).?,
            .description = item.getT("description", .String).?,
            .tags = &.{},
            .git = "",
            .root_file = "",
        });
    }
    const list = arr.items;

    const name_col_width = blk: {
        var w: usize = 4;
        for (list) |pkg| {
            const len = pkg.name.len;
            if (len > w) {
                w = len;
            }
        }
        break :blk w + 2;
    };

    const author_col_width = blk: {
        var w: usize = 6;
        for (list) |pkg| {
            const len = pkg.author.len;
            if (len > w) {
                w = len;
            }
        }
        break :blk w + 2;
    };

    try out.writeAll("NAME");
    try print_c_n(out, ' ', name_col_width - 4);
    try out.writeAll("AUTHOR");
    try print_c_n(out, ' ', author_col_width - 6);
    try out.writeAll("DESCRIPTION\n");

    for (list) |pkg| {
        try out.writeAll(pkg.name);
        try print_c_n(out, ' ', name_col_width - pkg.name.len);

        try out.writeAll(pkg.author);
        try print_c_n(out, ' ', author_col_width - pkg.author.len);

        try out.writeAll(pkg.description);
        try out.writeAll("\n");
    }
}

fn print_c_n(out: anytype, c: u8, n: usize) !void {
    for (range(n)) |_| {
        try out.writeAll(&.{c});
    }
}
