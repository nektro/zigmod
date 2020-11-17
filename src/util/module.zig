const std = @import("std");

//
//

pub const Module = struct {
    name: []const u8,
    main: []const u8,
    c_include_dirs: [][]const u8,
    c_source_files: [][]const u8,

    deps: []Module,
    clean_path: []const u8,
};
