const std = @import("std");
const build = std.build;

pub const cache = ".zigmod/deps";

pub fn addAllTo(exe: *build.LibExeObjStep) void {
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
    "89ujp8gq842x6mzok8feypwze138n2d96zpugw44hcq7406r",
    "8mdbh0zuneb0i3hs5jby5je0heem1i6yxusl7c8y8qx68hqc",
    "s84v9o48ucb0xq0cmzq0cn433hgw0iaqztugja16h8bzxu3h",
    "2ta738wrqbaqzl3iwzoo8nj35k9ynwz5p5iyz80ryrpp4ttf",
    "2b7mq571jmq31ktmpigopu29480iw245heueajgxzxn7ab8o",
    "csbnipaad8n77buaszsnjvlmn6j173fl7pkprsctelswjywe",
    "0npcrzfdlrvkf44mzjo8bduj9gmqyefo0j3rstt6b0pm2r6r",
};

pub const _paths = .{
    "",
    "/v/git/github.com/yaml/libyaml/tag-0.2.5/",
    "/v/git/github.com/nektro/zig-ansi/commit-25039ca/",
    "/v/git/github.com/ziglibs/known-folders/commit-f0f4188/",
    "/v/git/github.com/Vexu/zuri/commit-0f9cec8/",
    "/v/git/github.com/alexnask/iguanaTLS/commit-58f72f6/",
    "/v/git/github.com/nektro/zig-licenses/commit-a15ef9b/",
};

pub const package_data = struct {
    pub const _s84v9o48ucb0xq0cmzq0cn433hgw0iaqztugja16h8bzxu3h = build.Pkg{ .name = "ansi", .path = cache ++ "/v/git/github.com/nektro/zig-ansi/commit-25039ca/src/lib.zig", .dependencies = &[_]build.Pkg{ } };
    pub const _2ta738wrqbaqzl3iwzoo8nj35k9ynwz5p5iyz80ryrpp4ttf = build.Pkg{ .name = "known-folders", .path = cache ++ "/v/git/github.com/ziglibs/known-folders/commit-f0f4188/known-folders.zig", .dependencies = &[_]build.Pkg{ } };
    pub const _2b7mq571jmq31ktmpigopu29480iw245heueajgxzxn7ab8o = build.Pkg{ .name = "zuri", .path = cache ++ "/v/git/github.com/Vexu/zuri/commit-0f9cec8/src/zuri.zig", .dependencies = &[_]build.Pkg{ } };
    pub const _csbnipaad8n77buaszsnjvlmn6j173fl7pkprsctelswjywe = build.Pkg{ .name = "iguanatls", .path = cache ++ "/v/git/github.com/alexnask/iguanaTLS/commit-58f72f6/src/main.zig", .dependencies = &[_]build.Pkg{ } };
    pub const _0npcrzfdlrvkf44mzjo8bduj9gmqyefo0j3rstt6b0pm2r6r = build.Pkg{ .name = "licenses", .path = cache ++ "/v/git/github.com/nektro/zig-licenses/commit-a15ef9b/src/lib.zig", .dependencies = &[_]build.Pkg{ } };
};

pub const packages = &[_]build.Pkg{
    package_data._s84v9o48ucb0xq0cmzq0cn433hgw0iaqztugja16h8bzxu3h,
    package_data._2ta738wrqbaqzl3iwzoo8nj35k9ynwz5p5iyz80ryrpp4ttf,
    package_data._2b7mq571jmq31ktmpigopu29480iw245heueajgxzxn7ab8o,
    package_data._csbnipaad8n77buaszsnjvlmn6j173fl7pkprsctelswjywe,
    package_data._0npcrzfdlrvkf44mzjo8bduj9gmqyefo0j3rstt6b0pm2r6r,
};

pub const pkgs = struct {
    pub const ansi = packages[1];
    pub const known_folders = packages[2];
    pub const zuri = packages[3];
    pub const iguanatls = packages[4];
    pub const licenses = packages[5];
};

pub const c_include_dirs = &[_][]const u8{
    cache ++ _paths[1] ++ "include",
};

pub const c_source_flags = struct {
    pub const @"89ujp8gq842x6mzok8feypwze138n2d96zpugw44hcq7406r" = &[_][]const u8{};
    pub const @"8mdbh0zuneb0i3hs5jby5je0heem1i6yxusl7c8y8qx68hqc" = &[_][]const u8{"-DYAML_VERSION_MAJOR=0","-DYAML_VERSION_MINOR=2","-DYAML_VERSION_PATCH=5","-DYAML_VERSION_STRING=\"0.2.5\"","-DYAML_DECLARE_STATIC=1",};
    pub const @"s84v9o48ucb0xq0cmzq0cn433hgw0iaqztugja16h8bzxu3h" = &[_][]const u8{};
    pub const @"2ta738wrqbaqzl3iwzoo8nj35k9ynwz5p5iyz80ryrpp4ttf" = &[_][]const u8{};
    pub const @"2b7mq571jmq31ktmpigopu29480iw245heueajgxzxn7ab8o" = &[_][]const u8{};
    pub const @"csbnipaad8n77buaszsnjvlmn6j173fl7pkprsctelswjywe" = &[_][]const u8{};
    pub const @"0npcrzfdlrvkf44mzjo8bduj9gmqyefo0j3rstt6b0pm2r6r" = &[_][]const u8{};
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

