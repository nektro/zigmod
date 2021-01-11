const std = @import("std");
const gpa = std.heap.c_allocator;
const fs = std.fs;

const known_folders = @import("known-folders");
const u = @import("./util/index.zig");

//
//

pub fn execute(args: [][]u8) !void {
    //
    const dir = try fs.path.join(gpa, &[_][]const u8{".zigmod", "deps"});

    const top_module = try fetch_deps(dir, "zig.mod");

    //
    const f = try fs.cwd().createFile("deps.zig", .{});
    defer f.close();

    const w = f.writer();
    try w.writeAll("const std = @import(\"std\");\n");
    try w.writeAll("const build = std.build;\n");
    try w.writeAll("\n");
    try w.print("const cache = \"{Z}\";\n", .{dir});
    try w.writeAll("\n");
    try w.print("{}\n", .{
        \\pub fn addAllTo(exe: *build.LibExeObjStep) void {
        \\    @setEvalBranchQuota(1_000_000);
        \\    for (packages) |pkg| {
        \\        exe.addPackage(pkg);
        \\    }
        \\    if (c_include_dirs.len > 0 or c_source_files.len > 0) {
        \\        exe.linkLibC();
        \\    }
        \\    for (c_include_dirs) |dir| {
        \\        exe.addIncludeDir(dir);
        \\    }
        \\    inline for (c_source_files) |fpath| {
        \\        exe.addCSourceFile(fpath[1], @field(c_source_flags, fpath[0]));
        \\    }
        \\    for (system_libs) |lib| {
        \\        exe.linkSystemLibrary(lib);
        \\    }
        \\}
        \\
        \\fn get_flags(comptime index: usize) []const u8 {
        \\    return @field(c_source_flags, _paths[index]);
        \\}
        \\
    });

    const list = &std.ArrayList(u.Module).init(gpa);
    try collect_pkgs(top_module, list);

    try w.writeAll("pub const _ids = .{\n");
    try print_ids(w, list.items);
    try w.writeAll("};\n\n");

    try w.print("pub const _paths = {}\n", .{".{"});
    try print_paths(w, list.items);
    try w.writeAll("};\n\n");

    try w.writeAll("pub const package_data = struct {\n");
    const duped = &std.ArrayList(u.Module).init(gpa);
    for (list.items) |mod| {
        if (mod.main.len > 0 and mod.clean_path.len > 0) {
            try duped.append(mod);
        }
    }
    try print_pkg_data_to(w, duped, &std.ArrayList(u.Module).init(gpa));
    try w.writeAll("};\n\n");

    try w.writeAll("pub const packages = ");
    try print_deps(w, dir, top_module, 0, true);
    try w.writeAll(";\n\n");

    try w.writeAll("pub const pkgs = ");
    try print_deps(w, dir, top_module, 0, false);
    try w.writeAll(";\n\n");

    try w.writeAll("pub const c_include_dirs = &[_][]const u8{\n");
    try print_incl_dirs_to(w, list.items);
    try w.writeAll("};\n\n");

    try w.writeAll("pub const c_source_flags = struct {\n");
    try print_csrc_flags_to(w, list.items);
    try w.writeAll("};\n\n");

    try w.writeAll("pub const c_source_files = &[_][2][]const u8{\n");
    try print_csrc_dirs_to(w, list.items);
    try w.writeAll("};\n\n");

    try w.writeAll("pub const system_libs = &[_][]const u8{\n");
    try print_sys_libs_to(w, list.items, &std.ArrayList([]const u8).init(gpa));
    try w.writeAll("};\n\n");
}

fn fetch_deps(dir: []const u8, mpath: []const u8) anyerror!u.Module {
    const m = try u.ModFile.init(gpa, mpath);
    const moduledeps = &std.ArrayList(u.Module).init(gpa);
    var moddir: []const u8 = undefined;
    for (m.deps) |d| {
        const p = try fs.path.join(gpa, &[_][]const u8{dir, try d.clean_path()});
        const pv = try fs.path.join(gpa, &[_][]const u8{dir, try d.clean_path_v()});
        u.print("fetch: {}: {}: {}", .{m.name, @tagName(d.type), d.path});
        moddir = p;
        switch (d.type) {
            .system_lib => {
                // no op
            },
            .git => blk: {
                if (!try u.does_folder_exist(p)) {
                    try d.type.pull(d.path, p);
                }
                else {
                    try d.type.update(p, d.path);
                }
                if (d.version.len > 0) {
                    const vers = u.parse_split(u.GitVersionType, "-").do(d.version) catch |e| switch (e) {
                        error.IterEmpty => unreachable,
                        error.NoMemberFound => {
                            const vtype = d.version[0..std.mem.indexOf(u8, d.version, "-").?];
                            u.assert(false, "fetch: git: version type '{}' is invalid.", .{vtype});
                            unreachable;
                        },
                    };
                    if (try u.does_folder_exist(pv)) {
                        if (vers.id == .branch) {
                            try d.type.update(p, d.path);
                        }
                        moddir = pv;
                        break :blk;
                    }
                    if ((try u.run_cmd(p, &[_][]const u8{"git", "checkout", vers.string})) > 0) {
                        u.assert(false, "fetch: git: {}: {} {} does not exist", .{d.path, @tagName(vers.id), vers.string});
                    } else {
                        _ = try u.run_cmd(p, &[_][]const u8{"git", "checkout", "-"});
                    }
                    try d.type.pull(d.path, pv);
                    _ = try u.run_cmd(pv, &[_][]const u8{"git", "checkout", vers.string});
                    if (vers.id != .branch) {
                        const pvd = try std.fs.cwd().openDir(pv, .{});
                        try pvd.deleteTree(".git");
                    }
                    moddir = pv;
                }
            },
            .hg => {
                if (!try u.does_folder_exist(p)) {
                    try d.type.pull(d.path, p);
                }
                else {
                    try d.type.update(p, d.path);
                }
            },
            .http => blk: {
                if (try u.does_folder_exist(pv)) {
                    moddir = pv;
                    break :blk;
                }
                const file_name = try u.last(try u.split(d.path, "/"));
                if (d.version.len > 0) {
                    const file_path = try std.fs.path.join(gpa, &[_][]const u8{pv, file_name});
                    try d.type.pull(d.path, pv);
                    if (try u.validate_hash(try u.last(try u.split(pv, "/")), file_path)) {
                        try std.fs.deleteFileAbsolute(file_path);
                        moddir = pv;
                        break :blk;
                    }
                    try u.rm_recv(pv);
                    u.assert(false, "{} does not match hash {}", .{d.path, d.version});
                    break :blk;
                }
                if (try u.does_folder_exist(p)) {
                    try u.rm_recv(p);
                }
                const file_path = try std.fs.path.join(gpa, &[_][]const u8{p, file_name});
                try d.type.pull(d.path, p);
                try std.fs.deleteFileAbsolute(file_path);
            },
        }
        switch (d.type) {
            .system_lib => {
                if (d.is_for_this()) try moduledeps.append(u.Module{
                    .is_sys_lib = true,
                    .id = "",
                    .name = d.path,
                    .only_os = d.only_os,
                    .except_os = d.except_os,
                    .main = "",
                    .c_include_dirs = &[_][]const u8{},
                    .c_source_flags = &[_][]const u8{},
                    .c_source_files = &[_][]const u8{},
                    .deps = &[_]u.Module{},
                    .clean_path = "",
                });
            },
            else => blk: {
                var dd = try fetch_deps(dir, try u.concat(&[_][]const u8{moddir, "/zig.mod"})) catch |e| switch (e) {
                    error.FileNotFound => {
                        if (d.main.len > 0 or d.c_include_dirs.len > 0 or d.c_source_files.len > 0) {
                            var mod_from = try u.Module.from(d);
                            mod_from.id = try u.random_string(48);
                            mod_from.clean_path = u.trim_prefix(moddir, dir)[1..];
                            if (mod_from.is_for_this()) try moduledeps.append(mod_from);
                        }
                        break :blk;
                    },
                    else => e,
                };
                dd.clean_path = u.trim_prefix(moddir, dir)[1..];

                if (dd.id.len == 0) dd.id = try u.random_string(48);
                if (d.name.len > 0) dd.name = d.name;
                if (d.main.len > 0) dd.main = d.main;
                if (d.c_include_dirs.len > 0) dd.c_include_dirs = d.c_include_dirs;
                if (d.c_source_flags.len > 0) dd.c_source_flags = d.c_source_flags;
                if (d.c_source_files.len > 0) dd.c_source_files = d.c_source_files;
                if (d.only_os.len > 0) dd.only_os = d.only_os;
                if (d.except_os.len > 0) dd.except_os = d.except_os;

                if (dd.is_for_this()) try moduledeps.append(dd);
            },
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
        .deps = moduledeps.items,
        .clean_path = "",
        .only_os = &[_][]const u8{},
        .except_os = &[_][]const u8{},
    };
}

fn print_ids(w: fs.File.Writer, list: []u.Module) !void {
    for (list) |mod| {
        if (mod.is_sys_lib) {
            continue;
        }
        if (mod.clean_path.len == 0) {
            try w.print("    \"\",\n", .{});
        } else {
            try w.print("    \"{}\",\n", .{mod.id});
        }
    }
}

fn print_paths(w: fs.File.Writer, list: []u.Module) !void {
    for (list) |mod| {
        if (mod.is_sys_lib) {
            continue;
        }
        if (mod.clean_path.len == 0) {
            try w.print("    \"\",\n", .{});
        } else {
            const s = std.fs.path.sep_str;
            try w.print("    \"{Z}{Z}{Z}\",\n", .{s, mod.clean_path, s});
        }
    }
}

fn print_deps(w: fs.File.Writer, dir: []const u8, m: u.Module, tabs: i32, array: bool) anyerror!void {
    if (m.has_no_zig_deps() and tabs > 0) {
        try w.print("null", .{});
        return;
    }
    if (array) {
        try u.print_all(w, .{"&[_]build.Pkg{"}, true);
    } else {
        try u.print_all(w, .{"struct {"}, true);
    }
    const t = "    ";
    const r = try u.repeat(t, tabs);
    for (m.deps) |d, i| {
        if (d.main.len == 0) {
            continue;
        }
        if (!array) {
            try w.print("    pub const {} = packages[{}];\n", .{d.name, i});
        }
        else {
            try w.print("    package_data._{},\n", .{d.id});
        }
    }
    try w.print("{}", .{try u.concat(&[_][]const u8{r,"}"})});
}

fn print_incl_dirs_to(w: fs.File.Writer, list: []u.Module) !void {
    for (list) |mod, i| {
        if (mod.is_sys_lib) {
            continue;
        }
        for (mod.c_include_dirs) |it| {
            if (i > 0) {
                try w.print("    cache ++ _paths[{}] ++ \"{Z}\",\n", .{i, it});
            } else {
                try w.print("    \"\",\n", .{});
            }
        }
    }
}

fn print_csrc_dirs_to(w: fs.File.Writer, list: []u.Module) !void {
    for (list) |mod, i| {
        if (mod.is_sys_lib) {
            continue;
        }
        for (mod.c_source_files) |it| {
            if (i > 0) {
                try w.print("    {}_ids[{}], cache ++ _paths[{}] ++ \"{}\"{},\n", .{"[_][]const u8{", i, i, it, "}"});
            } else {
                try w.print("    {}\"{}\", \".{}/{}\"{},\n", .{"[_][]const u8{", mod.clean_path, mod.clean_path, it, "}"});
            }
        }
    }
}

fn print_csrc_flags_to(w: fs.File.Writer, list: []u.Module) !void {
    for (list) |mod, i| {
        if (mod.is_sys_lib) {
            continue;
        }
        if (i == 0) {
            try w.print("    pub const @\"{}\" = {};\n", .{"", "&[_][]const u8{}"});
        } else {
            try w.print("    pub const @\"{}\" = {}", .{mod.id, "&[_][]const u8{"});
            for (mod.c_source_flags) |it| {
                try w.print("\"{Z}\",", .{it});
            }
            try w.print("{};\n", .{"}"});
        }
    }
}

fn print_sys_libs_to(w: fs.File.Writer, list: []u.Module, list2: *std.ArrayList([]const u8)) !void {
    for (list) |mod| {
        if (!mod.is_sys_lib) {
            continue;
        }
        try w.print("    \"{}\",\n", .{mod.name});
    }
}

fn collect_pkgs(mod: u.Module, list: *std.ArrayList(u.Module)) anyerror!void {
    //
    if (u.list_contains_gen(u.Module, list, mod)) {
        return;
    }
    try list.append(mod);
    for (mod.deps) |d| {
        try collect_pkgs(d, list);
    }
}

fn print_pkg_data_to(w: fs.File.Writer, list: *std.ArrayList(u.Module), list2: *std.ArrayList(u.Module)) anyerror!void {
    var i: usize = 0;
    while (i < list.items.len) : (i += 1) {
        const mod = list.items[i];
        if (contains_all(mod.deps, list2)) {
            try w.print("    pub const _{} = build.Pkg{{ .name = \"{}\", .path = cache ++ \"/{Z}/{}\", .dependencies = &[_]build.Pkg{{", .{mod.id, mod.name, mod.clean_path, mod.main});
            for (mod.deps) |d| {
                if (d.main.len > 0) {
                    try w.print(" _{},", .{d.id});
                }
            }
            try w.print(" }} }};\n", .{});

            try list2.append(mod);
            _ = list.orderedRemove(i);
            break;
        }
    }
    if (list.items.len > 0) {
        try print_pkg_data_to(w, list, list2);
    }
}

/// returns if all of the zig modules in needles are in haystack
fn contains_all(needles: []u.Module, haystack: *std.ArrayList(u.Module)) bool {
    for (needles) |item| {
        if (item.main.len > 0 and !u.list_contains_gen(u.Module, haystack, item)) {
            return false;
        }
    }
    return true;
}
