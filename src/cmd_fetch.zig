const std = @import("std");
const gpa = std.heap.c_allocator;
const fs = std.fs;

const known_folders = @import("known-folders");
const u = @import("./util/index.zig");

//
//

pub fn execute(args: [][]u8) !void {
    //
    const home = try known_folders.getPath(gpa, .home);
    const dir = try fs.path.join(gpa, &[_][]const u8{home.?, ".cache", "zigmod", "deps"});

    const top_module = try fetch_deps(dir, "zig.mod");

    //
    const f = try fs.cwd().createFile("deps.zig", .{});
    defer f.close();

    const w = f.writer();
    try w.print("const std = @import(\"std\");\n", .{});
    try w.print("const build = std.build;\n", .{});
    try w.print("\n", .{});
    try w.print("const cache = \"{Z}\";\n", .{dir});
    try w.print("\n", .{});
    try w.print("{}\n", .{
        \\pub fn addAllTo(exe: *build.LibExeObjStep) void {
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
    });
    try w.print("\n", .{});
    try w.print("pub const _ids = {}\n", .{".{"});
    try print_ids(w, top_module, &std.ArrayList([]const u8).init(gpa));
    try w.print("{}\n", .{"};"});
    try w.print("\n", .{});
    try w.print("pub const _paths = {}\n", .{".{"});
    try print_paths(w, top_module, &std.ArrayList([]const u8).init(gpa));
    try w.print("{}\n", .{"};"});
    try w.print("\n", .{});
    try w.print("pub const packages = ", .{});
    try print_deps(w, dir, top_module, 0, true);
    try w.print(";\n", .{});
    try w.print("\n", .{});
    try w.print("pub const pkgs = ", .{});
    try print_deps(w, dir, top_module, 0, false);
    try w.print(";\n", .{});
    try w.print("\n", .{});
    try w.print("{}\n", .{"pub const c_include_dirs = &[_][]const u8{"});
    try print_incl_dirs_to(w, top_module, &std.ArrayList([]const u8).init(gpa), true);
    try w.print("{};\n", .{"}"});
    try w.print("\n", .{});
    try w.print("{}\n", .{"pub const c_source_flags = struct {"});
    try print_csrc_flags_to(w, top_module, &std.ArrayList([]const u8).init(gpa), true);
    try w.print("{};\n", .{"}"});
    try w.print("\n", .{});
    try w.print("{}\n", .{"pub const c_source_files = &[_][2][]const u8{"});
    try print_csrc_dirs_to(w, top_module, &std.ArrayList([]const u8).init(gpa), true);
    try w.print("{};\n", .{"}"});
    try w.print("\n", .{});
    try w.print("{}\n", .{"pub const system_libs = &[_][]const u8{"});
    try print_sys_libs_to(w, top_module, &std.ArrayList([]const u8).init(gpa), &std.ArrayList([]const u8).init(gpa));
    try w.print("{};\n", .{"}"});
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
                        const pvd = try u.open_dir_absolute(pv);
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

fn print_ids(w: fs.File.Writer, mod: u.Module, list: *std.ArrayList([]const u8)) anyerror!void {
    if (u.list_contains(list.items, mod.clean_path)) {
        return;
    }
    try list.append(mod.clean_path);
    //
    if (mod.clean_path.len == 0) {
        try w.print("    \"\",\n", .{});
    } else {
        try w.print("    \"{}\",\n", .{mod.id});
    }
    //
    for (mod.deps) |d| {
        if (d.is_sys_lib) continue;
        try print_ids(w, d, list);
    }
}

fn print_paths(w: fs.File.Writer, mod: u.Module, list: *std.ArrayList([]const u8)) anyerror!void {
    if (u.list_contains(list.items, mod.clean_path)) {
        return;
    }
    try list.append(mod.clean_path);
    //
    if (mod.clean_path.len == 0) {
        try w.print("    \"\",\n", .{});
    } else {
        const s = std.fs.path.sep_str;
        try w.print("    \"{Z}{Z}{Z}\",\n", .{s, mod.clean_path, s});
    }
    //
    for (mod.deps) |d| {
        if (d.is_sys_lib) continue;
        try print_paths(w, d, list);
    }
}

fn print_deps(w: fs.File.Writer, dir: []const u8, m: u.Module, tabs: i32, array: bool) anyerror!void {
    if (m.deps.len == 0 and tabs > 0) {
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
    var c: usize = 0;
    for (m.deps) |d| {
        if (d.main.len == 0) {
            continue;
        }
        c += 1;
        if (!array) {
            try w.print("    pub const {} = packages[{}];\n", .{d.name, c-1});
            continue;
        }
        try w.print("{}\n", .{try u.concat(&[_][]const u8{r,t,"build.Pkg{"})});
        try w.print("{}\n", .{try u.concat(&[_][]const u8{r,t,t,".name = \"",d.name,"\","})});
        try w.print("{}\n", .{try u.concat(&[_][]const u8{r,t,t,".path = cache ++ \"/",d.clean_path,"/",d.main,"\","})});
        try w.print("{}", .{try u.concat(&[_][]const u8{r,t,t,".dependencies = "})});
        try print_deps(w, dir, d, tabs+2, array);
        try w.print("{}\n", .{","});
        try w.print("{}\n", .{try u.concat(&[_][]const u8{r,t,"},"})});
    }
    try w.print("{}", .{try u.concat(&[_][]const u8{r,"}"})});
}

fn print_incl_dirs_to(w: fs.File.Writer, mod: u.Module, list: *std.ArrayList([]const u8), local: bool) anyerror!void {
    if (u.list_contains(list.items, mod.clean_path)) {
        return;
    }
    try list.append(mod.clean_path);
    for (mod.c_include_dirs) |it| {
        if (!local) {
            try w.print("    cache ++ _paths[{}] ++ \"{Z}\",\n", .{list.items.len-1, it});
        } else {
            // try w.print("    ,\n", .{mod.clean_path, it});
        }
    }
    for (mod.deps) |d| {
        if (d.is_sys_lib) continue;
        try print_incl_dirs_to(w, d, list, false);
    }
}

fn print_csrc_dirs_to(w: fs.File.Writer, mod: u.Module, list: *std.ArrayList([]const u8), local: bool) anyerror!void {
    if (u.list_contains(list.items, mod.clean_path)) {
        return;
    }
    try list.append(mod.clean_path);
    for (mod.c_source_files) |it| {
        if (!local) {
            try w.print("    {}_ids[{}], cache ++ _paths[{}] ++ \"{}\"{},\n", .{"[_][]const u8{", list.items.len-1, list.items.len-1, it, "}"});
        } else {
            try w.print("    {}\"{}\", \".{}/{}\"{},\n", .{"[_][]const u8{", mod.clean_path, mod.clean_path, it, "}"});
        }
    }
    for (mod.deps) |d| {
        if (d.is_sys_lib) continue;
        try print_csrc_dirs_to(w, d, list, false);
    }
}

fn print_csrc_flags_to(w: fs.File.Writer, mod: u.Module, list: *std.ArrayList([]const u8), local: bool) anyerror!void {
    if (u.list_contains(list.items, mod.clean_path)) {
        return;
    }
    try list.append(mod.clean_path);
    if (local) {
        try w.print("    pub const @\"{}\" = {};\n", .{"", "&[_][]const u8{}"});
    }
    else {
        try w.print("    pub const @\"{}\" = {}", .{mod.id, "&[_][]const u8{"});
        for (mod.c_source_flags) |it| {
            try w.print("\"{Z}\",", .{it});
        }
        try w.print("{};\n", .{"}"});
    }
    for (mod.deps) |d| {
        if (d.is_sys_lib) continue;
        try print_csrc_flags_to(w, d, list, false);
    }
}

fn print_sys_libs_to(w: fs.File.Writer, mod: u.Module, list: *std.ArrayList([]const u8), list2: *std.ArrayList([]const u8)) anyerror!void {
    if (u.list_contains(list.items, mod.clean_path)) {
        return;
    }
    try list.append(mod.clean_path);
    //
    for (mod.deps) |d| {
        if (!d.is_sys_lib) continue;
        //
        if (!u.list_contains(list2.items, d.name)) {
            try w.print("    \"{}\",\n", .{d.name});
            try list2.append(d.name);
        }
        //
        try print_sys_libs_to(w, d, list, list2);
    }
}
