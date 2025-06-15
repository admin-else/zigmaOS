const fmt = @import("std").fmt;
const Writer = @import("std").io.Writer;

const buffer = @as([*]volatile u16, @ptrFromInt(0xB8000));
const width = 80;
const height = 25;
const bufferSize = width * height;

var x: u16 = 0;
var y: u16 = 0;
var color: ColorPair = ColorPair{ .bg = .BLACK, .fg = .WHITE };

const Color = enum(u4) { BLACK = 0x0, BLUE = 0x1, GREEN = 0x2, CYAN = 0x3, RED = 0x4, MAGENTA = 0x5, BROWN = 0x6, LIGHT_GRAY = 0x7, DARK_GRAY = 0x8, LIGHT_BLUE = 0x9, LIGHT_GREEN = 0xA, LIGHT_CYAN = 0xB, LIGHT_RED = 0xC, LIGHT_MAGENTA = 0xD, YELLOW = 0xE, WHITE = 0xF };

const ColorPair = packed struct(u8) { fg: Color, bg: Color };
const CharAndColor = packed struct(u16) { char: u8, color: ColorPair };

pub fn setColor(c: ColorPair) void {
    color = c;
}

pub fn reset() void {
    @memset(buffer[0..bufferSize], CharAndColor{ .char = ' ', .color = color });
    x = 0;
    y = 0;
    color = ColorPair{ .bg = .BLACK, .fg = .WHITE };
}

pub fn putchar(c: u8) void {
    switch (c) {
        '\n' => {
            x = 0;
            y = if (y < height) y + 1 else 0;
        },
        else => {
            buffer[x + y * width] = @bitCast(CharAndColor{ .char = c, .color = color });
            x += 1;
            if (x >= width) {
                x = 0;
                y += 1;
                if (y >= height)
                    y = 0;
            }
        },
    }
}

pub fn puts(s: []const u8) void {
    for (s) |c| {
        putchar(c);
    }
}

pub const writer = Writer(void, error{}, callback){ .context = {} };

fn callback(_: void, string: []const u8) error{}!usize {
    puts(string);
    return string.len;
}

pub fn printf(comptime format: []const u8, args: anytype) void {
    fmt.format(writer, format, args) catch unreachable;
}
