const std = @import("std");
const gpa = std.heap.c_allocator;

const u = @import("./../../util/index.zig");
const aq = @import("./../aq.zig");

//
//

pub fn execute(args: [][]u8) !void {
    const pkg_id_v = args[0];

    const url = try std.mem.join(gpa, "/", &.{ aq.server_root, pkg_id_v });
    const val = try aq.server_fetch(url);

    const v = val.get("vers").?;
    const maj = v.get("real_major").?.Int;
    const min = v.get("real_minor").?.Int;
    const hash = v.get("tar_hash").?.String;

    std.debug.print("  - src: http {s}/{s}.tar.gz _ {d} {d}\n", .{ aq.server_root, pkg_id_v, maj, min });
    std.debug.print("    version: {s}\n", .{hash});
}
