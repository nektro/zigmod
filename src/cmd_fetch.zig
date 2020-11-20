const std = @import("std");
const gpa = std.heap.c_allocator;

const known_folders = @import("known-folders");
const u = @import("./util/index.zig");

//
//

pub fn execute(args: [][]u8) !void {
    //
    const home = try known_folders.getPath(gpa, .home);
    const dir = try std.fmt.allocPrint(gpa, "{}{}", .{home, "/.cache/zigmod"});

    const top_module = try fetch_deps(dir, "./zig.mod");

    //
    const f = try std.fs.cwd().createFile("./deps.zig", .{});
    defer f.close();

    const w = f.writer();
    try w.print("const std = @import(\"std\");\n", .{});
    try w.print("const build = std.build;\n", .{});
    try w.print("\n", .{});
    try w.print("const home = \"{}\";\n", .{home});
    try w.print("const cache = home ++ \"/.cache/zigmod\";\n", .{});
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
        \\}
    });
    try w.print("\n", .{});
    try w.print("pub const packages = ", .{});
    try print_deps(w, dir, top_module, 0);
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
}

fn fetch_deps(dir: []const u8, mpath: []const u8) anyerror!u.Module {
    const m = try u.ModFile.init(gpa, mpath);
    const moduledeps = &std.ArrayList(u.Module).init(gpa);
    var moddir: []const u8 = undefined;
    for (m.deps) |d| {
        const p = try u.concat(&[_][]const u8{dir, "/deps/", try d.clean_path()});
        const pv = try u.concat(&[_][]const u8{dir, "/v/", try d.clean_path(), "/", d.version});
        u.print("fetch: {}: {}: {}", .{m.name, @tagName(d.type), d.path});
        moddir = p;
        switch (d.type) {
            .git => blk: {
                if (try u.does_file_exist(pv)) {
                    moddir = pv;
                    break :blk;
                }
                if (!try u.does_file_exist(p)) {
                    _ = try run_cmd(null, &[_][]const u8{"git", "clone", d.path, p});
                }
                else {
                    _ = try run_cmd(p, &[_][]const u8{"git", "fetch"});
                    _ = try run_cmd(p, &[_][]const u8{"git", "pull"});
                }
                if (d.version.len > 0) {
                    const iter = &std.mem.split(d.version, "-");
                    const v_type_s = iter.next().?;
                    if (std.meta.stringToEnum(u.GitVersionType, v_type_s)) |v_type| {
                        const ref = iter.rest();
                        if ((try run_cmd(p, &[_][]const u8{"git", "rev-parse", ref})) > 0) {
                            u.assert(false, "fetch: git: {}: {} {} does not exist", .{d.path, @tagName(v_type), ref});
                        }
                        _ = try run_cmd(null, &[_][]const u8{"git", "clone", d.path, pv});
                        _ = try run_cmd(pv, &[_][]const u8{"git", "checkout", ref});
                        const pvd = try std.fs.openDirAbsolute(pv, .{});
                        try pvd.deleteTree(".git");
                        moddir = pv;
                    }
                    else {
                        u.assert(false, "fetch: git: version type: '{}' on {} is invalid.", .{v_type_s, d.path});
                    }
                }
            },
            .hg => {
                if (!try u.does_file_exist(p)) {
                    _= try run_cmd(null, &[_][]const u8{"hg", "clone", d.path, p});
                }
                else {
                    _= try run_cmd(p, &[_][]const u8{"hg", "pull"});
                }
            },
        }
        switch (d.type) {
            else => blk: {
                var dd = try fetch_deps(dir, try u.concat(&[_][]const u8{moddir, "/zig.mod"})) catch |e| switch (e) {
                    error.FileNotFound => {
                        if (d.c_include_dirs.len > 0 or d.c_source_files.len > 0) {
                            var mod_from = try u.Module.from(d);
                            mod_from.clean_path = u.trim_prefix(moddir, dir)[1..];
                            try moduledeps.append(mod_from);
                        }
                        break :blk;
                    },
                    else => e,
                };
                dd.clean_path = u.trim_prefix(moddir, dir)[1..];

                if (d.name.len > 0) dd.name = d.name;
                if (d.main.len > 0) dd.main = d.main;
                if (d.c_include_dirs.len > 0) dd.c_include_dirs = d.c_include_dirs;
                if (d.c_source_flags.len > 0) dd.c_source_flags = d.c_source_flags;
                if (d.c_source_files.len > 0) dd.c_source_files = d.c_source_files;

                try moduledeps.append(dd);
            },
        }
    }
    return u.Module{
        .name = m.name,
        .main = m.main,
        .c_include_dirs = m.c_include_dirs,
        .c_source_flags = m.c_source_flags,
        .c_source_files = m.c_source_files,
        .deps = moduledeps.items,
        .clean_path = "",
    };
}

fn run_cmd(dir: ?[]const u8, args: []const []const u8) !u32 {
    const result = std.ChildProcess.exec(.{ .allocator = gpa, .cwd = dir, .argv = args, }) catch |e| switch(e) {
        error.FileNotFound => {
            u.assert(false, "\"{}\" command not found", .{args[0]});
            unreachable;
        },
        else => return e,
    };
    return result.term.Exited;
}

fn print_deps(w: std.fs.File.Writer, dir: []const u8, m: u.Module, tabs: i32) anyerror!void {
    if (m.deps.len == 0 and tabs > 0) {
        try w.print("null", .{});
        return;
    }
    try u.print_all(w, .{"&[_]build.Pkg{"}, true);
    const t = "    ";
    const r = try u.repeat(t, tabs);
    for (m.deps) |d| {
        if (d.main.len == 0) {
            continue;
        }
        try w.print("{}\n", .{try u.concat(&[_][]const u8{r,t,"build.Pkg{"})});
        try w.print("{}\n", .{try u.concat(&[_][]const u8{r,t,t,".name = \"",d.name,"\","})});
        try w.print("{}\n", .{try u.concat(&[_][]const u8{r,t,t,".path = cache ++ \"/",d.clean_path,"/",d.main,"\","})});
        try w.print("{}", .{try u.concat(&[_][]const u8{r,t,t,".dependencies = "})});
        try print_deps(w, dir, d, tabs+2);
        try w.print("{}\n", .{","});
        try w.print("{}\n", .{try u.concat(&[_][]const u8{r,t,"},"})});
    }
    try w.print("{}", .{try u.concat(&[_][]const u8{r,"}"})});
}

fn print_incl_dirs_to(w: std.fs.File.Writer, mod: u.Module, list: *std.ArrayList([]const u8), local: bool) anyerror!void {
    if (u.list_contains(list, mod.clean_path)) {
        return;
    }
    try list.append(mod.clean_path);
    for (mod.c_include_dirs) |it| {
        if (!local) {
            try w.print("    cache ++ \"/{}/{}\",\n", .{mod.clean_path, it});
        } else {
            try w.print("    \".{}/{}\",\n", .{mod.clean_path, it});
        }
    }
    for (mod.deps) |d| {
        try print_incl_dirs_to(w, d, list, false);
    }
}

fn print_csrc_dirs_to(w: std.fs.File.Writer, mod: u.Module, list: *std.ArrayList([]const u8), local: bool) anyerror!void {
    if (u.list_contains(list, mod.clean_path)) {
        return;
    }
    try list.append(mod.clean_path);
    for (mod.c_source_files) |it| {
        if (!local) {
            try w.print("    {}\"{}\", cache ++ \"/{}/{}\"{},\n", .{"[_][]const u8{", mod.clean_path, mod.clean_path, it, "}"});
        } else {
            try w.print("    {}\"{}\", \".{}/{}\"{},\n", .{"[_][]const u8{", mod.clean_path, mod.clean_path, it, "}"});
        }
    }
    for (mod.deps) |d| {
        try print_csrc_dirs_to(w, d, list, false);
    }
}

fn print_csrc_flags_to(w: std.fs.File.Writer, mod: u.Module, list: *std.ArrayList([]const u8), local: bool) anyerror!void {
    if (u.list_contains(list, mod.clean_path)) {
        return;
    }
    try list.append(mod.clean_path);
    if (local) {
        try w.print("    pub const @\"{}\" = {};\n", .{"", "&[_][]const u8{}"});
    }
    else {
        try w.print("    pub const @\"{}\" = {}", .{mod.clean_path, "&[_][]const u8{"});
        for (mod.c_source_flags) |it| {
            try w.print("\"{Z}\",", .{it});
        }
        try w.print("{};\n", .{"}"});
    }
    for (mod.deps) |d| {
        try print_csrc_flags_to(w, d, list, false);
    }
}
