const std = @import("std");

const u = @import("index.zig");

//
//

pub const Module = struct {
    name: []const u8,
    main: []const u8,
    c_include_dirs: [][]const u8,
    c_source_flags: [][]const u8,
    c_source_files: [][]const u8,

    deps: []Module,
    clean_path: []const u8,

    pub fn from(dep: u.Dep) !Module {
        return Module{
            .name = dep.name,
            .main = dep.main,
            .c_include_dirs = dep.c_include_dirs,
            .c_source_flags = dep.c_source_flags,
            .c_source_files = dep.c_source_files,
            .deps = &[_]Module{},
            .clean_path = try dep.clean_path(),
        };
    }
};
