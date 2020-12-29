const std = @import("std");
const gpa = std.heap.c_allocator;
const fs = std.fs;

const u = @import("./util/index.zig");

//
//

pub fn collect_deps(dir: []const u8, mpath: []const u8) anyerror!u.Module {
    const m = try u.ModFile.init(gpa, mpath);
    const moduledeps = &std.ArrayList(u.Module).init(gpa);
    var moddir: []const u8 = undefined;
    for (m.deps) |d| {
        const p = try fs.path.join(gpa, &[_][]const u8{dir, try d.clean_path()});
        const pv = try fs.path.join(gpa, &[_][]const u8{dir, "v", try d.clean_path(), d.version});
        if (try u.does_file_exist(pv)) {
            moddir = pv;
        } else {
            u.assert(try u.does_file_exist(p), "unable to find dep: {} {}, please run zigmod fetch", .{d.path, d.version});
            moddir = p;
        }
        switch (d.type) {
            .system_lib => {
                if (d.is_for_this()) try moduledeps.append(u.Module{
                    .is_sys_lib = true,
                    .id = d.id,
                    .name = d.path,
                    .only_os = d.only_os,
                    .except_os = d.except_os,
                    .main = "",
                    .c_include_dirs = &[_][]const u8{},
                    .c_source_flags = &[_][]const u8{},
                    .c_source_files = &[_][]const u8{},
                    .deps = &[_]u.Module{},
                    .clean_path = "",
                });
            },
            else => blk: {
                var dd = try collect_deps(dir, try u.concat(&[_][]const u8{moddir, "/zig.mod"})) catch |e| switch (e) {
                    error.FileNotFound => {
                        if (d.c_include_dirs.len > 0 or d.c_source_files.len > 0) {
                            var mod_from = try u.Module.from(d);
                            mod_from.id = try u.random_string(48);
                            mod_from.clean_path = u.trim_prefix(moddir, dir)[1..];
                            if (mod_from.is_for_this()) try moduledeps.append(mod_from);
                        }
                        break :blk;
                    },
                    else => e,
                };
                dd.clean_path = u.trim_prefix(moddir, dir)[1..];

                if (dd.id.len == 0) dd.id = try u.random_string(48);
                if (d.name.len > 0) dd.name = d.name;
                if (d.main.len > 0) dd.main = d.main;
                if (d.c_include_dirs.len > 0) dd.c_include_dirs = d.c_include_dirs;
                if (d.c_source_flags.len > 0) dd.c_source_flags = d.c_source_flags;
                if (d.c_source_files.len > 0) dd.c_source_files = d.c_source_files;
                if (d.only_os.len > 0) dd.only_os = d.only_os;
                if (d.except_os.len > 0) dd.except_os = d.except_os;

                if (dd.is_for_this()) try moduledeps.append(dd);
            },
        }
    }
    return u.Module{
        .is_sys_lib = false,
        .id = m.id,
        .name = m.name,
        .main = m.main,
        .c_include_dirs = m.c_include_dirs,
        .c_source_flags = m.c_source_flags,
        .c_source_files = m.c_source_files,
        .deps = moduledeps.items,
        .clean_path = "",
        .only_os = &[_][]const u8{},
        .except_os = &[_][]const u8{},
    };
}
