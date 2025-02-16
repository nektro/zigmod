const std = @import("std");
const gpa = std.heap.c_allocator;
const string = []const u8;
const style = @import("ansi").style;
const licenses = @import("licenses");
const extras = @import("extras");

const zigmod = @import("../lib.zig");
const u = @import("./../util/index.zig");
const common = @import("./../common.zig");

const List = std.ArrayList(zigmod.Module);
const Map = std.StringArrayHashMap(*List);

// Inspired by:
// https://github.com/onur/cargo-license

pub fn execute(self_name: []const u8, args: [][:0]u8) !void {
    _ = self_name;
    _ = args;

    const cachepath = try u.find_cachepath();
    const dir = std.fs.cwd();

    var options = common.CollectOptions{
        .log = false,
        .update = false,
        .alloc = gpa,
    };

    try do(cachepath, dir, &options, std.io.getStdOut());
}

pub fn do(cachepath: string, dir: std.fs.Dir, options: *common.CollectOptions, outfile: std.fs.File) !void {
    const top_module = try common.collect_deps_deep(cachepath, dir, options);

    var master_list = List.init(gpa);
    errdefer master_list.deinit();
    try common.collect_pkgs(top_module, &master_list);
    std.mem.sort(zigmod.Module, master_list.items, {}, zigmod.Module.lessThan);

    var map = Map.init(gpa);
    errdefer map.deinit();

    var unspecified_list = List.init(gpa);
    errdefer unspecified_list.deinit();

    for (master_list.items) |item| {
        if (item.clean_path.len == 0) {
            continue;
        }
        if (std.mem.eql(u8, item.clean_path, "files")) {
            continue;
        }
        if (item.yaml == null) {
            try unspecified_list.append(item);
            continue;
        }
        const license_code = item.yaml.?.get_string("license") orelse "";
        if (license_code.len == 0) {
            try unspecified_list.append(item);
            continue;
        }
        const map_item = try map.getOrPut(license_code);
        if (!map_item.found_existing) {
            const temp = try gpa.create(List);
            temp.* = List.init(gpa);
            map_item.value_ptr.* = temp;
        }
        const tracking_list = map_item.value_ptr.*;
        try tracking_list.append(item);
    }

    const istty = outfile.isTty();
    const writer = outfile.writer();
    const Bold = if (!istty) "" else style.Bold;
    const Faint = if (!istty) "" else style.Faint;
    const ResetIntensity = if (!istty) "" else style.ResetIntensity;

    var first = true;
    var iter = map.iterator();
    while (iter.next()) |entry| {
        if (!first) try writer.writeAll("\n");
        first = false;
        try writer.writeAll(Bold);
        try writer.print("{s}:\n", .{entry.key_ptr.*});
        if (extras.containsString(licenses.spdx, entry.key_ptr.*)) {
            try writer.writeAll(Faint);
            try writer.print("= {s}{s}\n", .{ "https://spdx.org/licenses/", entry.key_ptr.* });
        }
        try writer.writeAll(ResetIntensity);
        for (entry.value_ptr.*.items) |item| {
            if (std.mem.eql(u8, item.clean_path, "../..")) {
                try writer.writeAll("- This\n");
            } else {
                try writer.print("- {s} {s}\n", .{ @tagName(item.dep.?.type), item.dep.?.path });
            }
        }
    }
    if (unspecified_list.items.len > 0) {
        if (!first) try writer.writeAll("\n");
        try writer.writeAll(Bold);
        try writer.writeAll("Unspecified:\n");
        try writer.writeAll(ResetIntensity);
        for (unspecified_list.items) |item| {
            if (std.mem.eql(u8, item.clean_path, "../..")) {
                try writer.writeAll("- This\n");
            } else {
                try writer.print("- {s} {s}\n", .{ @tagName(item.dep.?.type), item.dep.?.path });
            }
        }
    }
}
