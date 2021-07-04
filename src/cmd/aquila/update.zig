const std = @import("std");
const gpa = std.heap.c_allocator;

const u = @import("./../../util/index.zig");
const aq = @import("./../aq.zig");

//
//

pub fn execute(args: [][]u8) !void {
    _ = args;

    const mod = try u.ModFile.init(gpa, "zig.mod");

    for (mod.deps) |d| {
        try check_dep(d);
    }
    for (mod.devdeps) |d| {
        try check_dep(d);
    }
}

fn check_dep(dep: u.Dep) !void {
    if (dep.type != .http) {
        return;
    }
    if (!std.mem.startsWith(u8, dep.path, aq.server_root)) {
        return;
    }
    var pkg_id_v = std.mem.split(url_to_pkgid(dep.path), "/");
    const host = pkg_id_v.next().?;
    const user = pkg_id_v.next().?;
    const pkg = pkg_id_v.next().?;
    const vers = try vers_get_pieces(pkg_id_v.next().?);

    const url = try std.mem.join(gpa, "/", &.{ aq.server_root, host, user, pkg });
    const val = try aq.server_fetch(url);

    const versions = val.get("versions").?.Array;
    const latest = versions[versions.len - 1];

    const rmaj = latest.get("real_major").?.Number;
    const rmin = latest.get("real_minor").?.Number;

    if (rmaj == vers[0] and rmin == vers[1]) {
        return;
    }

    std.log.info("found new version: {s}/{s}/{s}/v{d}.{d}", .{ host, user, pkg, rmaj, rmin });
}

fn url_to_pkgid(url: []const u8) []const u8 {
    var res = url;
    res = std.mem.trimLeft(u8, res, aq.server_root);
    res = std.mem.trimRight(u8, res, ".tar.gz");
    return res;
}

fn vers_get_pieces(v: []const u8) ![2]f64 {
    var it = std.mem.split(v[1..], ".");
    const maj = it.next().?;
    const min = it.next().?;
    return [_]f64{
        try std.fmt.parseFloat(f64, maj),
        try std.fmt.parseFloat(f64, min),
    };
}
