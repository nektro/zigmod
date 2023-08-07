// zig fmt: off
const std = @import("std");
const builtin = @import("builtin");
const ModuleDependency = std.build.ModuleDependency;
const string = []const u8;

pub const GitExactStep = struct {
    step: std.build.Step,
    builder: *std.build.Builder,
    url: string,
    commit: string,

        pub fn create(b: *std.build.Builder, url: string, commit: string) *GitExactStep {
            var result = b.allocator.create(GitExactStep) catch @panic("memory");
            result.* = GitExactStep{
                .step = std.build.Step.init(.{
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

            var clonestep = std.build.RunStep.create(b, "clone");
            clonestep.addArgs(&.{ "git", "clone", "-q", "--progress", url, repopath });
            result.step.dependOn(&clonestep.step);

            var checkoutstep = std.build.RunStep.create(b, "checkout");
            checkoutstep.addArgs(&.{ "git", "-C", repopath, "checkout", "-q", commit });
            result.step.dependOn(&checkoutstep.step);
            checkoutstep.step.dependOn(&clonestep.step);

            return result;
        }

        fn make(step: *std.build.Step, prog_node: *std.Progress.Node) !void {
            _ = step;
            _ = prog_node;
        }
};

pub fn fetch(exe: *std.build.LibExeObjStep) void {
    const b = exe.step.owner;
    inline for (comptime std.meta.declarations(package_data)) |decl| {
        const path = &@field(package_data, decl.name).entry;
        const root = if (@field(package_data, decl.name).store) |_| b.cache_root.path.? else ".";
        if (path.* != null) path.* = b.fmt("{s}/zigmod/deps{s}", .{ root, path.*.? });
    }
    exe.step.dependOn(&GitExactStep.create(b, "https://github.com/MasterQ32/zig-uri", "d4299ad6043ad19f2ce0676687b0bff57273eae2").step);
    exe.step.dependOn(&GitExactStep.create(b, "https://github.com/marlersoft/zigwin32", "b70e7f818d77a0c0f39b0bd9c549e16439ff5780").step);
    exe.step.dependOn(&GitExactStep.create(b, "https://github.com/nektro/arqv-ini", "ee395fd34e152d9067def609d86b7af5382b83b1").step);
    exe.step.dependOn(&GitExactStep.create(b, "https://github.com/nektro/iguanaTLS", "e70995575b397f33d798339d4f1656bcdf0ab82f").step);
    exe.step.dependOn(&GitExactStep.create(b, "https://github.com/nektro/zig-ansi", "faf9585bfe5980c24748ee8a3e6a22faaa50b437").step);
    exe.step.dependOn(&GitExactStep.create(b, "https://github.com/nektro/zig-detect-license", "8f13721bd18c0e546841b6f2e11da839550d6287").step);
    exe.step.dependOn(&GitExactStep.create(b, "https://github.com/nektro/zig-extras", "ff267312e8d714c9b9d8c44ad3291f6e509dc12f").step);
    exe.step.dependOn(&GitExactStep.create(b, "https://github.com/nektro/zig-inquirer", "5cc2a5565d04fe2c0085f0d6818590e800d9dcf7").step);
    exe.step.dependOn(&GitExactStep.create(b, "https://github.com/nektro/zig-leven", "550cabd5a18ace5e67761bc5b867c10e926f4314").step);
    exe.step.dependOn(&GitExactStep.create(b, "https://github.com/nektro/zig-licenses", "c9b8cbf3565675a056ad4e9b57cb4f84020e7680").step);
    exe.step.dependOn(&GitExactStep.create(b, "https://github.com/nektro/zig-licenses-text", "3c07c6e4eb0965dafd0b029c632f823631b3169c").step);
    exe.step.dependOn(&GitExactStep.create(b, "https://github.com/nektro/zig-range", "4b2f12808aa09be4b27a163efc424dd4e0415992").step);
    exe.step.dependOn(&GitExactStep.create(b, "https://github.com/nektro/zig-time", "ca9c0e6b644d74c1d549cc2c1ee22113aa021bd8").step);
    exe.step.dependOn(&GitExactStep.create(b, "https://github.com/nektro/zig-yaml", "e56b9fed6c0afd1c4d29bedc08c3899ffe1165e9").step);
    exe.step.dependOn(&GitExactStep.create(b, "https://github.com/truemedian/hzzp", "501386e13b2f7849128f3b271d23de6127b1d9d7").step);
    exe.step.dependOn(&GitExactStep.create(b, "https://github.com/truemedian/zfetch", "829973144f680cd16be16923041fa810c1dee417").step);
    exe.step.dependOn(&GitExactStep.create(b, "https://github.com/ziglibs/known-folders", "d13ba6137084e55f873f6afb67447fe8906cc951").step);
    exe.step.dependOn(&GitExactStep.create(b, "https://github.com/yaml/libyaml", "2c891fc7a770e8ba2fec34fc6b545c672beb37e6").step);
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

pub fn addAllTo(exe: *std.build.LibExeObjStep) void {
    checkMinZig(builtin.zig_version, exe);
    fetch(exe);
    const b = exe.step.owner;
    @setEvalBranchQuota(1_000_000);
    for (packages) |pkg| {
        const moddep = pkg.zp(b);
        exe.addModule(moddep.name, moddep.module);
    }
    var llc = false;
    var vcpkg = false;
    inline for (comptime std.meta.declarations(package_data)) |decl| {
        const pkg = @as(Package, @field(package_data, decl.name));
        const root = if (pkg.store) |st| b.fmt("{s}/zigmod/deps/{s}", .{ b.cache_root.path.?, st }) else ".";
        for (pkg.system_libs) |item| {
            exe.linkSystemLibrary(item);
            llc = true;
        }
        for (pkg.frameworks) |item| {
            if (!builtin.target.isDarwin()) @panic(exe.step.owner.fmt("a dependency is attempting to link to the framework {s}, which is only possible under Darwin", .{item}));
            exe.linkFramework(item);
            llc = true;
        }
        for (pkg.c_include_dirs) |item| {
            exe.addIncludePath(std.build.LazyPath {.path = b.fmt("{s}/{s}", .{ root, item })});
            llc = true;
        }
        for (pkg.c_source_files) |item| {
            exe.addCSourceFile(std.Build.Step.Compile.CSourceFile {.file = std.Build.LazyPath { .path = b.fmt("{s}/{s}", .{ root, item }) }, .flags = pkg.c_source_flags });
            llc = true;
        }
        vcpkg = vcpkg or pkg.vcpkg;
    }
    if (llc) exe.linkLibC();
    if (builtin.os.tag == .windows and vcpkg) exe.addVcpkgPaths(.static) catch |err| @panic(@errorName(err));
}

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
    vcpkg: bool = false,
    module: ?ModuleDependency = null,

    pub fn zp(self: *Package, b: *std.build.Builder) ModuleDependency {
        var temp: [100]ModuleDependency = undefined;
        for (self.deps, 0..) |item, i| {
            temp[i] = item.zp(b);
        }
        if (self.module) |mod| {
            return mod;
        }
        const result = ModuleDependency{
            .name = self.name,
            .module = b.createModule(.{
                .source_file = .{ .path = self.entry.? },
                .dependencies = b.allocator.dupe(ModuleDependency, temp[0..self.deps.len]) catch @panic("oom"),
            }),
        };
        self.module = result;
        return result;
    }
};

fn checkMinZig(current: std.SemanticVersion, exe: *std.build.LibExeObjStep) void {
    const min = std.SemanticVersion.parse("0.11.0-dev.3620+c76ce25a6") catch return;
    if (current.order(min).compare(.lt)) @panic(exe.step.owner.fmt("Your Zig version v{} does not meet the minimum build requirement of v{}", .{current, min}));
}

pub const package_data = struct {
    pub var _u9w9dpp6p804 = Package{
        .store = "/git/github.com/MasterQ32/zig-uri/d4299ad6043ad19f2ce0676687b0bff57273eae2",
        .name = "uri",
        .entry = "/git/github.com/MasterQ32/zig-uri/d4299ad6043ad19f2ce0676687b0bff57273eae2/uri.zig",
    };
    pub var _o6ogpor87xc2 = Package{
        .store = "/git/github.com/marlersoft/zigwin32/b70e7f818d77a0c0f39b0bd9c549e16439ff5780",
        .name = "win32",
        .entry = "/git/github.com/marlersoft/zigwin32/b70e7f818d77a0c0f39b0bd9c549e16439ff5780/win32.zig",
    };
    pub var _u7sysdckdymi = Package{
        .store = "/git/github.com/nektro/arqv-ini/ee395fd34e152d9067def609d86b7af5382b83b1",
        .name = "ini",
        .entry = "/git/github.com/nektro/arqv-ini/ee395fd34e152d9067def609d86b7af5382b83b1/src/ini.zig",
    };
    pub var _csbnipaad8n7 = Package{
        .store = "/git/github.com/nektro/iguanaTLS/e70995575b397f33d798339d4f1656bcdf0ab82f",
        .name = "iguanaTLS",
        .entry = "/git/github.com/nektro/iguanaTLS/e70995575b397f33d798339d4f1656bcdf0ab82f/src/main.zig",
    };
    pub var _s84v9o48ucb0 = Package{
        .store = "/git/github.com/nektro/zig-ansi/faf9585bfe5980c24748ee8a3e6a22faaa50b437",
        .name = "ansi",
        .entry = "/git/github.com/nektro/zig-ansi/faf9585bfe5980c24748ee8a3e6a22faaa50b437/src/lib.zig",
    };
    pub var _f7dubzb7cyqe = Package{
        .store = "/git/github.com/nektro/zig-extras/ff267312e8d714c9b9d8c44ad3291f6e509dc12f",
        .name = "extras",
        .entry = "/git/github.com/nektro/zig-extras/ff267312e8d714c9b9d8c44ad3291f6e509dc12f/src/lib.zig",
    };
    pub var _0npcrzfdlrvk = Package{
        .store = "/git/github.com/nektro/zig-licenses/c9b8cbf3565675a056ad4e9b57cb4f84020e7680",
        .name = "licenses",
        .entry = "/git/github.com/nektro/zig-licenses/c9b8cbf3565675a056ad4e9b57cb4f84020e7680/src/lib.zig",
    };
    pub var _pt88y5d80m25 = Package{
        .store = "/git/github.com/nektro/zig-licenses-text/3c07c6e4eb0965dafd0b029c632f823631b3169c",
        .name = "licenses-text",
        .entry = "/git/github.com/nektro/zig-licenses-text/3c07c6e4eb0965dafd0b029c632f823631b3169c/src/lib.zig",
    };
    pub var _tnj3qf44tpeq = Package{
        .store = "/git/github.com/nektro/zig-range/4b2f12808aa09be4b27a163efc424dd4e0415992",
        .name = "range",
        .entry = "/git/github.com/nektro/zig-range/4b2f12808aa09be4b27a163efc424dd4e0415992/src/lib.zig",
    };
    pub var _c1xirp1ota5p = Package{
        .store = "/git/github.com/nektro/zig-inquirer/5cc2a5565d04fe2c0085f0d6818590e800d9dcf7",
        .name = "inquirer",
        .entry = "/git/github.com/nektro/zig-inquirer/5cc2a5565d04fe2c0085f0d6818590e800d9dcf7/src/lib.zig",
        .deps = &[_]*Package{ &_s84v9o48ucb0, &_tnj3qf44tpeq },
    };
    pub var _96h80ezrvj7i = Package{
        .store = "/git/github.com/nektro/zig-leven/550cabd5a18ace5e67761bc5b867c10e926f4314",
        .name = "leven",
        .entry = "/git/github.com/nektro/zig-leven/550cabd5a18ace5e67761bc5b867c10e926f4314/src/lib.zig",
        .deps = &[_]*Package{ &_tnj3qf44tpeq },
    };
    pub var _2ovav391ivak = Package{
        .store = "/git/github.com/nektro/zig-detect-license/8f13721bd18c0e546841b6f2e11da839550d6287",
        .name = "detect-license",
        .entry = "/git/github.com/nektro/zig-detect-license/8f13721bd18c0e546841b6f2e11da839550d6287/src/lib.zig",
        .deps = &[_]*Package{ &_pt88y5d80m25, &_96h80ezrvj7i },
    };
    pub var _iecwp4b3bsfm = Package{
        .store = "/git/github.com/nektro/zig-time/ca9c0e6b644d74c1d549cc2c1ee22113aa021bd8",
        .name = "time",
        .entry = "/git/github.com/nektro/zig-time/ca9c0e6b644d74c1d549cc2c1ee22113aa021bd8/time.zig",
        .deps = &[_]*Package{ &_f7dubzb7cyqe },
    };
    pub var _g982zq6e8wsv = Package{
        .store = "/git/github.com/nektro/zig-yaml/e56b9fed6c0afd1c4d29bedc08c3899ffe1165e9",
        .name = "yaml",
        .entry = "/git/github.com/nektro/zig-yaml/e56b9fed6c0afd1c4d29bedc08c3899ffe1165e9/yaml.zig",
        .deps = &[_]*Package{ &_f7dubzb7cyqe },
    };
    pub var _9k24gimke1an = Package{
        .store = "/git/github.com/truemedian/hzzp/501386e13b2f7849128f3b271d23de6127b1d9d7",
        .name = "hzzp",
        .entry = "/git/github.com/truemedian/hzzp/501386e13b2f7849128f3b271d23de6127b1d9d7/src/main.zig",
    };
    pub var _ejw82j2ipa0e = Package{
        .store = "/git/github.com/truemedian/zfetch/829973144f680cd16be16923041fa810c1dee417",
        .name = "zfetch",
        .entry = "/git/github.com/truemedian/zfetch/829973144f680cd16be16923041fa810c1dee417/src/main.zig",
        .deps = &[_]*Package{ &_9k24gimke1an, &_csbnipaad8n7, &_u9w9dpp6p804 },
    };
    pub var _2ta738wrqbaq = Package{
        .store = "/git/github.com/ziglibs/known-folders/d13ba6137084e55f873f6afb67447fe8906cc951",
        .name = "known-folders",
        .entry = "/git/github.com/ziglibs/known-folders/d13ba6137084e55f873f6afb67447fe8906cc951/known-folders.zig",
    };
    pub var _89ujp8gq842x = Package{
        .name = "zigmod",
        .entry = "/../..//src/lib.zig",
        .deps = &[_]*Package{ &_g982zq6e8wsv, &_s84v9o48ucb0, &_2ta738wrqbaq, &_0npcrzfdlrvk, &_ejw82j2ipa0e, &_2ovav391ivak, &_c1xirp1ota5p, &_u7sysdckdymi, &_iecwp4b3bsfm, &_f7dubzb7cyqe },
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
