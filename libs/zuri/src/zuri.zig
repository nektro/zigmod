const std = @import("std");
const mem = std.mem;
const Allocator = std.mem.Allocator;
const assert = std.debug.assert;
const parseUnsigned = std.fmt.parseUnsigned;
const net = std.net;
const expect = std.testing.expect;

const ValueMap = std.StringHashMap([]const u8);

pub const Uri = struct {
    scheme: []const u8,
    username: []const u8,
    password: []const u8,
    host: Host,
    port: ?u16,
    path: []const u8,
    query: []const u8,
    fragment: []const u8,
    len: usize,

    /// possible uri host values
    pub const Host = union(enum) {
        ip: net.Address,
        name: []const u8,
    };

    /// possible errors for mapQuery
    pub const MapError = error{
        NoQuery,
        OutOfMemory,
    };

    /// map query string into a hashmap of key value pairs with no value being an empty string
    pub fn mapQuery(allocator: *Allocator, query: []const u8) MapError!ValueMap {
        if (query.len == 0) {
            return error.NoQuery;
        }
        var map = ValueMap.init(allocator);
        errdefer map.deinit();
        var start: u32 = 0;
        var mid: u32 = 0;
        for (query) |c, i| {
            if (c == ';' or c == '&') {
                if (mid != 0) {
                    _ = try map.put(query[start..mid], query[mid + 1 .. i]);
                } else {
                    _ = try map.put(query[start..i], "");
                }
                start = @truncate(u32, i + 1);
                mid = 0;
            } else if (c == '=') {
                mid = @truncate(u32, i);
            }
        }
        if (mid != 0) {
            _ = try map.put(query[start..mid], query[mid + 1 ..]);
        } else {
            _ = try map.put(query[start..], "");
        }

        return map;
    }

    /// possible errors for decode and encode
    pub const EncodeError = error{
        InvalidCharacter,
        OutOfMemory,
    };

    /// decode path if it is percent encoded
    pub fn decode(allocator: *Allocator, path: []const u8) EncodeError!?[]u8 {
        var ret: ?[]u8 = null;
        var ret_index: usize = 0;
        var i: usize = 0;

        while (i < path.len) : (i += 1) {
            if (path[i] == '%') {
                if (!isPchar(path[i..])) {
                    return error.InvalidCharacter;
                }
                if (ret == null) {
                    ret = try allocator.alloc(u8, path.len);
                    mem.copy(u8, ret.?, path[0..i]);
                    ret_index = i;
                }

                // charToDigit can't fail because the chars are validated earlier
                var new = (std.fmt.charToDigit(path[i + 1], 16) catch unreachable) << 4;
                new |= std.fmt.charToDigit(path[i + 2], 16) catch unreachable;
                ret.?[ret_index] = new;
                ret_index += 1;
                i += 2;
            } else if (path[i] != '/' and !isPchar(path[i..])) {
                return error.InvalidCharacter;
            } else if (ret != null) {
                ret.?[ret_index] = path[i];
                ret_index += 1;
            }
        }
        if (ret != null) {
            return allocator.realloc(ret.?, ret_index) catch ret.?[0..ret_index];
        }
        return ret;
    }

    /// percent encode if path contains characters not allowed in paths
    pub fn encode(allocator: *Allocator, path: []const u8) EncodeError!?[]u8 {
        var ret: ?[]u8 = null;
        var ret_index: usize = 0;
        for (path) |c, i| {
            if (c != '/' and !isPchar(path[i..])) {
                if (ret == null) {
                    ret = try allocator.alloc(u8, path.len * 3);
                    mem.copy(u8, ret.?, path[0..i]);
                    ret_index = i;
                }
                const hex_digits = "0123456789ABCDEF";
                ret.?[ret_index] = '%';
                ret.?[ret_index + 1] = hex_digits[(c & 0xF0) >> 4];
                ret.?[ret_index + 2] = hex_digits[c & 0x0F];
                ret_index += 3;
            } else if (ret != null) {
                ret.?[ret_index] = c;
                ret_index += 1;
            }
        }
        if (ret != null) {
            return allocator.realloc(ret.?, ret_index) catch ret.?[0..ret_index];
        }
        return ret;
    }

    /// resolves `path`, leaves trailing '/'
    /// assumes `path` to be valid
    pub fn resolvePath(allocator: *Allocator, path: []const u8) error{OutOfMemory}![]u8 {
        assert(path.len > 0);
        var list = std.ArrayList([]const u8).init(allocator);
        errdefer list.deinit();

        var it = mem.tokenize(path, "/");
        while (it.next()) |p| {
            if (mem.eql(u8, p, ".")) {
                continue;
            } else if (mem.eql(u8, p, "..")) {
                _ = list.popOrNull();
            } else {
                try list.append(p);
            }
        }

        var buf = try allocator.alloc(u8, path.len);
        errdefer allocator.free(buf);
        var len: usize = 0;
        var segments = list.toOwnedSlice();
        defer allocator.free(segments);

        for (segments) |s| {
            buf[len] = '/';
            len += 1;
            mem.copy(u8, buf[len..], s);
            len += s.len;
        }

        if (path[path.len - 1] == '/') {
            buf[len] = '/';
            len += 1;
        }

        return allocator.realloc(buf, len) catch buf[0..len];
    }

    /// possible errors for parse
    pub const Error = error{
        /// input is not a valid uri due to a invalid character
        /// mostly a result of invalid ipv6
        InvalidCharacter,

        /// given input was empty
        EmptyUri,
    };

    /// parse URI from input
    /// empty input is an error
    /// if assume_auth is true then `example.com` will result in `example.com` being the host instead of path
    pub fn parse(input: []const u8, assume_auth: bool) Error!Uri {
        if (input.len == 0) {
            return error.EmptyUri;
        }
        var uri = Uri{
            .scheme = "",
            .username = "",
            .password = "",
            .host = .{ .name = "" },
            .port = null,
            .path = "",
            .query = "",
            .fragment = "",
            .len = 0,
        };

        switch (input[0]) {
            'a'...'z', 'A'...'Z' => {
                uri.parseMaybeScheme(input);
            },
            else => {},
        }

        if (input.len > uri.len + 2 and input[uri.len] == '/' and input[uri.len + 1] == '/') {
            uri.len += 2; // for the '//'
            try uri.parseAuth(input[uri.len..]);
        } else if (assume_auth) {
            try uri.parseAuth(input[uri.len..]);
        }

        // make host ip4 address if possible
        if (uri.host == .name and uri.host.name.len > 0) blk: {
            var a = net.Address.parseIp4(uri.host.name, 0) catch break :blk;
            uri.host = .{ .ip = a }; // workaround for https://github.com/ziglang/zig/issues/3234
        }

        if (uri.host == .ip and uri.port != null) {
            uri.host.ip.setPort(uri.port.?);
        }

        uri.parsePath(input[uri.len..]);

        if (input.len > uri.len + 1 and input[uri.len] == '?') {
            uri.parseQuery(input[uri.len + 1 ..]);
        }

        if (input.len > uri.len + 1 and input[uri.len] == '#') {
            uri.parseFragment(input[uri.len + 1 ..]);
        }
        return uri;
    }

    fn parseMaybeScheme(u: *Uri, input: []const u8) void {
        for (input) |c, i| {
            switch (c) {
                'a'...'z', 'A'...'Z', '0'...'9', '+', '-', '.' => {
                    // allowed characters
                },
                ':' => {
                    u.scheme = input[0..i];
                    u.len += u.scheme.len + 1; // +1 for the ':'
                    return;
                },
                else => {
                    // not a valid scheme
                    return;
                },
            }
        }
        return;
    }

    fn parseAuth(u: *Uri, input: []const u8) Error!void {
        for (input) |c, i| {
            switch (c) {
                '@' => {
                    u.username = input[0..i];
                    u.len += i + 1; // +1 for the '@'
                    return u.parseHost(input[i + 1 ..]);
                },
                '[' => {
                    if (i != 0)
                        return error.InvalidCharacter;
                    return u.parseIP(input);
                },
                ':' => {
                    u.host.name = input[0..i];
                    u.len += i + 1; // +1 for the '@'
                    return u.parseAuthColon(input[i + 1 ..]);
                },
                '/', '?', '#' => {
                    u.host.name = input[0..i];
                    u.len += i;
                    return;
                },
                else => if (!isPchar(input)) {
                    u.host.name = input[0..i];
                    u.len += input.len;
                    return;
                },
            }
        }
        u.host.name = input;
        u.len += input.len;
    }

    fn parseAuthColon(u: *Uri, input: []const u8) Error!void {
        for (input) |c, i| {
            if (c == '@') {
                u.username = u.host.name;
                u.password = input[0..i];
                u.len += i + 1; //1 for the '@'
                return u.parseHost(input[i + 1 ..]);
            } else if (c == '/' or c == '?' or c == '#' or !isPchar(input)) {
                u.port = parseUnsigned(u16, input[0..i], 10) catch return error.InvalidCharacter;
                u.len += i;
                return;
            }
        }
        u.port = parseUnsigned(u16, input, 10) catch return error.InvalidCharacter;
        u.len += input.len;
    }

    fn parseHost(u: *Uri, input: []const u8) Error!void {
        for (input) |c, i| {
            switch (c) {
                ':' => {
                    u.host.name = input[0..i];
                    u.len += i + 1; // +1 for the ':'
                    return u.parsePort(input[i..]);
                },
                '[' => {
                    if (i != 0)
                        return error.InvalidCharacter;
                    return u.parseIP(input);
                },
                else => if (c == '/' or c == '?' or c == '#' or !isPchar(input)) {
                    u.host.name = input[0..i];
                    u.len += i;
                    return;
                },
            }
        }
        u.host.name = input[0..];
        u.len += input.len;
    }

    fn parseIP(u: *Uri, input: []const u8) Error!void {
        const end = mem.indexOfScalar(u8, input, ']') orelse return error.InvalidCharacter;
        var addr = net.Address.parseIp6(input[1..end], 0) catch return error.InvalidCharacter;
        u.host = .{ .ip = addr };
        u.len += end + 1;

        if (input.len > end + 2 and input[end + 1] == ':') {
            u.len += 1;
            try u.parsePort(input[end + 2 ..]);
        }
    }

    fn parsePort(u: *Uri, input: []const u8) Error!void {
        for (input) |c, i| {
            switch (c) {
                '0'...'9' => {
                    // digits
                },
                else => {
                    if (i == 0) return error.InvalidCharacter;
                    u.port = parseUnsigned(u16, input[0..i], 10) catch return error.InvalidCharacter;
                    u.len += i;
                    return;
                },
            }
        }
        if (input.len == 0) return error.InvalidCharacter;
        u.port = parseUnsigned(u16, input[0..], 10) catch return error.InvalidCharacter;
        u.len += input.len;
    }

    fn parsePath(u: *Uri, input: []const u8) void {
        for (input) |c, i| {
            if (c != '/' and (c == '?' or c == '#' or !isPchar(input[i..]))) {
                u.path = input[0..i];
                u.len += u.path.len;
                return;
            }
        }
        u.path = input[0..];
        u.len += u.path.len;
    }

    fn parseQuery(u: *Uri, input: []const u8) void {
        u.len += 1; // +1 for the '?'
        for (input) |c, i| {
            if (c == '#' or (c != '/' and c != '?' and !isPchar(input[i..]))) {
                u.query = input[0..i];
                u.len += u.query.len;
                return;
            }
        }
        u.query = input;
        u.len += input.len;
    }

    fn parseFragment(u: *Uri, input: []const u8) void {
        u.len += 1; // +1 for the '#'
        for (input) |c, i| {
            if (c != '/' and c != '?' and !isPchar(input[i..])) {
                u.fragment = input[0..i];
                u.len += u.fragment.len;
                return;
            }
        }
        u.fragment = input;
        u.len += u.fragment.len;
    }

    /// returns true if str starts with a valid path character or a percent encoded octet
    pub fn isPchar(str: []const u8) bool {
        assert(str.len > 0);
        return switch (str[0]) {
            'a'...'z', 'A'...'Z', '0'...'9', '-', '.', '_', '~', '!', '$', '&', '\'', '(', ')', '*', '+', ',', ';', '=', ':', '@' => true,
            '%' => str.len > 3 and isHex(str[1]) and isHex(str[2]),
            else => false,
        };
    }

    /// returns true if c is a hexadecimal digit
    pub fn isHex(c: u8) bool {
        return switch (c) {
            '0'...'9', 'a'...'f', 'A'...'F' => true,
            else => false,
        };
    }
};

test "basic url" {
    const uri = try Uri.parse("https://ziglang.org:80/documentation/master/?test#toc-Introduction", false);
    expect(mem.eql(u8, uri.scheme, "https"));
    expect(mem.eql(u8, uri.username, ""));
    expect(mem.eql(u8, uri.password, ""));
    expect(mem.eql(u8, uri.host.name, "ziglang.org"));
    expect(uri.port.? == 80);
    expect(mem.eql(u8, uri.path, "/documentation/master/"));
    expect(mem.eql(u8, uri.query, "test"));
    expect(mem.eql(u8, uri.fragment, "toc-Introduction"));
    expect(uri.len == 66);
}

test "short" {
    const uri = try Uri.parse("telnet://192.0.2.16:80/", false);
    expect(mem.eql(u8, uri.scheme, "telnet"));
    expect(mem.eql(u8, uri.username, ""));
    expect(mem.eql(u8, uri.password, ""));
    var buf = [_]u8{0} ** 100;
    var ip = std.fmt.bufPrint(buf[0..], "{}", .{uri.host.ip}) catch unreachable;
    expect(mem.eql(u8, ip, "192.0.2.16:80"));
    expect(uri.port.? == 80);
    expect(mem.eql(u8, uri.path, "/"));
    expect(mem.eql(u8, uri.query, ""));
    expect(mem.eql(u8, uri.fragment, ""));
    expect(uri.len == 23);
}

test "single char" {
    const uri = try Uri.parse("a", false);
    expect(mem.eql(u8, uri.scheme, ""));
    expect(mem.eql(u8, uri.username, ""));
    expect(mem.eql(u8, uri.password, ""));
    expect(mem.eql(u8, uri.host.name, ""));
    expect(uri.port == null);
    expect(mem.eql(u8, uri.path, "a"));
    expect(mem.eql(u8, uri.query, ""));
    expect(mem.eql(u8, uri.fragment, ""));
    expect(uri.len == 1);
}

test "ipv6" {
    const uri = try Uri.parse("ldap://[2001:db8::7]/c=GB?objectClass?one", false);
    expect(mem.eql(u8, uri.scheme, "ldap"));
    expect(mem.eql(u8, uri.username, ""));
    expect(mem.eql(u8, uri.password, ""));
    var buf = [_]u8{0} ** 100;
    var ip = std.fmt.bufPrint(buf[0..], "{}", .{uri.host.ip}) catch unreachable;
    expect(std.mem.eql(u8, ip, "[2001:db8::7]:0"));
    expect(uri.port == null);
    expect(mem.eql(u8, uri.path, "/c=GB"));
    expect(mem.eql(u8, uri.query, "objectClass?one"));
    expect(mem.eql(u8, uri.fragment, ""));
    expect(uri.len == 41);
}

test "mailto" {
    const uri = try Uri.parse("mailto:John.Doe@example.com", false);
    expect(mem.eql(u8, uri.scheme, "mailto"));
    expect(mem.eql(u8, uri.username, ""));
    expect(mem.eql(u8, uri.password, ""));
    expect(mem.eql(u8, uri.host.name, ""));
    expect(uri.port == null);
    expect(mem.eql(u8, uri.path, "John.Doe@example.com"));
    expect(mem.eql(u8, uri.query, ""));
    expect(mem.eql(u8, uri.fragment, ""));
    expect(uri.len == 27);
}

test "tel" {
    const uri = try Uri.parse("tel:+1-816-555-1212", false);
    expect(mem.eql(u8, uri.scheme, "tel"));
    expect(mem.eql(u8, uri.username, ""));
    expect(mem.eql(u8, uri.password, ""));
    expect(mem.eql(u8, uri.host.name, ""));
    expect(uri.port == null);
    expect(mem.eql(u8, uri.path, "+1-816-555-1212"));
    expect(mem.eql(u8, uri.query, ""));
    expect(mem.eql(u8, uri.fragment, ""));
    expect(uri.len == 19);
}

test "urn" {
    const uri = try Uri.parse("urn:oasis:names:specification:docbook:dtd:xml:4.1.2", false);
    expect(mem.eql(u8, uri.scheme, "urn"));
    expect(mem.eql(u8, uri.username, ""));
    expect(mem.eql(u8, uri.password, ""));
    expect(mem.eql(u8, uri.host.name, ""));
    expect(uri.port == null);
    expect(mem.eql(u8, uri.path, "oasis:names:specification:docbook:dtd:xml:4.1.2"));
    expect(mem.eql(u8, uri.query, ""));
    expect(mem.eql(u8, uri.fragment, ""));
    expect(uri.len == 51);
}

test "userinfo" {
    const uri = try Uri.parse("ftp://username:password@host.com/", false);
    expect(mem.eql(u8, uri.scheme, "ftp"));
    expect(mem.eql(u8, uri.username, "username"));
    expect(mem.eql(u8, uri.password, "password"));
    expect(mem.eql(u8, uri.host.name, "host.com"));
    expect(uri.port == null);
    expect(mem.eql(u8, uri.path, "/"));
    expect(mem.eql(u8, uri.query, ""));
    expect(mem.eql(u8, uri.fragment, ""));
    expect(uri.len == 33);
}

test "map query" {
    const uri = try Uri.parse("https://ziglang.org:80/documentation/master/?test;1=true&false#toc-Introduction", false);
    expect(mem.eql(u8, uri.scheme, "https"));
    expect(mem.eql(u8, uri.username, ""));
    expect(mem.eql(u8, uri.password, ""));
    expect(mem.eql(u8, uri.host.name, "ziglang.org"));
    expect(uri.port.? == 80);
    expect(mem.eql(u8, uri.path, "/documentation/master/"));
    expect(mem.eql(u8, uri.query, "test;1=true&false"));
    expect(mem.eql(u8, uri.fragment, "toc-Introduction"));
    var map = try Uri.mapQuery(alloc, uri.query);
    defer map.deinit();
    expect(mem.eql(u8, map.get("test").?, ""));
    expect(mem.eql(u8, map.get("1").?, "true"));
    expect(mem.eql(u8, map.get("false").?, ""));
}

test "ends in space" {
    const uri = try Uri.parse("https://ziglang.org/documentation/master/ something else", false);
    expect(mem.eql(u8, uri.scheme, "https"));
    expect(mem.eql(u8, uri.username, ""));
    expect(mem.eql(u8, uri.password, ""));
    expect(mem.eql(u8, uri.host.name, "ziglang.org"));
    expect(mem.eql(u8, uri.path, "/documentation/master/"));
    expect(uri.len == 41);
}

test "assume auth" {
    const uri = try Uri.parse("ziglang.org", true);
    expect(mem.eql(u8, uri.host.name, "ziglang.org"));
    expect(uri.len == 11);
}

var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
const alloc = &arena.allocator;

test "encode" {
    const path = (try Uri.encode(alloc, "/안녕하세요.html")).?;
    expect(mem.eql(u8, path, "/%EC%95%88%EB%85%95%ED%95%98%EC%84%B8%EC%9A%94.html"));
}

test "decode" {
    const path = (try Uri.decode(alloc, "/%EC%95%88%EB%85%95%ED%95%98%EC%84%B8%EC%9A%94.html")).?;
    expect(mem.eql(u8, path, "/안녕하세요.html"));
}

test "resolvePath" {
    var a = try Uri.resolvePath(alloc, "/a/b/..");
    expect(mem.eql(u8, a, "/a"));
    a = try Uri.resolvePath(alloc, "/a/b/../");
    expect(mem.eql(u8, a, "/a/"));
    a = try Uri.resolvePath(alloc, "/a/b/c/../d/../");
    expect(mem.eql(u8, a, "/a/b/"));
    a = try Uri.resolvePath(alloc, "/a/b/c/../d/..");
    expect(mem.eql(u8, a, "/a/b"));
    a = try Uri.resolvePath(alloc, "/a/b/c/../d/.././");
    expect(mem.eql(u8, a, "/a/b/"));
    a = try Uri.resolvePath(alloc, "/a/b/c/../d/../.");
    expect(mem.eql(u8, a, "/a/b"));
    a = try Uri.resolvePath(alloc, "/a/../../");
    expect(mem.eql(u8, a, "/"));

    arena.deinit();
}
