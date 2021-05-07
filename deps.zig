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
    "89ujp8gq842x6mzok8feypwze138n2d96zpugw44hcq7406r",
    "8mdbh0zuneb0i3hs5jby5je0heem1i6yxusl7c8y8qx68hqc",
    "s84v9o48ucb0xq0cmzq0cn433hgw0iaqztugja16h8bzxu3h",
    "2ta738wrqbaqzl3iwzoo8nj35k9ynwz5p5iyz80ryrpp4ttf",
    "0npcrzfdlrvkf44mzjo8bduj9gmqyefo0j3rstt6b0pm2r6r",
    "ejw82j2ipa0eul25ohgdh6yy5nkrtn2pf0rq18m0079w6wj7",
    "9k24gimke1anv665ilg4si32ayl3dsaqgmdfdpu1ceoky8tl",
    "csbnipaad8n77buaszsnjvlmn6j173fl7pkprsctelswjywe",
    "yyhw90zkzgmubwpp87n0pzf936n850an66y1c6qan5y6sogv",
    "u9w9dpp6p804p38o3u87f437pf942wxunyjite27dyhtu7ns",
    "ocmr9rtohgccd6gm6tp8b1yzylyzkqwvo1q4btrsvj0cse9y",
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
};

pub const package_data = struct {
    pub const _s84v9o48ucb0xq0cmzq0cn433hgw0iaqztugja16h8bzxu3h = std.build.Pkg{ .name = "ansi", .path = cache ++ "/git/github.com/nektro/zig-ansi/src/lib.zig", .dependencies = &[_]std.build.Pkg{ } };
    pub const _2ta738wrqbaqzl3iwzoo8nj35k9ynwz5p5iyz80ryrpp4ttf = std.build.Pkg{ .name = "known-folders", .path = cache ++ "/git/github.com/ziglibs/known-folders/known-folders.zig", .dependencies = &[_]std.build.Pkg{ } };
    pub const _0npcrzfdlrvkf44mzjo8bduj9gmqyefo0j3rstt6b0pm2r6r = std.build.Pkg{ .name = "licenses", .path = cache ++ "/git/github.com/nektro/zig-licenses/src/lib.zig", .dependencies = &[_]std.build.Pkg{ } };
    pub const _9k24gimke1anv665ilg4si32ayl3dsaqgmdfdpu1ceoky8tl = std.build.Pkg{ .name = "hzzp", .path = cache ++ "/git/github.com/truemedian/hzzp/src/main.zig", .dependencies = &[_]std.build.Pkg{ } };
    pub const _csbnipaad8n77buaszsnjvlmn6j173fl7pkprsctelswjywe = std.build.Pkg{ .name = "iguanaTLS", .path = cache ++ "/git/github.com/alexnask/iguanaTLS/src/main.zig", .dependencies = &[_]std.build.Pkg{ } };
    pub const _yyhw90zkzgmubwpp87n0pzf936n850an66y1c6qan5y6sogv = std.build.Pkg{ .name = "network", .path = cache ++ "/git/github.com/MasterQ32/zig-network/network.zig", .dependencies = &[_]std.build.Pkg{ } };
    pub const _u9w9dpp6p804p38o3u87f437pf942wxunyjite27dyhtu7ns = std.build.Pkg{ .name = "uri", .path = cache ++ "/git/github.com/MasterQ32/zig-uri/uri.zig", .dependencies = &[_]std.build.Pkg{ } };
    pub const _ejw82j2ipa0eul25ohgdh6yy5nkrtn2pf0rq18m0079w6wj7 = std.build.Pkg{ .name = "zfetch", .path = cache ++ "/git/github.com/truemedian/zfetch/src/main.zig", .dependencies = &[_]std.build.Pkg{ _9k24gimke1anv665ilg4si32ayl3dsaqgmdfdpu1ceoky8tl, _csbnipaad8n77buaszsnjvlmn6j173fl7pkprsctelswjywe, _yyhw90zkzgmubwpp87n0pzf936n850an66y1c6qan5y6sogv, _u9w9dpp6p804p38o3u87f437pf942wxunyjite27dyhtu7ns, } };
    pub const _ocmr9rtohgccd6gm6tp8b1yzylyzkqwvo1q4btrsvj0cse9y = std.build.Pkg{ .name = "json", .path = cache ++ "/git/github.com/nektro/zig-json/src/lib.zig", .dependencies = &[_]std.build.Pkg{ } };
    pub const _89ujp8gq842x6mzok8feypwze138n2d96zpugw44hcq7406r = std.build.Pkg{ .name = "zigmod", .path = cache ++ "/../../src/lib.zig", .dependencies = &[_]std.build.Pkg{ _s84v9o48ucb0xq0cmzq0cn433hgw0iaqztugja16h8bzxu3h, _2ta738wrqbaqzl3iwzoo8nj35k9ynwz5p5iyz80ryrpp4ttf, _0npcrzfdlrvkf44mzjo8bduj9gmqyefo0j3rstt6b0pm2r6r, _ejw82j2ipa0eul25ohgdh6yy5nkrtn2pf0rq18m0079w6wj7, _ocmr9rtohgccd6gm6tp8b1yzylyzkqwvo1q4btrsvj0cse9y, } };
};

pub const packages = &[_]std.build.Pkg{
    package_data._89ujp8gq842x6mzok8feypwze138n2d96zpugw44hcq7406r,
    package_data._s84v9o48ucb0xq0cmzq0cn433hgw0iaqztugja16h8bzxu3h,
};

pub const pkgs = struct {
    pub const zigmod = packages[0];
    pub const ansi = packages[1];
};

pub const c_include_dirs = &[_][]const u8{
    cache ++ _paths[1] ++ "include",
};

pub const c_source_flags = struct {
    pub const @"8mdbh0zuneb0i3hs5jby5je0heem1i6yxusl7c8y8qx68hqc" = &.{"-DYAML_VERSION_MAJOR=0","-DYAML_VERSION_MINOR=2","-DYAML_VERSION_PATCH=5","-DYAML_VERSION_STRING=\"0.2.5\"","-DYAML_DECLARE_STATIC=1",};
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

