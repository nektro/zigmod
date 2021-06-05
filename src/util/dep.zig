const std = @import("std");
const gpa = std.heap.c_allocator;
const builtin = std.builtin;

const u = @import("index.zig");
const yaml = @import("./yaml.zig");

//
//

pub const Dep = struct {
    const Self = @This();

    type: u.DepType,
    path: []const u8,

    id: []const u8,
    name: []const u8,
    main: []const u8,
    version: []const u8,
    c_include_dirs: [][]const u8,
    c_source_flags: [][]const u8,
    c_source_files: [][]const u8,
    only_os: [][]const u8,
    except_os: [][]const u8,
    yaml: ?yaml.Mapping,

    pub fn clean_path(self: Dep) ![]const u8 {
        var p = self.path;
        p = u.trim_prefix(p, "http://");
        p = u.trim_prefix(p, "https://");
        p = u.trim_prefix(p, "git://");
        p = u.trim_suffix(u8, p, ".git");
        p = try std.mem.join(gpa, "/", &.{ @tagName(self.type), p });
        return p;
    }

    pub fn clean_path_v(self: Dep) ![]const u8 {
        if (self.type == .http and self.version.len > 0) {
            const i = std.mem.indexOf(u8, self.version, "-").?;
            return std.mem.join(gpa, "/", &.{ "v", try self.clean_path(), self.version[i + 1 .. 15] });
        }
        return std.mem.join(gpa, "/", &.{ "v", try self.clean_path(), self.version });
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
