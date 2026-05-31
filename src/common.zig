const std = @import("std");
const string = []const u8;
const builtin = @import("builtin");
const ansi = @import("ansi");
const extras = @import("extras");
const nio = @import("nio");
const nfs = @import("nfs");

const zigmod = @import("./lib.zig");
const u = @import("./util/funcs.zig");

const gpa = std.heap.c_allocator;

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

pub fn collect_deps_deep(cachepath: [:0]const u8, mdir: nfs.Dir, options: *CollectOptions) !zigmod.Module {
    try nfs.cwd().makePath(cachepath);

    const m = try zigmod.ModFile.from_dir(options.alloc, mdir, ".");
    try options.init();
    var moduledeps = std.ArrayList(zigmod.Module).init(options.alloc);
    errdefer moduledeps.deinit();
    if (m.root_files.len > 0) {
        try gen_files_package(options.alloc, cachepath, mdir, m.root_files);
    }
    try moduledeps.append(try collect_deps(cachepath, mdir, ".", .local, options));
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
        .type = .local,
        .id = zigmod.Module.ROOT,
        .name = "root",
        .main = m.main,
        .deps = try moduledeps.toOwnedSlice(),
        .clean_path = "",
        .yaml = m.yaml,
        .dep = null,
        .min_zig_version = m.min_zig_version,
    };
}

pub fn collect_deps(cachepath: [:0]const u8, mdir: nfs.Dir, mdir_path: string, dtype: zigmod.Dep.Type, options: *CollectOptions) anyerror!zigmod.Module {
    try nfs.cwd().makePath(cachepath);

    const m = try zigmod.ModFile.from_dir(options.alloc, mdir, mdir_path);
    var moduledeps = std.ArrayList(zigmod.Module).init(options.alloc);
    errdefer moduledeps.deinit();
    if (m.files.len > 0) {
        try gen_files_package(options.alloc, cachepath, mdir, m.files);
    }
    for (m.deps) |*d| {
        if (try get_module_from_dep(d, cachepath, options)) |founddep| {
            try moduledeps.append(founddep);
        }
    }
    return zigmod.Module{
        .type = dtype,
        .id = m.id,
        .name = m.name,
        .main = m.main,
        .c_include_dirs = m.c_include_dirs,
        .c_source_flags = m.c_source_flags,
        .c_source_files = m.c_source_files,
        .deps = try moduledeps.toOwnedSlice(),
        .clean_path = "../..",
        .yaml = m.yaml,
        .dep = null,
        .min_zig_version = m.min_zig_version,
    };
}

pub fn collect_pkgs(mod: zigmod.Module, list: *std.ArrayList(zigmod.Module)) anyerror!void {
    if (extras.containsAggregate(zigmod.Module, list.items, mod)) {
        return;
    }
    try list.append(mod);
    for (mod.deps) |d| {
        try collect_pkgs(d, list);
    }
}

pub fn get_modpath(cachepath: string, d: zigmod.Dep, options: *CollectOptions) ![:0]const u8 {
    const p = try std.fs.path.joinZ(options.alloc, &.{ cachepath, try d.clean_path(options.alloc) });
    const pv = try std.fs.path.joinZ(options.alloc, &.{ cachepath, try d.clean_path_v(options.alloc) });

    const nocache = d.type.isLocal();
    if (!nocache and extras.containsString(options.already_fetched.items, p)) return p;
    if (!nocache and extras.containsString(options.already_fetched.items, pv)) return pv;

    if (options.log and d.type != .local) {
        std.debug.print("fetch: {s}: {s}\n", .{ @tagName(d.type), d.path });
    }
    defer {
        if (options.log and d.type != .local) {
            std.debug.print("{s}", .{ansi.csi.CursorUp(1)});
            std.debug.print("{s}", .{ansi.csi.EraseInLine(0)});
        }
    }
    switch (d.type) {
        .local => {
            if (!std.mem.endsWith(u8, d.main, ".zig")) {
                return gpa.dupeZ(u8, d.main);
            }
            return d.path;
        },
        .system_lib, .framework => {
            // no op
            return "";
        },
        .git => {
            if (d.version.len > 0) {
                const vers = u.parse_split(zigmod.Dep.Type.Version.Git, '-').do(d.version) catch |e| switch (e) {
                    error.IterEmpty => unreachable,
                    error.NoMemberFound => {
                        const vtype = d.version[0..std.mem.indexOfScalar(u8, d.version, '-').?];
                        u.fail("fetch: git: version type '{s}' is invalid.", .{vtype});
                    },
                };
                if (try nfs.cwd().existsDir(pv)) {
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
                if (builtin.os.tag != .windows and vers.id == .commit) {
                    var pvd = try nfs.cwd().openDir(pv, .{});
                    defer pvd.close();
                    try pvd.deleteTree(".git");
                }
                var pvd = try nfs.cwd().openDir(pv, .{});
                defer pvd.close();
                try setTreeReadOnly(pvd, options.alloc);
                return pv;
            }
            if (!try nfs.cwd().existsDir(p)) {
                try d.type.pull(options.alloc, d.path, p);
            } else {
                if (options.update) {
                    try d.type.update(options.alloc, p, d.path);
                }
            }
            return p;
        },
        .hg => {
            if (!try nfs.cwd().existsDir(p)) {
                try d.type.pull(options.alloc, d.path, p);
            } else {
                if (options.update) {
                    try d.type.update(options.alloc, p, d.path);
                }
            }
            return p;
        },
        .http => {
            if (try nfs.cwd().existsDir(pv)) {
                return pv;
            }
            const file_name = u.last(try u.split(options.alloc, d.path, '/')).?;
            if (d.version.len > 0) {
                if (try nfs.cwd().existsDir(pv)) {
                    return pv;
                }
                const file_path = try std.fs.path.joinZ(options.alloc, &.{ pv, file_name });
                try d.type.pull(options.alloc, d.path, pv);
                if (try u.validate_hash(options.alloc, d.version, file_path)) {
                    try nfs.cwd().deleteFile(file_path);
                    var pvd = try nfs.cwd().openDir(pv, .{});
                    defer pvd.close();
                    try setTreeReadOnly(pvd, options.alloc);
                    return pv;
                }
                try nfs.cwd().deleteTree(pv);
                u.fail("{s} does not match hash {s}", .{ d.path, d.version });
                return p;
            }
            if (try nfs.cwd().existsDir(p)) {
                try nfs.cwd().deleteTree(p);
            }
            const file_path_s = try std.fs.path.resolve(options.alloc, &.{ p, file_name });
            defer gpa.free(file_path_s);
            const file_path = try gpa.dupeZ(u8, file_path_s);
            try d.type.pull(options.alloc, d.path, p);
            try nfs.cwd().deleteFile(file_path);
            return p;
        },
        .pijul => {
            if (d.version.len > 0) {
                const vers = u.parse_split(zigmod.DepType.Version.Pijul, "-").do(d.version) catch |e| switch (e) {
                    error.IterEmpty => unreachable,
                    error.NoMemberFound => {
                        const vtype = d.version[0..std.mem.indexOf(u8, d.version, "-").?];
                        u.fail("pijul: version type '{s}' is invalid.", .{vtype});
                    },
                };
                // this version is already pulled
                if (try u.does_folder_exist(pv)) {
                    if (vers.id == .channel) {
                        if (options.update) {
                            // This does not work with pijul, have to use explicit channel name
                            // try d.type.update(options.alloc, pv, d.path);
                            if ((try u.run_cmd(options.alloc, pv, &.{ "pijul", "pull", "--all", "--from-channel", vers.string })) > 0) {
                                u.fail("pijul pull --from-channel {s}: did not succeed", .{vers.string});
                            }
                        }
                    }
                    return pv;
                }
                // version has not pulled yet
                if ((try u.run_cmd(options.alloc, null, &.{ "pijul", "clone", "--channel", vers.string, d.path, pv })) > 0) {
                    u.fail("pijul clone --channel: {s}: {s} {s} does not exist", .{ d.path, @tagName(vers.id), vers.string });
                }
                return pv;
            }

            // no version string
            if (!try u.does_folder_exist(p)) {
                try d.type.pull(options.alloc, d.path, p);
            } else {
                if (options.update) {
                    try d.type.update(options.alloc, p, d.path);
                }
            }
            return p;
        },
    }
}

pub fn get_module_from_dep(d: *zigmod.Dep, cachepath: [:0]const u8, options: *CollectOptions) anyerror!?zigmod.Module {
    if (options.lock) |lock| {
        for (lock) |item| {
            if (std.mem.eql(u8, item[0], try d.clean_path(options.alloc))) {
                d.type = std.meta.stringToEnum(zigmod.Dep.Type, item[1]).?;
                d.path = try gpa.dupeZ(u8, item[2]);
                d.version = item[3];
                break;
            }
        }
    }
    if (!d.is_for_this()) return null;
    const modpath = try get_modpath(cachepath, d.*, options);
    const moddir = if (modpath.len == 0) try nfs.cwd().openDir(cachepath, .{}) else try nfs.cwd().openDir(modpath, .{});

    const nocache = d.type.isLocal();
    if (!nocache) try options.already_fetched.append(modpath);

    switch (d.type) {
        .system_lib, .framework => {
            return zigmod.Module{
                .type = d.type,
                .id = try u.do_hash(std.crypto.hash.sha3.Shake(96), d.path),
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
            };
        },
        else => {
            var dd = collect_deps(cachepath, moddir, modpath, d.type, options) catch |e| switch (e) {
                error.ManifestNotFound => {
                    if (d.main.len > 0 or d.c_include_dirs.len > 0 or d.c_source_files.len > 0 or d.keep) {
                        var mod_from = try zigmod.Module.from(options.alloc, d.*, cachepath, options);
                        if (d.type != .local) {
                            const new_clean_path = extras.trimPrefix(modpath, cachepath)[1..];
                            mod_from.clean_path = new_clean_path.ptr[0..new_clean_path.len :0];
                        }
                        if (mod_from.is_for_this()) return mod_from;
                        return null;
                    }
                    const moddirO = try nfs.cwd().openDir(modpath, .{});
                    const tryname = try u.detect_pkgname(options.alloc, d.name, modpath);
                    const trymain = u.detct_mainfile(options.alloc, d.main, moddirO, tryname) catch |err| switch (err) {
                        error.CantFindMain => null,
                        else => |ee| return ee,
                    };
                    if (trymain) |_| {
                        d.*.name = tryname;
                        d.*.main = trymain.?;
                        var mod_from = try zigmod.Module.from(options.alloc, d.*, cachepath, options);
                        if (d.type != .local) mod_from.clean_path = extras.trimPrefix(modpath, cachepath)[1..][0.. :0];
                        if (mod_from.is_for_this()) return mod_from;
                        return null;
                    }
                    u.fail("no zig.mod or zigmod.yml found and no override props defined. unable to use add this dependency!", .{});
                },
                else => |ee| return ee,
            };
            dd.dep = d.*;
            dd.for_build = d.for_build;
            const save = dd;
            if (d.type != .local) {
                const new_clean_path = extras.trimPrefix(modpath, cachepath)[1..];
                dd.clean_path = new_clean_path.ptr[0..new_clean_path.len :0];
            }
            if (std.mem.eql(u8, &dd.id, &zigmod.Dep.EMPTY)) dd.id = u.random_string(48);
            if (d.name.len > 0) dd.name = d.name;
            if (d.main.len > 0) dd.main = d.main;
            if (d.c_include_dirs.len > 0) dd.c_include_dirs = d.c_include_dirs;
            if (d.c_source_flags.len > 0) dd.c_source_flags = d.c_source_flags;
            if (d.c_source_files.len > 0) dd.c_source_files = d.c_source_files;
            if (d.only_os.len > 0) dd.only_os = d.only_os;
            if (d.except_os.len > 0) dd.except_os = d.except_os;
            if (d.type == .local) dd.main = try std.fs.path.join(options.alloc, &.{ d.main, save.main });
            if (dd.is_for_this()) return dd;
            return null;
        },
    }
}

pub fn gen_files_package(alloc: std.mem.Allocator, cachepath: string, mdir: nfs.Dir, dirs: []const string) !void {
    var map = std.StringHashMap(string).init(alloc);
    defer map.deinit();

    for (dirs) |dir_path| {
        const dir = try mdir.openDirC(dir_path, .{});
        var walker = try dir.walk(alloc);
        defer walker.deinit();
        while (try walker.next()) |p| {
            if (p.type == .DIR) {
                continue;
            }
            const path = try alloc.dupe(u8, p.path);
            try map.put(path, try nio.fmt.allocPrint(alloc, "{s}/{s}", .{ dir_path, path }));
        }
    }

    var dpath: string = try mdir.realpathAlloc(alloc, ".");
    const is_not_root = std.mem.indexOf(u8, dpath, cachepath);
    dpath = if (is_not_root) |idx| dpath[idx..] else "../..";

    const fname = "files.zig";
    const destdir = mdir;
    const rff = try destdir.createFile(fname, .{});
    defer rff.close();
    var iter = map.iterator();
    while (iter.next()) |item| {
        try rff.print("pub const @\"/{}\" = @embedFile(\"{}\");\n", .{ u.altStringEscape(item.key_ptr.*), u.altStringEscape(item.value_ptr.*) });
    }
}

pub fn parse_lockfile(alloc: std.mem.Allocator, dir: nfs.Dir) ![]const [4]string {
    var list = std.ArrayList([4]string).init(alloc);
    const max = std.math.maxInt(usize);
    if (!try dir.exists("zigmod.lock")) return &[_][4]string{};
    var f = try dir.openFile("zigmod.lock", .{});
    defer f.close();
    var r = nio.BufferedReader(4096, nfs.File).init(f);
    var i: usize = 0;
    var v: usize = 1;
    while (try r.readUntilDelimiterOrEofAlloc(alloc, '\n', max)) |line_full| : (i += 1) {
        const line = line_full[0 .. line_full.len - 1];
        if (i == 0 and std.mem.eql(u8, line, "2")) {
            v = 2;
            continue;
        }
        switch (v) {
            1 => {
                var iter = std.mem.splitScalar(u8, line, ' ');
                try list.append([4]string{
                    iter.next().?,
                    iter.next().?,
                    iter.next().?,
                    iter.next().?,
                });
            },
            2 => {
                var iter = std.mem.splitScalar(u8, line, ' ');
                const asdep = zigmod.Dep{
                    .type = std.meta.stringToEnum(zigmod.Dep.Type, iter.next().?).?,
                    .path = try gpa.dupeZ(u8, iter.next().?),
                    .version = iter.next().?,
                    .id = zigmod.Dep.EMPTY,
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

fn setTreeReadOnly(dir: nfs.Dir, alloc: std.mem.Allocator) !void {
    var walker = try dir.walk(alloc);
    defer walker.deinit();

    while (try walker.next()) |entry| {
        if (entry.type != .REG) continue;
        var file = try dir.openFile(entry.path, .{});
        defer file.close();
        const stat = try file.stat();
        var mode = stat.mode;
        mode |= ~@as(nfs.File.Mode, 0o222);
        try file.chmod(mode);
    }
}
