const std = @import("std");
const string = []const u8;
const builtin = @import("builtin");
const yaml = @import("yaml");
const extras = @import("extras");

const zigmod = @import("../lib.zig");
const u = @import("index.zig");

//
//

pub const Dep = struct {
    const Self = @This();

    type: Type,
    path: string,
    id: [48]u8,
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
    for_build: bool = false,

    pub const EMPTY = (" " ** 48).*;

    pub const Type = @import("./dep_type.zig").DepType;

    pub fn clean_path(self: Dep, alloc: std.mem.Allocator) !string {
        if (self.type == .local) {
            return self.path;
        }
        var p = self.path;
        p = extras.trimPrefix(p, "http://");
        p = extras.trimPrefix(p, "https://");
        p = extras.trimPrefix(p, "git://");
        p = extras.trimSuffix(p, ".git");
        p = try std.mem.join(alloc, "/", &.{ @tagName(self.type), p });
        return p;
    }

    pub fn clean_path_v(self: Dep, alloc: std.mem.Allocator) !string {
        if (self.type == .http and self.version.len > 0) {
            const i = std.mem.indexOf(u8, self.version, "-").?;
            return std.mem.join(alloc, "/", &.{ "v", try self.clean_path(alloc), self.version[i + 1 .. 15] });
        }
        return std.mem.join(alloc, "/", &.{ "v", try self.clean_path(alloc), self.version });
    }

    pub fn is_for_this(self: Dep) bool {
        const os = @tagName(builtin.os.tag);
        if (self.only_os.len > 0) {
            return extras.containsString(self.only_os, os);
        }
        if (self.except_os.len > 0) {
            return !extras.containsString(self.except_os, os);
        }
        return true;
    }

    pub fn exact_version(self: Dep, alloc: std.mem.Allocator, dpath: string) !string {
        if (self.version.len == 0) {
            return try self.type.exact_version(alloc, dpath);
        }
        return switch (self.type) {
            .git => blk: {
                const vers = try u.parse_split(zigmod.Dep.Type.Version.Git, "-").do(self.version);
                if (vers.id.frozen()) break :blk self.version;
                break :blk try self.type.exact_version(alloc, dpath);
            },
            else => self.version,
        };
    }
};
