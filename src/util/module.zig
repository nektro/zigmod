const std = @import("std");
const string = []const u8;
const builtin = @import("builtin");
const yaml = @import("yaml");
const extras = @import("extras");

const zigmod = @import("../lib.zig");
const u = @import("funcs.zig");
const common = @import("./../common.zig");

//
//

pub const Module = struct {
    type: zigmod.Dep.Type,
    id: [48]u8,
    name: string,
    main: string,
    c_include_dirs: []const string = &.{},
    c_source_flags: []const string = &.{},
    c_source_files: []const string = &.{},
    only_os: []const string = &.{},
    except_os: []const string = &.{},
    yaml: ?yaml.Mapping,
    deps: []Module,
    clean_path: string,
    dep: ?zigmod.Dep,
    for_build: bool = false,
    min_zig_version: ?std.SemanticVersion,

    pub const ROOT: [48]u8 = ("root" ++ (" " ** 44)).*;

    pub fn from(alloc: std.mem.Allocator, dep: zigmod.Dep, cachepath: string, options: *common.CollectOptions) !Module {
        var moddeps = std.ArrayList(Module).init(alloc);
        errdefer moddeps.deinit();

        for (dep.deps) |*d| {
            if (try common.get_module_from_dep(d, cachepath, options)) |founddep| {
                try moddeps.append(founddep);
            }
        }

        var id = dep.id;
        if (std.mem.eql(u8, &id, &zigmod.Dep.EMPTY)) id = u.random_string(48);

        return Module{
            .type = dep.type,
            .id = id,
            .name = dep.name,
            .main = dep.main,
            .c_include_dirs = dep.c_include_dirs,
            .c_source_flags = dep.c_source_flags,
            .c_source_files = dep.c_source_files,
            .deps = try moddeps.toOwnedSlice(),
            .clean_path = try dep.clean_path(alloc),
            .only_os = dep.only_os,
            .except_os = dep.except_os,
            .yaml = dep.yaml,
            .dep = dep,
            .for_build = dep.for_build,
            .min_zig_version = null,
        };
    }

    pub fn eql(self: Module, another: Module) bool {
        return std.mem.eql(u8, &self.id, &another.id);
    }

    pub fn get_hash(self: Module, alloc: std.mem.Allocator, cdpath: string) !string {
        const file_list_1 = try u.file_list(alloc, try std.mem.concat(alloc, u8, &.{ cdpath, "/", self.clean_path }));

        var file_list_2 = std.ArrayList(string).init(alloc);
        errdefer file_list_2.deinit();
        for (file_list_1) |item| {
            const _a = extras.trimPrefix(item, cdpath);
            const _b = extras.trimPrefix(_a, self.clean_path);
            if (_b[0] == '.') continue;
            try file_list_2.append(_b);
        }

        std.mem.sort(string, file_list_2.items, void{}, struct {
            pub fn lt(context: void, lhs: string, rhs: string) bool {
                _ = context;
                return std.mem.lessThan(u8, lhs, rhs);
            }
        }.lt);

        var h = std.crypto.hash.Blake3.init(.{});
        for (file_list_2.items) |item| {
            const abs_path = try std.fs.path.join(alloc, &.{ cdpath, self.clean_path, item });
            const file = try std.fs.cwd().openFile(abs_path, .{});
            defer file.close();
            const input = try file.reader().readAllAlloc(alloc, u.mb * 100);
            h.update(input);
        }
        var out: [32]u8 = undefined;
        h.final(&out);
        const hex = try std.fmt.allocPrint(alloc, "blake3-{x}", .{std.fmt.fmtSliceHexLower(out[0..])});
        return hex;
    }

    pub fn is_for_this(self: Module) bool {
        const os = @tagName(builtin.os.tag);
        if (self.only_os.len > 0) {
            return extras.containsString(self.only_os, os);
        }
        if (self.except_os.len > 0) {
            return !extras.containsString(self.except_os, os);
        }
        return true;
    }

    pub fn has_no_zig_deps(self: Module) bool {
        for (self.deps) |d| {
            if (d.main.len > 0) {
                return false;
            }
        }
        return true;
    }

    pub fn has_syslib_deps(self: Module) bool {
        for (self.deps) |d| {
            if (d.type == .system_lib) {
                return true;
            }
        }
        return false;
    }

    pub fn has_framework_deps(self: Module) bool {
        for (self.deps) |d| {
            if (d.type == .framework) {
                return true;
            }
        }
        return false;
    }

    pub fn short_id(self: *const Module) string {
        return u.slice(u8, &self.id, 0, @min(12, std.mem.indexOfScalar(u8, &self.id, ' ') orelse self.id.len));
    }

    pub fn minZigVersion(self: Module) ?std.SemanticVersion {
        var res = self.min_zig_version;

        for (self.deps) |dm| {
            if (dm.minZigVersion()) |sv| {
                if (res == null or sv.order(res.?).compare(.gt)) {
                    res = sv;
                }
            }
        }
        return res;
    }

    pub fn lessThan(_: void, lhs: Module, rhs: Module) bool {
        for (lhs.clean_path, 0..) |_, i| {
            if (i == rhs.clean_path.len) return false;
            if (lhs.clean_path[i] < rhs.clean_path[i]) return true;
            if (lhs.clean_path[i] > rhs.clean_path[i]) return false;
        }
        return false;
    }

    pub fn pin(self: Module, alloc: std.mem.Allocator, cachepath: string) !string {
        return switch (self.type) {
            .local => "",
            .system_lib => "",
            .framework => "",
            else => |sub| {
                var cdir = try std.fs.cwd().openDir(cachepath, .{});
                defer cdir.close();
                var mdir = try cdir.openDir(self.clean_path, .{});
                defer mdir.close();
                return switch (sub) {
                    .local, .system_lib, .framework => unreachable,
                    .git => try u.git_rev_HEAD(alloc, mdir),
                    .hg => @panic("TODO"),
                    .http => @panic("TODO"),
                };
            },
        };
    }
};
