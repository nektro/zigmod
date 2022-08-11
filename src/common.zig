const std = @import("std");
const string = []const u8;
const builtin = @import("builtin");
const ansi = @import("ansi");
const root = @import("root");

const zigmod = @import("./lib.zig");
const u = @import("./util/index.zig");

const build_options = if (@hasDecl(root, "build_options")) root.build_options else struct {};
const bootstrap = if (@hasDecl(build_options, "bootstrap")) build_options.bootstrap else false;

//
//

pub const CollectOptions = struct {
    log: bool,
    update: bool,
    lock: ?[]const [4]string = null,
    alloc: std.mem.Allocator,
    already_fetched: *std.ArrayList(string) = undefined,

    pub fn init(self: *CollectOptions) !void {
        self.already_fetched = try self.alloc.create(std.ArrayList(string));
        self.already_fetched.* = std.ArrayList(string).init(self.alloc);
    }
};

pub fn collect_deps_deep(cachepath: string, mdir: std.fs.Dir, options: *CollectOptions) !zigmod.Module {
    try std.fs.cwd().makePath(cachepath);

    const m = try zigmod.ModFile.from_dir(options.alloc, mdir);
    try options.init();
    var moduledeps = std.ArrayList(zigmod.Module).init(options.alloc);
    defer moduledeps.deinit();
    if (m.root_files.len > 0) {
        try moduledeps.append(try add_files_package(options.alloc, cachepath, "root", mdir, m.root_files));
    }
    try moduledeps.append(try collect_deps(cachepath, mdir, options));
    for (m.rootdeps) |*d| {
        if (try get_module_from_dep(d, cachepath, options)) |founddep| {
            try moduledeps.append(founddep);
        }
    }
    for (m.builddeps) |*d| {
        if (try get_module_from_dep(d, cachepath, options)) |founddep| {
            try moduledeps.append(founddep);
        }
    }
    return zigmod.Module{
        .is_sys_lib = false,
        .is_framework = false,
        .id = "root",
        .name = "root",
        .main = m.main,
        .deps = moduledeps.toOwnedSlice(),
        .clean_path = "",
        .yaml = m.yaml,
        .dep = null,
        .min_zig_version = m.min_zig_version,
        .vcpkg = m.vcpkg,
    };
}

pub fn collect_deps(cachepath: string, mdir: std.fs.Dir, options: *CollectOptions) anyerror!zigmod.Module {
    try std.fs.cwd().makePath(cachepath);

    const m = try zigmod.ModFile.from_dir(options.alloc, mdir);
    var moduledeps = std.ArrayList(zigmod.Module).init(options.alloc);
    defer moduledeps.deinit();
    if (m.files.len > 0) {
        try moduledeps.append(try add_files_package(options.alloc, cachepath, m.id, mdir, m.files));
    }
    for (m.deps) |*d| {
        if (try get_module_from_dep(d, cachepath, options)) |founddep| {
            try moduledeps.append(founddep);
        }
    }
    return zigmod.Module{
        .is_sys_lib = false,
        .is_framework = false,
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
        .min_zig_version = m.min_zig_version,
        .vcpkg = m.vcpkg,
    };
}

pub fn collect_pkgs(mod: zigmod.Module, list: *std.ArrayList(zigmod.Module)) anyerror!void {
    if (u.list_contains_gen(zigmod.Module, list.items, mod)) {
        return;
    }
    try list.append(mod);
    for (mod.deps) |d| {
        try collect_pkgs(d, list);
    }
}

pub fn get_modpath(cachepath: string, d: zigmod.Dep, options: *CollectOptions) !string {
    const p = try std.fs.path.join(options.alloc, &.{ cachepath, try d.clean_path(options.alloc) });
    const pv = try std.fs.path.join(options.alloc, &.{ cachepath, try d.clean_path_v(options.alloc) });

    const nocache = d.type.isLocal();
    if (!nocache and u.list_contains(options.already_fetched.items, p)) return p;
    if (!nocache and u.list_contains(options.already_fetched.items, pv)) return pv;

    if (options.log and d.type != .local) {
        std.debug.print("fetch: {s}: {s}\n", .{ @tagName(d.type), d.path });
    }
    defer {
        if (!bootstrap and options.log and d.type != .local) {
            std.debug.print("{s}", .{ansi.csi.CursorUp(1)});
            std.debug.print("{s}", .{ansi.csi.EraseInLine(0)});
        }
    }
    switch (d.type) {
        .local => {
            if (!std.mem.endsWith(u8, d.main, ".zig")) {
                return d.main;
            }
            return d.path;
        },
        .system_lib, .framework => {
            // no op
            return "";
        },
        .git => {
            if (d.version.len > 0) {
                const vers = u.parse_split(zigmod.DepType.Version.Git, "-").do(d.version) catch |e| switch (e) {
                    error.IterEmpty => unreachable,
                    error.NoMemberFound => {
                        const vtype = d.version[0..std.mem.indexOf(u8, d.version, "-").?];
                        u.fail("fetch: git: version type '{s}' is invalid.", .{vtype});
                    },
                };
                if (try u.does_folder_exist(pv)) {
                    if (vers.id == .branch) {
                        if (options.update) {
                            try d.type.update(options.alloc, pv, d.path);
                        }
                    }
                    return pv;
                }
                try d.type.pull(options.alloc, d.path, pv);
                if ((try u.run_cmd(options.alloc, pv, &.{ "git", "checkout", vers.string })) > 0) {
                    u.fail("fetch: git: {s}: {s} {s} does not exist", .{ d.path, @tagName(vers.id), vers.string });
                }
                if (builtin.os.tag != .windows and vers.id != .branch) {
                    const pvd = try std.fs.cwd().openDir(pv, .{});
                    try pvd.deleteTree(".git");
                }
                return pv;
            }
            if (!try u.does_folder_exist(p)) {
                try d.type.pull(options.alloc, d.path, p);
            } else {
                if (options.update) {
                    try d.type.update(options.alloc, p, d.path);
                }
            }
            return p;
        },
        .hg => {
            if (!try u.does_folder_exist(p)) {
                try d.type.pull(options.alloc, d.path, p);
            } else {
                if (options.update) {
                    try d.type.update(options.alloc, p, d.path);
                }
            }
            return p;
        },
        .http => {
            if (try u.does_folder_exist(pv)) {
                return pv;
            }
            const file_name = try u.last(try u.split(options.alloc, d.path, "/"));
            if (d.version.len > 0) {
                if (try u.does_folder_exist(pv)) {
                    return pv;
                }
                const file_path = try std.fs.path.join(options.alloc, &.{ pv, file_name });
                try d.type.pull(options.alloc, d.path, pv);
                if (try u.validate_hash(options.alloc, d.version, file_path)) {
                    try std.fs.cwd().deleteFile(file_path);
                    return pv;
                }
                try std.fs.cwd().deleteTree(pv);
                u.fail("{s} does not match hash {s}", .{ d.path, d.version });
                return p;
            }
            if (try u.does_folder_exist(p)) {
                try std.fs.cwd().deleteTree(p);
            }
            const file_path = try std.fs.path.resolve(options.alloc, &.{ p, file_name });
            try d.type.pull(options.alloc, d.path, p);
            try std.fs.deleteFileAbsolute(file_path);
            return p;
        },
    }
}

pub fn get_module_from_dep(d: *zigmod.Dep, cachepath: string, options: *CollectOptions) anyerror!?zigmod.Module {
    if (options.lock) |lock| {
        for (lock) |item| {
            if (std.mem.eql(u8, item[0], try d.clean_path(options.alloc))) {
                d.type = std.meta.stringToEnum(zigmod.DepType, item[1]).?;
                d.path = item[2];
                d.version = item[3];
                break;
            }
        }
    }
    if (!d.is_for_this()) return null;
    const modpath = try get_modpath(cachepath, d.*, options);
    const moddir = if (std.mem.eql(u8, modpath, "files") or modpath.len == 0) try std.fs.cwd().openDir(cachepath, .{}) else try std.fs.cwd().openDir(modpath, .{});

    const nocache = d.type.isLocal();
    if (!nocache) try options.already_fetched.append(modpath);

    switch (d.type) {
        .system_lib, .framework => {
            return zigmod.Module{
                .is_sys_lib = d.type == .system_lib,
                .is_framework = d.type == .framework,
                .id = try u.do_hash(options.alloc, std.crypto.hash.sha3.Sha3_384, d.path),
                .name = d.path,
                .only_os = d.only_os,
                .except_os = d.except_os,
                .main = "",
                .deps = &[_]zigmod.Module{},
                .clean_path = d.path,
                .yaml = null,
                .dep = d.*,
                .for_build = d.for_build,
                .min_zig_version = null,
                .vcpkg = false,
            };
        },
        else => {
            var dd = try collect_deps(cachepath, moddir, options) catch |e| switch (e) {
                error.ManifestNotFound => {
                    if (d.main.len > 0 or d.c_include_dirs.len > 0 or d.c_source_files.len > 0 or d.keep) {
                        var mod_from = try zigmod.Module.from(options.alloc, d.*, modpath, options);
                        if (d.type != .local) mod_from.clean_path = u.trim_prefix(modpath, cachepath)[1..];
                        if (mod_from.is_for_this()) return mod_from;
                        return null;
                    }
                    const moddirO = try std.fs.cwd().openDir(modpath, .{});
                    const tryname = try u.detect_pkgname(options.alloc, d.name, modpath);
                    const trymain = u.detct_mainfile(options.alloc, d.main, moddirO, tryname) catch |err| switch (err) {
                        error.CantFindMain => null,
                        else => return err,
                    };
                    if (trymain) |_| {
                        d.*.name = tryname;
                        d.*.main = trymain.?;
                        var mod_from = try zigmod.Module.from(options.alloc, d.*, cachepath, options);
                        if (d.type != .local) mod_from.clean_path = u.trim_prefix(modpath, cachepath)[1..];
                        if (mod_from.is_for_this()) return mod_from;
                        return null;
                    }
                    u.fail("no zig.mod or zigmod.yml found and no override props defined. unable to use add this dependency!", .{});
                },
                else => e,
            };
            dd.dep = d.*;
            dd.for_build = d.for_build;
            const save = dd;
            if (d.type != .local) dd.clean_path = u.trim_prefix(modpath, cachepath)[1..];
            if (dd.id.len == 0) dd.id = try u.random_string(options.alloc, 48);
            if (d.name.len > 0) dd.name = d.name;
            if (d.main.len > 0) dd.main = d.main;
            if (d.c_include_dirs.len > 0) dd.c_include_dirs = d.c_include_dirs;
            if (d.c_source_flags.len > 0) dd.c_source_flags = d.c_source_flags;
            if (d.c_source_files.len > 0) dd.c_source_files = d.c_source_files;
            if (d.only_os.len > 0) dd.only_os = d.only_os;
            if (d.except_os.len > 0) dd.except_os = d.except_os;
            if (d.type == .local) dd.main = try std.fs.path.join(options.alloc, &.{ d.main, save.main });
            if (std.mem.eql(u8, modpath, "files")) dd.clean_path = modpath;
            if (dd.is_for_this()) return dd;
            return null;
        },
    }
}

pub fn add_files_package(alloc: std.mem.Allocator, cachepath: string, pkg_name: string, mdir: std.fs.Dir, dirs: []const string) !zigmod.Module {
    const fname = try std.mem.join(alloc, "", &.{ pkg_name, ".zig" });

    var map = std.StringHashMap(string).init(alloc);
    defer map.deinit();

    for (dirs) |dir_path| {
        const dir = try mdir.openIterableDir(dir_path, .{});
        var walker = try dir.walk(alloc);
        defer walker.deinit();
        while (try walker.next()) |p| {
            if (p.kind == .Directory) {
                continue;
            }
            const path = try alloc.dupe(u8, p.path);
            try map.put(path, try std.fmt.allocPrint(alloc, "{s}/{s}", .{ dir_path, path }));
        }
    }

    const cwdpath = try std.fs.cwd().realpathAlloc(alloc, ".");
    const mpath = try mdir.realpathAlloc(alloc, ".");
    var fpath = u.trim_prefix(mpath, cwdpath);
    if (fpath.len == 0) fpath = std.fs.path.sep_str;

    var cachedir = try std.fs.cwd().openDir(cachepath, .{});
    defer cachedir.close();
    try cachedir.makePath("files");
    var destdir = try cachedir.openDir("files", .{});
    defer destdir.close();
    const rff = try destdir.createFile(fname, .{});
    defer rff.close();
    const w = rff.writer();
    try w.print("const srcpath = \"../../../{}\";\n\n", .{std.zig.fmtEscapes(fpath[1..])});
    var iter = map.iterator();
    while (iter.next()) |item| {
        try w.print("pub const @\"/{}\" = @embedFile(srcpath ++ \"/{}\");\n", .{ std.zig.fmtEscapes(item.key_ptr.*), std.zig.fmtEscapes(item.value_ptr.*) });
    }

    var d: zigmod.Dep = .{
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
        .alloc = alloc,
    };
    const filesdestpath = try std.fs.path.join(alloc, &.{ cachepath, "files" });
    return (try get_module_from_dep(&d, filesdestpath, &options)).?;
}

pub fn parse_lockfile(alloc: std.mem.Allocator, dir: std.fs.Dir) ![]const [4]string {
    var list = std.ArrayList([4]string).init(alloc);
    const max = std.math.maxInt(usize);
    if (!try u.does_file_exist(dir, "zigmod.lock")) return &[_][4]string{};
    const f = try dir.openFile("zigmod.lock", .{});
    const r = f.reader();
    var i: usize = 0;
    var v: usize = 1;
    while (try r.readUntilDelimiterOrEofAlloc(alloc, '\n', max)) |line| : (i += 1) {
        if (i == 0 and std.mem.eql(u8, line, "2")) {
            v = 2;
            continue;
        }
        switch (v) {
            1 => {
                var iter = std.mem.split(u8, line, " ");
                try list.append([4]string{
                    iter.next().?,
                    iter.next().?,
                    iter.next().?,
                    iter.next().?,
                });
            },
            2 => {
                var iter = std.mem.split(u8, line, " ");
                const asdep = zigmod.Dep{
                    .type = std.meta.stringToEnum(zigmod.DepType, iter.next().?).?,
                    .path = iter.next().?,
                    .version = iter.next().?,
                    .id = "",
                    .name = "",
                    .main = "",
                    .yaml = null,
                    .deps = &.{},
                };
                try list.append([4]string{
                    try asdep.clean_path(alloc),
                    @tagName(asdep.type),
                    asdep.path,
                    asdep.version,
                });
            },
            else => {
                u.fail("invalid zigmod.lock version: {d}", .{v});
            },
        }
    }
    return list.toOwnedSlice();
}
