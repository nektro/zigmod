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

        fn make(step: *std.Build.Step, prog_node: *std.Progress.Node) !void {
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
    step.dependOn(&GitExactStep.create(b, "https://github.com/marlersoft/zigwin32", "c778640d3dc153e900fbe37e2816b5176af3c802").step);
    step.dependOn(&GitExactStep.create(b, "https://github.com/nektro/arqv-ini", "38a018ad3a19d5b4663a5364d2d31271f250846b").step);
    step.dependOn(&GitExactStep.create(b, "https://github.com/nektro/iguanaTLS", "4dc8850883b49e4a452871298788b06b1af9fe24").step);
    step.dependOn(&GitExactStep.create(b, "https://github.com/nektro/zfetch", "863be236188e5f24d16554f9dcd7df96dd254a13").step);
    step.dependOn(&GitExactStep.create(b, "https://github.com/nektro/zig-ansi", "c3e439f86b0484e4428f38c4d8b07b7b5ae1634b").step);
    step.dependOn(&GitExactStep.create(b, "https://github.com/nektro/zig-detect-license", "3ff57d0681b7bd7f8ca9bd092afa0b4bfe2f1afd").step);
    step.dependOn(&GitExactStep.create(b, "https://github.com/nektro/zig-extras", "74f0ddb0a4dfa7921739b88cc381951a6b6e73ce").step);
    step.dependOn(&GitExactStep.create(b, "https://github.com/nektro/zig-git", "103f4e419c35b88f802bb8234ece1c0a9aa40c03").step);
    step.dependOn(&GitExactStep.create(b, "https://github.com/nektro/zig-inquirer", "9e1d873db79e9ffa6ae6e06bd372428c9be85d97").step);
    step.dependOn(&GitExactStep.create(b, "https://github.com/nektro/zig-leven", "e548b0bcc7b6f34f636c0b6b905928d31254c54d").step);
    step.dependOn(&GitExactStep.create(b, "https://github.com/nektro/zig-licenses", "f46d9f774df929885eef66c733a1e2a46bf16aec").step);
    step.dependOn(&GitExactStep.create(b, "https://github.com/nektro/zig-licenses-text", "b01e5a2dffcc564bddd8f514fe64bab9b5c52572").step);
    step.dependOn(&GitExactStep.create(b, "https://github.com/nektro/zig-range", "4b2f12808aa09be4b27a163efc424dd4e0415992").step);
    step.dependOn(&GitExactStep.create(b, "https://github.com/nektro/zig-time", "ba546bbf2e8438c9b2325f36f392c9d95b432e8e").step);
    step.dependOn(&GitExactStep.create(b, "https://github.com/nektro/zig-tracer", "ad868b45cfd445aa4d3f53cf8dda4b62b73efb54").step);
    step.dependOn(&GitExactStep.create(b, "https://github.com/nektro/zig-yaml", "0d17fb99cba338aedc1abac12d78d5e5f04f0b6b").step);
    step.dependOn(&GitExactStep.create(b, "https://github.com/truemedian/hzzp", "a7f03a1e652abe8c89b376d090cec50acb0d2a1a").step);
    step.dependOn(&GitExactStep.create(b, "https://github.com/ziglibs/known-folders", "0ad514dcfb7525e32ae349b9acc0a53976f3a9fa").step);
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
            result.root_source_file = .{ .path = capture };
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
    const min = std.SemanticVersion.parse("0.12.0") catch return;
    if (current.order(min).compare(.lt)) @panic(exe.step.owner.fmt("Your Zig version v{} does not meet the minimum build requirement of v{}", .{current, min}));
}

pub const package_data = struct {
    pub var _o6ogpor87xc2 = Package{
        .store = "/git/github.com/marlersoft/zigwin32/c778640d3dc153e900fbe37e2816b5176af3c802",
        .name = "win32",
        .entry = "/git/github.com/marlersoft/zigwin32/c778640d3dc153e900fbe37e2816b5176af3c802/win32.zig",
    };
    pub var _u7sysdckdymi = Package{
        .store = "/git/github.com/nektro/arqv-ini/38a018ad3a19d5b4663a5364d2d31271f250846b",
        .name = "ini",
        .entry = "/git/github.com/nektro/arqv-ini/38a018ad3a19d5b4663a5364d2d31271f250846b/src/ini.zig",
    };
    pub var _csbnipaad8n7 = Package{
        .store = "/git/github.com/nektro/iguanaTLS/4dc8850883b49e4a452871298788b06b1af9fe24",
        .name = "iguanaTLS",
        .entry = "/git/github.com/nektro/iguanaTLS/4dc8850883b49e4a452871298788b06b1af9fe24/src/main.zig",
    };
    pub var _s84v9o48ucb0 = Package{
        .store = "/git/github.com/nektro/zig-ansi/c3e439f86b0484e4428f38c4d8b07b7b5ae1634b",
        .name = "ansi",
        .entry = "/git/github.com/nektro/zig-ansi/c3e439f86b0484e4428f38c4d8b07b7b5ae1634b/src/lib.zig",
    };
    pub var _f7dubzb7cyqe = Package{
        .store = "/git/github.com/nektro/zig-extras/74f0ddb0a4dfa7921739b88cc381951a6b6e73ce",
        .name = "extras",
        .entry = "/git/github.com/nektro/zig-extras/74f0ddb0a4dfa7921739b88cc381951a6b6e73ce/src/lib.zig",
    };
    pub var _0npcrzfdlrvk = Package{
        .store = "/git/github.com/nektro/zig-licenses/f46d9f774df929885eef66c733a1e2a46bf16aec",
        .name = "licenses",
        .entry = "/git/github.com/nektro/zig-licenses/f46d9f774df929885eef66c733a1e2a46bf16aec/src/lib.zig",
    };
    pub var _pt88y5d80m25 = Package{
        .store = "/git/github.com/nektro/zig-licenses-text/b01e5a2dffcc564bddd8f514fe64bab9b5c52572",
        .name = "licenses-text",
        .entry = "/git/github.com/nektro/zig-licenses-text/b01e5a2dffcc564bddd8f514fe64bab9b5c52572/src/lib.zig",
    };
    pub var _tnj3qf44tpeq = Package{
        .store = "/git/github.com/nektro/zig-range/4b2f12808aa09be4b27a163efc424dd4e0415992",
        .name = "range",
        .entry = "/git/github.com/nektro/zig-range/4b2f12808aa09be4b27a163efc424dd4e0415992/src/lib.zig",
    };
    pub var _c1xirp1ota5p = Package{
        .store = "/git/github.com/nektro/zig-inquirer/9e1d873db79e9ffa6ae6e06bd372428c9be85d97",
        .name = "inquirer",
        .entry = "/git/github.com/nektro/zig-inquirer/9e1d873db79e9ffa6ae6e06bd372428c9be85d97/src/lib.zig",
        .deps = &[_]*Package{ &_s84v9o48ucb0, &_tnj3qf44tpeq },
    };
    pub var _96h80ezrvj7i = Package{
        .store = "/git/github.com/nektro/zig-leven/e548b0bcc7b6f34f636c0b6b905928d31254c54d",
        .name = "leven",
        .entry = "/git/github.com/nektro/zig-leven/e548b0bcc7b6f34f636c0b6b905928d31254c54d/src/lib.zig",
        .deps = &[_]*Package{ &_tnj3qf44tpeq },
    };
    pub var _2ovav391ivak = Package{
        .store = "/git/github.com/nektro/zig-detect-license/3ff57d0681b7bd7f8ca9bd092afa0b4bfe2f1afd",
        .name = "detect-license",
        .entry = "/git/github.com/nektro/zig-detect-license/3ff57d0681b7bd7f8ca9bd092afa0b4bfe2f1afd/src/lib.zig",
        .deps = &[_]*Package{ &_pt88y5d80m25, &_96h80ezrvj7i },
    };
    pub var _iecwp4b3bsfm = Package{
        .store = "/git/github.com/nektro/zig-time/ba546bbf2e8438c9b2325f36f392c9d95b432e8e",
        .name = "time",
        .entry = "/git/github.com/nektro/zig-time/ba546bbf2e8438c9b2325f36f392c9d95b432e8e/time.zig",
        .deps = &[_]*Package{ &_f7dubzb7cyqe },
    };
    pub var _ede2wygpe1iy = Package{
        .store = "/git/github.com/nektro/zig-tracer/ad868b45cfd445aa4d3f53cf8dda4b62b73efb54",
        .name = "tracer",
        .entry = "/git/github.com/nektro/zig-tracer/ad868b45cfd445aa4d3f53cf8dda4b62b73efb54/src/mod.zig",
        .deps = &[_]*Package{ &_f7dubzb7cyqe },
    };
    pub var _0k64oe2nuzvj = Package{
        .store = "/git/github.com/nektro/zig-git/103f4e419c35b88f802bb8234ece1c0a9aa40c03",
        .name = "git",
        .entry = "/git/github.com/nektro/zig-git/103f4e419c35b88f802bb8234ece1c0a9aa40c03/git.zig",
        .deps = &[_]*Package{ &_iecwp4b3bsfm, &_f7dubzb7cyqe, &_ede2wygpe1iy },
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
        .store = "/git/github.com/nektro/zfetch/863be236188e5f24d16554f9dcd7df96dd254a13",
        .name = "zfetch",
        .entry = "/git/github.com/nektro/zfetch/863be236188e5f24d16554f9dcd7df96dd254a13/src/main.zig",
        .deps = &[_]*Package{ &_9k24gimke1an, &_csbnipaad8n7 },
    };
    pub var _2ta738wrqbaq = Package{
        .store = "/git/github.com/ziglibs/known-folders/0ad514dcfb7525e32ae349b9acc0a53976f3a9fa",
        .name = "known-folders",
        .entry = "/git/github.com/ziglibs/known-folders/0ad514dcfb7525e32ae349b9acc0a53976f3a9fa/known-folders.zig",
    };
    pub var _89ujp8gq842x = Package{
        .name = "zigmod",
        .entry = "/../..//src/lib.zig",
        .deps = &[_]*Package{ &_g982zq6e8wsv, &_s84v9o48ucb0, &_2ta738wrqbaq, &_0npcrzfdlrvk, &_ejw82j2ipa0e, &_2ovav391ivak, &_c1xirp1ota5p, &_u7sysdckdymi, &_iecwp4b3bsfm, &_f7dubzb7cyqe, &_0k64oe2nuzvj },
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
