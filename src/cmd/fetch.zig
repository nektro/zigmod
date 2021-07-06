const std = @import("std");
const gpa = std.heap.c_allocator;

const known_folders = @import("known-folders");

const u = @import("./../util/index.zig");
const common = @import("./../common.zig");

//
//

pub fn execute(args: [][]u8) !void {
    //
    const dir = try std.fs.path.join(gpa, &.{ ".zigmod", "deps" });
    const should_update = !(args.len >= 1 and std.mem.eql(u8, args[0], "--no-update"));

    const top_module = try common.collect_deps_deep(dir, "zig.mod", .{
        .log = should_update,
        .update = should_update,
    });

    //
    const f = try std.fs.cwd().createFile("deps.zig", .{});
    defer f.close();

    const w = f.writer();
    try w.writeAll("const std = @import(\"std\");\n");
    try w.writeAll("const Pkg = std.build.Pkg;\n");
    try w.writeAll("const FileSource = std.build.FileSource;\n");
    try w.writeAll("\n");
    try w.print("pub const cache = \"{}\";\n", .{std.zig.fmtEscapes(dir)});
    try w.writeAll("\n");
    try w.print("{s}\n", .{
        \\pub fn addAllTo(exe: *std.build.LibExeObjStep) void {
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
    try common.collect_pkgs(top_module, list);

    try w.writeAll("pub const _ids = .{\n");
    try print_ids(w, list.items);
    try w.writeAll("};\n\n");

    try w.print("pub const _paths = {s}\n", .{".{"});
    try print_paths(w, list.items);
    try w.writeAll("};\n\n");

    try w.writeAll("pub const package_data = struct {\n");
    const duped = &std.ArrayList(u.Module).init(gpa);
    for (list.items) |mod| {
        if (std.mem.eql(u8, mod.id, "root")) {
            continue;
        }
        if (mod.main.len == 0) {
            continue;
        }
        try duped.append(mod);
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

    //

    try create_lockfile(list, dir);
}

fn create_lockfile(list: *std.ArrayList(u.Module), dir: []const u8) !void {
    const fl = try std.fs.cwd().createFile("zigmod.lock", .{});
    defer fl.close();

    const wl = fl.writer();
    for (list.items) |m| {
        if (m.dep) |md| {
            const mpath = try std.fs.path.join(gpa, &.{ dir, m.clean_path });
            const version = if (md.version.len > 0) md.version else (try md.type.exact_version(mpath))[0..14];
            try wl.print("{s} {s} {s} {s}\n", .{ m.id, @tagName(md.type), md.path, version });
        }
    }
}

fn print_ids(w: std.fs.File.Writer, list: []u.Module) !void {
    for (list) |mod| {
        if (std.mem.eql(u8, mod.id, "root")) {
            continue;
        }
        if (mod.is_sys_lib) {
            continue;
        }
        try w.print("    \"{s}\",\n", .{mod.id[0..12]});
    }
}

fn print_paths(w: std.fs.File.Writer, list: []u.Module) !void {
    for (list) |mod| {
        if (std.mem.eql(u8, mod.id, "root")) {
            continue;
        }
        if (mod.is_sys_lib) {
            continue;
        }
        if (mod.clean_path.len == 0) {
            try w.print("    \"\",\n", .{});
        } else {
            const s = std.fs.path.sep_str;
            try w.print("    \"{}{}{}\",\n", .{ std.zig.fmtEscapes(s), std.zig.fmtEscapes(mod.clean_path), std.zig.fmtEscapes(s) });
        }
    }
}

fn print_deps(w: std.fs.File.Writer, dir: []const u8, m: u.Module, tabs: i32, array: bool) !void {
    _ = dir;

    if (m.has_no_zig_deps() and tabs > 0) {
        try w.print("null", .{});
        return;
    }
    if (array) {
        try u.print_all(w, .{"&[_]Pkg{"}, true);
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
            const r1 = try std.mem.replaceOwned(u8, gpa, d.name, "-", "_");
            const r2 = try std.mem.replaceOwned(u8, gpa, r1, "/", "_");
            try w.print("    pub const {s} = packages[{}];\n", .{ r2, i });
        } else {
            try w.print("    package_data._{s},\n", .{d.id[0..12]});
        }
    }
    try w.print("{s}", .{try u.concat(&.{ r, "}" })});
}

fn print_incl_dirs_to(w: std.fs.File.Writer, list: []u.Module) !void {
    for (list) |mod, i| {
        if (mod.is_sys_lib) {
            continue;
        }
        for (mod.c_include_dirs) |it| {
            if (i > 0) {
                try w.print("    cache ++ _paths[{}] ++ \"{}\",\n", .{ i - 1, std.zig.fmtEscapes(it) });
            } else {
                try w.print("    \"{}\",\n", .{std.zig.fmtEscapes(it)});
            }
        }
    }
}

fn print_csrc_dirs_to(w: std.fs.File.Writer, list: []u.Module) !void {
    for (list) |mod, i| {
        if (mod.is_sys_lib) {
            continue;
        }
        for (mod.c_source_files) |it| {
            if (i > 0) {
                try w.print("    {s}_ids[{}], cache ++ _paths[{}] ++ \"{s}\"{s},\n", .{ "[_][]const u8{", i - 1, i - 1, it, "}" });
            } else {
                try w.print("    {s}_ids[{}], \".{}/{s}\"{s},\n", .{ "[_][]const u8{", i - 1, std.zig.fmtEscapes(mod.clean_path), it, "}" });
            }
        }
    }
}

fn print_csrc_flags_to(w: std.fs.File.Writer, list: []u.Module) !void {
    for (list) |mod| {
        if (mod.is_sys_lib) {
            continue;
        }
        if (mod.c_source_flags.len == 0 and mod.c_source_files.len == 0) {
            continue;
        }
        try w.print("    pub const @\"{s}\" = {s}", .{ mod.id[0..12], "&.{" });
        for (mod.c_source_flags) |it| {
            try w.print("\"{}\",", .{std.zig.fmtEscapes(it)});
        }
        try w.print("{s};\n", .{"}"});
    }
}

fn print_sys_libs_to(w: std.fs.File.Writer, list: []u.Module, list2: *std.ArrayList([]const u8)) !void {
    _ = list2;

    for (list) |mod| {
        if (!mod.is_sys_lib) {
            continue;
        }
        try w.print("    \"{s}\",\n", .{mod.name});
    }
}

fn print_pkg_data_to(w: std.fs.File.Writer, notdone: *std.ArrayList(u.Module), done: *std.ArrayList(u.Module)) !void {
    var len: usize = notdone.items.len;
    while (notdone.items.len > 0) {
        for (notdone.items) |mod, i| {
            if (contains_all(mod.deps, done.items)) {
                try w.print("    pub const _{s} = Pkg{{ .name = \"{s}\", .path = FileSource{{ .path = cache ++ \"/{}/{s}\" }}, .dependencies = &[_]Pkg{{", .{ mod.id[0..12], mod.name, std.zig.fmtEscapes(mod.clean_path), mod.main });
                for (mod.deps) |d| {
                    if (d.main.len > 0) {
                        try w.print(" _{s},", .{d.id[0..12]});
                    }
                }
                try w.print(" }} }};\n", .{});

                try done.append(mod);
                _ = notdone.orderedRemove(i);
                break;
            }
        }
        if (notdone.items.len == len) {
            u.assert(false, "notdone still has {d} items", .{len});
        }
        len = notdone.items.len;
    }
}

/// returns if all of the zig modules in needles are in haystack
fn contains_all(needles: []u.Module, haystack: []const u.Module) bool {
    for (needles) |item| {
        if (item.main.len > 0 and !u.list_contains_gen(u.Module, haystack, item)) {
            return false;
        }
    }
    return true;
}
