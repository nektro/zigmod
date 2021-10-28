const std = @import("std");
const gpa = std.heap.c_allocator;

const style = @import("ansi").style;
const licenses = @import("licenses");

const zigmod = @import("../lib.zig");
const u = @import("./../util/index.zig");
const common = @import("./../common.zig");

const Module = zigmod.Module;
const List = std.ArrayList(zigmod.Module);
const Map = std.StringArrayHashMap(*List);

// Inspired by:
// https://github.com/onur/cargo-license

pub fn execute(args: [][]u8) !void {
    _ = args;

    const cachepath = try std.fs.path.join(gpa, &.{ ".zigmod", "deps" });
    const dir = std.fs.cwd();

    var options = common.CollectOptions{
        .log = false,
        .update = false,
        .alloc = gpa,
    };
    const top_module = try common.collect_deps_deep(cachepath, dir, &options);

    const master_list = &List.init(gpa);
    try common.collect_pkgs(top_module, master_list);

    const map = &Map.init(gpa);

    const unspecified_list = &List.init(gpa);

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
        const license_code = item.yaml.?.get_string("license");
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

    var iter = map.iterator();
    while (iter.next()) |entry| {
        std.debug.print(style.Bold ++ "{s}:\n", .{entry.key_ptr.*});
        if (u.list_contains(licenses.spdx, entry.key_ptr.*)) {
            std.debug.print(style.Faint ++ "= {s}{s}\n", .{ "https://spdx.org/licenses/", entry.key_ptr.* });
        }
        std.debug.print(style.ResetIntensity, .{});
        for (entry.value_ptr.*.items) |item| {
            if (std.mem.eql(u8, item.clean_path, "../..")) {
                std.debug.print("- This\n", .{});
            } else {
                std.debug.print("- {s} {s}\n", .{ @tagName(item.dep.?.type), item.dep.?.path });
            }
        }
        std.debug.print("\n", .{});
    }
    if (unspecified_list.items.len > 0) {
        std.debug.print(style.Bold ++ "Unspecified:\n", .{});
        std.debug.print(style.ResetIntensity, .{});
        for (unspecified_list.items) |item| {
            if (std.mem.eql(u8, item.clean_path, "../..")) {
                std.debug.print("- This\n", .{});
            } else {
                std.debug.print("- {s} {s}\n", .{ @tagName(item.dep.?.type), item.dep.?.path });
            }
        }
    }
}
