const std = @import("std");
const string = []const u8;
const extras = @import("extras");

const zigmod = @import("../lib.zig");
const u = @import("./../util/index.zig");
const common = @import("./../common.zig");

//
//

pub fn execute(self_name: []const u8, args: [][]u8) !void {
    _ = self_name;
    _ = args;

    //
    const gpa = std.heap.c_allocator;
    const cachepath = try u.find_cachepath();
    const dir = std.fs.cwd();

    var options = common.CollectOptions{
        .log = false,
        .update = false,
        .alloc = gpa,
    };
    const top_module = try common.collect_deps_deep(cachepath, dir, &options);

    var list = std.ArrayList(zigmod.Module).init(gpa);
    try common.collect_pkgs(top_module, &list);

    std.mem.sort(zigmod.Module, list.items, {}, zigmod.Module.lessThan);

    try create_depszig(gpa, cachepath, dir, top_module, list.items);
}

pub fn create_depszig(alloc: std.mem.Allocator, cachepath: string, dir: std.fs.Dir, top_module: zigmod.Module, list: []const zigmod.Module) !void {
    const f = try dir.createFile("deps.zig", .{});
    defer f.close();

    const w = f.writer();
    try w.writeAll("// zig fmt: off\n");
    try w.writeAll("const std = @import(\"std\");\n");
    try w.writeAll("const builtin = @import(\"builtin\");\n");
    try w.writeAll("const string = []const u8;\n");
    try w.writeAll("\n");
    try w.writeAll(
        \\pub const GitExactStep = struct {
        \\    step: std.Build.Step,
        \\    builder: *std.Build,
        \\    url: string,
        \\    commit: string,
        \\
        \\        pub fn create(b: *std.Build, url: string, commit: string) *GitExactStep {
        \\            var result = b.allocator.create(GitExactStep) catch @panic("memory");
        \\            result.* = GitExactStep{
        \\                .step = std.Build.Step.init(.{
        \\                    .id = .custom,
        \\                    .name = b.fmt("git clone {s} @ {s}", .{ url, commit }),
        \\                    .owner = b,
        \\                    .makeFn = make,
        \\                }),
        \\                .builder = b,
        \\                .url = url,
        \\                .commit = commit,
        \\            };
        \\
        \\            var urlpath = url;
        \\            urlpath = trimPrefix(u8, urlpath, "https://");
        \\            urlpath = trimPrefix(u8, urlpath, "git://");
        \\            const repopath = b.fmt("{s}/zigmod/deps/git/{s}/{s}", .{ b.cache_root.path.?, urlpath, commit });
        \\            flip(std.fs.cwd().access(repopath, .{})) catch return result;
        \\
        \\            var clonestep = std.Build.Step.Run.create(b, "clone");
        \\            clonestep.addArgs(&.{ "git", "clone", "-q", "--progress", url, repopath });
        \\
        \\            var checkoutstep = std.Build.Step.Run.create(b, "checkout");
        \\            checkoutstep.addArgs(&.{ "git", "-C", repopath, "checkout", "-q", commit });
        \\            result.step.dependOn(&checkoutstep.step);
        \\            checkoutstep.step.dependOn(&clonestep.step);
        //            TODO rm the .git folder
        //            TODO mark folder as read-only
        \\
        \\            return result;
        \\        }
        \\
        \\        fn make(step: *std.Build.Step, prog_node: *std.Progress.Node) !void {
        \\            _ = step;
        \\            _ = prog_node;
        \\        }
        \\};
        \\
        \\pub fn fetch(exe: *std.Build.Step.Compile) *std.Build.Step {
        \\    const b = exe.step.owner;
        \\    const step = b.step("fetch", "");
        \\    inline for (comptime std.meta.declarations(package_data)) |decl| {
        \\          const path = &@field(package_data, decl.name).entry;
        \\          const root = if (@field(package_data, decl.name).store) |_| b.cache_root.path.? else ".";
        \\          if (path.* != null) path.* = b.fmt("{s}/zigmod/deps{s}", .{ root, path.*.? });
        \\    }
        \\
    );
    for (list) |module| {
        switch (module.type) {
            .local => {},
            .system_lib => {},
            .framework => {},
            .git => try w.print("    step.dependOn(&GitExactStep.create(b, \"{s}\", \"{s}\").step);\n", .{ module.dep.?.path, try module.pin(alloc, cachepath) }),
            .hg => @panic("TODO"),
            .http => @panic("TODO"),
        }
    }
    try w.writeAll(
        \\    return step;
        \\}
        \\
        \\fn trimPrefix(comptime T: type, haystack: []const T, needle: []const T) []const T {
        \\    if (std.mem.startsWith(T, haystack, needle)) {
        \\        return haystack[needle.len .. haystack.len];
        \\    }
        \\    return haystack;
        \\}
        \\
        \\fn flip(foo: anytype) !void {
        \\    _ = foo catch return;
        \\    return error.ExpectedError;
        \\}
        \\
        \\pub fn addAllTo(exe: *std.Build.Step.Compile) void {
        \\    checkMinZig(builtin.zig_version, exe);
        \\    const fetch_step = fetch(exe);
        \\    @setEvalBranchQuota(1_000_000);
        \\    for (packages) |pkg| {
        \\        const module = pkg.module(exe, fetch_step);
        \\        exe.root_module.addImport(pkg.name, module);
        \\    }
        \\}
        \\
        \\var link_lib_c = false;
        \\pub const Package = struct {
        \\    name: string = "",
        \\    entry: ?string = null,
        \\    store: ?string = null,
        \\    deps: []const *Package = &.{},
        \\    c_include_dirs: []const string = &.{},
        \\    c_source_files: []const string = &.{},
        \\    c_source_flags: []const string = &.{},
        \\    system_libs: []const string = &.{},
        \\    frameworks: []const string = &.{},
        \\    module_memo: ?*std.Build.Module = null,
        \\
        \\    pub fn module(self: *Package, exe: *std.Build.Step.Compile, fetch_step: *std.Build.Step) *std.Build.Module {
        \\        if (self.module_memo) |cached| {
        \\            return cached;
        \\        }
        \\        const b = exe.step.owner;
        \\
        \\        const result = b.createModule(.{});
        \\        const dummy_library = b.addStaticLibrary(.{
        \\            .name = "dummy",
        \\            .target = exe.root_module.resolved_target orelse b.host,
        \\            .optimize = exe.root_module.optimize.?,
        \\        });
        \\        dummy_library.step.dependOn(fetch_step);
        \\        if (self.entry) |capture| {
        \\            result.root_source_file = .{ .path = capture };
        \\        }
        \\        for (self.deps) |item| {
        \\            const module_dep = item.module(exe, fetch_step);
        \\            if (module_dep.root_source_file != null) {
        \\                result.addImport(item.name, module_dep);
        \\            }
        \\            for (module_dep.include_dirs.items) |jtem| {
        \\                switch (jtem) {
        \\                    .path => result.addIncludePath(jtem.path),
        \\                    .path_system, .path_after, .framework_path, .framework_path_system, .other_step, .config_header_step => {},
        \\                }
        \\            }
        \\        }
        \\        for (self.c_include_dirs) |item| {
        \\            result.addIncludePath(.{ .cwd_relative = b.fmt("{s}/zigmod/deps{s}/{s}", .{ b.cache_root.path.?, self.store.?, item }) });
        \\            dummy_library.addIncludePath(.{ .cwd_relative = b.fmt("{s}/zigmod/deps{s}/{s}", .{ b.cache_root.path.?, self.store.?, item }) });
        \\            link_lib_c = true;
        \\        }
        \\        for (self.c_source_files) |item| {
        \\            dummy_library.addCSourceFile(.{ .file = .{ .cwd_relative = b.fmt("{s}/zigmod/deps{s}/{s}", .{ b.cache_root.path.?, self.store.?, item }) }, .flags = self.c_source_flags });
        \\        }
        \\        for (self.system_libs) |item| {
        \\            dummy_library.linkSystemLibrary(item);
        \\        }
        \\        for (self.frameworks) |item| {
        \\            dummy_library.linkFramework(item);
        \\        }
        \\        if (self.c_source_files.len > 0 or self.system_libs.len > 0 or self.frameworks.len > 0) {
        \\            dummy_library.linkLibC();
        \\            exe.root_module.linkLibrary(dummy_library);
        \\            link_lib_c = true;
        \\        }
        \\        if (link_lib_c) {
        \\            result.link_libc = true;
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

    try w.writeAll("pub const package_data = struct {\n");
    var duped = std.ArrayList(zigmod.Module).init(alloc);
    var done = std.ArrayList(zigmod.Module).init(alloc);
    for (list) |mod| {
        if (mod.type == .system_lib or mod.type == .framework) {
            continue;
        }
        try duped.append(mod);
    }
    try print_pkg_data_to(w, alloc, cachepath, &duped, &done);
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

fn print_dirs(w: std.fs.File.Writer, list: []const zigmod.Module) !void {
    for (list) |mod| {
        if (mod.type == .system_lib or mod.type == .framework) continue;
        if (std.mem.eql(u8, mod.id, "root")) {
            try w.writeAll("    pub const _root = \"\";\n");
            continue;
        }
        try w.print("    pub const _{s} = cache ++ \"/{}\";\n", .{ mod.short_id(), std.zig.fmtEscapes(mod.clean_path) });
    }
}

fn print_deps(w: std.fs.File.Writer, m: zigmod.Module) !void {
    try w.writeAll("[_]*Package{\n");
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

fn print_pkg_data_to(w: std.fs.File.Writer, alloc: std.mem.Allocator, cachepath: string, notdone: *std.ArrayList(zigmod.Module), done: *std.ArrayList(zigmod.Module)) !void {
    var len: usize = notdone.items.len;
    while (notdone.items.len > 0) {
        for (notdone.items, 0..) |mod, i| {
            if (contains_all(mod.deps, done.items)) {
                try w.print(
                    \\    pub var _{s} = Package{{
                    \\
                , .{
                    mod.short_id(),
                });
                const fixed_path = if (std.mem.startsWith(u8, mod.clean_path, "v/")) mod.clean_path[2..std.mem.lastIndexOfScalar(u8, mod.clean_path, '/').?] else mod.clean_path;
                switch (mod.type) {
                    .system_lib, .framework => {},
                    .local => {},
                    .git => try w.print("        .store = \"/{}/{s}\",\n", .{ std.zig.fmtEscapes(fixed_path), try mod.pin(alloc, cachepath) }),
                    .hg => @panic("TODO"),
                    .http => @panic("TODO"),
                }
                if (mod.main.len > 0 and !std.mem.eql(u8, mod.id, "root")) {
                    try w.print("        .name = \"{s}\",\n", .{mod.name});
                    try w.print("        .entry = \"/{}/{s}/{s}\",\n", .{ std.zig.fmtEscapes(fixed_path), try mod.pin(alloc, cachepath), mod.main });

                    if (mod.deps.len != 0) {
                        try w.writeAll("        .deps = &[_]*Package{");
                        for (mod.deps, 0..) |moddep, j| {
                            try w.print(" &_{s}", .{moddep.id[0..12]});
                            if (j != mod.deps.len - 1) try w.writeAll(",");
                        }
                        try w.writeAll(" },\n");
                    }
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
