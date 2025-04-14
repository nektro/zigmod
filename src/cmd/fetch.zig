const std = @import("std");
const string = []const u8;
const ansi = @import("ansi");
const extras = @import("extras");

const zigmod = @import("../lib.zig");
const u = @import("./../util/index.zig");
const common = @import("./../common.zig");
const license = @import("./license.zig");

//
//

pub fn execute(self_name: []const u8, args: [][:0]u8) !void {
    _ = self_name;

    const gpa = std.heap.c_allocator;
    const cachepath = try u.find_cachepath();
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

    try create_lockfile(gpa, &list, cachepath, dir);

    try diff_lockfile(gpa);

    options.update = false;

    var outfile = try dir.createFile("licenses.txt", .{});
    defer outfile.close();

    try license.do(cachepath, dir, &options, outfile);
}

pub fn create_depszig(alloc: std.mem.Allocator, cachepath: string, dir: std.fs.Dir, top_module: zigmod.Module, list: *std.ArrayList(zigmod.Module)) !void {
    const f = try dir.createFile("deps.zig", .{});
    defer f.close();

    const w = f.writer();
    try w.writeAll("// zig fmt: off\n");
    try w.writeAll("const std = @import(\"std\");\n");
    try w.writeAll("const builtin = @import(\"builtin\");\n");
    try w.writeAll("const string = []const u8;\n");
    try w.writeAll("\n");
    try w.print("pub const cache = \"{}\";\n", .{std.zig.fmtEscapes(cachepath)});
    try w.writeAll("\n");
    try w.writeAll(
        \\pub fn addAllTo(exe: *std.Build.Step.Compile) void {
        \\    checkMinZig(builtin.zig_version, exe);
        \\    @setEvalBranchQuota(1_000_000);
        \\    for (packages) |pkg| {
        \\        const module = pkg.module(exe);
        \\        exe.root_module.addImport(pkg.import.?[0], module);
        \\    }
        \\    for (package_data._root.system_libs) |libname| {
        \\        exe.linkSystemLibrary(libname);
        \\        exe.linkLibC();
        \\    }
        \\    // clear module memo cache so addAllTo can be called more than once in the same build.zig
        \\    inline for (comptime std.meta.declarations(package_data)) |decl| @field(package_data, decl.name).module_memo = null;
        \\}
        \\
        \\var link_lib_c = false;
        \\pub const Package = struct {
        \\    directory: string,
        \\    import: ?struct { string, std.Build.LazyPath } = null,
        \\    dependencies: []const *Package,
        \\    c_include_dirs: []const string = &.{},
        \\    c_source_files: []const string = &.{},
        \\    c_source_flags: []const string = &.{},
        \\    system_libs: []const string = &.{},
        \\    frameworks: []const string = &.{},
        \\    module_memo: ?*std.Build.Module = null,
        \\
        \\    pub fn module(self: *Package, exe: *std.Build.Step.Compile) *std.Build.Module {
        \\        if (self.module_memo) |cached| {
        \\            return cached;
        \\        }
        \\        const b = exe.step.owner;
        \\        const result = b.createModule(.{
        \\            .target = exe.root_module.resolved_target orelse b.graph.host,
        \\        });
        \\        if (self.import) |capture| {
        \\            result.root_source_file = capture[1];
        \\        }
        \\        for (self.dependencies) |item| {
        \\            const module_dep = item.module(exe);
        \\            if (module_dep.root_source_file != null) {
        \\                result.addImport(item.import.?[0], module_dep);
        \\            }
        \\            for (module_dep.include_dirs.items) |jtem| {
        \\                switch (jtem) {
        \\                    .path => result.addIncludePath(jtem.path),
        \\                    .path_system, .path_after, .framework_path, .framework_path_system, .other_step, .config_header_step => {},
        \\                }
        \\            }
        \\        }
        \\        for (self.c_include_dirs) |item| {
        \\            result.addIncludePath(.{ .cwd_relative = (b.fmt("{s}/{s}", .{ self.directory, item })) });
        \\            exe.addIncludePath(.{ .cwd_relative = (b.fmt("{s}/{s}", .{ self.directory, item })) });
        \\            link_lib_c = true;
        \\        }
        \\        for (self.c_source_files) |item| {
        \\            exe.addCSourceFile(.{ .file = .{ .cwd_relative = (b.fmt("{s}/{s}", .{ self.directory, item })) }, .flags = self.c_source_flags });
        \\            link_lib_c = true;
        \\        }
        \\        for (self.system_libs) |item| {
        \\            result.linkSystemLibrary(item, .{});
        \\            exe.linkSystemLibrary(item);
        \\            link_lib_c = true;
        \\        }
        \\        for (self.frameworks) |item| {
        \\            result.linkFramework(item, .{});
        \\            exe.linkFramework(item);
        \\            link_lib_c = true;
        \\        }
        \\        if (link_lib_c) {
        \\            result.link_libc = true;
        \\            exe.linkLibC();
        \\        }
        \\        self.module_memo = result;
        \\        return result;
        \\    }
        \\};
        \\
        \\
    );

    try w.print(
        \\fn checkMinZig(current: std.SemanticVersion, exe: *std.Build.Step.Compile) void {{
        \\    const min = std.SemanticVersion.parse("{?}") catch return;
        \\    if (current.order(min).compare(.lt)) @panic(exe.step.owner.fmt("Your Zig version v{{}} does not meet the minimum build requirement of v{{}}", .{{current, min}}));
        \\}}
        \\
        \\
    , .{top_module.minZigVersion()});

    try w.writeAll("pub const dirs = struct {\n");
    try print_dirs(w, list.items, alloc);
    try w.writeAll("};\n\n");

    try w.writeAll("pub const package_data = struct {\n");
    var duped = std.ArrayList(zigmod.Module).init(alloc);
    var done = std.ArrayList(zigmod.Module).init(alloc);
    for (list.items) |mod| {
        if (mod.type == .system_lib or mod.type == .framework) {
            continue;
        }
        try duped.append(mod);
    }
    try print_pkg_data_to(w, &duped, &done);
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

    std.mem.sort(zigmod.Module, list.items, {}, zigmod.Module.lessThan);

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

    if (try extras.doesFolderExist(null, ".git")) {
        const result = try u.run_cmd_raw(alloc, null, &.{ "git", "diff", "zigmod.lock" });
        var stdout = std.io.fixedBufferStream(result.stdout);
        const r = stdout.reader();
        while (try r.readUntilDelimiterOrEofAlloc(alloc, '\n', max)) |line| {
            if (std.mem.startsWith(u8, line, "@@")) break;
        }

        var rems = std.ArrayList(string).init(alloc);
        var adds = std.ArrayList(string).init(alloc);
        while (try r.readUntilDelimiterOrEofAlloc(alloc, '\n', max)) |line| {
            if (line[0] == ' ') continue;
            if (line[0] == '-') try rems.append(line[1..]);
            if (line[0] == '+') if (line[1] == '2') break else try adds.append(line[1..]);
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

fn print_dirs(w: std.fs.File.Writer, list: []const zigmod.Module, alloc: std.mem.Allocator) !void {
    for (list) |mod| {
        if (mod.type == .system_lib or mod.type == .framework) continue;
        if (std.mem.eql(u8, &mod.id, &zigmod.Module.ROOT)) {
            try w.writeAll("    pub const _root = \"\";\n");
            continue;
        }
        if (std.mem.eql(u8, mod.clean_path, "../..")) {
            const cwd_realpath = try std.fs.cwd().realpathAlloc(alloc, ".");
            try w.print("    pub const _{s} = \"{}\";\n", .{ mod.short_id(), std.zig.fmtEscapes(cwd_realpath) });
            continue;
        }
        try w.print("    pub const _{s} = cache ++ \"/{}\";\n", .{ mod.short_id(), std.zig.fmtEscapes(mod.clean_path) });
    }
}

fn print_deps(w: std.fs.File.Writer, m: zigmod.Module) !void {
    try w.writeAll("&[_]*Package{\n");
    for (m.deps) |d| {
        if (d.main.len == 0) {
            continue;
        }
        if (d.for_build) {
            continue;
        }
        try w.print("    &package_data._{s},\n", .{d.id[0..12]});
    }
    try w.writeAll("}");
}

fn print_pkg_data_to(w: std.fs.File.Writer, notdone: *std.ArrayList(zigmod.Module), done: *std.ArrayList(zigmod.Module)) !void {
    var len: usize = notdone.items.len;
    while (notdone.items.len > 0) {
        for (notdone.items, 0..) |mod, i| {
            if (contains_all(mod.deps, done.items)) {
                try w.print(
                    \\    pub var _{s} = Package{{
                    \\        .directory = dirs._{s},
                    \\
                , .{
                    mod.short_id(),
                    mod.short_id(),
                });
                if (mod.main.len > 0 and !std.mem.eql(u8, &mod.id, &zigmod.Module.ROOT)) {
                    try w.print(
                        \\        .import = .{{ "{s}", .{{ .cwd_relative = dirs._{s} ++ "/{s}" }} }},
                        \\
                    , .{
                        mod.name,
                        mod.short_id(),
                        mod.main,
                    });
                }
                {
                    try w.writeAll("        .dependencies =");
                    try w.writeAll(" &.{");
                    for (mod.deps, 0..) |moddep, j| {
                        if (moddep.type == .system_lib) continue;
                        if (moddep.type == .framework) continue;
                        try w.print(" &_{s}", .{moddep.id[0..12]});
                        if (j != mod.deps.len - 1) try w.writeAll(",");
                    }
                    try w.writeAll(" },\n");
                }
                if (mod.c_include_dirs.len > 0) {
                    try w.writeAll("        .c_include_dirs = &.{");
                    for (mod.c_include_dirs, 0..) |item, j| {
                        try w.print(" \"{}\"", .{std.zig.fmtEscapes(item)});
                        if (j != mod.c_include_dirs.len - 1) try w.writeAll(",");
                    }
                    try w.writeAll(" },\n");
                }
                if (mod.c_source_files.len > 0) {
                    try w.writeAll("        .c_source_files = &.{");
                    for (mod.c_source_files, 0..) |item, j| {
                        try w.print(" \"{}\"", .{std.zig.fmtEscapes(item)});
                        if (j != mod.c_source_files.len - 1) try w.writeAll(",");
                    }
                    try w.writeAll(" },\n");
                }
                if (mod.c_source_flags.len > 0) {
                    try w.writeAll("        .c_source_flags = &.{");
                    for (mod.c_source_flags, 0..) |item, j| {
                        try w.print(" \"{}\"", .{std.zig.fmtEscapes(item)});
                        if (j != mod.c_source_flags.len - 1) try w.writeAll(",");
                    }
                    try w.writeAll(" },\n");
                }
                if (mod.has_syslib_deps()) {
                    try w.writeAll("        .system_libs = &.{");
                    for (mod.deps, 0..) |item, j| {
                        if (!(item.type == .system_lib)) continue;
                        try w.print(" \"{}\"", .{std.zig.fmtEscapes(item.name)});
                        if (j != mod.deps.len - 1) try w.writeAll(",");
                    }
                    try w.writeAll(" },\n");
                }
                if (mod.has_framework_deps()) {
                    try w.writeAll("        .frameworks = &.{");
                    for (mod.deps, 0..) |item, j| {
                        if (!(item.type == .system_lib)) continue;
                        try w.print(" \"{}\"", .{std.zig.fmtEscapes(item.name)});
                        if (j != mod.deps.len - 1) try w.writeAll(",");
                    }
                    try w.writeAll(" },\n");
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
        if (item.main.len > 0 and !extras.containsAggregate(zigmod.Module, haystack, item)) {
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
        try w.print("    pub const {s} = &package_data._{s};\n", .{ ident, d.id[0..12] });
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
