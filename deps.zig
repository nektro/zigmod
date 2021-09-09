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
    pub const _root = "";
    pub const _89ujp8gq842x = cache ++ "/../..";
    pub const _8mdbh0zuneb0 = cache ++ "/v/git/github.com/yaml/libyaml/tag-0.2.5";
    pub const _csbnipaad8n7 = cache ++ "/git/github.com/nektro/iguanaTLS";
    pub const _s84v9o48ucb0 = cache ++ "/git/github.com/nektro/zig-ansi";
    pub const _2ta738wrqbaq = cache ++ "/git/github.com/ziglibs/known-folders";
    pub const _0npcrzfdlrvk = cache ++ "/git/github.com/nektro/zig-licenses";
    pub const _ejw82j2ipa0e = cache ++ "/git/github.com/truemedian/zfetch";
    pub const _9k24gimke1an = cache ++ "/git/github.com/truemedian/hzzp";
    pub const _yyhw90zkzgmu = cache ++ "/git/github.com/MasterQ32/zig-network";
    pub const _u9w9dpp6p804 = cache ++ "/git/github.com/MasterQ32/zig-uri";
    pub const _ocmr9rtohgcc = cache ++ "/git/github.com/nektro/zig-json";
    pub const _tnj3qf44tpeq = cache ++ "/git/github.com/nektro/zig-range";
    pub const _2ovav391ivak = cache ++ "/git/github.com/nektro/zig-detect-license";
    pub const _pt88y5d80m25 = cache ++ "/git/github.com/nektro/zig-licenses-text";
    pub const _96h80ezrvj7i = cache ++ "/git/github.com/nektro/zig-leven";
    pub const _qyrnfg0iwpzl = cache ++ "/git/github.com/nektro/zig-fs-check";
    pub const _c1xirp1ota5p = cache ++ "/git/github.com/nektro/zig-inquirer";
    pub const _u7sysdckdymi = cache ++ "/git/github.com/arqv/ini";
    pub const _o6ogpor87xc2 = cache ++ "/git/github.com/marlersoft/zigwin32";
};

pub const package_data = struct {
    pub const _8mdbh0zuneb0 = Package{
        .directory = dirs._8mdbh0zuneb0,
        .c_include_dirs = &.{ "include" },
        .c_source_files = &.{ "src/api.c", "src/dumper.c", "src/emitter.c", "src/loader.c", "src/parser.c", "src/reader.c", "src/scanner.c", "src/writer.c" },
        .c_source_flags = &.{ "-DYAML_VERSION_MAJOR=0", "-DYAML_VERSION_MINOR=2", "-DYAML_VERSION_PATCH=5", "-DYAML_VERSION_STRING=\"0.2.5\"", "-DYAML_DECLARE_STATIC=1" },
    };
    pub const _csbnipaad8n7 = Package{
        .directory = dirs._csbnipaad8n7,
        .pkg = Pkg{ .name = "iguanaTLS", .path = .{ .path = dirs._csbnipaad8n7 ++ "/src/main.zig" }, .dependencies = null },
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
    pub const _pt88y5d80m25 = Package{
        .directory = dirs._pt88y5d80m25,
        .pkg = Pkg{ .name = "licenses-text", .path = .{ .path = dirs._pt88y5d80m25 ++ "/src/lib.zig" }, .dependencies = null },
    };
    pub const _96h80ezrvj7i = Package{
        .directory = dirs._96h80ezrvj7i,
        .pkg = Pkg{ .name = "leven", .path = .{ .path = dirs._96h80ezrvj7i ++ "/src/lib.zig" }, .dependencies = &.{ _tnj3qf44tpeq.pkg.? } },
    };
    pub const _qyrnfg0iwpzl = Package{
        .directory = dirs._qyrnfg0iwpzl,
        .pkg = Pkg{ .name = "fs-check", .path = .{ .path = dirs._qyrnfg0iwpzl ++ "/src/lib.zig" }, .dependencies = null },
    };
    pub const _2ovav391ivak = Package{
        .directory = dirs._2ovav391ivak,
        .pkg = Pkg{ .name = "detect-license", .path = .{ .path = dirs._2ovav391ivak ++ "/src/lib.zig" }, .dependencies = &.{ _pt88y5d80m25.pkg.?, _96h80ezrvj7i.pkg.?, _qyrnfg0iwpzl.pkg.? } },
    };
    pub const _c1xirp1ota5p = Package{
        .directory = dirs._c1xirp1ota5p,
        .pkg = Pkg{ .name = "inquirer", .path = .{ .path = dirs._c1xirp1ota5p ++ "/src/lib.zig" }, .dependencies = &.{ _s84v9o48ucb0.pkg.?, _tnj3qf44tpeq.pkg.? } },
    };
    pub const _u7sysdckdymi = Package{
        .directory = dirs._u7sysdckdymi,
        .pkg = Pkg{ .name = "ini", .path = .{ .path = dirs._u7sysdckdymi ++ "/src/ini.zig" }, .dependencies = null },
    };
    pub const _89ujp8gq842x = Package{
        .directory = dirs._89ujp8gq842x,
        .pkg = Pkg{ .name = "zigmod", .path = .{ .path = dirs._89ujp8gq842x ++ "/src/lib.zig" }, .dependencies = &.{ _csbnipaad8n7.pkg.?, _s84v9o48ucb0.pkg.?, _2ta738wrqbaq.pkg.?, _0npcrzfdlrvk.pkg.?, _ejw82j2ipa0e.pkg.?, _ocmr9rtohgcc.pkg.?, _tnj3qf44tpeq.pkg.?, _2ovav391ivak.pkg.?, _c1xirp1ota5p.pkg.?, _u7sysdckdymi.pkg.? } },
    };
    pub const _o6ogpor87xc2 = Package{
        .directory = dirs._o6ogpor87xc2,
        .pkg = Pkg{ .name = "win32", .path = .{ .path = dirs._o6ogpor87xc2 ++ "/win32.zig" }, .dependencies = null },
    };
    pub const _root = Package{
        .directory = dirs._root,
    };
};

pub const packages = &[_]Package{
    package_data._89ujp8gq842x,
    package_data._o6ogpor87xc2,
};

pub const pkgs = struct {
    pub const zigmod = package_data._89ujp8gq842x;
    pub const win32 = package_data._o6ogpor87xc2;
};

pub const imports = struct {
    pub const zigmod = @import(".zigmod/deps/../../src/lib.zig");
};
