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
    name: []const u8,
    main: []const u8,
    c_include_dirs: [][]const u8,
    c_source_files: [][]const u8,
    deps: []u.Dep,

    pub fn init(alloc: *std.mem.Allocator, fpath: []const u8) !Self {
        //
        const mpath = try std.fs.realpathAlloc(alloc, fpath);
        const file = try std.fs.openFileAbsolute(mpath, .{});
        defer file.close();
        const input = try file.reader().readAllAlloc(alloc, mb);
        const doc = try yaml.parse(alloc, input);

        const name = doc.mapping.get("name").?.string;
        const main = doc.mapping.get("main").?.string;

        const cinclude_list = &std.ArrayList([]const u8).init(alloc);
        if (doc.mapping.get("c_include_dirs")) |val| {
            if (val == .sequence) {
                for (val.sequence) |item, i| {
                    u.assert(item == .string, "modfile: {}[{}] is not a string", .{"c_include_dirs", i});
                    try cinclude_list.append(item.string);
                }
            }
        }

        const csrc_list = &std.ArrayList([]const u8).init(alloc);
        if (doc.mapping.get("c_source_files")) |val| {
            if (val == .sequence) {
                for (val.sequence) |item, i| {
                    u.assert(item == .string, "modfile: {}[{}] is not a string", .{"c_source_files", i});
                    try csrc_list.append(item.string);
                }
            }
        }

        const dep_list = &std.ArrayList(u.Dep).init(alloc);
        if (doc.mapping.get("dependencies")) |dep_seq| {
            if (dep_seq == .sequence) {
                for (dep_seq.sequence) |item| {
                    const dtype = item.mapping.get("type").?.string;
                    const path = item.mapping.get("path").?.string;
                    const dep_type = std.meta.stringToEnum(u.DepType, dtype).?;

                    try dep_list.append(u.Dep{
                        .type = dep_type,
                        .path = path,
                    });
                }
            }
        }

        return Self{
            .alloc = alloc,
            .name = name,
            .main = main,
            .c_include_dirs = cinclude_list.items,
            .c_source_files = csrc_list.items,
            .deps = dep_list.items,
        };
    }
};
