// zig fmt: off
const std = @import("std");
const builtin = @import("builtin");
const Pkg = std.build.Pkg;
const string = []const u8;

pub const GitExactStep = struct {
    step: std.build.Step,
    builder: *std.build.Builder,
    url: string,
    commit: string,

        pub fn create(b: *std.build.Builder, url: string, commit: string) *GitExactStep {
            var result = b.allocator.create(GitExactStep) catch @panic("memory");
            result.* = GitExactStep{
                .step = std.build.Step.init(.custom, b.fmt("git clone {s} @ {s}", .{ url, commit }), b.allocator, make),
                .builder = b,
                .url = url,
                .commit = commit,
            };

            var urlpath = url;
            urlpath = trimPrefix(u8, urlpath, "https://");
            urlpath = trimPrefix(u8, urlpath, "git://");
            const repopath = b.fmt("{s}/zigmod/deps/git/{s}/{s}", .{ b.cache_root, urlpath, commit });
            flip(std.fs.cwd().access(repopath, .{})) catch return result;

            var clonestep = std.build.RunStep.create(b, "clone");
            clonestep.addArgs(&.{ "git", "clone", "-q", "--progress", url, repopath });
            result.step.dependOn(&clonestep.step);

            var checkoutstep = std.build.RunStep.create(b, "checkout");
            checkoutstep.addArgs(&.{ "git", "-C", repopath, "checkout", "-q", commit });
            result.step.dependOn(&checkoutstep.step);

            return result;
        }

        fn make(step: *std.build.Step) !void {
            _ = step;
        }
};

pub fn fetch(exe: *std.build.LibExeObjStep) void {
    const b = exe.builder;
    inline for (comptime std.meta.declarations(package_data)) |decl| {
        const path = &@field(package_data, decl.name).entry;
        const root = if (@field(package_data, decl.name).store) |_| b.cache_root else ".";
        if (path.* != null) path.* = b.fmt("{s}/zigmod/deps{s}", .{ root, path.*.? });
    }
    exe.step.dependOn(&GitExactStep.create(b, "https://gist.github.com/nektro/d468fea84f8217e4c26ee8fbeeea38cc", "0911d65210fe14467fa73afd5b09d781a3995adc").step);
    exe.step.dependOn(&GitExactStep.create(b, "https://github.com/MasterQ32/zig-uri", "e879df3a236869f92298fbe2db3c25e6e84cfd4c").step);
    exe.step.dependOn(&GitExactStep.create(b, "https://github.com/marlersoft/zigwin32", "209f07cc5861c7bd9c3010a37f32bf6244f9a158").step);
    exe.step.dependOn(&GitExactStep.create(b, "https://github.com/nektro/arqv-ini", "1a9b2e90379895e197893b6e19c93bd213ad36e6").step);
    exe.step.dependOn(&GitExactStep.create(b, "https://github.com/nektro/iguanaTLS", "c9403b8414d7f80b5e2c04c8f1f8780ca1d2827f").step);
    exe.step.dependOn(&GitExactStep.create(b, "https://github.com/nektro/zig-ansi", "d4a53bcac5b87abecc65491109ec22aaf5f3dc2f").step);
    exe.step.dependOn(&GitExactStep.create(b, "https://github.com/nektro/zig-detect-license", "de5c285d999eea68b9189b48bb000243fef0a689").step);
    exe.step.dependOn(&GitExactStep.create(b, "https://github.com/nektro/zig-extras", "01fae956e2f17aa992e717e041a3dd457d440b31").step);
    exe.step.dependOn(&GitExactStep.create(b, "https://github.com/nektro/zig-inquirer", "14c3492c46f9765c3e77436741794d1a3118cbee").step);
    exe.step.dependOn(&GitExactStep.create(b, "https://github.com/nektro/zig-json", "a091eaa9f9ae91c3875630ba1983b33ea04971a3").step);
    exe.step.dependOn(&GitExactStep.create(b, "https://github.com/nektro/zig-leven", "ab852cf74fa0b4edc530d925f0654b62c60365bf").step);
    exe.step.dependOn(&GitExactStep.create(b, "https://github.com/nektro/zig-licenses", "c9b8cbf3565675a056ad4e9b57cb4f84020e7680").step);
    exe.step.dependOn(&GitExactStep.create(b, "https://github.com/nektro/zig-licenses-text", "3c07c6e4eb0965dafd0b029c632f823631b3169c").step);
    exe.step.dependOn(&GitExactStep.create(b, "https://github.com/nektro/zig-range", "4b2f12808aa09be4b27a163efc424dd4e0415992").step);
    exe.step.dependOn(&GitExactStep.create(b, "https://github.com/nektro/zig-time", "52a6050939b83e9f8b52b2236a36332dcb4c17a3").step);
    exe.step.dependOn(&GitExactStep.create(b, "https://github.com/truemedian/hzzp", "d4fbade2d806fc93bc5f79ec8efdcc25ea625fa3").step);
    exe.step.dependOn(&GitExactStep.create(b, "https://github.com/truemedian/zfetch", "829973144f680cd16be16923041fa810c1dee417").step);
    exe.step.dependOn(&GitExactStep.create(b, "https://github.com/ziglibs/known-folders", "24845b0103e611c108d6bc334231c464e699742c").step);
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
    const b = exe.builder;
    @setEvalBranchQuota(1_000_000);
    for (packages) |pkg| {
        exe.addPackage(pkg.zp(b));
    }
    var llc = false;
    var vcpkg = false;
    inline for (comptime std.meta.declarations(package_data)) |decl| {
        const pkg = @as(Package, @field(package_data, decl.name));
        const root = if (pkg.store) |st| b.fmt("{s}/zigmod/deps/{s}", .{ b.cache_root, st }) else ".";
        for (pkg.system_libs) |item| {
            exe.linkSystemLibrary(item);
            llc = true;
        }
        for (pkg.frameworks) |item| {
            if (!builtin.target.isDarwin()) @panic(exe.builder.fmt("a dependency is attempting to link to the framework {s}, which is only possible under Darwin", .{item}));
            exe.linkFramework(item);
            llc = true;
        }
        for (pkg.c_include_dirs) |item| {
            exe.addIncludeDir(b.fmt("{s}/{s}", .{ root, item }));
            llc = true;
        }
        for (pkg.c_source_files) |item| {
            exe.addCSourceFile(b.fmt("{s}/{s}", .{ root, item }), pkg.c_source_flags);
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

    pub fn zp(self: *const Package, b: *std.build.Builder) Pkg {
        var temp: [100]Pkg = undefined;
        for (self.deps) |item, i| {
            temp[i] = item.zp(b);
        }
        return .{
            .name = self.name,
            .source = .{ .path = self.entry.? },
            .dependencies = b.allocator.dupe(Pkg, temp[0..self.deps.len]) catch @panic("oom"),
        };
    }
};

fn checkMinZig(current: std.SemanticVersion, exe: *std.build.LibExeObjStep) void {
    const min = std.SemanticVersion.parse("0.10.0-dev.3998+c25ce5bba") catch return;
    if (current.order(min).compare(.lt)) @panic(exe.builder.fmt("Your Zig version v{} does not meet the minimum build requirement of v{}", .{current, min}));
}

pub const package_data = struct {
    pub var _u9w9dpp6p804 = Package{
        .store = "/git/github.com/MasterQ32/zig-uri/e879df3a236869f92298fbe2db3c25e6e84cfd4c",
        .name = "uri",
        .entry = "/git/github.com/MasterQ32/zig-uri/e879df3a236869f92298fbe2db3c25e6e84cfd4c/uri.zig",
    };
    pub var _o6ogpor87xc2 = Package{
        .store = "/git/github.com/marlersoft/zigwin32/209f07cc5861c7bd9c3010a37f32bf6244f9a158",
        .name = "win32",
        .entry = "/git/github.com/marlersoft/zigwin32/209f07cc5861c7bd9c3010a37f32bf6244f9a158/win32.zig",
    };
    pub var _u7sysdckdymi = Package{
        .store = "/git/github.com/nektro/arqv-ini/1a9b2e90379895e197893b6e19c93bd213ad36e6",
        .name = "ini",
        .entry = "/git/github.com/nektro/arqv-ini/1a9b2e90379895e197893b6e19c93bd213ad36e6/src/ini.zig",
    };
    pub var _csbnipaad8n7 = Package{
        .store = "/git/github.com/nektro/iguanaTLS/c9403b8414d7f80b5e2c04c8f1f8780ca1d2827f",
        .name = "iguanaTLS",
        .entry = "/git/github.com/nektro/iguanaTLS/c9403b8414d7f80b5e2c04c8f1f8780ca1d2827f/src/main.zig",
    };
    pub var _s84v9o48ucb0 = Package{
        .store = "/git/github.com/nektro/zig-ansi/d4a53bcac5b87abecc65491109ec22aaf5f3dc2f",
        .name = "ansi",
        .entry = "/git/github.com/nektro/zig-ansi/d4a53bcac5b87abecc65491109ec22aaf5f3dc2f/src/lib.zig",
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
    pub var _f7dubzb7cyqe = Package{
        .store = "/git/github.com/nektro/zig-extras/01fae956e2f17aa992e717e041a3dd457d440b31",
        .name = "extras",
        .entry = "/git/github.com/nektro/zig-extras/01fae956e2f17aa992e717e041a3dd457d440b31/src/lib.zig",
        .deps = &[_]*Package{ &_tnj3qf44tpeq },
    };
    pub var _g982zq6e8wsv = Package{
        .store = "/git/gist.github.com/nektro/d468fea84f8217e4c26ee8fbeeea38cc/0911d65210fe14467fa73afd5b09d781a3995adc",
        .name = "yaml",
        .entry = "/git/gist.github.com/nektro/d468fea84f8217e4c26ee8fbeeea38cc/0911d65210fe14467fa73afd5b09d781a3995adc/yaml.zig",
        .deps = &[_]*Package{ &_f7dubzb7cyqe },
    };
    pub var _c1xirp1ota5p = Package{
        .store = "/git/github.com/nektro/zig-inquirer/14c3492c46f9765c3e77436741794d1a3118cbee",
        .name = "inquirer",
        .entry = "/git/github.com/nektro/zig-inquirer/14c3492c46f9765c3e77436741794d1a3118cbee/src/lib.zig",
        .deps = &[_]*Package{ &_s84v9o48ucb0, &_tnj3qf44tpeq },
    };
    pub var _ocmr9rtohgcc = Package{
        .store = "/git/github.com/nektro/zig-json/a091eaa9f9ae91c3875630ba1983b33ea04971a3",
        .name = "json",
        .entry = "/git/github.com/nektro/zig-json/a091eaa9f9ae91c3875630ba1983b33ea04971a3/src/lib.zig",
        .deps = &[_]*Package{ &_f7dubzb7cyqe },
    };
    pub var _96h80ezrvj7i = Package{
        .store = "/git/github.com/nektro/zig-leven/ab852cf74fa0b4edc530d925f0654b62c60365bf",
        .name = "leven",
        .entry = "/git/github.com/nektro/zig-leven/ab852cf74fa0b4edc530d925f0654b62c60365bf/src/lib.zig",
        .deps = &[_]*Package{ &_tnj3qf44tpeq },
    };
    pub var _2ovav391ivak = Package{
        .store = "/git/github.com/nektro/zig-detect-license/de5c285d999eea68b9189b48bb000243fef0a689",
        .name = "detect-license",
        .entry = "/git/github.com/nektro/zig-detect-license/de5c285d999eea68b9189b48bb000243fef0a689/src/lib.zig",
        .deps = &[_]*Package{ &_pt88y5d80m25, &_96h80ezrvj7i },
    };
    pub var _iecwp4b3bsfm = Package{
        .store = "/git/github.com/nektro/zig-time/52a6050939b83e9f8b52b2236a36332dcb4c17a3",
        .name = "time",
        .entry = "/git/github.com/nektro/zig-time/52a6050939b83e9f8b52b2236a36332dcb4c17a3/time.zig",
        .deps = &[_]*Package{ &_tnj3qf44tpeq, &_f7dubzb7cyqe },
    };
    pub var _9k24gimke1an = Package{
        .store = "/git/github.com/truemedian/hzzp/d4fbade2d806fc93bc5f79ec8efdcc25ea625fa3",
        .name = "hzzp",
        .entry = "/git/github.com/truemedian/hzzp/d4fbade2d806fc93bc5f79ec8efdcc25ea625fa3/src/main.zig",
    };
    pub var _ejw82j2ipa0e = Package{
        .store = "/git/github.com/truemedian/zfetch/829973144f680cd16be16923041fa810c1dee417",
        .name = "zfetch",
        .entry = "/git/github.com/truemedian/zfetch/829973144f680cd16be16923041fa810c1dee417/src/main.zig",
        .deps = &[_]*Package{ &_9k24gimke1an, &_csbnipaad8n7, &_u9w9dpp6p804 },
    };
    pub var _2ta738wrqbaq = Package{
        .store = "/git/github.com/ziglibs/known-folders/24845b0103e611c108d6bc334231c464e699742c",
        .name = "known-folders",
        .entry = "/git/github.com/ziglibs/known-folders/24845b0103e611c108d6bc334231c464e699742c/known-folders.zig",
    };
    pub var _89ujp8gq842x = Package{
        .name = "zigmod",
        .entry = "/../..//src/lib.zig",
        .deps = &[_]*Package{ &_g982zq6e8wsv, &_s84v9o48ucb0, &_2ta738wrqbaq, &_0npcrzfdlrvk, &_ejw82j2ipa0e, &_ocmr9rtohgcc, &_tnj3qf44tpeq, &_2ovav391ivak, &_c1xirp1ota5p, &_u7sysdckdymi, &_iecwp4b3bsfm, &_f7dubzb7cyqe },
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

pub const packages = [_]*const Package{
    &package_data._89ujp8gq842x,
    &package_data._o6ogpor87xc2,
};

pub const pkgs = struct {
    pub const zigmod = &package_data._89ujp8gq842x;
    pub const win32 = &package_data._o6ogpor87xc2;
};

pub const imports = struct {
};
