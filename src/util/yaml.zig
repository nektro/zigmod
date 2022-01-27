const std = @import("std");
const string = []const u8;

const c = @cImport({
    @cInclude("yaml.h");
});
const u = @import("./index.zig");

//
//

pub const Stream = struct {
    docs: []const Document,
};

pub const Document = struct {
    mapping: Mapping,
};

pub const Item = union(enum) {
    event: Token,
    kv: Key,
    mapping: Mapping,
    sequence: Sequence,
    document: Document,
    string: string,
    stream: Stream,

    pub fn format(self: Item, comptime fmt: string, options: std.fmt.FormatOptions, writer: anytype) @TypeOf(writer).Error!void {
        _ = fmt;
        _ = options;

        try writer.writeAll("Item{");
        switch (self) {
            .event => {
                // try std.fmt.format(writer, "{s}", .{@tagName(self.event.type)});
                try std.fmt.format(writer, "event {d}", .{self.event});
            },
            .kv, .document, .stream => {
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

pub const Sequence = []const Item;

pub const Key = struct {
    key: string,
    value: Value,
};

pub const Value = union(enum) {
    string: string,
    mapping: Mapping,
    sequence: Sequence,

    pub fn format(self: Value, comptime fmt: string, options: std.fmt.FormatOptions, writer: anytype) @TypeOf(writer).Error!void {
        _ = fmt;
        _ = options;

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
    items: []const Key,

    pub fn get(self: Mapping, k: string) ?Value {
        for (self.items) |item| {
            if (std.mem.eql(u8, item.key, k)) {
                return item.value;
            }
        }
        return null;
    }

    pub fn get_string(self: Mapping, k: string) string {
        return if (self.get(k)) |v| v.string else "";
    }

    pub fn get_string_array(self: Mapping, alloc: std.mem.Allocator, k: string) ![]string {
        var list = std.ArrayList(string).init(alloc);
        defer list.deinit();
        if (self.get(k)) |val| {
            if (val == .sequence) {
                for (val.sequence) |item| {
                    if (item != .string) {
                        continue;
                    }
                    try list.append(item.string);
                }
            }
        }
        return list.toOwnedSlice();
    }

    pub fn format(self: Mapping, comptime fmt: string, options: std.fmt.FormatOptions, writer: anytype) @TypeOf(writer).Error!void {
        _ = fmt;
        _ = options;

        try writer.writeAll("{ ");
        for (self.items) |it| {
            try std.fmt.format(writer, "{s}: ", .{it.key});
            try std.fmt.format(writer, "{}, ", .{it.value});
        }
        try writer.writeAll("}");
    }
};

pub const Token = c.yaml_event_t;
pub const TokenList = []const Token;

//
//

pub fn parse(alloc: std.mem.Allocator, input: string) !Document {
    var parser: c.yaml_parser_t = undefined;
    _ = c.yaml_parser_initialize(&parser);
    defer c.yaml_parser_delete(&parser);

    const lines = try u.split(alloc, input, "\n");

    _ = c.yaml_parser_set_input_string(&parser, input.ptr, input.len);

    var all_events = std.ArrayList(Token).init(alloc);
    var event: Token = undefined;
    while (true) {
        const p = c.yaml_parser_parse(&parser, &event);
        if (p == 0) {
            break;
        }

        const et = event.type;
        try all_events.append(event);
        c.yaml_event_delete(&event);

        if (et == c.YAML_STREAM_END_EVENT) {
            break;
        }
    }

    const p = &Parser{
        .alloc = alloc,
        .tokens = all_events.items,
        .lines = lines,
        .index = 0,
    };
    const stream = try p.parse();
    return stream.docs[0];
}

pub const Parser = struct {
    alloc: std.mem.Allocator,
    tokens: TokenList,
    lines: []const string,
    index: usize,

    pub fn parse(self: *Parser) !Stream {
        const item = try parse_item(self, null);
        return item.stream;
    }

    fn next(self: *Parser) ?Token {
        if (self.index >= self.tokens.len) {
            return null;
        }
        defer self.index += 1;
        return self.tokens[self.index];
    }
};

pub const Error =
    std.mem.Allocator.Error ||
    error{YamlUnexpectedToken};

fn parse_item(p: *Parser, start: ?Token) Error!Item {
    const tok = start orelse p.next();
    return switch (tok.?.type) {
        c.YAML_STREAM_START_EVENT => Item{ .stream = try parse_stream(p) },
        c.YAML_DOCUMENT_START_EVENT => Item{ .document = try parse_document(p) },
        c.YAML_MAPPING_START_EVENT => Item{ .mapping = try parse_mapping(p) },
        c.YAML_SEQUENCE_START_EVENT => Item{ .sequence = try parse_sequence(p) },
        c.YAML_SCALAR_EVENT => Item{ .string = get_event_string(tok.?, p.lines) },
        else => unreachable,
    };
}

fn parse_stream(p: *Parser) Error!Stream {
    var res = std.ArrayList(Document).init(p.alloc);
    defer res.deinit();

    while (true) {
        const tok = p.next();
        if (tok.?.type == c.YAML_STREAM_END_EVENT) {
            return Stream{ .docs = res.toOwnedSlice() };
        }
        if (tok.?.type != c.YAML_DOCUMENT_START_EVENT) {
            return error.YamlUnexpectedToken;
        }
        const item = try parse_item(p, tok);
        try res.append(item.document);
    }
}

fn parse_document(p: *Parser) Error!Document {
    const tok = p.next();
    if (tok.?.type != c.YAML_MAPPING_START_EVENT) {
        return error.YamlUnexpectedToken;
    }
    const item = try parse_item(p, tok);

    if (p.next().?.type != c.YAML_DOCUMENT_END_EVENT) {
        return error.YamlUnexpectedToken;
    }
    return Document{ .mapping = item.mapping };
}

fn parse_mapping(p: *Parser) Error!Mapping {
    var res = std.ArrayList(Key).init(p.alloc);
    defer res.deinit();

    while (true) {
        const tok = p.next();
        if (tok.?.type == c.YAML_MAPPING_END_EVENT) {
            return Mapping{ .items = res.toOwnedSlice() };
        }
        if (tok.?.type != c.YAML_SCALAR_EVENT) {
            return error.YamlUnexpectedToken;
        }
        try res.append(Key{
            .key = get_event_string(tok.?, p.lines),
            .value = try parse_value(p),
        });
    }
}

fn parse_value(p: *Parser) Error!Value {
    const item = try parse_item(p, null);
    return switch (item) {
        .mapping => |x| Value{ .mapping = x },
        .sequence => |x| Value{ .sequence = x },
        .string => |x| Value{ .string = x },
        else => unreachable,
    };
}

fn parse_sequence(p: *Parser) Error!Sequence {
    var res = std.ArrayList(Item).init(p.alloc);
    defer res.deinit();

    while (true) {
        const tok = p.next();
        if (tok.?.type == c.YAML_SEQUENCE_END_EVENT) {
            return res.toOwnedSlice();
        }
        try res.append(try parse_item(p, tok));
    }
}

fn get_event_string(event: Token, lines: []const string) string {
    const sm = event.start_mark;
    const em = event.end_mark;
    return lines[sm.line][sm.column..em.column];
}
