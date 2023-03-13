const std = @import("std");
const string = []const u8;

const zigmod = @import("../lib.zig");
const u = @import("./../util/index.zig");
const common = @import("./../common.zig");

//
//

pub fn execute(args: [][]u8) !void {
    _ = args;

    //
    const gpa = std.heap.c_allocator;
    const cachepath = try std.fs.path.join(gpa, &.{ ".zigmod", "deps" });
    const dir = std.fs.cwd();

    var options = common.CollectOptions{
        .log = false,
        .update = false,
        .alloc = gpa,
    };
    const top_module = try common.collect_deps_deep(cachepath, dir, &options);

    var list = std.ArrayList(zigmod.Module).init(gpa);
    try common.collect_pkgs(top_module, &list);

    std.sort.sort(zigmod.Module, list.items, {}, zigmod.Module.lessThan);

    try create_depszig(gpa, cachepath, dir, top_module, list.items);
}

pub fn create_depszig(alloc: std.mem.Allocator, cachepath: string, dir: std.fs.Dir, top_module: zigmod.Module, list: []const zigmod.Module) !void {
    const f = try dir.createFile("deps.zig", .{});
    defer f.close();

    const w = f.writer();
    try w.writeAll("// zig fmt: off\n");
    try w.writeAll("const std = @import(\"std\");\n");
    try w.writeAll("const builtin = @import(\"builtin\");\n");
    try w.writeAll("const ModuleDependency = std.build.ModuleDependency;\n");
    try w.writeAll("const string = []const u8;\n");
    try w.writeAll("\n");
    try w.writeAll(
        \\pub const GitExactStep = struct {
        \\    step: std.build.Step,
        \\    builder: *std.build.Builder,
        \\    url: string,
        \\    commit: string,
        \\
        \\        pub fn create(b: *std.build.Builder, url: string, commit: string) *GitExactStep {
        \\            var result = b.allocator.create(GitExactStep) catch @panic("memory");
        \\            result.* = GitExactStep{
        \\                .step = std.build.Step.init(.custom, b.fmt("git clone {s} @ {s}", .{ url, commit }), b.allocator, make),
        \\                .builder = b,
        \\                .url = url,
        \\                .commit = commit,
        \\            };
        \\
        \\            var urlpath = url;
        \\            urlpath = trimPrefix(u8, urlpath, "https://");
        \\            urlpath = trimPrefix(u8, urlpath, "git://");
        \\            const repopath = b.fmt("{s}/zigmod/deps/git/{s}/{s}", .{ b.cache_root, urlpath, commit });
        \\            flip(std.fs.cwd().access(repopath, .{})) catch return result;
        \\
        \\            var clonestep = std.build.RunStep.create(b, "clone");
        \\            clonestep.addArgs(&.{ "git", "clone", "-q", "--progress", url, repopath });
        \\            result.step.dependOn(&clonestep.step);
        \\
        \\            var checkoutstep = std.build.RunStep.create(b, "checkout");
        \\            checkoutstep.addArgs(&.{ "git", "-C", repopath, "checkout", "-q", commit });
        \\            result.step.dependOn(&checkoutstep.step);
        //            TODO rm the .git folder
        //            TODO mark folder as read-only
        \\
        \\            return result;
        \\        }
        \\
        \\        fn make(step: *std.build.Step) !void {
        \\            _ = step;
        \\        }
        \\};
        \\
        \\pub fn fetch(exe: *std.build.LibExeObjStep) void {
        \\    const b = exe.builder;
        \\    inline for (comptime std.meta.declarations(package_data)) |decl| {
        \\        const path = &@field(package_data, decl.name).entry;
        \\        const root = if (@field(package_data, decl.name).store) |_| b.cache_root else ".";
        \\        if (path.* != null) path.* = b.fmt("{s}/zigmod/deps{s}", .{ root, path.*.? });
        \\    }
        \\
    );
    for (list) |module| {
        switch (module.type) {
            .local => {},
            .system_lib => {},
            .framework => {},
            .git => try w.print("    exe.step.dependOn(&GitExactStep.create(b, \"{s}\", \"{s}\").step);\n", .{ module.dep.?.path, try module.pin(alloc, cachepath) }),
            .hg => @panic("TODO"),
            .http => @panic("TODO"),
        }
    }
    try w.writeAll(
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
        \\pub fn addAllTo(exe: *std.build.LibExeObjStep) void {
        \\    checkMinZig(builtin.zig_version, exe);
        \\    fetch(exe);
        \\    const b = exe.builder;
        \\    @setEvalBranchQuota(1_000_000);
        \\    for (packages) |pkg| {
        \\        const moddep = pkg.zp(b);
        \\        exe.addModule(moddep.name, moddep.module);
        \\    }
        \\    var llc = false;
        \\    var vcpkg = false;
        \\    inline for (comptime std.meta.declarations(package_data)) |decl| {
        \\        const pkg = @as(Package, @field(package_data, decl.name));
        \\        const root = if (pkg.store) |st| b.fmt("{s}/zigmod/deps/{s}", .{ b.cache_root, st }) else ".";
        \\        for (pkg.system_libs) |item| {
        \\            exe.linkSystemLibrary(item);
        \\            llc = true;
        \\        }
        \\        for (pkg.frameworks) |item| {
        \\            if (!builtin.target.isDarwin()) @panic(exe.builder.fmt("a dependency is attempting to link to the framework {s}, which is only possible under Darwin", .{item}));
        \\            exe.linkFramework(item);
        \\            llc = true;
        \\        }
        \\        for (pkg.c_include_dirs) |item| {
        \\            exe.addIncludePath(b.fmt("{s}/{s}", .{ root, item }));
        \\            llc = true;
        \\        }
        \\        for (pkg.c_source_files) |item| {
        \\            exe.addCSourceFile(b.fmt("{s}/{s}", .{ root, item }), pkg.c_source_flags);
        \\            llc = true;
        \\        }
        \\        vcpkg = vcpkg or pkg.vcpkg;
        \\    }
        \\    if (llc) exe.linkLibC();
        \\    if (builtin.os.tag == .windows and vcpkg) exe.addVcpkgPaths(.static) catch |err| @panic(@errorName(err));
        \\}
        \\
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
        \\    vcpkg: bool = false,
        \\
        \\    pub fn zp(self: *const Package, b: *std.build.Builder) ModuleDependency {
        \\        var temp: [100]ModuleDependency = undefined;
        \\        for (self.deps, 0..) |item, i| {
        \\            temp[i] = item.zp(b);
        \\        }
        \\        return .{
        \\            .name = self.name,
        \\            .module = b.createModule(.{
        \\                .source_file = .{ .path = self.entry.? },
        \\                .dependencies = b.allocator.dupe(ModuleDependency, temp[0..self.deps.len]) catch @panic("oom"),
        \\            }),
        \\        };
        \\    }
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
    try w.writeAll("[_]*const Package{\n");
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
                var fixed_path = if (std.mem.startsWith(u8, mod.clean_path, "v/")) mod.clean_path[2..std.mem.lastIndexOfScalar(u8, mod.clean_path, '/').?] else mod.clean_path;
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

                    if (!mod.has_no_zig_deps()) {
                        try w.writeAll("        .deps = &[_]*Package{");
                        for (mod.deps, 0..) |moddep, j| {
                            if (moddep.main.len == 0) continue;
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
