const std = @import("std");
const builtin = @import("builtin");
const extras = @import("extras");
const nfs = @import("nfs");

const zigmod = @import("../lib.zig");
const u = @import("./../util/funcs.zig");
const common = @import("./../common.zig");

//
//

pub fn execute(self_name: []const u8, args: [][:0]u8) !void {
    _ = self_name;

    const gpa = std.heap.c_allocator;
    const cachepath = try u.find_cachepath();
    const dir = nfs.cwd();
    const should_lock = args.len >= 1 and std.mem.eql(u8, args[0], "--locked");
    const format_i: usize = if (should_lock) 1 else 0;
    const Format = enum {
        tree,
        mermaid,
        dot,
    };
    const format_s = if (args.len >= 1 + format_i and std.mem.eql(u8, args[format_i], "--format")) args[format_i + 1] else "";
    const format = std.meta.stringToEnum(Format, format_s) orelse u.fail("unrecognized --format: {s}", .{format_s});

    var options = common.CollectOptions{
        .log = false,
        .update = false,
        .alloc = gpa,
        .lock = if (should_lock) try common.parse_lockfile(gpa, dir) else null,
    };
    const top_module = try common.collect_deps_deep(cachepath, dir, &options);

    var seencache = std.ArrayList([48]u8).init(gpa);
    defer seencache.deinit();

    const stdout = std.io.getStdOut();
    const w = stdout.writer();

    switch (format) {
        .tree => {
            try printTree(w, top_module, 0);
        },
        .mermaid => {
            try w.writeAll("graph TD;\n");
            try printMermaid(w, top_module, &seencache);
        },
        .dot => {
            try w.writeAll("digraph {\n");
            try printDot(w, top_module, &seencache);
            try w.writeAll("}\n");
        },
    }
}

fn printTree(writer: anytype, module: zigmod.Module, depth: u16) !void {
    try writer.writeByteNTimes('\t', depth);
    try writer.writeAll(module.name);
    try writer.writeByte('\n');

    for (module.deps) |dep| {
        try printTree(writer, dep, depth + 1);
    }
}

fn printMermaid(writer: anytype, module: zigmod.Module, seencache: *std.ArrayList([48]u8)) !void {
    for (seencache.items) |item| {
        if (std.mem.eql(u8, &module.id, &item)) {
            return;
        }
    }
    try seencache.append(module.id);

    for (module.deps) |dep| {
        if (dep.name.len == 0) continue;
        try writer.print("    {s}-->{s};\n", .{ module.name, dep.name });
    }
    for (module.deps) |dep| {
        try printMermaid(writer, dep, seencache);
    }
}

fn printDot(writer: anytype, module: zigmod.Module, seencache: *std.ArrayList([48]u8)) !void {
    for (seencache.items) |item| {
        if (std.mem.eql(u8, &module.id, &item)) {
            return;
        }
    }
    try seencache.append(module.id);

    for (module.deps) |dep| {
        if (dep.name.len == 0) continue;
        try writer.print("  \"{s}\" -> \"{s}\";\n", .{ module.name, dep.name });
    }
    for (module.deps) |dep| {
        try printDot(writer, dep, seencache);
    }
}
