const std = @import("std");
const string = []const u8;
const builtin = @import("builtin");

const zigmod = @import("../lib.zig");
const u = @import("index.zig");
const yaml = @import("./yaml.zig");
const common = @import("./../common.zig");

//
//

pub const Module = struct {
    alloc: std.mem.Allocator,
    is_sys_lib: bool,
    is_framework: bool,
    id: string,
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
    vcpkg: bool,

    pub fn from(alloc: std.mem.Allocator, dep: zigmod.Dep, modpath: string, options: *common.CollectOptions) !Module {
        var moddeps = std.ArrayList(Module).init(alloc);
        defer moddeps.deinit();

        for (dep.deps) |*d| {
            if (try common.get_module_from_dep(d, modpath, options)) |founddep| {
                try moddeps.append(founddep);
            }
        }
        return Module{
            .alloc = alloc,
            .is_sys_lib = false,
            .is_framework = false,
            .id = if (dep.id.len > 0) dep.id else try u.random_string(alloc, 48),
            .name = dep.name,
            .main = dep.main,
            .c_include_dirs = dep.c_include_dirs,
            .c_source_flags = dep.c_source_flags,
            .c_source_files = dep.c_source_files,
            .deps = moddeps.toOwnedSlice(),
            .clean_path = try dep.clean_path(),
            .only_os = dep.only_os,
            .except_os = dep.except_os,
            .yaml = dep.yaml,
            .dep = dep,
            .for_build = dep.for_build,
            .min_zig_version = null,
            .vcpkg = dep.vcpkg,
        };
    }

    pub fn eql(self: Module, another: Module) bool {
        return std.mem.eql(u8, self.id, another.id);
    }

    pub fn get_hash(self: Module, cdpath: string) !string {
        const file_list_1 = try u.file_list(self.alloc, try std.mem.concat(self.alloc, u8, &.{ cdpath, "/", self.clean_path }));

        var file_list_2 = std.ArrayList(string).init(self.alloc);
        defer file_list_2.deinit();
        for (file_list_1) |item| {
            const _a = u.trim_prefix(item, cdpath);
            const _b = u.trim_prefix(_a, self.clean_path);
            if (_b[0] == '.') continue;
            try file_list_2.append(_b);
        }

        std.sort.sort(string, file_list_2.items, void{}, struct {
            pub fn lt(context: void, lhs: string, rhs: string) bool {
                _ = context;
                return std.mem.lessThan(u8, lhs, rhs);
            }
        }.lt);

        const h = &std.crypto.hash.Blake3.init(.{});
        for (file_list_2.items) |item| {
            const abs_path = try std.fs.path.join(self.alloc, &.{ cdpath, self.clean_path, item });
            const file = try std.fs.cwd().openFile(abs_path, .{});
            defer file.close();
            const input = try file.reader().readAllAlloc(self.alloc, u.mb * 100);
            h.update(input);
        }
        var out: [32]u8 = undefined;
        h.final(&out);
        const hex = try std.fmt.allocPrint(self.alloc, "blake3-{x}", .{std.fmt.fmtSliceHexLower(out[0..])});
        return hex;
    }

    pub fn is_for_this(self: Module) bool {
        const os = @tagName(builtin.os.tag);
        if (self.only_os.len > 0) {
            return u.list_contains(self.only_os, os);
        }
        if (self.except_os.len > 0) {
            return !u.list_contains(self.except_os, os);
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
            if (d.is_sys_lib) {
                return true;
            }
        }
        return false;
    }

    pub fn has_framework_deps(self: Module) bool {
        for (self.deps) |d| {
            if (d.is_framework) {
                return true;
            }
        }
        return false;
    }

    pub fn short_id(self: Module) string {
        return u.slice(u8, self.id, 0, 12);
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
};
