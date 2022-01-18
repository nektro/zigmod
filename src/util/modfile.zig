const std = @import("std");
const string = []const u8;

const zigmod = @import("../lib.zig");
const u = @import("index.zig");
const yaml = @import("./yaml.zig");

//
//

const b = 1;
const kb = b * 1024;
const mb = kb * 1024;

pub const ModFile = struct {
    const Self = @This();

    id: string,
    name: string,
    main: string,
    c_include_dirs: []const string,
    c_source_flags: []const string,
    c_source_files: []const string,
    deps: []zigmod.Dep,
    yaml: yaml.Mapping,
    root_files: []const string,
    files: []const string,
    rootdeps: []zigmod.Dep,
    builddeps: []zigmod.Dep,

    pub fn init(alloc: std.mem.Allocator, mpath: string) !Self {
        const file = try std.fs.cwd().openFile(mpath, .{});
        defer file.close();
        const input = try file.reader().readAllAlloc(alloc, mb);
        const doc = try yaml.parse(alloc, input);
        return from_mapping(alloc, doc.mapping);
    }

    pub fn from_dir(alloc: std.mem.Allocator, dir: std.fs.Dir) !Self {
        const file = try dir.openFile("zig.mod", .{});
        defer file.close();
        const input = try file.reader().readAllAlloc(alloc, mb);
        const doc = try yaml.parse(alloc, input);
        return from_mapping(alloc, doc.mapping);
    }

    pub fn from_mapping(alloc: std.mem.Allocator, mapping: yaml.Mapping) !Self {
        const id = mapping.get_string("id");
        const name = mapping.get("name").?.string;
        const main = mapping.get_string("main");

        if (std.mem.indexOf(u8, name, "/")) |_| {
            u.fail("name may not contain any '/'", .{});
        }

        return Self{
            .id = if (id.len == 0) try u.random_string(alloc, 48) else id,
            .name = name,
            .main = main,
            .c_include_dirs = try mapping.get_string_array(alloc, "c_include_dirs"),
            .c_source_flags = try mapping.get_string_array(alloc, "c_source_flags"),
            .c_source_files = try mapping.get_string_array(alloc, "c_source_files"),
            .deps = try dep_list_by_name(alloc, mapping, &.{"dependencies"}, false),
            .yaml = mapping,
            .root_files = try mapping.get_string_array(alloc, "root_files"),
            .files = try mapping.get_string_array(alloc, "files"),
            .rootdeps = try dep_list_by_name(alloc, mapping, &.{ "dev_dependencies", "root_dependencies" }, false),
            .builddeps = try dep_list_by_name(alloc, mapping, &.{ "dev_dependencies", "build_dependencies" }, true),
        };
    }

    fn dep_list_by_name(alloc: std.mem.Allocator, mapping: yaml.Mapping, props: []const string, for_build: bool) std.mem.Allocator.Error![]zigmod.Dep {
        var dep_list = std.ArrayList(zigmod.Dep).init(alloc);
        defer dep_list.deinit();

        for (props) |prop| {
            if (mapping.get(prop)) |dep_seq| {
                if (dep_seq != .sequence) continue;
                for (dep_seq.sequence) |item| {
                    var dtype: string = undefined;
                    var path: string = undefined;
                    var version: ?string = null;
                    var name = item.mapping.get_string("name");
                    var main = item.mapping.get_string("main");

                    if (item.mapping.get("src")) |val| {
                        var src_iter = std.mem.tokenize(u8, val.string, " ");
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
                    const dep_type = std.meta.stringToEnum(zigmod.DepType, dtype).?;
                    if (dep_type == .local) {
                        if (path.len > 0) {
                            name = path;
                            path = "";
                        }
                        if (version.?.len > 0) {
                            main = version.?;
                            version = "";
                        }
                    }

                    try dep_list.append(zigmod.Dep{
                        .alloc = alloc,
                        .type = dep_type,
                        .path = path,
                        .id = item.mapping.get_string("id"),
                        .name = name,
                        .main = main,
                        .version = version.?,
                        .c_include_dirs = try item.mapping.get_string_array(alloc, "c_include_dirs"),
                        .c_source_flags = try item.mapping.get_string_array(alloc, "c_source_flags"),
                        .c_source_files = try item.mapping.get_string_array(alloc, "c_source_files"),
                        .only_os = try u.list_remove(alloc, try u.split(alloc, item.mapping.get_string("only_os"), ","), ""),
                        .except_os = try u.list_remove(alloc, try u.split(alloc, item.mapping.get_string("except_os"), ","), ""),
                        .yaml = item.mapping,
                        .deps = try dep_list_by_name(alloc, item.mapping, &.{"dependencies"}, for_build),
                        .keep = std.mem.eql(u8, "true", item.mapping.get_string("keep")),
                        .vcpkg = std.mem.eql(u8, "true", item.mapping.get_string("vcpkg")),
                        .for_build = for_build,
                    });
                }
            }
        }
        return dep_list.toOwnedSlice();
    }
};
