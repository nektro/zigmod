// zig fmt: off
const std = @import("std");
const builtin = @import("builtin");
const string = []const u8;

pub const cache = ".zigmod/deps";

pub fn addAllTo(exe: *std.Build.Step.Compile) void {
    checkMinZig(builtin.zig_version, exe);
    @setEvalBranchQuota(1_000_000);
    for (packages) |pkg| {
        const module = pkg.module(exe);
        exe.root_module.addImport(pkg.import.?[0], module);
    }
}

var link_lib_c = false;
pub const Package = struct {
    directory: string,
    import: ?struct { string, std.Build.LazyPath } = null,
    dependencies: []const *Package,
    c_include_dirs: []const string = &.{},
    c_source_files: []const string = &.{},
    c_source_flags: []const string = &.{},
    system_libs: []const string = &.{},
    frameworks: []const string = &.{},
    module_memo: ?*std.Build.Module = null,

    pub fn module(self: *Package, exe: *std.Build.Step.Compile) *std.Build.Module {
        if (self.module_memo) |cached| {
            return cached;
        }
        const b = exe.step.owner;
        const result = b.createModule(.{});
        const dummy_library = b.addStaticLibrary(.{
            .name = "dummy",
            .target = exe.root_module.resolved_target orelse b.host,
            .optimize = exe.root_module.optimize.?,
        });
        if (self.import) |capture| {
            result.root_source_file = capture[1];
        }
        for (self.dependencies) |item| {
            const module_dep = item.module(exe);
            if (module_dep.root_source_file != null) {
                result.addImport(item.import.?[0], module_dep);
            }
            for (module_dep.include_dirs.items) |jtem| {
                switch (jtem) {
                    .path => result.addIncludePath(jtem.path),
                    .path_system, .path_after, .framework_path, .framework_path_system, .other_step, .config_header_step => {},
                }
            }
        }
        for (self.c_include_dirs) |item| {
            result.addIncludePath(b.path(b.fmt("{s}/{s}", .{ self.directory, item })));
            dummy_library.addIncludePath(b.path(b.fmt("{s}/{s}", .{ self.directory, item })));
            link_lib_c = true;
        }
        for (self.c_source_files) |item| {
            dummy_library.addCSourceFile(.{ .file = b.path(b.fmt("{s}/{s}", .{ self.directory, item })), .flags = self.c_source_flags });
        }
        for (self.system_libs) |item| {
            dummy_library.linkSystemLibrary(item);
        }
        for (self.frameworks) |item| {
            dummy_library.linkFramework(item);
        }
        if (self.c_source_files.len > 0 or self.system_libs.len > 0 or self.frameworks.len > 0) {
            dummy_library.linkLibC();
            exe.root_module.linkLibrary(dummy_library);
            link_lib_c = true;
        }
        if (link_lib_c) {
            result.link_libc = true;
        }
        self.module_memo = result;
        return result;
    }
};

fn checkMinZig(current: std.SemanticVersion, exe: *std.Build.Step.Compile) void {
    const min = std.SemanticVersion.parse("0.12.0") catch return;
    if (current.order(min).compare(.lt)) @panic(exe.step.owner.fmt("Your Zig version v{} does not meet the minimum build requirement of v{}", .{current, min}));
}

pub const dirs = struct {
    pub const _root = "";
    pub const _89ujp8gq842x = "/home/dennis/external/zigmod";
    pub const _g982zq6e8wsv = cache ++ "/git/github.com/nektro/zig-yaml";
    pub const _8mdbh0zuneb0 = cache ++ "/v/git/github.com/yaml/libyaml/tag-0.2.5";
    pub const _f7dubzb7cyqe = cache ++ "/git/github.com/nektro/zig-extras";
    pub const _s84v9o48ucb0 = cache ++ "/git/github.com/nektro/zig-ansi";
    pub const _2ta738wrqbaq = cache ++ "/git/github.com/ziglibs/known-folders";
    pub const _0npcrzfdlrvk = cache ++ "/git/github.com/nektro/zig-licenses";
    pub const _ejw82j2ipa0e = cache ++ "/git/github.com/nektro/zfetch";
    pub const _9k24gimke1an = cache ++ "/git/github.com/truemedian/hzzp";
    pub const _csbnipaad8n7 = cache ++ "/git/github.com/nektro/iguanaTLS";
    pub const _2ovav391ivak = cache ++ "/git/github.com/nektro/zig-detect-license";
    pub const _pt88y5d80m25 = cache ++ "/git/github.com/nektro/zig-licenses-text";
    pub const _96h80ezrvj7i = cache ++ "/git/github.com/nektro/zig-leven";
    pub const _c1xirp1ota5p = cache ++ "/git/github.com/nektro/zig-inquirer";
    pub const _u7sysdckdymi = cache ++ "/git/github.com/nektro/arqv-ini";
    pub const _iecwp4b3bsfm = cache ++ "/git/github.com/nektro/zig-time";
    pub const _0k64oe2nuzvj = cache ++ "/git/github.com/nektro/zig-git";
    pub const _ede2wygpe1iy = cache ++ "/git/github.com/nektro/zig-tracer";
    pub const _ocmr9rtohgcc = cache ++ "/git/github.com/nektro/zig-json";
    pub const _7l3oxw6nqqws = cache ++ "/git/github.com/nektro/zig-intrusive-parser";
    pub const _o6ogpor87xc2 = cache ++ "/git/github.com/marlersoft/zigwin32";
};

pub const package_data = struct {
    pub var _8mdbh0zuneb0 = Package{
        .directory = dirs._8mdbh0zuneb0,
        .dependencies = &.{ },
        .c_include_dirs = &.{ "include" },
        .c_source_files = &.{ "src/api.c", "src/dumper.c", "src/emitter.c", "src/loader.c", "src/parser.c", "src/reader.c", "src/scanner.c", "src/writer.c" },
        .c_source_flags = &.{ "-DYAML_VERSION_MAJOR=0", "-DYAML_VERSION_MINOR=2", "-DYAML_VERSION_PATCH=5", "-DYAML_VERSION_STRING=\"0.2.5\"", "-DYAML_DECLARE_STATIC=1" },
    };
    pub var _f7dubzb7cyqe = Package{
        .directory = dirs._f7dubzb7cyqe,
        .import = .{ "extras", .{ .cwd_relative = dirs._f7dubzb7cyqe ++ "/src/lib.zig" } },
        .dependencies = &.{ },
    };
    pub var _g982zq6e8wsv = Package{
        .directory = dirs._g982zq6e8wsv,
        .import = .{ "yaml", .{ .cwd_relative = dirs._g982zq6e8wsv ++ "/yaml.zig" } },
        .dependencies = &.{ &_8mdbh0zuneb0, &_f7dubzb7cyqe },
    };
    pub var _s84v9o48ucb0 = Package{
        .directory = dirs._s84v9o48ucb0,
        .import = .{ "ansi", .{ .cwd_relative = dirs._s84v9o48ucb0 ++ "/src/lib.zig" } },
        .dependencies = &.{ },
    };
    pub var _2ta738wrqbaq = Package{
        .directory = dirs._2ta738wrqbaq,
        .import = .{ "known-folders", .{ .cwd_relative = dirs._2ta738wrqbaq ++ "/known-folders.zig" } },
        .dependencies = &.{ },
    };
    pub var _0npcrzfdlrvk = Package{
        .directory = dirs._0npcrzfdlrvk,
        .import = .{ "licenses", .{ .cwd_relative = dirs._0npcrzfdlrvk ++ "/src/lib.zig" } },
        .dependencies = &.{ },
    };
    pub var _9k24gimke1an = Package{
        .directory = dirs._9k24gimke1an,
        .import = .{ "hzzp", .{ .cwd_relative = dirs._9k24gimke1an ++ "/src/main.zig" } },
        .dependencies = &.{ },
    };
    pub var _csbnipaad8n7 = Package{
        .directory = dirs._csbnipaad8n7,
        .import = .{ "iguanaTLS", .{ .cwd_relative = dirs._csbnipaad8n7 ++ "/src/main.zig" } },
        .dependencies = &.{ },
    };
    pub var _ejw82j2ipa0e = Package{
        .directory = dirs._ejw82j2ipa0e,
        .import = .{ "zfetch", .{ .cwd_relative = dirs._ejw82j2ipa0e ++ "/src/main.zig" } },
        .dependencies = &.{ &_9k24gimke1an, &_csbnipaad8n7 },
    };
    pub var _pt88y5d80m25 = Package{
        .directory = dirs._pt88y5d80m25,
        .import = .{ "licenses-text", .{ .cwd_relative = dirs._pt88y5d80m25 ++ "/src/lib.zig" } },
        .dependencies = &.{ },
    };
    pub var _96h80ezrvj7i = Package{
        .directory = dirs._96h80ezrvj7i,
        .import = .{ "leven", .{ .cwd_relative = dirs._96h80ezrvj7i ++ "/src/lib.zig" } },
        .dependencies = &.{ },
    };
    pub var _2ovav391ivak = Package{
        .directory = dirs._2ovav391ivak,
        .import = .{ "detect-license", .{ .cwd_relative = dirs._2ovav391ivak ++ "/src/lib.zig" } },
        .dependencies = &.{ &_pt88y5d80m25, &_96h80ezrvj7i },
    };
    pub var _c1xirp1ota5p = Package{
        .directory = dirs._c1xirp1ota5p,
        .import = .{ "inquirer", .{ .cwd_relative = dirs._c1xirp1ota5p ++ "/src/lib.zig" } },
        .dependencies = &.{ &_s84v9o48ucb0 },
    };
    pub var _u7sysdckdymi = Package{
        .directory = dirs._u7sysdckdymi,
        .import = .{ "ini", .{ .cwd_relative = dirs._u7sysdckdymi ++ "/src/ini.zig" } },
        .dependencies = &.{ },
    };
    pub var _iecwp4b3bsfm = Package{
        .directory = dirs._iecwp4b3bsfm,
        .import = .{ "time", .{ .cwd_relative = dirs._iecwp4b3bsfm ++ "/time.zig" } },
        .dependencies = &.{ &_f7dubzb7cyqe },
    };
    pub var _ede2wygpe1iy = Package{
        .directory = dirs._ede2wygpe1iy,
        .import = .{ "tracer", .{ .cwd_relative = dirs._ede2wygpe1iy ++ "/src/mod.zig" } },
        .dependencies = &.{ &_f7dubzb7cyqe },
    };
    pub var _0k64oe2nuzvj = Package{
        .directory = dirs._0k64oe2nuzvj,
        .import = .{ "git", .{ .cwd_relative = dirs._0k64oe2nuzvj ++ "/git.zig" } },
        .dependencies = &.{ &_iecwp4b3bsfm, &_f7dubzb7cyqe, &_ede2wygpe1iy },
    };
    pub var _7l3oxw6nqqws = Package{
        .directory = dirs._7l3oxw6nqqws,
        .import = .{ "intrusive-parser", .{ .cwd_relative = dirs._7l3oxw6nqqws ++ "/intrusive_parser.zig" } },
        .dependencies = &.{ &_f7dubzb7cyqe },
    };
    pub var _ocmr9rtohgcc = Package{
        .directory = dirs._ocmr9rtohgcc,
        .import = .{ "json", .{ .cwd_relative = dirs._ocmr9rtohgcc ++ "/json.zig" } },
        .dependencies = &.{ &_f7dubzb7cyqe, &_ede2wygpe1iy, &_7l3oxw6nqqws },
    };
    pub var _89ujp8gq842x = Package{
        .directory = dirs._89ujp8gq842x,
        .import = .{ "zigmod", .{ .cwd_relative = dirs._89ujp8gq842x ++ "/src/lib.zig" } },
        .dependencies = &.{ &_g982zq6e8wsv, &_s84v9o48ucb0, &_2ta738wrqbaq, &_0npcrzfdlrvk, &_ejw82j2ipa0e, &_2ovav391ivak, &_c1xirp1ota5p, &_u7sysdckdymi, &_iecwp4b3bsfm, &_f7dubzb7cyqe, &_0k64oe2nuzvj, &_ocmr9rtohgcc },
    };
    pub var _o6ogpor87xc2 = Package{
        .directory = dirs._o6ogpor87xc2,
        .import = .{ "win32", .{ .cwd_relative = dirs._o6ogpor87xc2 ++ "/win32.zig" } },
        .dependencies = &.{ },
    };
    pub var _root = Package{
        .directory = dirs._root,
        .dependencies = &.{ &_89ujp8gq842x, &_o6ogpor87xc2, &_f7dubzb7cyqe, &_s84v9o48ucb0 },
    };
};

pub const packages = &[_]*Package{
    &package_data._89ujp8gq842x,
    &package_data._o6ogpor87xc2,
    &package_data._f7dubzb7cyqe,
    &package_data._s84v9o48ucb0,
};

pub const pkgs = struct {
    pub const zigmod = &package_data._89ujp8gq842x;
    pub const win32 = &package_data._o6ogpor87xc2;
    pub const extras = &package_data._f7dubzb7cyqe;
    pub const ansi = &package_data._s84v9o48ucb0;
};

pub const imports = struct {
};
