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
    step.dependOn(&GitExactStep.create(b, "https://github.com/nektro/arqv-ini", "e229c738bbf5cf0d5464bf9178c17813069a7028").step);
    step.dependOn(&GitExactStep.create(b, "https://github.com/nektro/zig-ansi", "d1c2ebf3f6c9b0d3aaa74a123d2f0a5657242431").step);
    step.dependOn(&GitExactStep.create(b, "https://github.com/nektro/zig-detect-license", "e8ea5d969e1062d0be161f7a70e293b52aebc3f3").step);
    step.dependOn(&GitExactStep.create(b, "https://github.com/nektro/zig-extras", "2cb1b3d619b10f4ad2c870f0359adb0c6129ca67").step);
    step.dependOn(&GitExactStep.create(b, "https://github.com/nektro/zig-git", "8fdfc351842785192cad01aead798d85e25d1a48").step);
    step.dependOn(&GitExactStep.create(b, "https://github.com/nektro/zig-inquirer", "3270255ea4c6d919853527e6a73baecfdee6867d").step);
    step.dependOn(&GitExactStep.create(b, "https://github.com/nektro/zig-intrusive-parser", "c21ce202c557a710fba6a2333f33bee7bbea114c").step);
    step.dependOn(&GitExactStep.create(b, "https://github.com/nektro/zig-json", "27d7354d9dc44982f1de40706721aee7d9c998a5").step);
    step.dependOn(&GitExactStep.create(b, "https://github.com/nektro/zig-leven", "d97ef94cacf5c109b7f4b9e01a7e6645d8c8e09a").step);
    step.dependOn(&GitExactStep.create(b, "https://github.com/nektro/zig-licenses", "f0a95c802d6f955f131dae121550b2ec0acb97ff").step);
    step.dependOn(&GitExactStep.create(b, "https://github.com/nektro/zig-licenses-text", "88dc9ae4c338c652dc231ea477b8e0b56ac36743").step);
    step.dependOn(&GitExactStep.create(b, "https://github.com/nektro/zig-nfs", "4c6b77b141abab5f6ac70ea712521f062b54df65").step);
    step.dependOn(&GitExactStep.create(b, "https://github.com/nektro/zig-nio", "42f22d588059efa1e212f97402e94d81d675f28d").step);
    step.dependOn(&GitExactStep.create(b, "https://github.com/nektro/zig-sys-darwin", "3565d27455bd6c9f4650ea691cf4de47f9d229e7").step);
    step.dependOn(&GitExactStep.create(b, "https://github.com/nektro/zig-sys-linux", "3f07f214aac54bcf8f84975a2312cd91ac67fa04").step);
    step.dependOn(&GitExactStep.create(b, "https://github.com/nektro/zig-time", "c05c69b92a00b1afd07cb193f5069250e34ce488").step);
    step.dependOn(&GitExactStep.create(b, "https://github.com/nektro/zig-tracer", "afa0f6df50960f3772b4e0b311ff86521da3e6d5").step);
    step.dependOn(&GitExactStep.create(b, "https://github.com/nektro/zig-yaml", "fbf3642e7a9e354e2f48751b69ae1c41c0d7b062").step);
    step.dependOn(&GitExactStep.create(b, "https://github.com/madler/zlib", "da607da739fa6047df13e66a2af6b8bec7c2a498").step);
    step.dependOn(&GitExactStep.create(b, "https://github.com/yaml/libyaml", "2c891fc7a770e8ba2fec34fc6b545c672beb37e6").step);
    step.dependOn(&GitExactStep.create(b, "https://github.com/ziglibs/known-folders", "83d39161eac2ed6f37ad3cb4d9dd518696ce90bb").step);
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
                    .embed_path => {},
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
            if (std.zig.target.isLibCLibName(&target, item)) continue;
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
    const min = std.SemanticVersion.parse("0.15.2") catch return;
    if (current.order(min).compare(.lt)) @panic(exe.step.owner.fmt("Your Zig version v{f} does not meet the minimum build requirement of v{f}", .{current, min}));
}

pub const package_data = struct {
    pub var _o6ogpor87xc2 = Package{
        .store = "/git/github.com/marlersoft/zigwin32/ec98bb4d9eea532320a8551720a9e3ec6de64994",
        .name = "win32",
        .entry = "/git/github.com/marlersoft/zigwin32/ec98bb4d9eea532320a8551720a9e3ec6de64994/win32.zig",
    };
    pub var _u7sysdckdymi = Package{
        .store = "/git/github.com/nektro/arqv-ini/e229c738bbf5cf0d5464bf9178c17813069a7028",
        .name = "ini",
        .entry = "/git/github.com/nektro/arqv-ini/e229c738bbf5cf0d5464bf9178c17813069a7028/src/ini.zig",
    };
    pub var _s84v9o48ucb0 = Package{
        .store = "/git/github.com/nektro/zig-ansi/d1c2ebf3f6c9b0d3aaa74a123d2f0a5657242431",
        .name = "ansi",
        .entry = "/git/github.com/nektro/zig-ansi/d1c2ebf3f6c9b0d3aaa74a123d2f0a5657242431/src/lib.zig",
    };
    pub var _f7dubzb7cyqe = Package{
        .store = "/git/github.com/nektro/zig-extras/2cb1b3d619b10f4ad2c870f0359adb0c6129ca67",
        .name = "extras",
        .entry = "/git/github.com/nektro/zig-extras/2cb1b3d619b10f4ad2c870f0359adb0c6129ca67/src/lib.zig",
    };
    pub var _c1xirp1ota5p = Package{
        .store = "/git/github.com/nektro/zig-inquirer/3270255ea4c6d919853527e6a73baecfdee6867d",
        .name = "inquirer",
        .entry = "/git/github.com/nektro/zig-inquirer/3270255ea4c6d919853527e6a73baecfdee6867d/src/lib.zig",
        .deps = &[_]*Package{ &_s84v9o48ucb0 },
    };
    pub var _96h80ezrvj7i = Package{
        .store = "/git/github.com/nektro/zig-leven/d97ef94cacf5c109b7f4b9e01a7e6645d8c8e09a",
        .name = "leven",
        .entry = "/git/github.com/nektro/zig-leven/d97ef94cacf5c109b7f4b9e01a7e6645d8c8e09a/src/lib.zig",
    };
    pub var _0npcrzfdlrvk = Package{
        .store = "/git/github.com/nektro/zig-licenses/f0a95c802d6f955f131dae121550b2ec0acb97ff",
        .name = "licenses",
        .entry = "/git/github.com/nektro/zig-licenses/f0a95c802d6f955f131dae121550b2ec0acb97ff/src/lib.zig",
    };
    pub var _pt88y5d80m25 = Package{
        .store = "/git/github.com/nektro/zig-licenses-text/88dc9ae4c338c652dc231ea477b8e0b56ac36743",
        .name = "licenses-text",
        .entry = "/git/github.com/nektro/zig-licenses-text/88dc9ae4c338c652dc231ea477b8e0b56ac36743/src/lib.zig",
    };
    pub var _73bukkeci2u6 = Package{
        .store = "/git/github.com/nektro/zig-sys-darwin/3565d27455bd6c9f4650ea691cf4de47f9d229e7",
        .name = "sys-darwin",
        .entry = "/git/github.com/nektro/zig-sys-darwin/3565d27455bd6c9f4650ea691cf4de47f9d229e7/sys_darwin.zig",
    };
    pub var _h7tv7ayhffak = Package{
        .store = "/git/github.com/nektro/zig-sys-linux/3f07f214aac54bcf8f84975a2312cd91ac67fa04",
        .name = "sys-linux",
        .entry = "/git/github.com/nektro/zig-sys-linux/3f07f214aac54bcf8f84975a2312cd91ac67fa04/mod.zig",
    };
    pub var _kscsl0145t7x = Package{
        .store = "/git/github.com/nektro/zig-nio/42f22d588059efa1e212f97402e94d81d675f28d",
        .name = "nio",
        .entry = "/git/github.com/nektro/zig-nio/42f22d588059efa1e212f97402e94d81d675f28d/nio.zig",
        .deps = &[_]*Package{ &_h7tv7ayhffak, &_f7dubzb7cyqe, &_73bukkeci2u6 },
    };
    pub var _7l3oxw6nqqws = Package{
        .store = "/git/github.com/nektro/zig-intrusive-parser/c21ce202c557a710fba6a2333f33bee7bbea114c",
        .name = "intrusive-parser",
        .entry = "/git/github.com/nektro/zig-intrusive-parser/c21ce202c557a710fba6a2333f33bee7bbea114c/intrusive_parser.zig",
        .deps = &[_]*Package{ &_f7dubzb7cyqe, &_kscsl0145t7x },
    };
    pub var _iecwp4b3bsfm = Package{
        .store = "/git/github.com/nektro/zig-time/c05c69b92a00b1afd07cb193f5069250e34ce488",
        .name = "time",
        .entry = "/git/github.com/nektro/zig-time/c05c69b92a00b1afd07cb193f5069250e34ce488/time.zig",
        .deps = &[_]*Package{ &_f7dubzb7cyqe, &_h7tv7ayhffak, &_73bukkeci2u6 },
    };
    pub var _vph9l0hxpeze = Package{
        .store = "/git/github.com/nektro/zig-nfs/4c6b77b141abab5f6ac70ea712521f062b54df65",
        .name = "nfs",
        .entry = "/git/github.com/nektro/zig-nfs/4c6b77b141abab5f6ac70ea712521f062b54df65/nfs.zig",
        .deps = &[_]*Package{ &_h7tv7ayhffak, &_kscsl0145t7x, &_iecwp4b3bsfm, &_73bukkeci2u6 },
    };
    pub var _2ovav391ivak = Package{
        .store = "/git/github.com/nektro/zig-detect-license/e8ea5d969e1062d0be161f7a70e293b52aebc3f3",
        .name = "detect-license",
        .entry = "/git/github.com/nektro/zig-detect-license/e8ea5d969e1062d0be161f7a70e293b52aebc3f3/src/lib.zig",
        .deps = &[_]*Package{ &_pt88y5d80m25, &_96h80ezrvj7i, &_vph9l0hxpeze },
    };
    pub var _ede2wygpe1iy = Package{
        .store = "/git/github.com/nektro/zig-tracer/afa0f6df50960f3772b4e0b311ff86521da3e6d5",
        .name = "tracer",
        .entry = "/git/github.com/nektro/zig-tracer/afa0f6df50960f3772b4e0b311ff86521da3e6d5/src/mod.zig",
        .deps = &[_]*Package{ &_f7dubzb7cyqe, &_h7tv7ayhffak, &_vph9l0hxpeze, &_kscsl0145t7x, &_iecwp4b3bsfm },
    };
    pub var _0k64oe2nuzvj = Package{
        .store = "/git/github.com/nektro/zig-git/8fdfc351842785192cad01aead798d85e25d1a48",
        .name = "git",
        .entry = "/git/github.com/nektro/zig-git/8fdfc351842785192cad01aead798d85e25d1a48/git.zig",
        .deps = &[_]*Package{ &_iecwp4b3bsfm, &_f7dubzb7cyqe, &_ede2wygpe1iy, &_vph9l0hxpeze, &_kscsl0145t7x, &_0e2d06bb494b },
    };
    pub var _ocmr9rtohgcc = Package{
        .store = "/git/github.com/nektro/zig-json/27d7354d9dc44982f1de40706721aee7d9c998a5",
        .name = "json",
        .entry = "/git/github.com/nektro/zig-json/27d7354d9dc44982f1de40706721aee7d9c998a5/json.zig",
        .deps = &[_]*Package{ &_f7dubzb7cyqe, &_ede2wygpe1iy, &_7l3oxw6nqqws, &_kscsl0145t7x },
    };
    pub var _g982zq6e8wsv = Package{
        .store = "/git/github.com/nektro/zig-yaml/fbf3642e7a9e354e2f48751b69ae1c41c0d7b062",
        .name = "yaml",
        .entry = "/git/github.com/nektro/zig-yaml/fbf3642e7a9e354e2f48751b69ae1c41c0d7b062/yaml.zig",
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
        .store = "/git/github.com/ziglibs/known-folders/83d39161eac2ed6f37ad3cb4d9dd518696ce90bb",
        .name = "known-folders",
        .entry = "/git/github.com/ziglibs/known-folders/83d39161eac2ed6f37ad3cb4d9dd518696ce90bb/known-folders.zig",
    };
    pub var _89ujp8gq842x = Package{
        .name = "zigmod",
        .entry = "/../..//src/lib.zig",
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
