const std = @import("std");

const u = @import("index.zig");
const yaml = @import("./yaml.zig");

//
//

const b = 1;
const kb = b * 1024;
const mb = kb * 1024;

pub const ModFile = struct {
    const Self = @This();

    alloc: *std.mem.Allocator,
    id: []const u8,
    name: []const u8,
    main: []const u8,
    c_include_dirs: [][]const u8,
    c_source_flags: [][]const u8,
    c_source_files: [][]const u8,
    deps: []u.Dep,
    yaml: yaml.Mapping,

    pub fn init(alloc: *std.mem.Allocator, fpath: []const u8) !Self {
        //
        const mpath = try std.fs.realpathAlloc(alloc, fpath);
        const file = try std.fs.openFileAbsolute(mpath, .{});
        defer file.close();
        const input = try file.reader().readAllAlloc(alloc, mb);
        const doc = try yaml.parse(alloc, input);
        return from_mapping(alloc, doc.mapping);
    }

    pub fn from_mapping(alloc: *std.mem.Allocator, mapping: yaml.Mapping) anyerror!Self {
        const id = mapping.get_string("id");
        const name = mapping.get("name").?.string;
        const main = mapping.get_string("main");

        const dep_list = &std.ArrayList(u.Dep).init(alloc);
        if (mapping.get("dependencies")) |dep_seq| {
            if (dep_seq == .sequence) {
                for (dep_seq.sequence) |item| {
                    var dtype: []const u8 = undefined;
                    var path: []const u8 = undefined;
                    if (item.mapping.get("src")) |val| {
                        var src_iter = std.mem.split(val.string, " ");
                        dtype = src_iter.next().?;
                        path = src_iter.next().?;
                    } else {
                        dtype = item.mapping.get("type").?.string;
                        path = item.mapping.get("path").?.string;
                    }
                    const dep_type = std.meta.stringToEnum(u.DepType, dtype).?;

                    try dep_list.append(u.Dep{
                        .type = dep_type,
                        .path = path,
                        .id = item.mapping.get_string("id"),
                        .name = item.mapping.get_string("name"),
                        .main = item.mapping.get_string("main"),
                        .version = item.mapping.get_string("version"),
                        .c_include_dirs = try item.mapping.get_string_array(alloc, "c_include_dirs"),
                        .c_source_flags = try item.mapping.get_string_array(alloc, "c_source_flags"),
                        .c_source_files = try item.mapping.get_string_array(alloc, "c_source_files"),
                        .only_os = try u.list_remove(try u.split(item.mapping.get_string("only_os"), ","), ""),
                        .except_os = try u.list_remove(try u.split(item.mapping.get_string("except_os"), ","), ""),
                        .yaml = item.mapping,
                    });
                }
            }
        }

        return Self{
            .alloc = alloc,
            .id = if (id.len == 0) try u.random_string(48) else id,
            .name = name,
            .main = main,
            .c_include_dirs = try mapping.get_string_array(alloc, "c_include_dirs"),
            .c_source_flags = try mapping.get_string_array(alloc, "c_source_flags"),
            .c_source_files = try mapping.get_string_array(alloc, "c_source_files"),
            .deps = dep_list.items,
            .yaml = mapping,
        };
    }
};
