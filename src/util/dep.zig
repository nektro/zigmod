const std = @import("std");
const string = []const u8;
const builtin = @import("builtin");

const zigmod = @import("../lib.zig");
const u = @import("index.zig");
const yaml = @import("./yaml.zig");

//
//

pub const Dep = struct {
    const Self = @This();

    alloc: std.mem.Allocator,
    type: zigmod.DepType,
    path: string,
    id: string,
    name: string,
    main: string,
    version: string,
    c_include_dirs: []const string = &.{},
    c_source_flags: []const string = &.{},
    c_source_files: []const string = &.{},
    only_os: []const string = &.{},
    except_os: []const string = &.{},
    yaml: ?yaml.Mapping,
    deps: []zigmod.Dep,
    keep: bool = false,
    vcpkg: bool = false,
    for_build: bool = false,

    pub fn clean_path(self: Dep) !string {
        if (self.type == .local) {
            return if (self.path.len == 0) "../.." else self.path;
        }
        var p = self.path;
        p = u.trim_prefix(p, "http://");
        p = u.trim_prefix(p, "https://");
        p = u.trim_prefix(p, "git://");
        p = u.trim_suffix(p, ".git");
        p = try std.mem.join(self.alloc, "/", &.{ @tagName(self.type), p });
        return p;
    }

    pub fn clean_path_v(self: Dep) !string {
        if (self.type == .http and self.version.len > 0) {
            const i = std.mem.indexOf(u8, self.version, "-").?;
            return std.mem.join(self.alloc, "/", &.{ "v", try self.clean_path(), self.version[i + 1 .. 15] });
        }
        return std.mem.join(self.alloc, "/", &.{ "v", try self.clean_path(), self.version });
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

    pub fn exact_version(self: Dep, dpath: string) !string {
        if (self.version.len == 0) {
            return try self.type.exact_version(self.alloc, dpath);
        }
        return switch (self.type) {
            .git => blk: {
                const vers = try u.parse_split(zigmod.DepType.GitVersion, "-").do(self.version);
                if (vers.id.frozen()) break :blk self.version;
                break :blk try self.type.exact_version(self.alloc, dpath);
            },
            else => self.version,
        };
    }
};
