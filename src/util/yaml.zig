const std = @import("std");

const c = @cImport({
    @cInclude("yaml.h");
});
const u = @import("./index.zig");

//
//

const Array = [][]const u8;

pub const Document = struct {
    mapping: Mapping,
};

pub const Item = union(enum) {
    event: c.yaml_event_t,
    kv: Key,
    mapping: Mapping,
    sequence: []Item,
    document: Document,
    string: []const u8,

    pub fn format(self: Item, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) @TypeOf(writer).Error!void {
        try writer.writeAll("Item{");
        switch (self) {
            .event, .kv, .document => {
                unreachable;
            },
            .mapping => {
                try std.fmt.format(writer, "{}", .{self.mapping});
            },
            .sequence => {
                try writer.writeAll("[ ");
                for (self.sequence) |it| {
                    try std.fmt.format(writer, "{}, ", .{it});
                }
                try writer.writeAll("]");
            },
            .string => {
                try std.fmt.format(writer, "{s}", .{self.string});
            },
        }
        try writer.writeAll("}");
    }
};

pub const Key = struct {
    key: []const u8,
    value: Value,
};

pub const Value = union(enum) {
    string: []const u8,
    mapping: Mapping,
    sequence: []Item,

    pub fn format(self: Value, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) @TypeOf(writer).Error!void {
        try writer.writeAll("Value{");
        switch (self) {
            .string => {
                try std.fmt.format(writer, "{s}", .{self.string});
            },
            .mapping => {
                try std.fmt.format(writer, "{}", .{self.mapping});
            },
            .sequence => {
                try writer.writeAll("[ ");
                for (self.sequence) |it| {
                    try std.fmt.format(writer, "{}, ", .{it});
                }
                try writer.writeAll("]");
            },
        }
        try writer.writeAll("}");
    }
};

pub const Mapping = struct {
    items: []Key,

    pub fn get(self: Mapping, k: []const u8) ?Value {
        for (self.items) |item| {
            if (std.mem.eql(u8, item.key, k)) {
                return item.value;
            }
        }
        return null;
    }

    pub fn get_string(self: Mapping, k: []const u8) []const u8 {
        return if (self.get(k)) |v| v.string else "";
    }

    pub fn get_string_array(self: Mapping, alloc: *std.mem.Allocator, k: []const u8) ![][]const u8 {
        const list = &std.ArrayList([]const u8).init(alloc);
        defer list.deinit();
        if (self.get(k)) |val| {
            if (val == .sequence) {
                for (val.sequence) |item, i| {
                    if (item != .string) {
                        continue;
                    }
                    try list.append(item.string);
                }
            }
        }
        return list.toOwnedSlice();
    }

    pub fn format(self: Mapping, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) @TypeOf(writer).Error!void {
        try writer.writeAll("{ ");
        for (self.items) |it| {
            try std.fmt.format(writer, "{s}: ", .{it.key});
            try std.fmt.format(writer, "{}, ", .{it.value});
        }
        try writer.writeAll("}");
    }
};

//
//

pub fn parse(alloc: *std.mem.Allocator, input: []const u8) !Document {
    var parser: c.yaml_parser_t = undefined;
    _ = c.yaml_parser_initialize(&parser);

    const lines = try u.split(input, "\n");

    _ = c.yaml_parser_set_input_string(&parser, input.ptr, input.len);

    var all_events = std.ArrayList(Item).init(alloc);
    var event: c.yaml_event_t = undefined;
    while (true) {
        const p = c.yaml_parser_parse(&parser, &event);
        if (p == 0) {
            break;
        }

        const et = @enumToInt(event.type);
        try all_events.append(.{ .event = event });
        c.yaml_event_delete(&event);

        if (et == c.YAML_STREAM_END_EVENT) {
            break;
        }
    }

    c.yaml_parser_delete(&parser);

    var l: usize = all_events.items.len;
    while (true) {
        try condense_event_list(&all_events, lines);
        if (l == all_events.items.len) {
            break;
        }
        l = all_events.items.len;
    }

    u.assert(all_events.items.len == 1, "failure parsing zig.mod. please report an issue at https://github.com/nektro/zigmod/issues/new that contains the text of your zig.mod.", .{});
    return all_events.items[0].document;
}

fn get_event_string(event: c.yaml_event_t, lines: Array) []const u8 {
    const sm = event.start_mark;
    const em = event.end_mark;
    return lines[sm.line][sm.column..em.column];
}

fn condense_event_list(list: *std.ArrayList(Item), lines: Array) !void {
    var i: usize = 0;
    var new_list = std.ArrayList(Item).init(list.allocator);

    while (i < list.items.len) : (i += 1) {
        if (try condense_event_list_key(list.items, i, &new_list, lines)) |len| {
            i += len;
            continue;
        }
        if (try condense_event_list_mapping(list.items, i, &new_list, lines)) |len| {
            i += len;
            continue;
        }
        if (try condense_event_list_sequence(list.items, i, &new_list, lines)) |len| {
            i += len;
            continue;
        }
        if (try condense_event_list_document(list.items, i, &new_list, lines)) |len| {
            i += len;
            continue;
        }
        try new_list.append(list.items[i]);
    }

    list.deinit();
    list.* = new_list;
}

fn condense_event_list_key(from: []Item, at: usize, to: *std.ArrayList(Item), lines: Array) !?usize {
    if (at >= from.len - 1) {
        return null;
    }
    const t = from[at];
    const n = from[at + 1];

    if (!(t == .event and @enumToInt(t.event.type) == c.YAML_SCALAR_EVENT)) {
        return null;
    }
    if (n == .event and @enumToInt(n.event.type) == c.YAML_SCALAR_EVENT) {
        try to.append(Item{
            .kv = Key{
                .key = get_event_string(t.event, lines),
                .value = Value{ .string = get_event_string(n.event, lines) },
            },
        });
        return 0 + 2 - 1;
    }
    if (n == .sequence) {
        try to.append(Item{
            .kv = Key{
                .key = get_event_string(t.event, lines),
                .value = Value{ .sequence = n.sequence },
            },
        });
        return 0 + 2 - 1;
    }
    if (n == .mapping) {
        try to.append(Item{
            .kv = Key{
                .key = get_event_string(t.event, lines),
                .value = Value{ .mapping = n.mapping },
            },
        });
        return 0 + 2 - 1;
    }
    return null;
}

fn condense_event_list_mapping(from: []Item, at: usize, to: *std.ArrayList(Item), lines: Array) !?usize {
    if (!(from[at] == .event and @enumToInt(from[at].event.type) == c.YAML_MAPPING_START_EVENT)) {
        return null;
    }
    var i: usize = 1;
    while (true) : (i += 1) {
        const ele = from[at + i];
        if (ele == .event and @enumToInt(ele.event.type) == c.YAML_MAPPING_END_EVENT) {
            break;
        }
        if (ele == .event) {
            return null;
        }
    }

    const keys = &std.ArrayList(Key).init(to.allocator);
    for (from[at + 1 .. at + i]) |item| {
        switch (item) {
            .kv => {
                try keys.append(item.kv);
            },
            else => unreachable,
        }
    }

    try to.append(Item{
        .mapping = Mapping{ .items = keys.items },
    });
    return 0 + i;
}

fn condense_event_list_sequence(from: []Item, at: usize, to: *std.ArrayList(Item), lines: Array) !?usize {
    if (!(from[at] == .event and @enumToInt(from[at].event.type) == c.YAML_SEQUENCE_START_EVENT)) {
        return null;
    }
    var i: usize = 1;
    while (true) : (i += 1) {
        const ele = from[at + i];
        if (ele == .event) {
            if (@enumToInt(ele.event.type) == c.YAML_SEQUENCE_END_EVENT) {
                break;
            }
            if (@enumToInt(ele.event.type) == c.YAML_SCALAR_EVENT) {
                continue;
            }
            return null;
        }
    }

    const result = &std.ArrayList(Item).init(to.allocator);
    for (from[at + 1 .. at + i]) |item| {
        try result.append(switch (item) {
            .mapping => item,
            .event => Item{ .string = get_event_string(item.event, lines) },
            else => unreachable,
        });
    }
    try to.append(Item{
        .sequence = result.items,
    });
    return 0 + i;
}

fn condense_event_list_document(from: []Item, at: usize, to: *std.ArrayList(Item), lines: Array) !?usize {
    if (from.len < at + 4) {
        return null;
    }
    if (!(from[at] == .event and @enumToInt(from[at].event.type) == c.YAML_STREAM_START_EVENT)) {
        return null;
    }
    if (!(from[at + 1] == .event and @enumToInt(from[at + 1].event.type) == c.YAML_DOCUMENT_START_EVENT)) {
        return null;
    }
    if (!(from[at + 2] == .mapping)) {
        return null;
    }
    if (!(from[at + 3] == .event and @enumToInt(from[at + 3].event.type) == c.YAML_DOCUMENT_END_EVENT)) {
        return null;
    }
    if (!(from[at + 4] == .event and @enumToInt(from[at + 4].event.type) == c.YAML_STREAM_END_EVENT)) {
        return null;
    }
    try to.append(Item{
        .document = Document{
            .mapping = from[at + 2].mapping,
        },
    });
    return 0 + 5 - 1;
}
