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

        fn make(step: *std.Build.Step, prog_node: std.Progress.Node) !void {
            _ = step;
            _ = prog_node;
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
    step.dependOn(&GitExactStep.create(b, "https://github.com/nektro/arqv-ini", "77c6ab4dc5a98017b8a0d151b040d43f35c10f64").step);
    step.dependOn(&GitExactStep.create(b, "https://github.com/nektro/iguanaTLS", "ac960345b771c08e1ee73aec02fbcc068e197f9c").step);
    step.dependOn(&GitExactStep.create(b, "https://github.com/nektro/zfetch", "1e2fa1288816ede7f5e48d2a33230e4135a05ebc").step);
    step.dependOn(&GitExactStep.create(b, "https://github.com/nektro/zig-ansi", "e135d7b33f961eb30e9b14a4b410b1e24f808aac").step);
    step.dependOn(&GitExactStep.create(b, "https://github.com/nektro/zig-detect-license", "666da389f58c8b836e48a446289dc8841a71cf07").step);
    step.dependOn(&GitExactStep.create(b, "https://github.com/nektro/zig-extras", "6da75a0abf28b1b9ff74c6d54e0eba0bf647f9ad").step);
    step.dependOn(&GitExactStep.create(b, "https://github.com/nektro/zig-git", "6f387f91b0fbc7fbc7c13f6d184a25e675a26195").step);
    step.dependOn(&GitExactStep.create(b, "https://github.com/nektro/zig-inquirer", "aa5fa4c5a5fbd947a09667e878c13c05395ca0f3").step);
    step.dependOn(&GitExactStep.create(b, "https://github.com/nektro/zig-intrusive-parser", "7323c14a3732936260850e2546081e36d36368de").step);
    step.dependOn(&GitExactStep.create(b, "https://github.com/nektro/zig-json", "b6f62876a1d2bdb8fcbfe740912c570acb8d2922").step);
    step.dependOn(&GitExactStep.create(b, "https://github.com/nektro/zig-leven", "da5d1fa81254e8567d10eee8a76868fefb248747").step);
    step.dependOn(&GitExactStep.create(b, "https://github.com/nektro/zig-licenses", "a6682626e50219f04571cb2d9af8d77bf2fa97ca").step);
    step.dependOn(&GitExactStep.create(b, "https://github.com/nektro/zig-licenses-text", "acb8e0a423fd50106ffe3558b90a5f23c12515f7").step);
    step.dependOn(&GitExactStep.create(b, "https://github.com/nektro/zig-time", "e946a144423cdb5dac3d46d6856c6e6da73e9305").step);
    step.dependOn(&GitExactStep.create(b, "https://github.com/nektro/zig-tracer", "4c2ab3f9899568ea119ed44ffbc255f91ff1cda1").step);
    step.dependOn(&GitExactStep.create(b, "https://github.com/nektro/zig-yaml", "0d17fb99cba338aedc1abac12d78d5e5f04f0b6b").step);
    step.dependOn(&GitExactStep.create(b, "https://github.com/truemedian/hzzp", "a7f03a1e652abe8c89b376d090cec50acb0d2a1a").step);
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
            .target = exe.root_module.resolved_target orelse b.host,
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
        .store = "/git/github.com/nektro/arqv-ini/77c6ab4dc5a98017b8a0d151b040d43f35c10f64",
        .name = "ini",
        .entry = "/git/github.com/nektro/arqv-ini/77c6ab4dc5a98017b8a0d151b040d43f35c10f64/src/ini.zig",
    };
    pub var _csbnipaad8n7 = Package{
        .store = "/git/github.com/nektro/iguanaTLS/ac960345b771c08e1ee73aec02fbcc068e197f9c",
        .name = "iguanaTLS",
        .entry = "/git/github.com/nektro/iguanaTLS/ac960345b771c08e1ee73aec02fbcc068e197f9c/src/main.zig",
    };
    pub var _s84v9o48ucb0 = Package{
        .store = "/git/github.com/nektro/zig-ansi/e135d7b33f961eb30e9b14a4b410b1e24f808aac",
        .name = "ansi",
        .entry = "/git/github.com/nektro/zig-ansi/e135d7b33f961eb30e9b14a4b410b1e24f808aac/src/lib.zig",
    };
    pub var _f7dubzb7cyqe = Package{
        .store = "/git/github.com/nektro/zig-extras/6da75a0abf28b1b9ff74c6d54e0eba0bf647f9ad",
        .name = "extras",
        .entry = "/git/github.com/nektro/zig-extras/6da75a0abf28b1b9ff74c6d54e0eba0bf647f9ad/src/lib.zig",
    };
    pub var _c1xirp1ota5p = Package{
        .store = "/git/github.com/nektro/zig-inquirer/aa5fa4c5a5fbd947a09667e878c13c05395ca0f3",
        .name = "inquirer",
        .entry = "/git/github.com/nektro/zig-inquirer/aa5fa4c5a5fbd947a09667e878c13c05395ca0f3/src/lib.zig",
        .deps = &[_]*Package{ &_s84v9o48ucb0 },
    };
    pub var _7l3oxw6nqqws = Package{
        .store = "/git/github.com/nektro/zig-intrusive-parser/7323c14a3732936260850e2546081e36d36368de",
        .name = "intrusive-parser",
        .entry = "/git/github.com/nektro/zig-intrusive-parser/7323c14a3732936260850e2546081e36d36368de/intrusive_parser.zig",
        .deps = &[_]*Package{ &_f7dubzb7cyqe },
    };
    pub var _96h80ezrvj7i = Package{
        .store = "/git/github.com/nektro/zig-leven/da5d1fa81254e8567d10eee8a76868fefb248747",
        .name = "leven",
        .entry = "/git/github.com/nektro/zig-leven/da5d1fa81254e8567d10eee8a76868fefb248747/src/lib.zig",
    };
    pub var _0npcrzfdlrvk = Package{
        .store = "/git/github.com/nektro/zig-licenses/a6682626e50219f04571cb2d9af8d77bf2fa97ca",
        .name = "licenses",
        .entry = "/git/github.com/nektro/zig-licenses/a6682626e50219f04571cb2d9af8d77bf2fa97ca/src/lib.zig",
    };
    pub var _pt88y5d80m25 = Package{
        .store = "/git/github.com/nektro/zig-licenses-text/acb8e0a423fd50106ffe3558b90a5f23c12515f7",
        .name = "licenses-text",
        .entry = "/git/github.com/nektro/zig-licenses-text/acb8e0a423fd50106ffe3558b90a5f23c12515f7/src/lib.zig",
    };
    pub var _2ovav391ivak = Package{
        .store = "/git/github.com/nektro/zig-detect-license/666da389f58c8b836e48a446289dc8841a71cf07",
        .name = "detect-license",
        .entry = "/git/github.com/nektro/zig-detect-license/666da389f58c8b836e48a446289dc8841a71cf07/src/lib.zig",
        .deps = &[_]*Package{ &_pt88y5d80m25, &_96h80ezrvj7i },
    };
    pub var _iecwp4b3bsfm = Package{
        .store = "/git/github.com/nektro/zig-time/e946a144423cdb5dac3d46d6856c6e6da73e9305",
        .name = "time",
        .entry = "/git/github.com/nektro/zig-time/e946a144423cdb5dac3d46d6856c6e6da73e9305/time.zig",
        .deps = &[_]*Package{ &_f7dubzb7cyqe },
    };
    pub var _ede2wygpe1iy = Package{
        .store = "/git/github.com/nektro/zig-tracer/4c2ab3f9899568ea119ed44ffbc255f91ff1cda1",
        .name = "tracer",
        .entry = "/git/github.com/nektro/zig-tracer/4c2ab3f9899568ea119ed44ffbc255f91ff1cda1/src/mod.zig",
        .deps = &[_]*Package{ &_f7dubzb7cyqe },
    };
    pub var _0k64oe2nuzvj = Package{
        .store = "/git/github.com/nektro/zig-git/6f387f91b0fbc7fbc7c13f6d184a25e675a26195",
        .name = "git",
        .entry = "/git/github.com/nektro/zig-git/6f387f91b0fbc7fbc7c13f6d184a25e675a26195/git.zig",
        .deps = &[_]*Package{ &_iecwp4b3bsfm, &_f7dubzb7cyqe, &_ede2wygpe1iy },
    };
    pub var _ocmr9rtohgcc = Package{
        .store = "/git/github.com/nektro/zig-json/b6f62876a1d2bdb8fcbfe740912c570acb8d2922",
        .name = "json",
        .entry = "/git/github.com/nektro/zig-json/b6f62876a1d2bdb8fcbfe740912c570acb8d2922/json.zig",
        .deps = &[_]*Package{ &_f7dubzb7cyqe, &_ede2wygpe1iy, &_7l3oxw6nqqws },
    };
    pub var _g982zq6e8wsv = Package{
        .store = "/git/github.com/nektro/zig-yaml/0d17fb99cba338aedc1abac12d78d5e5f04f0b6b",
        .name = "yaml",
        .entry = "/git/github.com/nektro/zig-yaml/0d17fb99cba338aedc1abac12d78d5e5f04f0b6b/yaml.zig",
        .deps = &[_]*Package{ &_8mdbh0zuneb0, &_f7dubzb7cyqe },
    };
    pub var _9k24gimke1an = Package{
        .store = "/git/github.com/truemedian/hzzp/a7f03a1e652abe8c89b376d090cec50acb0d2a1a",
        .name = "hzzp",
        .entry = "/git/github.com/truemedian/hzzp/a7f03a1e652abe8c89b376d090cec50acb0d2a1a/src/main.zig",
    };
    pub var _ejw82j2ipa0e = Package{
        .store = "/git/github.com/nektro/zfetch/1e2fa1288816ede7f5e48d2a33230e4135a05ebc",
        .name = "zfetch",
        .entry = "/git/github.com/nektro/zfetch/1e2fa1288816ede7f5e48d2a33230e4135a05ebc/src/main.zig",
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
