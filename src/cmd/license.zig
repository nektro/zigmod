const std = @import("std");
const gpa = std.heap.c_allocator;

const u = @import("./../util/index.zig");
const common = @import("./../common.zig");

const ansi = @import("ansi");
const style = ansi.style;

const licenses = @import("licenses");

const Module = u.Module;
const List = std.ArrayList(u.Module);
const Map = std.StringArrayHashMap(*List);

// Inspired by:
// https://github.com/onur/cargo-license

pub fn execute(args: [][]u8) !void {
    //
    const dir = try std.fs.path.join(gpa, &.{ ".zigmod", "deps" });

    const top_module = try common.collect_deps_deep(dir, "zig.mod", .{
        .log = false,
        .update = false,
    });

    const master_list = &List.init(gpa);
    try common.collect_pkgs(top_module, master_list);

    const map = &Map.init(gpa);

    const unspecified_list = &List.init(gpa);

    for (master_list.items) |item| {
        if (item.clean_path.len == 0) {
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
            map_item.entry.value = temp;
        }
        const tracking_list = map_item.entry.value;
        try tracking_list.append(item);
    }

    var iter = map.iterator();
    while (iter.next()) |entry| {
        std.debug.print(style.Bold ++ "{s}:\n", .{entry.key});
        if (get_license(entry.key)) |license| {
            std.debug.print(style.Faint ++ "= {s}\n", .{license.url});
        }
        std.debug.print(style.ResetIntensity, .{});
        for (entry.value.items) |item| {
            std.debug.print("- {s}\n", .{if (!std.mem.eql(u8, item.clean_path, "../..")) item.clean_path else "This"});
        }
        std.debug.print("\n", .{});
    }
    if (unspecified_list.items.len > 0) {
        std.debug.print(style.Bold ++ "Unspecified:\n", .{});
        std.debug.print(style.ResetIntensity, .{});
        for (unspecified_list.items) |item| {
            std.debug.print("- {s}\n", .{if (!std.mem.eql(u8, item.clean_path, "../..")) item.clean_path else "This"});
        }
    }
}

fn get_license(name: []const u8) ?licenses.License {
    const T = licenses.spdx;
    inline for (std.meta.declarations(T)) |decl| {
        if (std.mem.eql(u8, decl.name, name)) {
            return @field(T, decl.name);
        }
    }
    return null;
}
