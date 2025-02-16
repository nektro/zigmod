// zig fmt: off
const std = @import("std");
const builtin = @import("builtin");
const string = []const u8;

pub const GitExactStep = struct {
    step: std.Build.Step,
    builder: *std.Build,
    url: string,
    commit: string,

        pub fn create(b: *std.Build, url: string, commit: string) *GitExactStep {
            var result = b.allocator.create(GitExactStep) catch @panic("memory");
            result.* = GitExactStep{
                .step = std.Build.Step.init(.{
                    .id = .custom,
                    .name = b.fmt("git clone {s} @ {s}", .{ url, commit }),
                    .owner = b,
                    .makeFn = make,
                }),
                .builder = b,
                .url = url,
                .commit = commit,
            };

            var urlpath = url;
            urlpath = trimPrefix(u8, urlpath, "https://");
            urlpath = trimPrefix(u8, urlpath, "git://");
            const repopath = b.fmt("{s}/zigmod/deps/git/{s}/{s}", .{ b.cache_root.path.?, urlpath, commit });
            flip(std.fs.cwd().access(repopath, .{})) catch return result;

            var clonestep = std.Build.Step.Run.create(b, "clone");
            clonestep.addArgs(&.{ "git", "clone", "-q", "--progress", url, repopath });

            var checkoutstep = std.Build.Step.Run.create(b, "checkout");
            checkoutstep.addArgs(&.{ "git", "-C", repopath, "checkout", "-q", commit });
            result.step.dependOn(&checkoutstep.step);
            checkoutstep.step.dependOn(&clonestep.step);

            return result;
        }

        fn make(step: *std.Build.Step, options: std.Build.Step.MakeOptions) !void {
            _ = step;
            _ = options;
        }
};

pub fn fetch(exe: *std.Build.Step.Compile) *std.Build.Step {
    const b = exe.step.owner;
    const step = b.step("fetch", "");
    inline for (comptime std.meta.declarations(package_data)) |decl| {
          const path = &@field(package_data, decl.name).entry;
          const root = if (@field(package_data, decl.name).store) |_| b.cache_root.path.? else ".";
          if (path.* != null) path.* = b.fmt("{s}/zigmod/deps{s}", .{ root, path.*.? });
    }
    step.dependOn(&GitExactStep.create(b, "https://github.com/marlersoft/zigwin32", "407a4c7b869ee3d10db520fdfae8b9faf9b2adb5").step);
    step.dependOn(&GitExactStep.create(b, "https://github.com/nektro/arqv-ini", "4c84770a8a2d10b9a9bb1157d69f49e8cd398e1a").step);
    step.dependOn(&GitExactStep.create(b, "https://github.com/nektro/iguanaTLS", "c0a8d949c5cf8c72e2dfdaddee9fb7854b1c217e").step);
    step.dependOn(&GitExactStep.create(b, "https://github.com/nektro/zfetch", "c2883dd57698f223b2cfdccfc7ea357a12e5f741").step);
    step.dependOn(&GitExactStep.create(b, "https://github.com/nektro/zig-ansi", "b0d7878680fff57fd5ed9e7e4d2694acc0b81255").step);
    step.dependOn(&GitExactStep.create(b, "https://github.com/nektro/zig-detect-license", "3049b32e72045d8cefd64b8a7f9b0b8f9e76d80a").step);
    step.dependOn(&GitExactStep.create(b, "https://github.com/nektro/zig-extras", "d4f8a6437cb5068072e4df338af77dde15ad3625").step);
    step.dependOn(&GitExactStep.create(b, "https://github.com/nektro/zig-git", "11805225d52bc28c2edc31fd7a855bd1aa16bc67").step);
    step.dependOn(&GitExactStep.create(b, "https://github.com/nektro/zig-inquirer", "d6005ee08b2f5ce3c4554fa7f91e733f58b1a434").step);
    step.dependOn(&GitExactStep.create(b, "https://github.com/nektro/zig-intrusive-parser", "75a9745d9100b17a9443e6a0051cb140ffbcd0b1").step);
    step.dependOn(&GitExactStep.create(b, "https://github.com/nektro/zig-json", "03b5392e53513a0f90aa5c10219c7caee6383997").step);
    step.dependOn(&GitExactStep.create(b, "https://github.com/nektro/zig-leven", "1c0e475b056ccc6a343187702ee4f3dc415e07cb").step);
    step.dependOn(&GitExactStep.create(b, "https://github.com/nektro/zig-licenses", "d683ae4d499c2a1f7f8c9cdd7304cd5a3c766e76").step);
    step.dependOn(&GitExactStep.create(b, "https://github.com/nektro/zig-licenses-text", "f1830fbbd78a31d54d8469a0243cb904e7295e10").step);
    step.dependOn(&GitExactStep.create(b, "https://github.com/nektro/zig-time", "b9a93152af3ba73e5f681f73a67f0d676e2ad433").step);
    step.dependOn(&GitExactStep.create(b, "https://github.com/nektro/zig-tracer", "662774eedca41771f9ebd1ab45cfdc8e4319d4b4").step);
    step.dependOn(&GitExactStep.create(b, "https://github.com/nektro/zig-yaml", "4489a2ed0b3f90e962527eaf9ac9c0203a99094a").step);
    step.dependOn(&GitExactStep.create(b, "https://github.com/truemedian/hzzp", "ab212bd208f0eb54d85861679677c5e3dc9bb543").step);
    step.dependOn(&GitExactStep.create(b, "https://github.com/ziglibs/known-folders", "1cceeb70e77dec941a4178160ff6c8d05a74de6f").step);
    step.dependOn(&GitExactStep.create(b, "https://github.com/yaml/libyaml", "2c891fc7a770e8ba2fec34fc6b545c672beb37e6").step);
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
}

var link_lib_c = false;
pub const Package = struct {
    name: string = "",
    entry: ?string = null,
    store: ?string = null,
    deps: []const *Package = &.{},
    c_include_dirs: []const string = &.{},
    c_source_files: []const string = &.{},
    c_source_flags: []const string = &.{},
    system_libs: []const string = &.{},
    frameworks: []const string = &.{},
    module_memo: ?*std.Build.Module = null,

    pub fn module(self: *Package, exe: *std.Build.Step.Compile, fetch_step: *std.Build.Step) *std.Build.Module {
        if (self.module_memo) |cached| {
            return cached;
        }
        const b = exe.step.owner;

        const result = b.createModule(.{});
        const dummy_library = b.addStaticLibrary(.{
            .name = "dummy",
            .target = exe.root_module.resolved_target orelse b.graph.host,
            .optimize = exe.root_module.optimize.?,
        });
        dummy_library.step.dependOn(fetch_step);
        if (self.entry) |capture| {
            result.root_source_file = .{ .cwd_relative = capture };
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
                }
            }
        }
        for (self.c_include_dirs) |item| {
            result.addIncludePath(.{ .cwd_relative = b.fmt("{s}/zigmod/deps{s}/{s}", .{ b.cache_root.path.?, self.store.?, item }) });
            dummy_library.addIncludePath(.{ .cwd_relative = b.fmt("{s}/zigmod/deps{s}/{s}", .{ b.cache_root.path.?, self.store.?, item }) });
            link_lib_c = true;
        }
        for (self.c_source_files) |item| {
            dummy_library.addCSourceFile(.{ .file = .{ .cwd_relative = b.fmt("{s}/zigmod/deps{s}/{s}", .{ b.cache_root.path.?, self.store.?, item }) }, .flags = self.c_source_flags });
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
    const min = std.SemanticVersion.parse("0.13.0") catch return;
    if (current.order(min).compare(.lt)) @panic(exe.step.owner.fmt("Your Zig version v{} does not meet the minimum build requirement of v{}", .{current, min}));
}

pub const package_data = struct {
    pub var _o6ogpor87xc2 = Package{
        .store = "/git/github.com/marlersoft/zigwin32/407a4c7b869ee3d10db520fdfae8b9faf9b2adb5",
        .name = "win32",
        .entry = "/git/github.com/marlersoft/zigwin32/407a4c7b869ee3d10db520fdfae8b9faf9b2adb5/win32.zig",
    };
    pub var _u7sysdckdymi = Package{
        .store = "/git/github.com/nektro/arqv-ini/4c84770a8a2d10b9a9bb1157d69f49e8cd398e1a",
        .name = "ini",
        .entry = "/git/github.com/nektro/arqv-ini/4c84770a8a2d10b9a9bb1157d69f49e8cd398e1a/src/ini.zig",
    };
    pub var _csbnipaad8n7 = Package{
        .store = "/git/github.com/nektro/iguanaTLS/c0a8d949c5cf8c72e2dfdaddee9fb7854b1c217e",
        .name = "iguanaTLS",
        .entry = "/git/github.com/nektro/iguanaTLS/c0a8d949c5cf8c72e2dfdaddee9fb7854b1c217e/src/main.zig",
    };
    pub var _s84v9o48ucb0 = Package{
        .store = "/git/github.com/nektro/zig-ansi/b0d7878680fff57fd5ed9e7e4d2694acc0b81255",
        .name = "ansi",
        .entry = "/git/github.com/nektro/zig-ansi/b0d7878680fff57fd5ed9e7e4d2694acc0b81255/src/lib.zig",
    };
    pub var _f7dubzb7cyqe = Package{
        .store = "/git/github.com/nektro/zig-extras/d4f8a6437cb5068072e4df338af77dde15ad3625",
        .name = "extras",
        .entry = "/git/github.com/nektro/zig-extras/d4f8a6437cb5068072e4df338af77dde15ad3625/src/lib.zig",
    };
    pub var _c1xirp1ota5p = Package{
        .store = "/git/github.com/nektro/zig-inquirer/d6005ee08b2f5ce3c4554fa7f91e733f58b1a434",
        .name = "inquirer",
        .entry = "/git/github.com/nektro/zig-inquirer/d6005ee08b2f5ce3c4554fa7f91e733f58b1a434/src/lib.zig",
        .deps = &[_]*Package{ &_s84v9o48ucb0 },
    };
    pub var _7l3oxw6nqqws = Package{
        .store = "/git/github.com/nektro/zig-intrusive-parser/75a9745d9100b17a9443e6a0051cb140ffbcd0b1",
        .name = "intrusive-parser",
        .entry = "/git/github.com/nektro/zig-intrusive-parser/75a9745d9100b17a9443e6a0051cb140ffbcd0b1/intrusive_parser.zig",
        .deps = &[_]*Package{ &_f7dubzb7cyqe },
    };
    pub var _96h80ezrvj7i = Package{
        .store = "/git/github.com/nektro/zig-leven/1c0e475b056ccc6a343187702ee4f3dc415e07cb",
        .name = "leven",
        .entry = "/git/github.com/nektro/zig-leven/1c0e475b056ccc6a343187702ee4f3dc415e07cb/src/lib.zig",
    };
    pub var _0npcrzfdlrvk = Package{
        .store = "/git/github.com/nektro/zig-licenses/d683ae4d499c2a1f7f8c9cdd7304cd5a3c766e76",
        .name = "licenses",
        .entry = "/git/github.com/nektro/zig-licenses/d683ae4d499c2a1f7f8c9cdd7304cd5a3c766e76/src/lib.zig",
    };
    pub var _pt88y5d80m25 = Package{
        .store = "/git/github.com/nektro/zig-licenses-text/f1830fbbd78a31d54d8469a0243cb904e7295e10",
        .name = "licenses-text",
        .entry = "/git/github.com/nektro/zig-licenses-text/f1830fbbd78a31d54d8469a0243cb904e7295e10/src/lib.zig",
    };
    pub var _2ovav391ivak = Package{
        .store = "/git/github.com/nektro/zig-detect-license/3049b32e72045d8cefd64b8a7f9b0b8f9e76d80a",
        .name = "detect-license",
        .entry = "/git/github.com/nektro/zig-detect-license/3049b32e72045d8cefd64b8a7f9b0b8f9e76d80a/src/lib.zig",
        .deps = &[_]*Package{ &_pt88y5d80m25, &_96h80ezrvj7i },
    };
    pub var _iecwp4b3bsfm = Package{
        .store = "/git/github.com/nektro/zig-time/b9a93152af3ba73e5f681f73a67f0d676e2ad433",
        .name = "time",
        .entry = "/git/github.com/nektro/zig-time/b9a93152af3ba73e5f681f73a67f0d676e2ad433/time.zig",
        .deps = &[_]*Package{ &_f7dubzb7cyqe },
    };
    pub var _ede2wygpe1iy = Package{
        .store = "/git/github.com/nektro/zig-tracer/662774eedca41771f9ebd1ab45cfdc8e4319d4b4",
        .name = "tracer",
        .entry = "/git/github.com/nektro/zig-tracer/662774eedca41771f9ebd1ab45cfdc8e4319d4b4/src/mod.zig",
        .deps = &[_]*Package{ &_f7dubzb7cyqe },
    };
    pub var _0k64oe2nuzvj = Package{
        .store = "/git/github.com/nektro/zig-git/11805225d52bc28c2edc31fd7a855bd1aa16bc67",
        .name = "git",
        .entry = "/git/github.com/nektro/zig-git/11805225d52bc28c2edc31fd7a855bd1aa16bc67/git.zig",
        .deps = &[_]*Package{ &_iecwp4b3bsfm, &_f7dubzb7cyqe, &_ede2wygpe1iy },
    };
    pub var _ocmr9rtohgcc = Package{
        .store = "/git/github.com/nektro/zig-json/03b5392e53513a0f90aa5c10219c7caee6383997",
        .name = "json",
        .entry = "/git/github.com/nektro/zig-json/03b5392e53513a0f90aa5c10219c7caee6383997/json.zig",
        .deps = &[_]*Package{ &_f7dubzb7cyqe, &_ede2wygpe1iy, &_7l3oxw6nqqws },
    };
    pub var _g982zq6e8wsv = Package{
        .store = "/git/github.com/nektro/zig-yaml/4489a2ed0b3f90e962527eaf9ac9c0203a99094a",
        .name = "yaml",
        .entry = "/git/github.com/nektro/zig-yaml/4489a2ed0b3f90e962527eaf9ac9c0203a99094a/yaml.zig",
        .deps = &[_]*Package{ &_8mdbh0zuneb0, &_f7dubzb7cyqe },
    };
    pub var _9k24gimke1an = Package{
        .store = "/git/github.com/truemedian/hzzp/ab212bd208f0eb54d85861679677c5e3dc9bb543",
        .name = "hzzp",
        .entry = "/git/github.com/truemedian/hzzp/ab212bd208f0eb54d85861679677c5e3dc9bb543/src/main.zig",
    };
    pub var _ejw82j2ipa0e = Package{
        .store = "/git/github.com/nektro/zfetch/c2883dd57698f223b2cfdccfc7ea357a12e5f741",
        .name = "zfetch",
        .entry = "/git/github.com/nektro/zfetch/c2883dd57698f223b2cfdccfc7ea357a12e5f741/src/main.zig",
        .deps = &[_]*Package{ &_9k24gimke1an, &_csbnipaad8n7 },
    };
    pub var _2ta738wrqbaq = Package{
        .store = "/git/github.com/ziglibs/known-folders/1cceeb70e77dec941a4178160ff6c8d05a74de6f",
        .name = "known-folders",
        .entry = "/git/github.com/ziglibs/known-folders/1cceeb70e77dec941a4178160ff6c8d05a74de6f/known-folders.zig",
    };
    pub var _89ujp8gq842x = Package{
        .name = "zigmod",
        .entry = "/../..//src/lib.zig",
        .deps = &[_]*Package{ &_g982zq6e8wsv, &_s84v9o48ucb0, &_2ta738wrqbaq, &_0npcrzfdlrvk, &_ejw82j2ipa0e, &_2ovav391ivak, &_c1xirp1ota5p, &_u7sysdckdymi, &_iecwp4b3bsfm, &_f7dubzb7cyqe, &_0k64oe2nuzvj, &_ocmr9rtohgcc },
    };
    pub var _root = Package{
    };
    pub var _8mdbh0zuneb0 = Package{
        .store = "/git/github.com/yaml/libyaml/2c891fc7a770e8ba2fec34fc6b545c672beb37e6",
        .c_include_dirs = &.{ "include" },
        .c_source_files = &.{ "src/api.c", "src/dumper.c", "src/emitter.c", "src/loader.c", "src/parser.c", "src/reader.c", "src/scanner.c", "src/writer.c" },
        .c_source_flags = &.{ "-DYAML_VERSION_MAJOR=0", "-DYAML_VERSION_MINOR=2", "-DYAML_VERSION_PATCH=5", "-DYAML_VERSION_STRING=\"0.2.5\"", "-DYAML_DECLARE_STATIC=1" },
    };
};

pub const packages = [_]*Package{
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
