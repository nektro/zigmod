const std = @import("std");
const Pkg = std.build.Pkg;
const string = []const u8;

pub const cache = ".zigmod/deps";

pub fn addAllTo(exe: *std.build.LibExeObjStep) void {
    @setEvalBranchQuota(1_000_000);
    for (packages) |pkg| {
        exe.addPackage(pkg.pkg.?);
    }
    inline for (std.meta.declarations(package_data)) |decl| {
        const pkg = @as(Package, @field(package_data, decl.name));
        var llc = false;
        inline for (pkg.system_libs) |item| {
            exe.linkSystemLibrary(item);
            llc = true;
        }
        inline for (pkg.c_include_dirs) |item| {
            exe.addIncludeDir(@field(dirs, decl.name) ++ "/" ++ item);
            llc = true;
        }
        inline for (pkg.c_source_files) |item| {
            exe.addCSourceFile(@field(dirs, decl.name) ++ "/" ++ item, pkg.c_source_flags);
            llc = true;
        }
        if (llc) {
            exe.linkLibC();
        }
    }
}

pub const Package = struct {
    directory: string,
    pkg: ?Pkg = null,
    c_include_dirs: []const string = &.{},
    c_source_files: []const string = &.{},
    c_source_flags: []const string = &.{},
    system_libs: []const string = &.{},
};

const dirs = struct {
    pub const _89ujp8gq842x = cache ++ "/../..";
    pub const _8mdbh0zuneb0 = cache ++ "/v/git/github.com/yaml/libyaml/tag-0.2.5";
    pub const _s84v9o48ucb0 = cache ++ "/git/github.com/nektro/zig-ansi";
    pub const _2ta738wrqbaq = cache ++ "/git/github.com/ziglibs/known-folders";
    pub const _0npcrzfdlrvk = cache ++ "/git/github.com/nektro/zig-licenses";
    pub const _ejw82j2ipa0e = cache ++ "/git/github.com/truemedian/zfetch";
    pub const _9k24gimke1an = cache ++ "/git/github.com/truemedian/hzzp";
    pub const _csbnipaad8n7 = cache ++ "/git/github.com/alexnask/iguanaTLS";
    pub const _yyhw90zkzgmu = cache ++ "/git/github.com/MasterQ32/zig-network";
    pub const _u9w9dpp6p804 = cache ++ "/git/github.com/MasterQ32/zig-uri";
    pub const _ocmr9rtohgcc = cache ++ "/git/github.com/nektro/zig-json";
    pub const _tnj3qf44tpeq = cache ++ "/git/github.com/nektro/zig-range";
};

pub const package_data = struct {
    pub const _8mdbh0zuneb0 = Package{
        .directory = dirs._8mdbh0zuneb0,
        .c_include_dirs = &.{ "include" },
        .c_source_files = &.{ "src/api.c", "src/dumper.c", "src/emitter.c", "src/loader.c", "src/parser.c", "src/reader.c", "src/scanner.c", "src/writer.c" },
        .c_source_flags = &.{ "-DYAML_VERSION_MAJOR=0", "-DYAML_VERSION_MINOR=2", "-DYAML_VERSION_PATCH=5", "-DYAML_VERSION_STRING=\"0.2.5\"", "-DYAML_DECLARE_STATIC=1" },
    };

    pub const _s84v9o48ucb0 = Package{
        .directory = dirs._s84v9o48ucb0,
        .pkg = Pkg{ .name = "ansi", .path = .{ .path = dirs._s84v9o48ucb0 ++ "/src/lib.zig" }, .dependencies = null },
    };

    pub const _2ta738wrqbaq = Package{
        .directory = dirs._2ta738wrqbaq,
        .pkg = Pkg{ .name = "known-folders", .path = .{ .path = dirs._2ta738wrqbaq ++ "/known-folders.zig" }, .dependencies = null },
    };

    pub const _0npcrzfdlrvk = Package{
        .directory = dirs._0npcrzfdlrvk,
        .pkg = Pkg{ .name = "licenses", .path = .{ .path = dirs._0npcrzfdlrvk ++ "/src/lib.zig" }, .dependencies = null },
    };

    pub const _9k24gimke1an = Package{
        .directory = dirs._9k24gimke1an,
        .pkg = Pkg{ .name = "hzzp", .path = .{ .path = dirs._9k24gimke1an ++ "/src/main.zig" }, .dependencies = null },
    };

    pub const _csbnipaad8n7 = Package{
        .directory = dirs._csbnipaad8n7,
        .pkg = Pkg{ .name = "iguanaTLS", .path = .{ .path = dirs._csbnipaad8n7 ++ "/src/main.zig" }, .dependencies = null },
    };

    pub const _yyhw90zkzgmu = Package{
        .directory = dirs._yyhw90zkzgmu,
        .pkg = Pkg{ .name = "network", .path = .{ .path = dirs._yyhw90zkzgmu ++ "/network.zig" }, .dependencies = null },
    };

    pub const _u9w9dpp6p804 = Package{
        .directory = dirs._u9w9dpp6p804,
        .pkg = Pkg{ .name = "uri", .path = .{ .path = dirs._u9w9dpp6p804 ++ "/uri.zig" }, .dependencies = null },
    };

    pub const _ejw82j2ipa0e = Package{
        .directory = dirs._ejw82j2ipa0e,
        .pkg = Pkg{ .name = "zfetch", .path = .{ .path = dirs._ejw82j2ipa0e ++ "/src/main.zig" }, .dependencies = &.{ _9k24gimke1an.pkg.?, _csbnipaad8n7.pkg.?, _yyhw90zkzgmu.pkg.?, _u9w9dpp6p804.pkg.? } },
    };

    pub const _ocmr9rtohgcc = Package{
        .directory = dirs._ocmr9rtohgcc,
        .pkg = Pkg{ .name = "json", .path = .{ .path = dirs._ocmr9rtohgcc ++ "/src/lib.zig" }, .dependencies = null },
    };

    pub const _tnj3qf44tpeq = Package{
        .directory = dirs._tnj3qf44tpeq,
        .pkg = Pkg{ .name = "range", .path = .{ .path = dirs._tnj3qf44tpeq ++ "/src/lib.zig" }, .dependencies = null },
    };

    pub const _89ujp8gq842x = Package{
        .directory = dirs._89ujp8gq842x,
        .pkg = Pkg{ .name = "zigmod", .path = .{ .path = dirs._89ujp8gq842x ++ "/src/lib.zig" }, .dependencies = &.{ _s84v9o48ucb0.pkg.?, _2ta738wrqbaq.pkg.?, _0npcrzfdlrvk.pkg.?, _ejw82j2ipa0e.pkg.?, _ocmr9rtohgcc.pkg.?, _tnj3qf44tpeq.pkg.? } },
    };

};

pub const packages = &[_]Package{
    package_data._89ujp8gq842x,
};

pub const pkgs = struct {
    pub const zigmod = package_data._89ujp8gq842x;
};

pub const imports = struct {
    pub const zigmod = @import(".zigmod/deps/../../src/lib.zig");
};

