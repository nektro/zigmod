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
    step.dependOn(&GitExactStep.create(b, "https://github.com/marlersoft/zigwin32", "ec98bb4d9eea532320a8551720a9e3ec6de64994").step);
    step.dependOn(&GitExactStep.create(b, "https://github.com/nektro/arqv-ini", "ab427a4de4f875eaa39ee56a29114fc020431546").step);
    step.dependOn(&GitExactStep.create(b, "https://github.com/nektro/iguanaTLS", "3450aaf3ca47986540e2b0258c2affc45af64ea2").step);
    step.dependOn(&GitExactStep.create(b, "https://github.com/nektro/zfetch", "40d141bf7db81f05a83cce5f2edc4b14e41a5c34").step);
    step.dependOn(&GitExactStep.create(b, "https://github.com/nektro/zig-ansi", "5f89211a749aef6bf518889c0467ceb24825c055").step);
    step.dependOn(&GitExactStep.create(b, "https://github.com/nektro/zig-detect-license", "9285c96497ec5debae97a859e69976148a66aa7a").step);
    step.dependOn(&GitExactStep.create(b, "https://github.com/nektro/zig-extras", "c2c581aa6a38438dd9ed8da0f59019691c5dd45d").step);
    step.dependOn(&GitExactStep.create(b, "https://github.com/nektro/zig-git", "acb6691534e00ded166cccc272e17efbf613a2ab").step);
    step.dependOn(&GitExactStep.create(b, "https://github.com/nektro/zig-inquirer", "4cddefa42744d61067567b0b36b5d2bb376e5ae3").step);
    step.dependOn(&GitExactStep.create(b, "https://github.com/nektro/zig-intrusive-parser", "eec3155dc8188b8440cb6097cc436f49511f01cd").step);
    step.dependOn(&GitExactStep.create(b, "https://github.com/nektro/zig-json", "80e943ac8734b91da3560c8f45bbe702d833ac11").step);
    step.dependOn(&GitExactStep.create(b, "https://github.com/nektro/zig-leven", "618eddde4ffbc6d34100e4bc6aa654d41161537a").step);
    step.dependOn(&GitExactStep.create(b, "https://github.com/nektro/zig-licenses", "6b59e45d33a58a5756b2d671a40703f1d110271e").step);
    step.dependOn(&GitExactStep.create(b, "https://github.com/nektro/zig-licenses-text", "cf0d7f870e85bf4cc35e56532b9e6dd37f9d20dd").step);
    step.dependOn(&GitExactStep.create(b, "https://github.com/nektro/zig-nfs", "cd5a750bf6d58fa355efe2223c3f9c0626198f13").step);
    step.dependOn(&GitExactStep.create(b, "https://github.com/nektro/zig-nio", "c50f286c78a4a9704ac3f9fecd7c351e7da89e02").step);
    step.dependOn(&GitExactStep.create(b, "https://github.com/nektro/zig-sys-linux", "9edefde5fcf96894b6aa4ab60241940bba65debf").step);
    step.dependOn(&GitExactStep.create(b, "https://github.com/nektro/zig-time", "6e4e3983cea4fe7f705ce6c6606832fca409a4c7").step);
    step.dependOn(&GitExactStep.create(b, "https://github.com/nektro/zig-tracer", "b2c23066c0431542cbc97aedadd9c8890c298e7b").step);
    step.dependOn(&GitExactStep.create(b, "https://github.com/nektro/zig-yaml", "54fd85b458b7cf1b81ebe6503d61ca82804d1db6").step);
    step.dependOn(&GitExactStep.create(b, "https://github.com/truemedian/hzzp", "ab212bd208f0eb54d85861679677c5e3dc9bb543").step);
    step.dependOn(&GitExactStep.create(b, "https://github.com/madler/zlib", "da607da739fa6047df13e66a2af6b8bec7c2a498").step);
    step.dependOn(&GitExactStep.create(b, "https://github.com/yaml/libyaml", "2c891fc7a770e8ba2fec34fc6b545c672beb37e6").step);
    step.dependOn(&GitExactStep.create(b, "https://github.com/ziglibs/known-folders", "aa24df42183ad415d10bc0a33e6238c437fc0f59").step);
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
    inline for (comptime std.meta.declarations(package_data)) |decl| @field(package_data, decl.name).module_memo = null;
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

        const result = b.createModule(.{
            .target = exe.root_module.resolved_target,
        });
        const target = result.resolved_target.?.result;
        const dummy_library = b.addStaticLibrary(.{
            .name = b.fmt("dummy-{s}", .{self.name}),
            .target = exe.root_module.resolved_target orelse b.graph.host,
            .optimize = exe.root_module.optimize.?,
        });
        dummy_library.step.dependOn(fetch_step);
        var links: u32 = 0;
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
            links += 1;
        }
        for (self.c_source_files) |item| {
            dummy_library.addCSourceFile(.{ .file = .{ .cwd_relative = b.fmt("{s}/zigmod/deps{s}/{s}", .{ b.cache_root.path.?, self.store.?, item }) }, .flags = self.c_source_flags });
            links += 1;
        }
        for (self.system_libs) |item| {
            if (std.zig.target.isLibCLibName(target, item)) continue;
            dummy_library.linkSystemLibrary(item);
            links += 1;
        }
        for (self.frameworks) |item| {
            dummy_library.linkFramework(item);
            links += 1;
        }
        if (links > 0) {
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
    const min = std.SemanticVersion.parse("0.14.0") catch return;
    if (current.order(min).compare(.lt)) @panic(exe.step.owner.fmt("Your Zig version v{} does not meet the minimum build requirement of v{}", .{current, min}));
}

pub const package_data = struct {
    pub var _o6ogpor87xc2 = Package{
        .store = "/git/github.com/marlersoft/zigwin32/ec98bb4d9eea532320a8551720a9e3ec6de64994",
        .name = "win32",
        .entry = "/git/github.com/marlersoft/zigwin32/ec98bb4d9eea532320a8551720a9e3ec6de64994/win32.zig",
    };
    pub var _u7sysdckdymi = Package{
        .store = "/git/github.com/nektro/arqv-ini/ab427a4de4f875eaa39ee56a29114fc020431546",
        .name = "ini",
        .entry = "/git/github.com/nektro/arqv-ini/ab427a4de4f875eaa39ee56a29114fc020431546/src/ini.zig",
    };
    pub var _csbnipaad8n7 = Package{
        .store = "/git/github.com/nektro/iguanaTLS/3450aaf3ca47986540e2b0258c2affc45af64ea2",
        .name = "iguanaTLS",
        .entry = "/git/github.com/nektro/iguanaTLS/3450aaf3ca47986540e2b0258c2affc45af64ea2/src/main.zig",
    };
    pub var _s84v9o48ucb0 = Package{
        .store = "/git/github.com/nektro/zig-ansi/5f89211a749aef6bf518889c0467ceb24825c055",
        .name = "ansi",
        .entry = "/git/github.com/nektro/zig-ansi/5f89211a749aef6bf518889c0467ceb24825c055/src/lib.zig",
    };
    pub var _f7dubzb7cyqe = Package{
        .store = "/git/github.com/nektro/zig-extras/c2c581aa6a38438dd9ed8da0f59019691c5dd45d",
        .name = "extras",
        .entry = "/git/github.com/nektro/zig-extras/c2c581aa6a38438dd9ed8da0f59019691c5dd45d/src/lib.zig",
    };
    pub var _c1xirp1ota5p = Package{
        .store = "/git/github.com/nektro/zig-inquirer/4cddefa42744d61067567b0b36b5d2bb376e5ae3",
        .name = "inquirer",
        .entry = "/git/github.com/nektro/zig-inquirer/4cddefa42744d61067567b0b36b5d2bb376e5ae3/src/lib.zig",
        .deps = &[_]*Package{ &_s84v9o48ucb0 },
    };
    pub var _96h80ezrvj7i = Package{
        .store = "/git/github.com/nektro/zig-leven/618eddde4ffbc6d34100e4bc6aa654d41161537a",
        .name = "leven",
        .entry = "/git/github.com/nektro/zig-leven/618eddde4ffbc6d34100e4bc6aa654d41161537a/src/lib.zig",
    };
    pub var _0npcrzfdlrvk = Package{
        .store = "/git/github.com/nektro/zig-licenses/6b59e45d33a58a5756b2d671a40703f1d110271e",
        .name = "licenses",
        .entry = "/git/github.com/nektro/zig-licenses/6b59e45d33a58a5756b2d671a40703f1d110271e/src/lib.zig",
    };
    pub var _h7tv7ayhffak = Package{
        .store = "/git/github.com/nektro/zig-sys-linux/9edefde5fcf96894b6aa4ab60241940bba65debf",
        .name = "sys-linux",
        .entry = "/git/github.com/nektro/zig-sys-linux/9edefde5fcf96894b6aa4ab60241940bba65debf/mod.zig",
        .deps = &[_]*Package{ },
        .system_libs = &.{ "c" },
    };
    pub var _kscsl0145t7x = Package{
        .store = "/git/github.com/nektro/zig-nio/c50f286c78a4a9704ac3f9fecd7c351e7da89e02",
        .name = "nio",
        .entry = "/git/github.com/nektro/zig-nio/c50f286c78a4a9704ac3f9fecd7c351e7da89e02/nio.zig",
        .deps = &[_]*Package{ &_h7tv7ayhffak, &_f7dubzb7cyqe },
    };
    pub var _7l3oxw6nqqws = Package{
        .store = "/git/github.com/nektro/zig-intrusive-parser/eec3155dc8188b8440cb6097cc436f49511f01cd",
        .name = "intrusive-parser",
        .entry = "/git/github.com/nektro/zig-intrusive-parser/eec3155dc8188b8440cb6097cc436f49511f01cd/intrusive_parser.zig",
        .deps = &[_]*Package{ &_f7dubzb7cyqe, &_kscsl0145t7x },
    };
    pub var _iecwp4b3bsfm = Package{
        .store = "/git/github.com/nektro/zig-time/6e4e3983cea4fe7f705ce6c6606832fca409a4c7",
        .name = "time",
        .entry = "/git/github.com/nektro/zig-time/6e4e3983cea4fe7f705ce6c6606832fca409a4c7/time.zig",
        .deps = &[_]*Package{ &_f7dubzb7cyqe, &_h7tv7ayhffak },
    };
    pub var _vph9l0hxpeze = Package{
        .store = "/git/github.com/nektro/zig-nfs/cd5a750bf6d58fa355efe2223c3f9c0626198f13",
        .name = "nfs",
        .entry = "/git/github.com/nektro/zig-nfs/cd5a750bf6d58fa355efe2223c3f9c0626198f13/nfs.zig",
        .deps = &[_]*Package{ &_h7tv7ayhffak, &_kscsl0145t7x, &_iecwp4b3bsfm },
    };
    pub var _ede2wygpe1iy = Package{
        .store = "/git/github.com/nektro/zig-tracer/b2c23066c0431542cbc97aedadd9c8890c298e7b",
        .name = "tracer",
        .entry = "/git/github.com/nektro/zig-tracer/b2c23066c0431542cbc97aedadd9c8890c298e7b/src/mod.zig",
        .deps = &[_]*Package{ &_f7dubzb7cyqe, &_h7tv7ayhffak, &_vph9l0hxpeze, &_kscsl0145t7x, &_iecwp4b3bsfm },
    };
    pub var _0k64oe2nuzvj = Package{
        .store = "/git/github.com/nektro/zig-git/acb6691534e00ded166cccc272e17efbf613a2ab",
        .name = "git",
        .entry = "/git/github.com/nektro/zig-git/acb6691534e00ded166cccc272e17efbf613a2ab/git.zig",
        .deps = &[_]*Package{ &_iecwp4b3bsfm, &_f7dubzb7cyqe, &_ede2wygpe1iy, &_vph9l0hxpeze, &_kscsl0145t7x, &_0e2d06bb494b },
    };
    pub var _ocmr9rtohgcc = Package{
        .store = "/git/github.com/nektro/zig-json/80e943ac8734b91da3560c8f45bbe702d833ac11",
        .name = "json",
        .entry = "/git/github.com/nektro/zig-json/80e943ac8734b91da3560c8f45bbe702d833ac11/json.zig",
        .deps = &[_]*Package{ &_f7dubzb7cyqe, &_ede2wygpe1iy, &_7l3oxw6nqqws, &_kscsl0145t7x },
    };
    pub var _pt88y5d80m25 = Package{
        .store = "/git/github.com/nektro/zig-licenses-text/cf0d7f870e85bf4cc35e56532b9e6dd37f9d20dd",
        .name = "licenses-text",
        .entry = "/git/github.com/nektro/zig-licenses-text/cf0d7f870e85bf4cc35e56532b9e6dd37f9d20dd/src/lib.zig",
        .deps = &[_]*Package{ &_ocmr9rtohgcc },
    };
    pub var _2ovav391ivak = Package{
        .store = "/git/github.com/nektro/zig-detect-license/9285c96497ec5debae97a859e69976148a66aa7a",
        .name = "detect-license",
        .entry = "/git/github.com/nektro/zig-detect-license/9285c96497ec5debae97a859e69976148a66aa7a/src/lib.zig",
        .deps = &[_]*Package{ &_pt88y5d80m25, &_96h80ezrvj7i },
    };
    pub var _g982zq6e8wsv = Package{
        .store = "/git/github.com/nektro/zig-yaml/54fd85b458b7cf1b81ebe6503d61ca82804d1db6",
        .name = "yaml",
        .entry = "/git/github.com/nektro/zig-yaml/54fd85b458b7cf1b81ebe6503d61ca82804d1db6/yaml.zig",
        .deps = &[_]*Package{ &_8mdbh0zuneb0 },
    };
    pub var _9k24gimke1an = Package{
        .store = "/git/github.com/truemedian/hzzp/ab212bd208f0eb54d85861679677c5e3dc9bb543",
        .name = "hzzp",
        .entry = "/git/github.com/truemedian/hzzp/ab212bd208f0eb54d85861679677c5e3dc9bb543/src/main.zig",
    };
    pub var _ejw82j2ipa0e = Package{
        .store = "/git/github.com/nektro/zfetch/40d141bf7db81f05a83cce5f2edc4b14e41a5c34",
        .name = "zfetch",
        .entry = "/git/github.com/nektro/zfetch/40d141bf7db81f05a83cce5f2edc4b14e41a5c34/src/main.zig",
        .deps = &[_]*Package{ &_9k24gimke1an, &_csbnipaad8n7 },
    };
    pub var _0e2d06bb494b = Package{
        .store = "/git/github.com/madler/zlib/da607da739fa6047df13e66a2af6b8bec7c2a498",
        .c_include_dirs = &.{ "" },
        .c_source_files = &.{ "inftrees.c", "inflate.c", "adler32.c", "zutil.c", "trees.c", "gzclose.c", "gzwrite.c", "gzread.c", "deflate.c", "compress.c", "crc32.c", "infback.c", "gzlib.c", "uncompr.c", "inffast.c" },
        .c_source_flags = &.{ "-DZ_HAVE_UNISTD_H=1" },
    };
    pub var _8mdbh0zuneb0 = Package{
        .store = "/git/github.com/yaml/libyaml/2c891fc7a770e8ba2fec34fc6b545c672beb37e6",
        .c_include_dirs = &.{ "include" },
        .c_source_files = &.{ "src/api.c", "src/dumper.c", "src/emitter.c", "src/loader.c", "src/parser.c", "src/reader.c", "src/scanner.c", "src/writer.c" },
        .c_source_flags = &.{ "-DYAML_VERSION_MAJOR=0", "-DYAML_VERSION_MINOR=2", "-DYAML_VERSION_PATCH=5", "-DYAML_VERSION_STRING=\"0.2.5\"", "-DYAML_DECLARE_STATIC=1" },
    };
    pub var _2ta738wrqbaq = Package{
        .store = "/git/github.com/ziglibs/known-folders/aa24df42183ad415d10bc0a33e6238c437fc0f59",
        .name = "known-folders",
        .entry = "/git/github.com/ziglibs/known-folders/aa24df42183ad415d10bc0a33e6238c437fc0f59/known-folders.zig",
    };
    pub var _89ujp8gq842x = Package{
        .name = "zigmod",
        .entry = "/../..//src/lib.zig",
        .deps = &[_]*Package{ &_g982zq6e8wsv, &_s84v9o48ucb0, &_2ta738wrqbaq, &_0npcrzfdlrvk, &_ejw82j2ipa0e, &_2ovav391ivak, &_c1xirp1ota5p, &_u7sysdckdymi, &_iecwp4b3bsfm, &_f7dubzb7cyqe, &_0k64oe2nuzvj, &_ocmr9rtohgcc, &_kscsl0145t7x, &_vph9l0hxpeze },
    };
    pub var _root = Package{
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
