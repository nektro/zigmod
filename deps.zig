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
            flip(std.Io.Dir.cwd().access(std.Options.debug_io, repopath, .{})) catch return result;

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
    step.dependOn(&GitExactStep.create(b, "https://github.com/marlersoft/zigwin32", "9f15c276b4e9d05afd34a10d8662a7dfc34647ea").step);
    step.dependOn(&GitExactStep.create(b, "https://github.com/nektro/arqv-ini", "d2465c64833590a04bd9b7f50c87363fd03e65bf").step);
    step.dependOn(&GitExactStep.create(b, "https://github.com/nektro/zig-ansi", "bebb39ae30d9848a1c212cee582d0b1c102d8b87").step);
    step.dependOn(&GitExactStep.create(b, "https://github.com/nektro/zig-detect-license", "6de79b4ff8f7462e26f224f4bed3c81710c8893b").step);
    step.dependOn(&GitExactStep.create(b, "https://github.com/nektro/zig-extras", "8f6c4761e5c22c6a5c83a032e764154b840275bc").step);
    step.dependOn(&GitExactStep.create(b, "https://github.com/nektro/zig-git", "88b94a1960be841bb93a0bca65d556cb6385d1fd").step);
    step.dependOn(&GitExactStep.create(b, "https://github.com/nektro/zig-inquirer", "e745b018f87ddc4c8958370332e6cf61625403cc").step);
    step.dependOn(&GitExactStep.create(b, "https://github.com/nektro/zig-intrusive-parser", "800cbe5b241fc52370cb8f892f0d9c6f97133725").step);
    step.dependOn(&GitExactStep.create(b, "https://github.com/nektro/zig-json", "a731b57ee685ff1ddeea9456a924f45ce4da3031").step);
    step.dependOn(&GitExactStep.create(b, "https://github.com/nektro/zig-leven", "014971d4b1e327a5c61322c3a6b9369fd1863864").step);
    step.dependOn(&GitExactStep.create(b, "https://github.com/nektro/zig-licenses", "bc1cd51625c13d6c7df819fd0d85968e617f5c57").step);
    step.dependOn(&GitExactStep.create(b, "https://github.com/nektro/zig-licenses-text", "a9d067c3c4d6c226a1de5531b66785bc15d869ee").step);
    step.dependOn(&GitExactStep.create(b, "https://github.com/nektro/zig-nfs", "1a27fe574706f0b91c9f66b22fe7d3fa8f5129d5").step);
    step.dependOn(&GitExactStep.create(b, "https://github.com/nektro/zig-nio", "17c4f044b15917efc1d3f018765881d53fa27e48").step);
    step.dependOn(&GitExactStep.create(b, "https://github.com/nektro/zig-sys-darwin", "b349aa32b55aae4cf2ae56740003f8aff0394920").step);
    step.dependOn(&GitExactStep.create(b, "https://github.com/nektro/zig-sys-freebsd", "f97e6c2de30af76818572490735c84ce1015958b").step);
    step.dependOn(&GitExactStep.create(b, "https://github.com/nektro/zig-sys-linux", "6dabe7cce239d882c8fd132ab5cda1d1f9ff3634").step);
    step.dependOn(&GitExactStep.create(b, "https://github.com/nektro/zig-sys-netbsd", "5ad432ca421c59099be3630b9d0dda49e8bef0a7").step);
    step.dependOn(&GitExactStep.create(b, "https://github.com/nektro/zig-sys-openbsd", "164646a5e7c4129eb92ac524a60f1759605c99df").step);
    step.dependOn(&GitExactStep.create(b, "https://github.com/nektro/zig-time", "1349fb2c8aaaa1503e8730facea6f87c5fe75dc0").step);
    step.dependOn(&GitExactStep.create(b, "https://github.com/nektro/zig-tracer", "4ad0602d52a3f40ef74f59f648602c61409f7ba7").step);
    step.dependOn(&GitExactStep.create(b, "https://github.com/nektro/zig-yaml", "dff9fd43ebf1046c70090bdccfeb2e4f1c0d584b").step);
    step.dependOn(&GitExactStep.create(b, "https://github.com/madler/zlib", "da607da739fa6047df13e66a2af6b8bec7c2a498").step);
    step.dependOn(&GitExactStep.create(b, "https://github.com/yaml/libyaml", "2c891fc7a770e8ba2fec34fc6b545c672beb37e6").step);
    step.dependOn(&GitExactStep.create(b, "https://github.com/ziglibs/known-folders", "207c34a16e4365edc20d92c7892f962b3bed46e8").step);
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
    store: ?string = null,
    main: ?string = null,
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
            if (self.store) |s| {
                result.root_source_file = (std.Build.LazyPath{ .cwd_relative = b.cache_root.path.? }).path(b, "zigmod/deps").path(b, s[1..]).path(b, m);
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
            result.addIncludePath(.{ .cwd_relative = b.fmt("{s}/zigmod/deps{s}/{s}", .{ b.cache_root.path.?, self.store.?, item }) });
            dummy_library.root_module.addIncludePath(.{ .cwd_relative = b.fmt("{s}/zigmod/deps{s}/{s}", .{ b.cache_root.path.?, self.store.?, item }) });
            link_lib_c = true;
            links += 1;
        }
        for (self.c_source_files) |item| {
            dummy_library.root_module.addCSourceFile(.{ .file = .{ .cwd_relative = b.fmt("{s}/zigmod/deps{s}/{s}", .{ b.cache_root.path.?, self.store.?, item }) }, .flags = self.c_source_flags });
            links += 1;
        }
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
    const min = std.SemanticVersion.parse("0.16.0") catch return;
    if (current.order(min).compare(.lt)) @panic(exe.step.owner.fmt("Your Zig version v{f} does not meet the minimum build requirement of v{f}", .{current, min}));
}

pub const package_data = struct {
    pub var _o6ogpor87xc2 = Package{
        .store = "/git/github.com/marlersoft/zigwin32/9f15c276b4e9d05afd34a10d8662a7dfc34647ea",
        .name = "win32",
        .main = "win32.zig",
    };
    pub var _u7sysdckdymi = Package{
        .store = "/git/github.com/nektro/arqv-ini/d2465c64833590a04bd9b7f50c87363fd03e65bf",
        .name = "ini",
        .main = "src/ini.zig",
    };
    pub var _s84v9o48ucb0 = Package{
        .store = "/git/github.com/nektro/zig-ansi/bebb39ae30d9848a1c212cee582d0b1c102d8b87",
        .name = "ansi",
        .main = "src/lib.zig",
    };
    pub var _f7dubzb7cyqe = Package{
        .store = "/git/github.com/nektro/zig-extras/8f6c4761e5c22c6a5c83a032e764154b840275bc",
        .name = "extras",
        .main = "src/lib.zig",
    };
    pub var _c1xirp1ota5p = Package{
        .store = "/git/github.com/nektro/zig-inquirer/e745b018f87ddc4c8958370332e6cf61625403cc",
        .name = "inquirer",
        .main = "src/lib.zig",
        .deps = &[_]*Package{ &_s84v9o48ucb0 },
    };
    pub var _96h80ezrvj7i = Package{
        .store = "/git/github.com/nektro/zig-leven/014971d4b1e327a5c61322c3a6b9369fd1863864",
        .name = "leven",
        .main = "src/lib.zig",
    };
    pub var _0npcrzfdlrvk = Package{
        .store = "/git/github.com/nektro/zig-licenses/bc1cd51625c13d6c7df819fd0d85968e617f5c57",
        .name = "licenses",
        .main = "src/lib.zig",
    };
    pub var _pt88y5d80m25 = Package{
        .store = "/git/github.com/nektro/zig-licenses-text/a9d067c3c4d6c226a1de5531b66785bc15d869ee",
        .name = "licenses-text",
        .main = "src/lib.zig",
    };
    pub var _73bukkeci2u6 = Package{
        .store = "/git/github.com/nektro/zig-sys-darwin/b349aa32b55aae4cf2ae56740003f8aff0394920",
        .name = "sys-darwin",
        .main = "sys_darwin.zig",
    };
    pub var _qfev2g50alvp = Package{
        .store = "/git/github.com/nektro/zig-sys-freebsd/f97e6c2de30af76818572490735c84ce1015958b",
        .name = "sys-freebsd",
        .main = "freebsd.zig",
    };
    pub var _h7tv7ayhffak = Package{
        .store = "/git/github.com/nektro/zig-sys-linux/6dabe7cce239d882c8fd132ab5cda1d1f9ff3634",
        .name = "sys-linux",
        .main = "mod.zig",
    };
    pub var _uvkgl6xf1azv = Package{
        .store = "/git/github.com/nektro/zig-sys-netbsd/5ad432ca421c59099be3630b9d0dda49e8bef0a7",
        .name = "sys-netbsd",
        .main = "netbsd.zig",
    };
    pub var _4rmxgmcykiba = Package{
        .store = "/git/github.com/nektro/zig-sys-openbsd/164646a5e7c4129eb92ac524a60f1759605c99df",
        .name = "sys-openbsd",
        .main = "openbsd.zig",
    };
    pub var _kscsl0145t7x = Package{
        .store = "/git/github.com/nektro/zig-nio/17c4f044b15917efc1d3f018765881d53fa27e48",
        .name = "nio",
        .main = "nio.zig",
        .deps = &[_]*Package{ &_h7tv7ayhffak, &_f7dubzb7cyqe, &_73bukkeci2u6, &_qfev2g50alvp, &_uvkgl6xf1azv, &_4rmxgmcykiba },
    };
    pub var _7l3oxw6nqqws = Package{
        .store = "/git/github.com/nektro/zig-intrusive-parser/800cbe5b241fc52370cb8f892f0d9c6f97133725",
        .name = "intrusive-parser",
        .main = "intrusive_parser.zig",
        .deps = &[_]*Package{ &_f7dubzb7cyqe, &_kscsl0145t7x },
    };
    pub var _iecwp4b3bsfm = Package{
        .store = "/git/github.com/nektro/zig-time/1349fb2c8aaaa1503e8730facea6f87c5fe75dc0",
        .name = "time",
        .main = "time.zig",
        .deps = &[_]*Package{ &_f7dubzb7cyqe, &_h7tv7ayhffak, &_73bukkeci2u6, &_kscsl0145t7x, &_qfev2g50alvp, &_uvkgl6xf1azv, &_4rmxgmcykiba },
    };
    pub var _vph9l0hxpeze = Package{
        .store = "/git/github.com/nektro/zig-nfs/1a27fe574706f0b91c9f66b22fe7d3fa8f5129d5",
        .name = "nfs",
        .main = "nfs.zig",
        .deps = &[_]*Package{ &_h7tv7ayhffak, &_kscsl0145t7x, &_iecwp4b3bsfm, &_73bukkeci2u6, &_qfev2g50alvp, &_uvkgl6xf1azv, &_4rmxgmcykiba },
    };
    pub var _2ovav391ivak = Package{
        .store = "/git/github.com/nektro/zig-detect-license/6de79b4ff8f7462e26f224f4bed3c81710c8893b",
        .name = "detect-license",
        .main = "src/lib.zig",
        .deps = &[_]*Package{ &_pt88y5d80m25, &_96h80ezrvj7i, &_vph9l0hxpeze },
    };
    pub var _ede2wygpe1iy = Package{
        .store = "/git/github.com/nektro/zig-tracer/4ad0602d52a3f40ef74f59f648602c61409f7ba7",
        .name = "tracer",
        .main = "src/mod.zig",
        .deps = &[_]*Package{ &_f7dubzb7cyqe, &_h7tv7ayhffak, &_vph9l0hxpeze, &_kscsl0145t7x, &_iecwp4b3bsfm },
    };
    pub var _0k64oe2nuzvj = Package{
        .store = "/git/github.com/nektro/zig-git/88b94a1960be841bb93a0bca65d556cb6385d1fd",
        .name = "git",
        .main = "git.zig",
        .deps = &[_]*Package{ &_iecwp4b3bsfm, &_f7dubzb7cyqe, &_ede2wygpe1iy, &_vph9l0hxpeze, &_kscsl0145t7x, &_0e2d06bb494b },
    };
    pub var _ocmr9rtohgcc = Package{
        .store = "/git/github.com/nektro/zig-json/a731b57ee685ff1ddeea9456a924f45ce4da3031",
        .name = "json",
        .main = "json.zig",
        .deps = &[_]*Package{ &_f7dubzb7cyqe, &_ede2wygpe1iy, &_7l3oxw6nqqws, &_kscsl0145t7x },
    };
    pub var _g982zq6e8wsv = Package{
        .store = "/git/github.com/nektro/zig-yaml/dff9fd43ebf1046c70090bdccfeb2e4f1c0d584b",
        .name = "yaml",
        .main = "yaml.zig",
        .deps = &[_]*Package{ &_8mdbh0zuneb0 },
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
        .store = "/git/github.com/ziglibs/known-folders/207c34a16e4365edc20d92c7892f962b3bed46e8",
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
