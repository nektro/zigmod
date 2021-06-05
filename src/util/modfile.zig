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
    devdeps: []u.Dep,

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

        if (std.mem.indexOf(u8, name, "/")) |_| {
            u.assert(false, "name may not contain any '/'", .{});
        }
        const dep_list = try dep_list_by_name(alloc, mapping, "dependencies");
        defer dep_list.deinit();
        const devdep_list = try dep_list_by_name(alloc, mapping, "dev_dependencies");
        defer devdep_list.deinit();

        return Self{
            .alloc = alloc,
            .id = if (id.len == 0) try u.random_string(48) else id,
            .name = name,
            .main = main,
            .c_include_dirs = try mapping.get_string_array(alloc, "c_include_dirs"),
            .c_source_flags = try mapping.get_string_array(alloc, "c_source_flags"),
            .c_source_files = try mapping.get_string_array(alloc, "c_source_files"),
            .deps = dep_list.toOwnedSlice(),
            .yaml = mapping,
            .devdeps = devdep_list.toOwnedSlice(),
        };
    }

    fn dep_list_by_name(alloc: *std.mem.Allocator, mapping: yaml.Mapping, prop: []const u8) !*std.ArrayList(u.Dep) {
        const dep_list = try alloc.create(std.ArrayList(u.Dep));
        dep_list.* = std.ArrayList(u.Dep).init(alloc);
        if (mapping.get(prop)) |dep_seq| {
            if (dep_seq == .sequence) {
                for (dep_seq.sequence) |item| {
                    var dtype: []const u8 = undefined;
                    var path: []const u8 = undefined;
                    var version: ?[]const u8 = null;
                    if (item.mapping.get("src")) |val| {
                        var src_iter = std.mem.tokenize(val.string, " ");
                        dtype = src_iter.next().?;
                        path = src_iter.next().?;
                        if (src_iter.next()) |dver| {
                            version = dver;
                        }
                    } else {
                        dtype = item.mapping.get("type").?.string;
                        path = item.mapping.get("path").?.string;
                    }
                    if (item.mapping.get("version")) |verv| {
                        version = verv.string;
                    }
                    if (version == null) {
                        version = "";
                    }
                    const dep_type = std.meta.stringToEnum(u.DepType, dtype).?;

                    try dep_list.append(u.Dep{
                        .type = dep_type,
                        .path = path,
                        .id = item.mapping.get_string("id"),
                        .name = item.mapping.get_string("name"),
                        .main = item.mapping.get_string("main"),
                        .version = version.?,
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
        return dep_list;
    }
};
