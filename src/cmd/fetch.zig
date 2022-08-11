const std = @import("std");
const string = []const u8;
const ansi = @import("ansi");
const root = @import("root");

const zigmod = @import("../lib.zig");
const u = @import("./../util/index.zig");
const common = @import("./../common.zig");

const build_options = if (@hasDecl(root, "build_options")) root.build_options else struct {};
const bootstrap = if (@hasDecl(build_options, "bootstrap")) build_options.bootstrap else false;

//
//

pub fn execute(args: [][]u8) !void {
    //
    const gpa = std.heap.c_allocator;
    const cachepath = try std.fs.path.join(gpa, &.{ ".zigmod", "deps" });
    const dir = std.fs.cwd();
    const should_update = !(args.len >= 1 and std.mem.eql(u8, args[0], "--no-update"));

    var options = common.CollectOptions{
        .log = should_update,
        .update = should_update,
        .alloc = gpa,
    };
    const top_module = try common.collect_deps_deep(cachepath, dir, &options);

    var list = std.ArrayList(zigmod.Module).init(gpa);
    try common.collect_pkgs(top_module, &list);

    try create_depszig(gpa, cachepath, dir, top_module, &list);

    if (bootstrap) return;

    try create_lockfile(gpa, &list, cachepath, dir);

    try diff_lockfile(gpa);
}

pub fn create_depszig(alloc: std.mem.Allocator, cachepath: string, dir: std.fs.Dir, top_module: zigmod.Module, list: *std.ArrayList(zigmod.Module)) !void {
    const f = try dir.createFile("deps.zig", .{});
    defer f.close();

    const w = f.writer();
    try w.writeAll("// zig fmt: off\n");
    try w.writeAll("const std = @import(\"std\");\n");
    try w.writeAll("const builtin = @import(\"builtin\");\n");
    try w.writeAll("const Pkg = std.build.Pkg;\n");
    try w.writeAll("const string = []const u8;\n");
    try w.writeAll("\n");
    try w.print("pub const cache = \"{}\";\n", .{std.zig.fmtEscapes(cachepath)});
    try w.writeAll("\n");
    try w.writeAll(
        \\pub fn addAllTo(exe: *std.build.LibExeObjStep) void {
        \\    checkMinZig(builtin.zig_version, exe);
        \\    @setEvalBranchQuota(1_000_000);
        \\    for (packages) |pkg| {
        \\        exe.addPackage(pkg.pkg.?);
        \\    }
        \\    var llc = false;
        \\    var vcpkg = false;
        \\    inline for (comptime std.meta.declarations(package_data)) |decl| {
        \\        const pkg = @as(Package, @field(package_data, decl.name));
        \\        for (pkg.system_libs) |item| {
        \\            exe.linkSystemLibrary(item);
        \\            llc = true;
        \\        }
        \\        for (pkg.frameworks) |item| {
        \\            if (!std.Target.current.isDarwin()) @panic(exe.builder.fmt("a dependency is attempting to link to the framework {s}, which is only possible under Darwin", .{item}));
        \\            exe.linkFramework(item);
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
        \\        vcpkg = vcpkg or pkg.vcpkg;
        \\    }
        \\    if (llc) exe.linkLibC();
        \\    if (builtin.os.tag == .windows and vcpkg) exe.addVcpkgPaths(.static) catch |err| @panic(@errorName(err));
        \\}
        \\
        \\pub const Package = struct {
        \\    directory: string,
        \\    pkg: ?Pkg = null,
        \\    c_include_dirs: []const string = &.{},
        \\    c_source_files: []const string = &.{},
        \\    c_source_flags: []const string = &.{},
        \\    system_libs: []const string = &.{},
        \\    frameworks: []const string = &.{},
        \\    vcpkg: bool = false,
        \\};
        \\
        \\
    );

    try w.print(
        \\fn checkMinZig(current: std.SemanticVersion, exe: *std.build.LibExeObjStep) void {{
        \\    const min = std.SemanticVersion.parse("{?}") catch return;
        \\    if (current.order(min).compare(.lt)) @panic(exe.builder.fmt("Your Zig version v{{}} does not meet the minimum build requirement of v{{}}", .{{current, min}}));
        \\}}
        \\
        \\
    , .{top_module.minZigVersion()});

    try w.writeAll("pub const dirs = struct {\n");
    try print_dirs(w, list.items);
    try w.writeAll("};\n\n");

    try w.writeAll("pub const package_data = struct {\n");
    var duped = std.ArrayList(zigmod.Module).init(alloc);
    for (list.items) |mod| {
        if (mod.is_sys_lib or mod.is_framework) {
            continue;
        }
        try duped.append(mod);
    }
    try print_pkg_data_to(w, &duped, &std.ArrayList(zigmod.Module).init(alloc));
    try w.writeAll("};\n\n");

    try w.writeAll("pub const packages = ");
    try print_deps(w, top_module);
    try w.writeAll(";\n\n");

    try w.writeAll("pub const pkgs = ");
    try print_pkgs(alloc, w, top_module);
    try w.writeAll(";\n\n");

    try w.writeAll("pub const imports = struct {\n");
    try print_imports(alloc, w, top_module, cachepath);
    try w.writeAll("};\n");
}

fn create_lockfile(alloc: std.mem.Allocator, list: *std.ArrayList(zigmod.Module), path: string, dir: std.fs.Dir) !void {
    const fl = try dir.createFile("zigmod.lock", .{});
    defer fl.close();

    const wl = fl.writer();
    try wl.writeAll("2\n");
    for (list.items) |m| {
        if (m.dep) |md| {
            if (md.type.isLocal()) continue;
            const mpath = try std.fs.path.join(alloc, &.{ path, m.clean_path });
            const version = try md.exact_version(alloc, mpath);
            try wl.print("{s} {s} {s}\n", .{ @tagName(md.type), md.path, version });
        }
    }
}

const DiffChange = struct {
    from: string,
    to: string,
};

fn diff_lockfile(alloc: std.mem.Allocator) !void {
    const max = std.math.maxInt(usize);

    if (try u.does_folder_exist(".git")) {
        const result = try u.run_cmd_raw(alloc, null, &.{ "git", "diff", "zigmod.lock" });
        const r = std.io.fixedBufferStream(result.stdout).reader();
        while (try r.readUntilDelimiterOrEofAlloc(alloc, '\n', max)) |line| {
            if (std.mem.startsWith(u8, line, "@@")) break;
        }

        var rems = std.ArrayList(string).init(alloc);
        var adds = std.ArrayList(string).init(alloc);
        while (try r.readUntilDelimiterOrEofAlloc(alloc, '\n', max)) |line| {
            if (line[0] == ' ') continue;
            if (line[0] == '-') try rems.append(line[1..]);
            if (line[0] == '+') if (line[1] == '2') continue else try adds.append(line[1..]);
        }

        var changes = std.StringHashMap(DiffChange).init(alloc);

        var didbreak = false;
        var i: usize = 0;
        while (i < rems.items.len) {
            const it = rems.items[i];
            const sni = u.indexOfN(it, ' ', 2).?;

            var j: usize = 0;
            while (j < adds.items.len) {
                const jt = adds.items[j];
                const snj = u.indexOfN(jt, ' ', 2).?;

                if (std.mem.eql(u8, it[0..sni], jt[0..snj])) {
                    try changes.put(it[0..sni], .{
                        .from = it[u.indexOfAfter(it, '-', sni).? + 1 .. it.len],
                        .to = jt[u.indexOfAfter(jt, '-', snj).? + 1 .. jt.len],
                    });
                    _ = rems.orderedRemove(i);
                    _ = adds.orderedRemove(j);
                    didbreak = true;
                    break;
                }
                if (!didbreak) j += 1;
            }
            if (!didbreak) i += 1;
            if (didbreak) didbreak = false;
        }

        if (adds.items.len > 0) {
            std.debug.print(comptime ansi.color.Faint("Newly added packages:\n"), .{});
            defer std.debug.print("\n", .{});

            for (adds.items) |it| {
                std.debug.print("- {s}\n", .{it});
            }
        }

        if (rems.items.len > 0) {
            std.debug.print(comptime ansi.color.Faint("Removed packages:\n"), .{});
            defer std.debug.print("\n", .{});

            for (rems.items) |it| {
                std.debug.print("- {s}\n", .{it});
            }
        }

        if (changes.unmanaged.size > 0) std.debug.print(comptime ansi.color.Faint("Updated packages:\n"), .{});
        var iter = changes.iterator();
        while (iter.next()) |it| {
            if (diff_printchange("git https://github.com", "- {s}/compare/{s}...{s}\n", it)) continue;
            if (diff_printchange("git https://gitlab.com", "- {s}/-/compare/{s}...{s}\n", it)) continue;
            if (diff_printchange("git https://gitea.com", "- {s}/compare/{s}...{s}\n", it)) continue;

            std.debug.print("- {s}\n", .{it.key_ptr.*});
            std.debug.print("  - {s} ... {s}\n", .{ it.value_ptr.from, it.value_ptr.to });
        }
    }
}

fn diff_printchange(comptime testt: string, comptime replacement: string, item: std.StringHashMap(DiffChange).Entry) bool {
    if (std.mem.startsWith(u8, item.key_ptr.*, testt)) {
        if (std.mem.eql(u8, item.value_ptr.from, item.value_ptr.to)) return true;
        std.debug.print(replacement, .{ item.key_ptr.*[4..], item.value_ptr.from, item.value_ptr.to });
        return true;
    }
    return false;
}

fn print_dirs(w: std.fs.File.Writer, list: []const zigmod.Module) !void {
    for (list) |mod| {
        if (mod.is_sys_lib or mod.is_framework) continue;
        if (std.mem.eql(u8, mod.id, "root")) {
            try w.writeAll("    pub const _root = \"\";\n");
            continue;
        }
        try w.print("    pub const _{s} = cache ++ \"/{}\";\n", .{ mod.short_id(), std.zig.fmtEscapes(mod.clean_path) });
    }
}

fn print_deps(w: std.fs.File.Writer, m: zigmod.Module) !void {
    try w.writeAll("&[_]Package{\n");
    for (m.deps) |d| {
        if (d.main.len == 0) {
            continue;
        }
        if (d.for_build) {
            continue;
        }
        try w.print("    package_data._{s},\n", .{d.id[0..12]});
    }
    try w.writeAll("}");
}

fn print_pkg_data_to(w: std.fs.File.Writer, notdone: *std.ArrayList(zigmod.Module), done: *std.ArrayList(zigmod.Module)) !void {
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
                        \\        .pkg = Pkg{{ .name = "{s}", .source = .{{ .path = dirs._{s} ++ "/{s}" }}, .dependencies =
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
                if (mod.has_framework_deps()) {
                    try w.writeAll("        .frameworks = &.{");
                    for (mod.deps) |item, j| {
                        if (!item.is_sys_lib) continue;
                        try w.print(" \"{}\"", .{std.zig.fmtEscapes(item.name)});
                        if (j != mod.deps.len - 1) try w.writeAll(",");
                    }
                    try w.writeAll(" },\n");
                }
                if (mod.vcpkg) {
                    try w.writeAll("        .vcpkg = true,\n");
                }
                try w.writeAll("    };\n");

                try done.append(mod);
                _ = notdone.orderedRemove(i);
                break;
            }
        }
        if (notdone.items.len == len) {
            u.fail("notdone still has {d} items", .{len});
        }
        len = notdone.items.len;
    }
}

/// returns if all of the zig modules in needles are in haystack
fn contains_all(needles: []zigmod.Module, haystack: []const zigmod.Module) bool {
    for (needles) |item| {
        if (item.main.len > 0 and !u.list_contains_gen(zigmod.Module, haystack, item)) {
            return false;
        }
    }
    return true;
}

fn print_pkgs(alloc: std.mem.Allocator, w: std.fs.File.Writer, m: zigmod.Module) !void {
    try w.writeAll("struct {\n");
    for (m.deps) |d| {
        if (d.main.len == 0) {
            continue;
        }
        if (d.for_build) {
            continue;
        }
        const ident = try zig_name_from_pkg_name(alloc, d.name);
        try w.print("    pub const {s} = package_data._{s};\n", .{ ident, d.id[0..12] });
    }
    try w.writeAll("}");
}

fn print_imports(alloc: std.mem.Allocator, w: std.fs.File.Writer, m: zigmod.Module, path: string) !void {
    for (m.deps) |d| {
        if (d.main.len == 0) {
            continue;
        }
        if (!d.for_build) {
            continue;
        }
        const ident = try zig_name_from_pkg_name(alloc, d.name);
        try w.print("    pub const {s} = @import(\"{}/{}/{s}\");\n", .{ ident, std.zig.fmtEscapes(path), std.zig.fmtEscapes(d.clean_path), d.main });
    }
}

fn zig_name_from_pkg_name(alloc: std.mem.Allocator, name: string) !string {
    var legal = name;
    legal = try std.mem.replaceOwned(u8, alloc, legal, "-", "_");
    legal = try std.mem.replaceOwned(u8, alloc, legal, "/", "_");
    legal = try std.mem.replaceOwned(u8, alloc, legal, ".", "_");
    return legal;
}
