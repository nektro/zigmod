// zig fmt: off
const std = @import("std");
const builtin = @import("builtin");
const string = []const u8;
const any_translate_c = true;
const Translator = @import("translate_c").Translator; // need to depend on ziglang/translate-c#2.0.2

pub var translate_c: ?*std.Build.Dependency = null;

pub const GitExactStep = struct {
    step: *std.Build.Step,
    path: std.Build.LazyPath,

    pub fn create(b: *std.Build, url: string, commit: string) GitExactStep {
        const sc_clone = b.addSystemCommand(&.{ "git", "clone" });
        sc_clone.addArg("--quiet");
        sc_clone.addArg("--progress");
        sc_clone.addArg("--depth");
        sc_clone.addArg("1");
        sc_clone.addArg("--revision");
        sc_clone.addArg(commit);
        sc_clone.addArg(url);
        const path = sc_clone.addOutputDirectoryArg(std.fs.path.basenamePosix(url));
        return .{
            .step = &sc_clone.step,
            .path = path,
        };
    }
};

pub fn fetch(exe: *std.Build.Step.Compile) *std.Build.Step {
    const b = exe.step.owner;
    const step = b.step("fetch", "");
    dependOnGit(GitExactStep.create(b, "https://github.com/marlersoft/zigwin32", "fb2645891520f3e99931db17a7eba04057e87e89"), step, &@field(package_data, "_o6ogpor87xc2"));
    dependOnGit(GitExactStep.create(b, "https://github.com/nektro/arqv-ini", "2951069265792192bd714980d44ccb4abee4a6e8"), step, &@field(package_data, "_u7sysdckdymi"));
    dependOnGit(GitExactStep.create(b, "https://github.com/nektro/zig-ansi", "952d0751c359612fc1a7c493453cc6223bbaff5d"), step, &@field(package_data, "_s84v9o48ucb0"));
    dependOnGit(GitExactStep.create(b, "https://github.com/nektro/zig-detect-license", "2ec231c2ae5274d926851f355f0896e0fcbbb5d0"), step, &@field(package_data, "_2ovav391ivak"));
    dependOnGit(GitExactStep.create(b, "https://github.com/nektro/zig-extras", "fb3aa273de9116bbb7befd448835b854d906f2ee"), step, &@field(package_data, "_f7dubzb7cyqe"));
    dependOnGit(GitExactStep.create(b, "https://github.com/nektro/zig-git", "f4bd29ad59967102db4532bda2d95d1512fbf3fb"), step, &@field(package_data, "_0k64oe2nuzvj"));
    dependOnGit(GitExactStep.create(b, "https://github.com/nektro/zig-inquirer", "6feae6d21ac54cba8e5d4da91868c4db9f82343b"), step, &@field(package_data, "_c1xirp1ota5p"));
    dependOnGit(GitExactStep.create(b, "https://github.com/nektro/zig-intrusive-parser", "6d074187f8c5aa2bdab11ee57c7180df768fca72"), step, &@field(package_data, "_7l3oxw6nqqws"));
    dependOnGit(GitExactStep.create(b, "https://github.com/nektro/zig-json", "4f6aa411f1dc93cc86a052d8a69804c8ff762e59"), step, &@field(package_data, "_ocmr9rtohgcc"));
    dependOnGit(GitExactStep.create(b, "https://github.com/nektro/zig-leven", "d990af4f7706edcb0d928d953d1a56c2830fa036"), step, &@field(package_data, "_96h80ezrvj7i"));
    dependOnGit(GitExactStep.create(b, "https://github.com/nektro/zig-licenses", "1fd04fc1b7619ca2ddfd07354a93e6d72334f76f"), step, &@field(package_data, "_0npcrzfdlrvk"));
    dependOnGit(GitExactStep.create(b, "https://github.com/nektro/zig-licenses-text", "a20d31da306967253b8a46c60d8368c7ac4b7229"), step, &@field(package_data, "_pt88y5d80m25"));
    dependOnGit(GitExactStep.create(b, "https://github.com/nektro/zig-nfs", "b32bb30bbdc7e5ad9bb3adb5c477a98897c9cb10"), step, &@field(package_data, "_vph9l0hxpeze"));
    dependOnGit(GitExactStep.create(b, "https://github.com/nektro/zig-nio", "b28c8efc86f3baec3737de86ffde5c4b3a5260f6"), step, &@field(package_data, "_kscsl0145t7x"));
    dependOnGit(GitExactStep.create(b, "https://github.com/nektro/zig-sys-darwin", "312638dcf043c3163e260ec5b42610856fc9eeab"), step, &@field(package_data, "_73bukkeci2u6"));
    dependOnGit(GitExactStep.create(b, "https://github.com/nektro/zig-sys-freebsd", "967ac568e385534825e6849bc82a9b51d45c600c"), step, &@field(package_data, "_qfev2g50alvp"));
    dependOnGit(GitExactStep.create(b, "https://github.com/nektro/zig-sys-linux", "750d2aa874a9ddb473e7cd0af99f1e722aaab79d"), step, &@field(package_data, "_h7tv7ayhffak"));
    dependOnGit(GitExactStep.create(b, "https://github.com/nektro/zig-sys-netbsd", "e16386268223744ac3f6036a028cc4359056731b"), step, &@field(package_data, "_uvkgl6xf1azv"));
    dependOnGit(GitExactStep.create(b, "https://github.com/nektro/zig-sys-openbsd", "081e11079887e8f02d8480b6219a13a41afd8d69"), step, &@field(package_data, "_4rmxgmcykiba"));
    dependOnGit(GitExactStep.create(b, "https://github.com/nektro/zig-time", "29f3f902cc8948faa36b853380c38ff587236661"), step, &@field(package_data, "_iecwp4b3bsfm"));
    dependOnGit(GitExactStep.create(b, "https://github.com/nektro/zig-tracer", "ccf9a6b85a38cc343aba772f2d2aac4df49000e1"), step, &@field(package_data, "_ede2wygpe1iy"));
    dependOnGit(GitExactStep.create(b, "https://github.com/nektro/zig-yaml", "e4e8dfe78a3a0e39d134382a18e8eb771418e850"), step, &@field(package_data, "_g982zq6e8wsv"));
    dependOnGit(GitExactStep.create(b, "https://github.com/madler/zlib", "da607da739fa6047df13e66a2af6b8bec7c2a498"), step, &@field(package_data, "_0e2d06bb494b"));
    dependOnGit(GitExactStep.create(b, "https://github.com/yaml/libyaml", "2c891fc7a770e8ba2fec34fc6b545c672beb37e6"), step, &@field(package_data, "_8mdbh0zuneb0"));
    dependOnGit(GitExactStep.create(b, "https://github.com/ziglibs/known-folders", "6da0d0c41b78b9ed2d34fa364fcb81b5ebece6c4"), step, &@field(package_data, "_2ta738wrqbaq"));
    return step;
}

fn trimPrefix(comptime T: type, haystack: []const T, needle: []const T) []const T {
    if (std.mem.startsWith(T, haystack, needle)) {
        return haystack[needle.len .. haystack.len];
    }
    return haystack;
}

fn flip(foo: anytype) !void {
    _ = foo catch return;
    return error.ExpectedError;
}

pub fn addAllTo(exe: *std.Build.Step.Compile) void {
    checkMinZig(builtin.zig_version, exe);
    const fetch_step = fetch(exe);
    @setEvalBranchQuota(1_000_000);
    for (packages) |pkg| {
        const module = pkg.module(exe, fetch_step);
        exe.root_module.addImport(pkg.name, module);
    }
    // clear module memo cache so addAllTo can be called more than once in the same build.zig
    inline for (comptime std.meta.declarations(package_data)) |decl| @field(package_data, decl).module_memo = null;
}

pub fn dependOnGit(ge: GitExactStep, s: *std.Build.Step, p: *Package) void {
    s.dependOn(ge.step);
    p.path = ge.path;
}

var link_lib_c = false;
pub const Package = struct {
    name: string = "",
    main: ?string = null,
    path: ?std.Build.LazyPath = null,
    deps: []const *Package = &.{},
    c_include_dirs: []const string = &.{},
    c_source_files: []const string = &.{},
    c_source_flags: []const string = &.{},
    system_libs: []const string = &.{},
    frameworks: []const string = &.{},
    module_memo: ?*std.Build.Module = null,
    translate_c_h: ?string = null,

    pub fn module(self: *Package, exe: *std.Build.Step.Compile, fetch_step: *std.Build.Step) *std.Build.Module {
        if (self.module_memo) |cached| {
            return cached;
        }
        const b = exe.step.owner;

        const result = b.createModule(.{
            .target = exe.root_module.resolved_target,
        });
        const target = result.resolved_target.?.result;
        const dummy_library = b.addLibrary(.{
            .linkage = .static,
            .name = b.fmt("dummy-{s}", .{self.name}),
            .root_module = b.createModule(.{
                .target = exe.root_module.resolved_target orelse b.graph.host,
                .optimize = exe.root_module.optimize.?,
            }),
        });
        dummy_library.step.dependOn(fetch_step);
        var links: u32 = 0;
        if (self.main) |m| {
            if (self.path) |p| {
                result.root_source_file = p.path(b, m);
            } else {
                result.root_source_file = b.path(m);
            }
        }
        for (self.deps) |item| {
            const module_dep = item.module(exe, fetch_step);
            if (module_dep.root_source_file != null) {
                result.addImport(item.name, module_dep);
            }
            for (module_dep.include_dirs.items) |jtem| {
                switch (jtem) {
                    .path => result.addIncludePath(jtem.path),
                    .path_system, .path_after, .framework_path, .framework_path_system, .other_step, .config_header_step => {},
                    .embed_path => {},
                }
            }
        }
        for (self.c_include_dirs) |item| {
            result.addIncludePath(self.path.?.path(b, item));
            dummy_library.root_module.addIncludePath(self.path.?.path(b, item));
            exe.root_module.addIncludePath(self.path.?.path(b, item));
            link_lib_c = true;
            links += 1;
        }
        for (self.c_source_files) |item| {
            dummy_library.root_module.addCSourceFile(.{ .file = self.path.?.path(b, item), .flags = self.c_source_flags });
            links += 1;
        }
        if (any_translate_c) if (self.translate_c_h) |h| {
            if (translate_c == null) translate_c = b.dependency("translate_c", .{});
            const t: Translator = .init(translate_c.?, .{
                .c_source_file = b.addWriteFile("c.h", b.fmt("// {s}\n#include <{s}>\n", .{ self.name, h })).getDirectory().path(b, "c.h"),
                .target = exe.root_module.resolved_target.?,
                .optimize = exe.root_module.optimize.?,
            });
            for (exe.root_module.include_dirs.items) |d| {
                if (d != .path) continue;
                t.addIncludePath(d.path);
            }
            result.addImport("c", t.mod);
            link_lib_c = true;
        };
        for (self.system_libs) |item| {
            if (std.zig.target.isLibCLibName(&target, item)) continue;
            dummy_library.root_module.linkSystemLibrary(item, .{});
            links += 1;
        }
        for (self.frameworks) |item| {
            dummy_library.root_module.linkFramework(item, .{});
            links += 1;
        }
        if (links > 0) {
            dummy_library.root_module.linkSystemLibrary("c", .{});
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
    const min = std.SemanticVersion.parse("0.17.0") catch return;
    if (current.order(min).compare(.lt)) @panic(exe.step.owner.fmt("Your Zig version v{f} does not meet the minimum build requirement of v{f}", .{current, min}));
}

pub const package_data = struct {
    pub var _o6ogpor87xc2 = Package{
        .name = "win32",
        .main = "win32.zig",
    };
    pub var _u7sysdckdymi = Package{
        .name = "ini",
        .main = "src/ini.zig",
    };
    pub var _s84v9o48ucb0 = Package{
        .name = "ansi",
        .main = "src/lib.zig",
    };
    pub var _f7dubzb7cyqe = Package{
        .name = "extras",
        .main = "src/lib.zig",
    };
    pub var _c1xirp1ota5p = Package{
        .name = "inquirer",
        .main = "src/lib.zig",
        .deps = &[_]*Package{ &_s84v9o48ucb0 },
        .translate_c_h = "termios.h",
    };
    pub var _96h80ezrvj7i = Package{
        .name = "leven",
        .main = "src/lib.zig",
    };
    pub var _0npcrzfdlrvk = Package{
        .name = "licenses",
        .main = "src/lib.zig",
    };
    pub var _pt88y5d80m25 = Package{
        .name = "licenses-text",
        .main = "src/lib.zig",
    };
    pub var _73bukkeci2u6 = Package{
        .name = "sys-darwin",
        .main = "sys_darwin.zig",
    };
    pub var _qfev2g50alvp = Package{
        .name = "sys-freebsd",
        .main = "freebsd.zig",
        .translate_c_h = "pthread.h",
    };
    pub var _h7tv7ayhffak = Package{
        .name = "sys-linux",
        .main = "mod.zig",
        .translate_c_h = "pthread.h",
    };
    pub var _uvkgl6xf1azv = Package{
        .name = "sys-netbsd",
        .main = "netbsd.zig",
        .translate_c_h = "pthread.h",
    };
    pub var _4rmxgmcykiba = Package{
        .name = "sys-openbsd",
        .main = "openbsd.zig",
        .translate_c_h = "pthread.h",
    };
    pub var _kscsl0145t7x = Package{
        .name = "nio",
        .main = "nio.zig",
        .deps = &[_]*Package{ &_h7tv7ayhffak, &_f7dubzb7cyqe, &_73bukkeci2u6, &_qfev2g50alvp, &_uvkgl6xf1azv, &_4rmxgmcykiba },
    };
    pub var _7l3oxw6nqqws = Package{
        .name = "intrusive-parser",
        .main = "intrusive_parser.zig",
        .deps = &[_]*Package{ &_f7dubzb7cyqe, &_kscsl0145t7x },
    };
    pub var _iecwp4b3bsfm = Package{
        .name = "time",
        .main = "time.zig",
        .deps = &[_]*Package{ &_f7dubzb7cyqe, &_h7tv7ayhffak, &_73bukkeci2u6, &_kscsl0145t7x, &_qfev2g50alvp, &_uvkgl6xf1azv, &_4rmxgmcykiba },
    };
    pub var _vph9l0hxpeze = Package{
        .name = "nfs",
        .main = "nfs.zig",
        .deps = &[_]*Package{ &_h7tv7ayhffak, &_kscsl0145t7x, &_iecwp4b3bsfm, &_73bukkeci2u6, &_qfev2g50alvp, &_uvkgl6xf1azv, &_4rmxgmcykiba },
    };
    pub var _2ovav391ivak = Package{
        .name = "detect-license",
        .main = "src/lib.zig",
        .deps = &[_]*Package{ &_pt88y5d80m25, &_96h80ezrvj7i, &_vph9l0hxpeze },
    };
    pub var _ede2wygpe1iy = Package{
        .name = "tracer",
        .main = "src/mod.zig",
        .deps = &[_]*Package{ &_f7dubzb7cyqe, &_h7tv7ayhffak, &_vph9l0hxpeze, &_kscsl0145t7x, &_iecwp4b3bsfm },
    };
    pub var _0k64oe2nuzvj = Package{
        .name = "git",
        .main = "git.zig",
        .deps = &[_]*Package{ &_iecwp4b3bsfm, &_f7dubzb7cyqe, &_ede2wygpe1iy, &_vph9l0hxpeze, &_kscsl0145t7x, &_0e2d06bb494b },
        .translate_c_h = "zlib.h",
    };
    pub var _ocmr9rtohgcc = Package{
        .name = "json",
        .main = "json.zig",
        .deps = &[_]*Package{ &_f7dubzb7cyqe, &_ede2wygpe1iy, &_7l3oxw6nqqws, &_kscsl0145t7x },
    };
    pub var _g982zq6e8wsv = Package{
        .name = "yaml",
        .main = "yaml.zig",
        .deps = &[_]*Package{ &_8mdbh0zuneb0 },
        .translate_c_h = "yaml.h",
    };
    pub var _0e2d06bb494b = Package{
        .c_include_dirs = &.{ "" },
        .c_source_files = &.{ "inftrees.c", "inflate.c", "adler32.c", "zutil.c", "trees.c", "gzclose.c", "gzwrite.c", "gzread.c", "deflate.c", "compress.c", "crc32.c", "infback.c", "gzlib.c", "uncompr.c", "inffast.c" },
        .c_source_flags = &.{ "-DZ_HAVE_UNISTD_H=1" },
    };
    pub var _8mdbh0zuneb0 = Package{
        .c_include_dirs = &.{ "include" },
        .c_source_files = &.{ "src/api.c", "src/dumper.c", "src/emitter.c", "src/loader.c", "src/parser.c", "src/reader.c", "src/scanner.c", "src/writer.c" },
        .c_source_flags = &.{ "-DYAML_VERSION_MAJOR=0", "-DYAML_VERSION_MINOR=2", "-DYAML_VERSION_PATCH=5", "-DYAML_VERSION_STRING=\"0.2.5\"", "-DYAML_DECLARE_STATIC=1" },
    };
    pub var _2ta738wrqbaq = Package{
        .name = "known-folders",
        .main = "known-folders.zig",
    };
    pub var _89ujp8gq842x = Package{
        .name = "zigmod",
        .main = "src/lib.zig",
        .deps = &[_]*Package{ &_g982zq6e8wsv, &_s84v9o48ucb0, &_2ta738wrqbaq, &_0npcrzfdlrvk, &_2ovav391ivak, &_c1xirp1ota5p, &_u7sysdckdymi, &_iecwp4b3bsfm, &_f7dubzb7cyqe, &_0k64oe2nuzvj, &_ocmr9rtohgcc, &_kscsl0145t7x, &_vph9l0hxpeze },
    };
    pub var _root = Package{
    };
};

pub const packages = [_]*Package{
    &package_data._89ujp8gq842x,
    &package_data._o6ogpor87xc2,
    &package_data._f7dubzb7cyqe,
    &package_data._s84v9o48ucb0,
    &package_data._kscsl0145t7x,
    &package_data._vph9l0hxpeze,
};

pub const pkgs = struct {
    pub const zigmod = &package_data._89ujp8gq842x;
    pub const win32 = &package_data._o6ogpor87xc2;
    pub const extras = &package_data._f7dubzb7cyqe;
    pub const ansi = &package_data._s84v9o48ucb0;
    pub const nio = &package_data._kscsl0145t7x;
    pub const nfs = &package_data._vph9l0hxpeze;
};

pub const imports = struct {
};
