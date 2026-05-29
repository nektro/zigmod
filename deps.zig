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
    step.dependOn(&GitExactStep.create(b, "https://github.com/nektro/zig-detect-license", "a1a066da88dab50873a56f0349dc12dc76542077").step);
    step.dependOn(&GitExactStep.create(b, "https://github.com/nektro/zig-extras", "c2c581aa6a38438dd9ed8da0f59019691c5dd45d").step);
    step.dependOn(&GitExactStep.create(b, "https://github.com/nektro/zig-git", "2b3f83cd341764f979969603e4f77e62f353b6a3").step);
    step.dependOn(&GitExactStep.create(b, "https://github.com/nektro/zig-inquirer", "4cddefa42744d61067567b0b36b5d2bb376e5ae3").step);
    step.dependOn(&GitExactStep.create(b, "https://github.com/nektro/zig-intrusive-parser", "a31b480914d15f3d13cdfb586aac950c73beebdd").step);
    step.dependOn(&GitExactStep.create(b, "https://github.com/nektro/zig-json", "428aa8a29e370fdb2e6739d5676b1de415e3f4e3").step);
    step.dependOn(&GitExactStep.create(b, "https://github.com/nektro/zig-leven", "618eddde4ffbc6d34100e4bc6aa654d41161537a").step);
    step.dependOn(&GitExactStep.create(b, "https://github.com/nektro/zig-licenses", "16cef5e32b3f8bbcf1064c599615290a720b6547").step);
    step.dependOn(&GitExactStep.create(b, "https://github.com/nektro/zig-licenses-text", "ba0f00dfb23d28c301e4b54d0a278def2c38dc7b").step);
    step.dependOn(&GitExactStep.create(b, "https://github.com/nektro/zig-nfs", "18b00c5c5d25e230ff4f3ea07fadb2a1d54a773d").step);
    step.dependOn(&GitExactStep.create(b, "https://github.com/nektro/zig-nio", "c1da2e8a31858880eb3e4cfcf12de0a865617623").step);
    step.dependOn(&GitExactStep.create(b, "https://github.com/nektro/zig-sys-darwin", "c5c1b35492224b0ed8d2570c8e71702947b1e400").step);
    step.dependOn(&GitExactStep.create(b, "https://github.com/nektro/zig-sys-linux", "9edefde5fcf96894b6aa4ab60241940bba65debf").step);
    step.dependOn(&GitExactStep.create(b, "https://github.com/nektro/zig-time", "0f4db4c980146e4a3fc86a9a9070452a25ff9317").step);
    step.dependOn(&GitExactStep.create(b, "https://github.com/nektro/zig-tracer", "3a5fdea4ffd387a53ac2a42fb503557cdbe20696").step);
    step.dependOn(&GitExactStep.create(b, "https://github.com/nektro/zig-yaml", "b1ebd056b9afaaa719cb55359c610455ffe04499").step);
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
        .store = "/git/github.com/nektro/zig-licenses/16cef5e32b3f8bbcf1064c599615290a720b6547",
        .name = "licenses",
        .entry = "/git/github.com/nektro/zig-licenses/16cef5e32b3f8bbcf1064c599615290a720b6547/src/lib.zig",
    };
    pub var _73bukkeci2u6 = Package{
        .store = "/git/github.com/nektro/zig-sys-darwin/c5c1b35492224b0ed8d2570c8e71702947b1e400",
        .name = "sys-darwin",
        .entry = "/git/github.com/nektro/zig-sys-darwin/c5c1b35492224b0ed8d2570c8e71702947b1e400/sys_darwin.zig",
    };
    pub var _h7tv7ayhffak = Package{
        .store = "/git/github.com/nektro/zig-sys-linux/9edefde5fcf96894b6aa4ab60241940bba65debf",
        .name = "sys-linux",
        .entry = "/git/github.com/nektro/zig-sys-linux/9edefde5fcf96894b6aa4ab60241940bba65debf/mod.zig",
        .deps = &[_]*Package{ },
        .system_libs = &.{ "c" },
    };
    pub var _kscsl0145t7x = Package{
        .store = "/git/github.com/nektro/zig-nio/c1da2e8a31858880eb3e4cfcf12de0a865617623",
        .name = "nio",
        .entry = "/git/github.com/nektro/zig-nio/c1da2e8a31858880eb3e4cfcf12de0a865617623/nio.zig",
        .deps = &[_]*Package{ &_h7tv7ayhffak, &_f7dubzb7cyqe, &_73bukkeci2u6 },
    };
    pub var _7l3oxw6nqqws = Package{
        .store = "/git/github.com/nektro/zig-intrusive-parser/a31b480914d15f3d13cdfb586aac950c73beebdd",
        .name = "intrusive-parser",
        .entry = "/git/github.com/nektro/zig-intrusive-parser/a31b480914d15f3d13cdfb586aac950c73beebdd/intrusive_parser.zig",
        .deps = &[_]*Package{ &_f7dubzb7cyqe, &_kscsl0145t7x },
    };
    pub var _iecwp4b3bsfm = Package{
        .store = "/git/github.com/nektro/zig-time/0f4db4c980146e4a3fc86a9a9070452a25ff9317",
        .name = "time",
        .entry = "/git/github.com/nektro/zig-time/0f4db4c980146e4a3fc86a9a9070452a25ff9317/time.zig",
        .deps = &[_]*Package{ &_f7dubzb7cyqe, &_h7tv7ayhffak, &_73bukkeci2u6 },
    };
    pub var _vph9l0hxpeze = Package{
        .store = "/git/github.com/nektro/zig-nfs/18b00c5c5d25e230ff4f3ea07fadb2a1d54a773d",
        .name = "nfs",
        .entry = "/git/github.com/nektro/zig-nfs/18b00c5c5d25e230ff4f3ea07fadb2a1d54a773d/nfs.zig",
        .deps = &[_]*Package{ &_h7tv7ayhffak, &_kscsl0145t7x, &_iecwp4b3bsfm, &_73bukkeci2u6 },
    };
    pub var _ede2wygpe1iy = Package{
        .store = "/git/github.com/nektro/zig-tracer/3a5fdea4ffd387a53ac2a42fb503557cdbe20696",
        .name = "tracer",
        .entry = "/git/github.com/nektro/zig-tracer/3a5fdea4ffd387a53ac2a42fb503557cdbe20696/src/mod.zig",
        .deps = &[_]*Package{ &_f7dubzb7cyqe, &_h7tv7ayhffak, &_vph9l0hxpeze, &_kscsl0145t7x, &_iecwp4b3bsfm },
    };
    pub var _0k64oe2nuzvj = Package{
        .store = "/git/github.com/nektro/zig-git/2b3f83cd341764f979969603e4f77e62f353b6a3",
        .name = "git",
        .entry = "/git/github.com/nektro/zig-git/2b3f83cd341764f979969603e4f77e62f353b6a3/git.zig",
        .deps = &[_]*Package{ &_iecwp4b3bsfm, &_f7dubzb7cyqe, &_ede2wygpe1iy, &_vph9l0hxpeze, &_kscsl0145t7x, &_0e2d06bb494b },
    };
    pub var _ocmr9rtohgcc = Package{
        .store = "/git/github.com/nektro/zig-json/428aa8a29e370fdb2e6739d5676b1de415e3f4e3",
        .name = "json",
        .entry = "/git/github.com/nektro/zig-json/428aa8a29e370fdb2e6739d5676b1de415e3f4e3/json.zig",
        .deps = &[_]*Package{ &_f7dubzb7cyqe, &_ede2wygpe1iy, &_7l3oxw6nqqws, &_kscsl0145t7x },
    };
    pub var _pt88y5d80m25 = Package{
        .store = "/git/github.com/nektro/zig-licenses-text/ba0f00dfb23d28c301e4b54d0a278def2c38dc7b",
        .name = "licenses-text",
        .entry = "/git/github.com/nektro/zig-licenses-text/ba0f00dfb23d28c301e4b54d0a278def2c38dc7b/src/lib.zig",
        .deps = &[_]*Package{ &_ocmr9rtohgcc },
    };
    pub var _2ovav391ivak = Package{
        .store = "/git/github.com/nektro/zig-detect-license/a1a066da88dab50873a56f0349dc12dc76542077",
        .name = "detect-license",
        .entry = "/git/github.com/nektro/zig-detect-license/a1a066da88dab50873a56f0349dc12dc76542077/src/lib.zig",
        .deps = &[_]*Package{ &_pt88y5d80m25, &_96h80ezrvj7i },
    };
    pub var _g982zq6e8wsv = Package{
        .store = "/git/github.com/nektro/zig-yaml/b1ebd056b9afaaa719cb55359c610455ffe04499",
        .name = "yaml",
        .entry = "/git/github.com/nektro/zig-yaml/b1ebd056b9afaaa719cb55359c610455ffe04499/yaml.zig",
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
    &package_data._kscsl0145t7x,
};

pub const pkgs = struct {
    pub const zigmod = &package_data._89ujp8gq842x;
    pub const win32 = &package_data._o6ogpor87xc2;
    pub const extras = &package_data._f7dubzb7cyqe;
    pub const ansi = &package_data._s84v9o48ucb0;
    pub const nio = &package_data._kscsl0145t7x;
};

pub const imports = struct {
};
