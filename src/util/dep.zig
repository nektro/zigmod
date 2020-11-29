const std = @import("std");
const gpa = std.heap.c_allocator;

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
        p = u.trim_prefix(p, "https://");
        p = u.trim_prefix(p, "https://");
        p = u.trim_suffix(u8, p, ".git");
        p = try std.fmt.allocPrint(gpa, "{}{}{}", .{@tagName(self.type), "/", p});
        return p;
    }
};
