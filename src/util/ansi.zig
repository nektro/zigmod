const std = @import("std");
const gpa = std.heap.c_allocator;

const u = @import("index.zig");

//
//

pub const ansi = struct {
    pub const escape = struct {
        pub const SS2 = u.ascii.ESC.s() ++ "N";
        pub const SS3 = u.ascii.ESC.s() ++ "O";
        pub const DCS = u.ascii.ESC.s() ++ "P";
        pub const CSI = u.ascii.ESC.s() ++ "[";
        pub const ST  = u.ascii.ESC.s() ++ "\\";
        pub const OSC = u.ascii.ESC.s() ++ "]";
        pub const SOS = u.ascii.ESC.s() ++ "X";
        pub const PM  = u.ascii.ESC.s() ++ "^";
        pub const APC = u.ascii.ESC.s() ++ "_";
        pub const RIS = u.ascii.ESC.s() ++ "c";
    };

    fn make_csi_sequence(comptime c: []const u8, x: anytype) []const u8 {
        return escape.CSI ++ u._join(";", arr_i_to_s(x)) ++ c;
    }

    fn arr_i_to_s(x: anytype) [][]const u8 {
        var res: [x.len][]const u8 = undefined;
        for (x) |item, i| {
            res[i] = std.fmt.comptimePrint("{}", .{item});
        }
        return &res;
    }

    pub const csi = struct {
        fn CursorUp(n: i32) []const u8 { return make_csi_sequence("A", .{n}); }
        fn CursorDown(n: i32) []const u8 { return make_csi_sequence("B", .{n}); }
        fn CursorForward(n: i32) []const u8 { return make_csi_sequence("C", .{n}); }
        fn CursorBack(n: i32) []const u8 { return make_csi_sequence("D", .{n}); }
        fn CursorNextLine(n: i32) []const u8 { return make_csi_sequence("E", .{n}); }
        fn CursorPrevLine(n: i32) []const u8 { return make_csi_sequence("F", .{n}); }
        fn CursorHorzAbs(n: i32) []const u8 { return make_csi_sequence("G", .{n}); }
        fn CursorPos(n: i32, m: i32) []const u8 { return make_csi_sequence("H", .{n, m}); }
        fn EraseInDisplay(n: i32) []const u8 { return make_csi_sequence("J", .{n}); }
        fn EraseInLine(n: i32) []const u8 { return make_csi_sequence("K", .{n}); }
        fn ScrollUp(n: i32) []const u8 { return make_csi_sequence("S", .{n}); }
        fn ScrollDown(n: i32) []const u8 { return make_csi_sequence("T", .{n}); }
        fn HorzVertPos(n: i32, m: i32) []const u8 { return make_csi_sequence("f", .{n, m}); }
        fn SGR(ns: anytype) []const u8 { return make_csi_sequence("m", ns); }
    };

    pub const style = struct {
        pub const ResetAll = csi.SGR(.{0});

        pub const Bold      = csi.SGR(.{1});
        pub const Faint     = csi.SGR(.{2});
        pub const Italic    = csi.SGR(.{3});
        pub const Underline = csi.SGR(.{4});
        pub const BlinkSlow = csi.SGR(.{5});
        pub const BlinkFast = csi.SGR(.{6});

        pub const ResetFont = csi.SGR(.{10});
        pub const Font1     = csi.SGR(.{11});
        pub const Font2     = csi.SGR(.{12});
        pub const Font3     = csi.SGR(.{13});
        pub const Font4     = csi.SGR(.{14});
        pub const Font5     = csi.SGR(.{15});
        pub const Font6     = csi.SGR(.{16});
        pub const Font7     = csi.SGR(.{17});
        pub const Font8     = csi.SGR(.{18});
        pub const Font9     = csi.SGR(.{19});

        pub const UnderlineDouble = csi.SGR(.{21});
        pub const ResetIntensity  = csi.SGR(.{22});
        pub const ResetItalic     = csi.SGR(.{23});
        pub const ResetUnderline  = csi.SGR(.{24});
        pub const ResetBlink      = csi.SGR(.{25});

        pub const FgBlack      = csi.SGR(.{30});
        pub const FgRed        = csi.SGR(.{31});
        pub const FgGreen      = csi.SGR(.{32});
        pub const FgYellow     = csi.SGR(.{33});
        pub const FgBlue       = csi.SGR(.{34});
        pub const FgMagenta    = csi.SGR(.{35});
        pub const FgCyan       = csi.SGR(.{36});
        pub const FgWhite      = csi.SGR(.{37});
        // Fg8bit       = func(n int) string { return csi.SGR(38, 5, n) }
        // Fg24bit      = func(r, g, b int) string { return csi.SGR(38, 2, r, g, b) }
        pub const ResetFgColor = csi.SGR(.{39});

        pub const BgBlack      = csi.SGR(.{40});
        pub const BgRed        = csi.SGR(.{41});
        pub const BgGreen      = csi.SGR(.{42});
        pub const BgYellow     = csi.SGR(.{43});
        pub const BgBlue       = csi.SGR(.{44});
        pub const BgMagenta    = csi.SGR(.{45});
        pub const BgCyan       = csi.SGR(.{46});
        pub const BgWhite      = csi.SGR(.{47});
        // Bg8bit       = func(n int) string { return csi.SGR(48, 5, n) }
        // Bg24bit      = func(r, g, b int) string { return csi.SGR(48, 2, r, g, b) }
        pub const ResetBgColor = csi.SGR(.{49});

        pub const Framed         = csi.SGR(.{51});
        pub const Encircled      = csi.SGR(.{52});
        pub const Overlined      = csi.SGR(.{53});
        pub const ResetFrameEnci = csi.SGR(.{54});
        pub const ResetOverlined = csi.SGR(.{55});
    };

    pub const color = struct {
        pub const Color = enum(u8) {
            Black,
            Red,
            Green,
            Yellow,
            Blue,
            Magenta,
            Cyan,
            White,
        };

        pub fn Fg(s: Color, comptime m: []const u8) []const u8 {
            return csi.SGR(.{30+@enumToInt(s)}) ++ m ++ style.ResetFgColor;
        }

        pub fn Bg(s: Color, comptime m: []const u8) []const u8 {
            return csi.SGR(.{40+@enumToInt(s)}) ++ m ++ style.ResetBgColor;
        }
    };
};
