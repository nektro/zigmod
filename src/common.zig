const std = @import("std");
const gpa = std.heap.c_allocator;

const u = @import("./util/index.zig");
const yaml = @import("./util/yaml.zig");
const string = []const u8;

//
//

pub const CollectOptions = struct {
    log: bool,
    update: bool,
    lock: ?[]const [4][]const u8 = null,
    alloc: *std.mem.Allocator = gpa,
    already_fetched: *std.ArrayList(string) = undefined,

    pub fn init(self: *CollectOptions) !void {
        self.already_fetched = try self.alloc.create(std.ArrayList(string));
        self.already_fetched.* = std.ArrayList(string).init(self.alloc);
    }
};

pub fn collect_deps_deep(dir: []const u8, mpath: []const u8, options: *CollectOptions) !u.Module {
    const m = try u.ModFile.init(gpa, mpath);
    try options.init();
    const moduledeps = &std.ArrayList(u.Module).init(gpa);
    defer moduledeps.deinit();
    try std.fs.cwd().makePath(".zigmod/deps/files");
    if (m.root_files.len > 0) {
        try moduledeps.append(try add_files_package("root", m.root_files, m.name));
    }
    try moduledeps.append(try collect_deps(dir, mpath, options));
    for (m.devdeps) |*d| {
        if (try get_module_from_dep(d, dir, m.name, options)) |founddep| {
            try moduledeps.append(founddep);
        }
    }
    return u.Module{
        .is_sys_lib = false,
        .id = "root",
        .name = "root",
        .main = m.main,
        .deps = moduledeps.toOwnedSlice(),
        .clean_path = "",
        .yaml = m.yaml,
        .dep = null,
    };
}

pub fn collect_deps(dir: []const u8, mpath: []const u8, options: *CollectOptions) anyerror!u.Module {
    const m = try u.ModFile.init(gpa, mpath);
    const moduledeps = &std.ArrayList(u.Module).init(gpa);
    defer moduledeps.deinit();
    if (m.files.len > 0) {
        try moduledeps.append(try add_files_package(m.id, m.files, m.name));
    }
    for (m.deps) |*d| {
        if (try get_module_from_dep(d, dir, m.name, options)) |founddep| {
            try moduledeps.append(founddep);
        }
    }
    return u.Module{
        .is_sys_lib = false,
        .id = m.id,
        .name = m.name,
        .main = m.main,
        .c_include_dirs = m.c_include_dirs,
        .c_source_flags = m.c_source_flags,
        .c_source_files = m.c_source_files,
        .deps = moduledeps.toOwnedSlice(),
        .clean_path = "../..",
        .yaml = m.yaml,
        .dep = null,
    };
}

pub fn collect_pkgs(mod: u.Module, list: *std.ArrayList(u.Module)) anyerror!void {
    if (u.list_contains_gen(u.Module, list.items, mod)) {
        return;
    }
    try list.append(mod);
    for (mod.deps) |d| {
        try collect_pkgs(d, list);
    }
}

fn get_moddir(basedir: []const u8, d: u.Dep, parent_name: []const u8, options: *CollectOptions) ![]const u8 {
    const p = try std.fs.path.join(gpa, &.{ basedir, try d.clean_path() });
    const pv = try std.fs.path.join(gpa, &.{ basedir, try d.clean_path_v() });

    if (u.list_contains(options.already_fetched.items, p)) return p;
    if (u.list_contains(options.already_fetched.items, pv)) return pv;

    const tempdir = try std.fs.path.join(gpa, &.{ basedir, "temp" });
    if (options.log and d.type != .local) {
        u.print("fetch: {s}: {s}: {s}", .{ parent_name, @tagName(d.type), d.path });
    }
    switch (d.type) {
        .local => {
            if (!std.mem.endsWith(u8, d.main, ".zig")) {
                return d.main;
            }
            return d.path;
        },
        .system_lib => {
            // no op
            return "";
        },
        .git => {
            if (d.version.len > 0) {
                const vers = u.parse_split(u.GitVersionType, "-").do(d.version) catch |e| switch (e) {
                    error.IterEmpty => unreachable,
                    error.NoMemberFound => {
                        const vtype = d.version[0..std.mem.indexOf(u8, d.version, "-").?];
                        u.assert(false, "fetch: git: version type '{s}' is invalid.", .{vtype});
                        unreachable;
                    },
                };
                if (try u.does_folder_exist(pv)) {
                    if (vers.id == .branch) {
                        if (options.update) {
                            try d.type.update(pv, d.path);
                        }
                    }
                    return pv;
                }
                try d.type.pull(d.path, tempdir);
                if ((try u.run_cmd(tempdir, &.{ "git", "checkout", vers.string })) > 0) {
                    u.assert(false, "fetch: git: {s}: {s} {s} does not exist", .{ d.path, @tagName(vers.id), vers.string });
                }
                const td_fd = try std.fs.cwd().openDir(basedir, .{});
                try std.fs.cwd().makePath(pv);
                try td_fd.rename("temp", try d.clean_path_v());
                if (vers.id != .branch) {
                    const pvd = try std.fs.cwd().openDir(pv, .{});
                    try pvd.deleteTree(".git");
                }
                return pv;
            }
            if (!try u.does_folder_exist(p)) {
                try d.type.pull(d.path, p);
            } else {
                if (options.update) {
                    try d.type.update(p, d.path);
                }
            }
            return p;
        },
        .hg => {
            if (!try u.does_folder_exist(p)) {
                try d.type.pull(d.path, p);
            } else {
                if (options.update) {
                    try d.type.update(p, d.path);
                }
            }
            return p;
        },
        .http => {
            if (try u.does_folder_exist(pv)) {
                return pv;
            }
            const file_name = try u.last(try u.split(d.path, "/"));
            if (d.version.len > 0) {
                if (try u.does_folder_exist(pv)) {
                    return pv;
                }
                const file_path = try std.fs.path.join(gpa, &.{ pv, file_name });
                try d.type.pull(d.path, pv);
                if (try u.validate_hash(d.version, file_path)) {
                    try std.fs.cwd().deleteFile(file_path);
                    return pv;
                }
                try std.fs.cwd().deleteTree(pv);
                u.assert(false, "{s} does not match hash {s}", .{ d.path, d.version });
                return p;
            }
            if (try u.does_folder_exist(p)) {
                try std.fs.cwd().deleteTree(p);
            }
            const file_path = try std.fs.path.join(gpa, &.{ p, file_name });
            try d.type.pull(d.path, p);
            try std.fs.deleteFileAbsolute(file_path);
            return p;
        },
    }
}

pub fn get_module_from_dep(d: *u.Dep, dir: []const u8, parent_name: []const u8, options: *CollectOptions) anyerror!?u.Module {
    if (options.lock) |lock| {
        for (lock) |item| {
            if (std.mem.eql(u8, item[0], try d.clean_path())) {
                d.type = std.meta.stringToEnum(u.DepType, item[1]).?;
                d.path = item[2];
                d.version = item[3];
                break;
            }
        }
    }
    const moddir = try get_moddir(dir, d.*, parent_name, options);
    try options.already_fetched.append(moddir);
    switch (d.type) {
        .system_lib => {
            return u.Module{
                .is_sys_lib = true,
                .id = "",
                .name = d.path,
                .only_os = d.only_os,
                .except_os = d.except_os,
                .main = "",
                .deps = &[_]u.Module{},
                .clean_path = d.path,
                .yaml = null,
                .dep = d.*,
            };
        },
        else => {
            var dd = try collect_deps(dir, try u.concat(&.{ moddir, "/zig.mod" }), options) catch |e| switch (e) {
                error.FileNotFound => {
                    if (d.main.len > 0 or d.c_include_dirs.len > 0 or d.c_source_files.len > 0) {
                        var mod_from = try u.Module.from(d.*, dir, options);
                        if (d.type != .local) mod_from.clean_path = u.trim_prefix(moddir, dir)[1..];
                        if (mod_from.is_for_this()) return mod_from;
                        return null;
                    }
                    u.assert(false, "no zig.mod found and no override props defined. unable to use add this dependency!", .{});
                    unreachable;
                },
                else => e,
            };
            dd.dep = d.*;
            const save = dd;
            if (d.type != .local) dd.clean_path = u.trim_prefix(moddir, dir)[1..];
            if (dd.id.len == 0) dd.id = try u.random_string(48);
            if (d.name.len > 0) dd.name = d.name;
            if (d.main.len > 0) dd.main = d.main;
            if (d.c_include_dirs.len > 0) dd.c_include_dirs = d.c_include_dirs;
            if (d.c_source_flags.len > 0) dd.c_source_flags = d.c_source_flags;
            if (d.c_source_files.len > 0) dd.c_source_files = d.c_source_files;
            if (d.only_os.len > 0) dd.only_os = d.only_os;
            if (d.except_os.len > 0) dd.except_os = d.except_os;
            if (d.type == .local) dd.main = try std.fs.path.join(gpa, &.{ d.main, save.main });
            if (dd.is_for_this()) return dd;
            return null;
        },
    }
}

fn add_files_package(pkg_name: []const u8, dirs: []const []const u8, parent_name: []const u8) !u.Module {
    const destination = ".zigmod/deps/files";
    const fname = try std.mem.join(gpa, "", &.{ pkg_name, ".zig" });

    const map = &std.StringHashMap([]const u8).init(gpa);
    defer map.deinit();

    for (dirs) |dir_path| {
        var walker = try std.fs.walkPath(gpa, dir_path);
        while (try walker.next()) |p| {
            if (p.kind == .Directory) {
                continue;
            }
            const path = try std.mem.dupe(gpa, u8, p.path);
            try map.put(path[dir_path.len..], path);
        }
    }

    const rff = try (try std.fs.cwd().openDir(destination, .{})).createFile(fname, .{});
    defer rff.close();
    const w = rff.writer();
    try w.writeAll(
        \\const std = @import("std");
        \\
        \\const files = std.ComptimeStringMap([]const u8, .{
        \\
    );
    var iter = map.iterator();
    while (iter.next()) |item| {
        try w.print("    .{{ .@\"0\" = \"{}\", .@\"1\" = @embedFile(\"./../../../{}\") }},\n", .{ std.zig.fmtEscapes(item.key_ptr.*), std.zig.fmtEscapes(item.value_ptr.*) });
    }
    try w.writeAll("\n");
    try w.writeAll(
        \\});
        \\
        \\pub fn open(comptime path: []const u8) ?[]const u8 {
        \\    if (path.len == 0) return null;
        \\    if (path[0] != '/') return null;
        \\    return files.get(path);
        \\}
        \\
    );

    var d: u.Dep = .{
        .type = .local,
        .path = "files",
        .id = "",
        .name = "self/files",
        .main = fname,
        .version = "absolute",
        .yaml = null,
        .deps = &.{},
    };
    var options = CollectOptions{
        .log = false,
        .update = false,
    };
    return (try get_module_from_dep(&d, destination, parent_name, &options)).?;
}

pub fn parse_lockfile(path: []const u8) ![]const [4][]const u8 {
    const list = &std.ArrayList([4][]const u8).init(gpa);
    const max = std.math.maxInt(usize);
    const f = try std.fs.cwd().openFile(path, .{});
    const r = f.reader();
    var i: usize = 0;
    var v: usize = 1;
    while (try r.readUntilDelimiterOrEofAlloc(gpa, '\n', max)) |line| : (i += 1) {
        if (i == 0 and std.mem.eql(u8, line, "2")) {
            v = 2;
            continue;
        }
        switch (v) {
            1 => {
                var iter = std.mem.split(line, " ");
                try list.append([4][]const u8{
                    iter.next().?,
                    iter.next().?,
                    iter.next().?,
                    iter.next().?,
                });
            },
            2 => {
                var iter = std.mem.split(line, " ");
                const asdep = u.Dep{
                    .type = std.meta.stringToEnum(u.DepType, iter.next().?).?,
                    .path = iter.next().?,
                    .version = iter.next().?,
                    .id = "",
                    .name = "",
                    .main = "",
                    .yaml = null,
                    .deps = &.{},
                };
                try list.append([4][]const u8{
                    try asdep.clean_path(),
                    @tagName(asdep.type),
                    asdep.path,
                    asdep.version,
                });
            },
            else => {
                u.assert(false, "invalid zigmod.lock version: {d}", .{v});
            },
        }
    }
    return list.toOwnedSlice();
}
