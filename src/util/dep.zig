const std = @import("std");
const gpa = std.heap.c_allocator;
const builtin = @import("builtin");

const u = @import("index.zig");

//
//

pub const Dep = struct {
    const Self = @This();

    type: u.DepType,
    path: []const u8,

    name: []const u8,
    main: []const u8,
    version: []const u8,
    c_include_dirs: [][]const u8,
    c_source_flags: [][]const u8,
    c_source_files: [][]const u8,
    only_os: [][]const u8,
    except_os: [][]const u8,

    pub fn clean_path(self: Dep) ![]const u8 {
        var p = self.path;
        p = u.trim_prefix(p, "http://");
        p = u.trim_prefix(p, "https://");
        p = u.trim_prefix(p, "git://");
        p = u.trim_suffix(u8, p, ".git");
        p = try std.fs.path.join(gpa, &[_][]const u8{@tagName(self.type), p});
        return p;
    }

    pub fn is_for_this(self: Dep) bool {
        const os = @tagName(builtin.os.tag);
        if (self.only_os.len > 0) {
            return u.list_contains(self.only_os, os);
        }
        if (self.except_os.len > 0) {
            return !u.list_contains(self.except_os, os);
        }
        return true;
    }
};
