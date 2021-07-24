const std = @import("std");
const gpa = std.heap.c_allocator;


const u = @import("./../util/index.zig");
const common = @import("./../common.zig");

const root = @import("root");
const build_options = if (@hasDecl(root, "build_options")) root.build_options else struct {};
const bootstrap = if (@hasDecl(build_options, "bootstrap")) build_options.bootstrap else false;

//
//

pub fn execute(args: [][]u8) !void {
    //
    const dir = try std.fs.path.join(gpa, &.{ ".zigmod", "deps" });
    const should_update = !(args.len >= 1 and std.mem.eql(u8, args[0], "--no-update"));

    var options = common.CollectOptions{
        .log = should_update,
        .update = should_update,
    };
    const top_module = try common.collect_deps_deep(dir, "zig.mod", &options);

    const list = &std.ArrayList(u.Module).init(gpa);
    try common.collect_pkgs(top_module, list);

    try create_depszig(dir, top_module, list);

    if (bootstrap) return;

    try create_lockfile(list, dir);
}

pub fn create_depszig(dir: []const u8, top_module: u.Module, list: *std.ArrayList(u.Module)) !void {
    const f = try std.fs.cwd().createFile("deps.zig", .{});
    defer f.close();

    const w = f.writer();
    try w.writeAll("const std = @import(\"std\");\n");
    try w.writeAll("const Pkg = std.build.Pkg;\n");
    try w.writeAll("const string = []const u8;\n");
    try w.writeAll("\n");
    try w.print("pub const cache = \"{}\";\n", .{std.zig.fmtEscapes(dir)});
    try w.writeAll("\n");
    try w.print("{s}\n", .{
        \\pub fn addAllTo(exe: *std.build.LibExeObjStep) void {
        \\    @setEvalBranchQuota(1_000_000);
        \\    for (packages) |pkg| {
        \\        exe.addPackage(pkg.pkg.?);
        \\    }
        \\    inline for (std.meta.declarations(package_data)) |decl| {
        \\        const pkg = @as(Package, @field(package_data, decl.name));
        \\        var llc = false;
        \\        inline for (pkg.system_libs) |item| {
        \\            exe.linkSystemLibrary(item);
        \\            llc = true;
        \\        }
        \\        inline for (pkg.c_include_dirs) |item| {
        \\            exe.addIncludeDir(@field(dirs, decl.name) ++ "/" ++ item);
        \\            llc = true;
        \\        }
        \\        inline for (pkg.c_source_files) |item| {
        \\            exe.addCSourceFile(@field(dirs, decl.name) ++ "/" ++ item, pkg.c_source_flags);
        \\            llc = true;
        \\        }
        \\        if (llc) {
        \\            exe.linkLibC();
        \\        }
        \\    }
        \\}
        \\
        \\pub const Package = struct {
        \\    directory: string,
        \\    pkg: ?Pkg = null,
        \\    c_include_dirs: []const string = &.{},
        \\    c_source_files: []const string = &.{},
        \\    c_source_flags: []const string = &.{},
        \\    system_libs: []const string = &.{},
        \\};
        \\
    });

    try w.writeAll("const dirs = struct {\n");
    try print_dirs(w, list.items);
    try w.writeAll("};\n\n");

    try w.writeAll("pub const package_data = struct {\n");
    const duped = &std.ArrayList(u.Module).init(gpa);
    for (list.items) |mod| {
        if (mod.is_sys_lib) {
            continue;
        }
        try duped.append(mod);
    }
    try print_pkg_data_to(w, duped, &std.ArrayList(u.Module).init(gpa));
    try w.writeAll("};\n\n");

    try w.writeAll("pub const packages = ");
    try print_deps(w, top_module);
    try w.writeAll(";\n\n");

    try w.writeAll("pub const pkgs = ");
    try print_pkgs(w, top_module);
    try w.writeAll(";\n\n");

    try w.writeAll("pub const imports = struct {\n");
    try print_imports(w, top_module, dir);
    try w.writeAll("};\n\n");
}

fn create_lockfile(list: *std.ArrayList(u.Module), dir: []const u8) !void {
    const fl = try std.fs.cwd().createFile("zigmod.lock", .{});
    defer fl.close();

    const wl = fl.writer();
    try wl.writeAll("2\n");
    for (list.items) |m| {
        if (m.dep) |md| {
            if (md.type == .local) {
                continue;
            }
            if (md.type == .system_lib) continue;
            const mpath = try std.fs.path.join(gpa, &.{ dir, m.clean_path });
            const version = if (md.version.len > 0) md.version else (try md.type.exact_version(mpath));
            try wl.print("{s} {s} {s}\n", .{ @tagName(md.type), md.path, version });
        }
    }
}

fn print_dirs(w: std.fs.File.Writer, list: []const u.Module) !void {
    for (list) |mod| {
        if (mod.is_sys_lib) continue;
        if (std.mem.eql(u8, mod.id, "root")) {
            try w.print("    pub const _root = \"\";\n", .{});
            continue;
        }
        try w.print("    pub const _{s} = cache ++ \"/{}\";\n", .{ mod.short_id(), std.zig.fmtEscapes(mod.clean_path) });
    }
}

fn print_deps(w: std.fs.File.Writer, m: u.Module) !void {
    try u.print_all(w, .{"&[_]Package{"}, true);
    for (m.deps) |d| {
        if (d.main.len == 0) {
            continue;
        }
        try w.print("    package_data._{s},\n", .{d.id[0..12]});
    }
    try w.writeAll("}");
}

fn print_pkg_data_to(w: std.fs.File.Writer, notdone: *std.ArrayList(u.Module), done: *std.ArrayList(u.Module)) !void {
    var len: usize = notdone.items.len;
    while (notdone.items.len > 0) {
        for (notdone.items) |mod, i| {
            if (contains_all(mod.deps, done.items)) {
                try w.print(
                    \\    pub const _{s} = Package{{
                    \\        .directory = dirs._{s},
                    \\
                , .{
                    mod.short_id(),
                    mod.short_id(),
                });
                if (mod.main.len > 0 and !std.mem.eql(u8, mod.id, "root")) {
                    try w.print(
                        \\        .pkg = Pkg{{ .name = "{s}", .path = .{{ .path = dirs._{s} ++ "/{s}" }}, .dependencies =
                    , .{
                        mod.name,
                        mod.short_id(),
                        mod.main,
                    });
                    if (mod.has_no_zig_deps()) {
                        try w.writeAll(" null },\n");
                    } else {
                        try w.writeAll(" &.{");
                        for (mod.deps) |moddep, j| {
                            if (moddep.main.len == 0) continue;
                            try w.print(" _{s}.pkg.?", .{moddep.id[0..12]});
                            if (j != mod.deps.len - 1) try w.writeAll(",");
                        }
                        try w.writeAll(" } },\n");
                    }
                }
                if (mod.c_include_dirs.len > 0) {
                    try w.writeAll("        .c_include_dirs = &.{");
                    for (mod.c_include_dirs) |item, j| {
                        try w.print(" \"{}\"", .{std.zig.fmtEscapes(item)});
                        if (j != mod.c_include_dirs.len - 1) try w.writeAll(",");
                    }
                    try w.writeAll(" },\n");
                }
                if (mod.c_source_files.len > 0) {
                    try w.writeAll("        .c_source_files = &.{");
                    for (mod.c_source_files) |item, j| {
                        try w.print(" \"{}\"", .{std.zig.fmtEscapes(item)});
                        if (j != mod.c_source_files.len - 1) try w.writeAll(",");
                    }
                    try w.writeAll(" },\n");
                }
                if (mod.c_source_flags.len > 0) {
                    try w.writeAll("        .c_source_flags = &.{");
                    for (mod.c_source_flags) |item, j| {
                        try w.print(" \"{}\"", .{std.zig.fmtEscapes(item)});
                        if (j != mod.c_source_flags.len - 1) try w.writeAll(",");
                    }
                    try w.writeAll(" },\n");
                }
                if (mod.has_syslib_deps()) {
                    try w.writeAll("        .system_libs = &.{");
                    for (mod.deps) |item, j| {
                        if (!item.is_sys_lib) continue;
                        try w.print(" \"{}\"", .{std.zig.fmtEscapes(item.name)});
                        if (j != mod.deps.len - 1) try w.writeAll(",");
                    }
                    try w.writeAll(" },\n");
                }
                try w.writeAll("    };\n\n");

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

fn print_pkgs(w: std.fs.File.Writer, m: u.Module) !void {
    try w.writeAll("struct {\n");
    for (m.deps) |d| {
        if (d.main.len == 0) {
            continue;
        }
        const r1 = try std.mem.replaceOwned(u8, gpa, d.name, "-", "_");
        const r2 = try std.mem.replaceOwned(u8, gpa, r1, "/", "_");
        try w.print("    pub const {s} = package_data._{s};\n", .{ r2, d.id[0..12] });
    }
    try w.writeAll("}");
}

fn print_imports(w: std.fs.File.Writer, m: u.Module, dir: []const u8) !void {
    for (m.deps) |d| {
        if (d.main.len == 0) {
            continue;
        }
        const r1 = try std.mem.replaceOwned(u8, gpa, d.name, "-", "_");
        const r2 = try std.mem.replaceOwned(u8, gpa, r1, "/", "_");
        try w.print("    pub const {s} = @import(\"{s}/{}/{s}\");\n", .{ r2, dir, std.zig.fmtEscapes(d.clean_path), d.main });
    }
}
