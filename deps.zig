const std = @import("std");

pub const cache = ".zigmod/deps";

pub fn addAllTo(exe: *std.build.LibExeObjStep) void {
    @setEvalBranchQuota(1_000_000);
    for (packages) |pkg| {
        exe.addPackage(pkg);
    }
    if (c_include_dirs.len > 0 or c_source_files.len > 0) {
        exe.linkLibC();
    }
    for (c_include_dirs) |dir| {
        exe.addIncludeDir(dir);
    }
    inline for (c_source_files) |fpath| {
        exe.addCSourceFile(fpath[1], @field(c_source_flags, fpath[0]));
    }
    for (system_libs) |lib| {
        exe.linkSystemLibrary(lib);
    }
}

fn get_flags(comptime index: usize) []const u8 {
    return @field(c_source_flags, _paths[index]);
}

pub const _ids = .{
    "89ujp8gq842x",
    "8mdbh0zuneb0",
    "s84v9o48ucb0",
    "2ta738wrqbaq",
    "0npcrzfdlrvk",
    "ejw82j2ipa0e",
    "9k24gimke1an",
    "csbnipaad8n7",
    "yyhw90zkzgmu",
    "u9w9dpp6p804",
    "ocmr9rtohgcc",
    "tnj3qf44tpeq",
};

pub const _paths = .{
    "/../../",
    "/v/git/github.com/yaml/libyaml/tag-0.2.5/",
    "/git/github.com/nektro/zig-ansi/",
    "/git/github.com/ziglibs/known-folders/",
    "/git/github.com/nektro/zig-licenses/",
    "/git/github.com/truemedian/zfetch/",
    "/git/github.com/truemedian/hzzp/",
    "/git/github.com/alexnask/iguanaTLS/",
    "/git/github.com/MasterQ32/zig-network/",
    "/git/github.com/MasterQ32/zig-uri/",
    "/git/github.com/nektro/zig-json/",
    "/v/http/aquila.red/1/nektro/range/v0.1.tar.gz/d2f72fdd/",
};

pub const package_data = struct {
    pub const _s84v9o48ucb0 = std.build.Pkg{ .name = "ansi", .path = std.build.FileSource{ .path = cache ++ "/git/github.com/nektro/zig-ansi/src/lib.zig" }, .dependencies = &[_]std.build.Pkg{ } };
    pub const _2ta738wrqbaq = std.build.Pkg{ .name = "known-folders", .path = std.build.FileSource{ .path = cache ++ "/git/github.com/ziglibs/known-folders/known-folders.zig" }, .dependencies = &[_]std.build.Pkg{ } };
    pub const _0npcrzfdlrvk = std.build.Pkg{ .name = "licenses", .path = std.build.FileSource{ .path = cache ++ "/git/github.com/nektro/zig-licenses/src/lib.zig" }, .dependencies = &[_]std.build.Pkg{ } };
    pub const _9k24gimke1an = std.build.Pkg{ .name = "hzzp", .path = std.build.FileSource{ .path = cache ++ "/git/github.com/truemedian/hzzp/src/main.zig" }, .dependencies = &[_]std.build.Pkg{ } };
    pub const _csbnipaad8n7 = std.build.Pkg{ .name = "iguanaTLS", .path = std.build.FileSource{ .path = cache ++ "/git/github.com/alexnask/iguanaTLS/src/main.zig" }, .dependencies = &[_]std.build.Pkg{ } };
    pub const _yyhw90zkzgmu = std.build.Pkg{ .name = "network", .path = std.build.FileSource{ .path = cache ++ "/git/github.com/MasterQ32/zig-network/network.zig" }, .dependencies = &[_]std.build.Pkg{ } };
    pub const _u9w9dpp6p804 = std.build.Pkg{ .name = "uri", .path = std.build.FileSource{ .path = cache ++ "/git/github.com/MasterQ32/zig-uri/uri.zig" }, .dependencies = &[_]std.build.Pkg{ } };
    pub const _ejw82j2ipa0e = std.build.Pkg{ .name = "zfetch", .path = std.build.FileSource{ .path = cache ++ "/git/github.com/truemedian/zfetch/src/main.zig" }, .dependencies = &[_]std.build.Pkg{ _9k24gimke1an, _csbnipaad8n7, _yyhw90zkzgmu, _u9w9dpp6p804, } };
    pub const _ocmr9rtohgcc = std.build.Pkg{ .name = "json", .path = std.build.FileSource{ .path = cache ++ "/git/github.com/nektro/zig-json/src/lib.zig" }, .dependencies = &[_]std.build.Pkg{ } };
    pub const _tnj3qf44tpeq = std.build.Pkg{ .name = "range", .path = std.build.FileSource{ .path = cache ++ "/v/http/aquila.red/1/nektro/range/v0.1.tar.gz/d2f72fdd/src/lib.zig" }, .dependencies = &[_]std.build.Pkg{ } };
    pub const _89ujp8gq842x = std.build.Pkg{ .name = "zigmod", .path = std.build.FileSource{ .path = cache ++ "/../../src/lib.zig" }, .dependencies = &[_]std.build.Pkg{ _s84v9o48ucb0, _2ta738wrqbaq, _0npcrzfdlrvk, _ejw82j2ipa0e, _ocmr9rtohgcc, _tnj3qf44tpeq, } };
};

pub const packages = &[_]std.build.Pkg{
    package_data._89ujp8gq842x,
};

pub const pkgs = struct {
    pub const zigmod = packages[0];
};

pub const c_include_dirs = &[_][]const u8{
    cache ++ _paths[1] ++ "include",
};

pub const c_source_flags = struct {
    pub const @"8mdbh0zuneb0" = &.{"-DYAML_VERSION_MAJOR=0","-DYAML_VERSION_MINOR=2","-DYAML_VERSION_PATCH=5","-DYAML_VERSION_STRING=\"0.2.5\"","-DYAML_DECLARE_STATIC=1",};
};

pub const c_source_files = &[_][2][]const u8{
    [_][]const u8{_ids[1], cache ++ _paths[1] ++ "src/api.c"},
    [_][]const u8{_ids[1], cache ++ _paths[1] ++ "src/dumper.c"},
    [_][]const u8{_ids[1], cache ++ _paths[1] ++ "src/emitter.c"},
    [_][]const u8{_ids[1], cache ++ _paths[1] ++ "src/loader.c"},
    [_][]const u8{_ids[1], cache ++ _paths[1] ++ "src/parser.c"},
    [_][]const u8{_ids[1], cache ++ _paths[1] ++ "src/reader.c"},
    [_][]const u8{_ids[1], cache ++ _paths[1] ++ "src/scanner.c"},
    [_][]const u8{_ids[1], cache ++ _paths[1] ++ "src/writer.c"},
};

pub const system_libs = &[_][]const u8{
};

