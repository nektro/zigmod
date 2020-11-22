const std = @import("std");
const gpa = std.heap.c_allocator;

const u = @import("./util/index.zig");

//
//

pub fn collect_deps(dir: []const u8, mpath: []const u8) anyerror!u.Module {
    const m = try u.ModFile.init(gpa, mpath);
    const moduledeps = &std.ArrayList(u.Module).init(gpa);
    var moddir: []const u8 = undefined;
    for (m.deps) |d| {
        const p = try u.concat(&[_][]const u8{dir, "/deps/", try d.clean_path()});
        const pv = try u.concat(&[_][]const u8{dir, "/v/", try d.clean_path(), "/", d.version});
        if (try u.does_file_exist(pv)) {
            moddir = pv;
        } else {
            u.assert(try u.does_file_exist(p), "unable to find dep: {} {}, please run zigmod fetch", .{d.path, d.version});
            moddir = p;
        }
        switch (d.type) {
            else => blk: {
                var dd = try collect_deps(dir, try u.concat(&[_][]const u8{moddir, "/zig.mod"})) catch |e| switch (e) {
                    error.FileNotFound => {
                        if (d.c_include_dirs.len > 0 or d.c_source_files.len > 0) {
                            var mod_from = try u.Module.from(d);
                            mod_from.clean_path = u.trim_prefix(moddir, dir)[1..];
                            try moduledeps.append(mod_from);
                        }
                        break :blk;
                    },
                    else => e,
                };
                dd.clean_path = u.trim_prefix(moddir, dir)[1..];

                if (d.name.len > 0) dd.name = d.name;
                if (d.main.len > 0) dd.main = d.main;
                if (d.c_include_dirs.len > 0) dd.c_include_dirs = d.c_include_dirs;
                if (d.c_source_flags.len > 0) dd.c_source_flags = d.c_source_flags;
                if (d.c_source_files.len > 0) dd.c_source_files = d.c_source_files;

                try moduledeps.append(dd);
            },
        }
    }
    return u.Module{
        .name = m.name,
        .main = m.main,
        .c_include_dirs = m.c_include_dirs,
        .c_source_flags = m.c_source_flags,
        .c_source_files = m.c_source_files,
        .deps = moduledeps.items,
        .clean_path = "",
    };
}
