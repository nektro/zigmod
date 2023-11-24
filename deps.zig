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
    exe.step.dependOn(&GitExactStep.create(b, "https://github.com/marlersoft/zigwin32", "6777f1db221d0cb50322842f558f03e3c3a4099f").step);
    exe.step.dependOn(&GitExactStep.create(b, "https://github.com/nektro/arqv-ini", "ddbe89bb0d9085e939bcbc713caeb2b7cf852bae").step);
    exe.step.dependOn(&GitExactStep.create(b, "https://github.com/nektro/iguanaTLS", "f5c7c3fe880c5a23fbcdc21dfcb83c2776931f40").step);
    exe.step.dependOn(&GitExactStep.create(b, "https://github.com/nektro/zfetch", "f51277414a2309f776fb79f3d55f26e37f9a54da").step);
    exe.step.dependOn(&GitExactStep.create(b, "https://github.com/nektro/zig-ansi", "ac607e4e7ac36d46cc67c8786262578330543a36").step);
    exe.step.dependOn(&GitExactStep.create(b, "https://github.com/nektro/zig-detect-license", "3ff57d0681b7bd7f8ca9bd092afa0b4bfe2f1afd").step);
    exe.step.dependOn(&GitExactStep.create(b, "https://github.com/nektro/zig-extras", "05f0e90a185cb04a09b96f686dffc6375c420e9b").step);
    exe.step.dependOn(&GitExactStep.create(b, "https://github.com/nektro/zig-inquirer", "5cc2a5565d04fe2c0085f0d6818590e800d9dcf7").step);
    exe.step.dependOn(&GitExactStep.create(b, "https://github.com/nektro/zig-leven", "550cabd5a18ace5e67761bc5b867c10e926f4314").step);
    exe.step.dependOn(&GitExactStep.create(b, "https://github.com/nektro/zig-licenses", "c9b8cbf3565675a056ad4e9b57cb4f84020e7680").step);
    exe.step.dependOn(&GitExactStep.create(b, "https://github.com/nektro/zig-licenses-text", "3c07c6e4eb0965dafd0b029c632f823631b3169c").step);
    exe.step.dependOn(&GitExactStep.create(b, "https://github.com/nektro/zig-range", "4b2f12808aa09be4b27a163efc424dd4e0415992").step);
    exe.step.dependOn(&GitExactStep.create(b, "https://github.com/nektro/zig-time", "12fad367a5282827aad7e12f0e9cd36f672c4010").step);
    exe.step.dependOn(&GitExactStep.create(b, "https://github.com/nektro/zig-yaml", "0d17fb99cba338aedc1abac12d78d5e5f04f0b6b").step);
    exe.step.dependOn(&GitExactStep.create(b, "https://github.com/truemedian/hzzp", "92e6072d8a385d8b08fdcae3ae2021fe5293528f").step);
    exe.step.dependOn(&GitExactStep.create(b, "https://github.com/ziglibs/known-folders", "855473062efac722624737f1adc56f9c0dd92017").step);
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
            exe.addIncludePath(.{.path = b.fmt("{s}/{s}", .{ root, item })});
            llc = true;
        }
        for (pkg.c_source_files) |item| {
            exe.addCSourceFile(.{ .file = .{ .path = b.fmt("{s}/{s}", .{ root, item }) }, .flags = pkg.c_source_flags });
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
    const min = std.SemanticVersion.parse("0.11.0") catch return;
    if (current.order(min).compare(.lt)) @panic(exe.step.owner.fmt("Your Zig version v{} does not meet the minimum build requirement of v{}", .{current, min}));
}

pub const package_data = struct {
    pub var _o6ogpor87xc2 = Package{
        .store = "/git/github.com/marlersoft/zigwin32/6777f1db221d0cb50322842f558f03e3c3a4099f",
        .name = "win32",
        .entry = "/git/github.com/marlersoft/zigwin32/6777f1db221d0cb50322842f558f03e3c3a4099f/win32.zig",
    };
    pub var _u7sysdckdymi = Package{
        .store = "/git/github.com/nektro/arqv-ini/ddbe89bb0d9085e939bcbc713caeb2b7cf852bae",
        .name = "ini",
        .entry = "/git/github.com/nektro/arqv-ini/ddbe89bb0d9085e939bcbc713caeb2b7cf852bae/src/ini.zig",
    };
    pub var _csbnipaad8n7 = Package{
        .store = "/git/github.com/nektro/iguanaTLS/f5c7c3fe880c5a23fbcdc21dfcb83c2776931f40",
        .name = "iguanaTLS",
        .entry = "/git/github.com/nektro/iguanaTLS/f5c7c3fe880c5a23fbcdc21dfcb83c2776931f40/src/main.zig",
    };
    pub var _s84v9o48ucb0 = Package{
        .store = "/git/github.com/nektro/zig-ansi/ac607e4e7ac36d46cc67c8786262578330543a36",
        .name = "ansi",
        .entry = "/git/github.com/nektro/zig-ansi/ac607e4e7ac36d46cc67c8786262578330543a36/src/lib.zig",
    };
    pub var _f7dubzb7cyqe = Package{
        .store = "/git/github.com/nektro/zig-extras/05f0e90a185cb04a09b96f686dffc6375c420e9b",
        .name = "extras",
        .entry = "/git/github.com/nektro/zig-extras/05f0e90a185cb04a09b96f686dffc6375c420e9b/src/lib.zig",
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
        .store = "/git/github.com/nektro/zig-detect-license/3ff57d0681b7bd7f8ca9bd092afa0b4bfe2f1afd",
        .name = "detect-license",
        .entry = "/git/github.com/nektro/zig-detect-license/3ff57d0681b7bd7f8ca9bd092afa0b4bfe2f1afd/src/lib.zig",
        .deps = &[_]*Package{ &_pt88y5d80m25, &_96h80ezrvj7i },
    };
    pub var _iecwp4b3bsfm = Package{
        .store = "/git/github.com/nektro/zig-time/12fad367a5282827aad7e12f0e9cd36f672c4010",
        .name = "time",
        .entry = "/git/github.com/nektro/zig-time/12fad367a5282827aad7e12f0e9cd36f672c4010/time.zig",
        .deps = &[_]*Package{ &_f7dubzb7cyqe },
    };
    pub var _g982zq6e8wsv = Package{
        .store = "/git/github.com/nektro/zig-yaml/0d17fb99cba338aedc1abac12d78d5e5f04f0b6b",
        .name = "yaml",
        .entry = "/git/github.com/nektro/zig-yaml/0d17fb99cba338aedc1abac12d78d5e5f04f0b6b/yaml.zig",
        .deps = &[_]*Package{ &_f7dubzb7cyqe },
    };
    pub var _9k24gimke1an = Package{
        .store = "/git/github.com/truemedian/hzzp/92e6072d8a385d8b08fdcae3ae2021fe5293528f",
        .name = "hzzp",
        .entry = "/git/github.com/truemedian/hzzp/92e6072d8a385d8b08fdcae3ae2021fe5293528f/src/main.zig",
    };
    pub var _ejw82j2ipa0e = Package{
        .store = "/git/github.com/nektro/zfetch/f51277414a2309f776fb79f3d55f26e37f9a54da",
        .name = "zfetch",
        .entry = "/git/github.com/nektro/zfetch/f51277414a2309f776fb79f3d55f26e37f9a54da/src/main.zig",
        .deps = &[_]*Package{ &_9k24gimke1an, &_csbnipaad8n7 },
    };
    pub var _2ta738wrqbaq = Package{
        .store = "/git/github.com/ziglibs/known-folders/855473062efac722624737f1adc56f9c0dd92017",
        .name = "known-folders",
        .entry = "/git/github.com/ziglibs/known-folders/855473062efac722624737f1adc56f9c0dd92017/known-folders.zig",
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
