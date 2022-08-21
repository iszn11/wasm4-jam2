const std = @import("std");
const imports = @import("wasm4_imports.zig");

const Vec2 = @import("Vec2.zig");

pub const screen_size = 160;

// --- MEMORY MAP --------------------------------------------------------------

pub const Color = packed struct {
    b: u8,
    g: u8,
    r: u8,
    _pad: u8 = 0,

    pub fn init(r: u8, g: u8, b: u8) Color { return Color{ .r = r, .g = g, .b = b }; }
};

pub const DrawColors = packed struct {
    /// Value of `0` means transparency, `1`-`4` chooses a color from the palette.
    color1: u4,
    /// Value of `0` means transparency, `1`-`4` chooses a color from the palette.
    color2: u4,
    /// Value of `0` means transparency, `1`-`4` chooses a color from the palette.
    color3: u4,
    /// Value of `0` means transparency, `1`-`4` chooses a color from the palette.
    color4: u4,
};

pub const Gamepad = packed struct {
    x: bool,
    z: bool,
    _pad: u2 = 0,
    left: bool,
    right: bool,
    up: bool,
    down: bool,
};

pub const Mouse = packed struct {
    x: i16,
    y: i16,
    left: bool,
    right: bool,
    middle: bool,
    _pad: u5 = 0,
};

pub const SystemFlags = packed struct {
    preserve_framebuffer: bool = false,
    hide_gamepad_overlay: bool = false,
    _pad: u6 = 0,
};

pub const Netplay = packed struct {
    player_index: u2,
    active: bool,
    _pad: u5 = 0,
};

pub const palette: *[4]Color = @intToPtr(*[4]Color, 0x04);
pub const draw_colors: *DrawColors = @intToPtr(*DrawColors, 0x14);
pub const gamepads: *const [4]Gamepad = @intToPtr(*const [4]Gamepad, 0x16);
pub const mouse: *const Mouse = @intToPtr(*const Mouse, 0x1A);
pub const system_flags: *SystemFlags = @intToPtr(*SystemFlags, 0x1F);
pub const netplay: *const Netplay = @intToPtr(*const Netplay, 0x20);
pub const framebuffer: *[6400]u8 = @intToPtr(*[6400]u8, 0xA0);

// --- DRAWING -----------------------------------------------------------------

pub const BlitFlags = packed struct {
    /// If not set, 1 bpp format is used, 2 bpp otherwise
    @"2bpp": bool = false,
    flip_x: bool = false,
    flip_y: bool = false,
    /// Rotate counter-clockwise by 90 degrees
    rotate: bool = false,
    _pad: u28 = 0,
};

var text_buf: [1024]u8 = undefined;

/// Copies pixels to the framebuffer. Affected by the `draw_colors` register.
/// `sprite` is in 1 bpp or 2 bpp format, has size `width`×`height` and is
/// copied to framebuffer with (`pos.x`, `pos.y`) being at its upper-left
/// corner.
pub inline fn blit(sprite: [*]const u8, pos: Vec2, width: u32, height: u32, flags: BlitFlags) void {
    imports.blit(sprite, pos.x, pos.y, width, height, @bitCast(u32, flags));
}

/// Copies a subregion within a larger sprite atlas to the framebuffer.
pub inline fn blitSub(sprite: [*]const u8, pos: Vec2, width: u32, height: u32, src_pos: Vec2, stride: u32, flags: BlitFlags) void {
    imports.blitSub(sprite, pos.x, pos.y, width, height, src_pos.x, src_pos.y, stride, @bitCast(u32, flags));
}

/// Draws a line between two points.
/// `draw_colors` color 1 is used as the line color.
pub inline fn line(x1: i32, y1: i32, x2: i32, y2: i32) void {
    imports.line(x1, y1, x2, y2);
}

/// Draws a horizontal line between (`x`, `y`) and (`x` + `len` - 1, `y`).
/// `draw_colors` color 1 is used as the line color.
pub inline fn hline(x: i32, y: i32, len: u32) void {
    imports.hline(x, y, len);
}

/// Draws a vertical line between (``x`, `y`) and (`x`, `y` + `len` - 1).
/// `draw_colors` color 1 is used as the line color.
pub inline fn vline(x: i32, y: i32, len: u32) void {
    imports.vline(x, y, len);
}

/// Draws an oval (or circle).
/// `draw_colors` color 1 is used as the fill color.
/// `draw_colors` color 2 is used as the outline color.
pub inline fn oval(x: i32, y: i32, width: u32, height: u32) void {
    imports.oval(x, y, width, height);
}

/// Draws a rectangle.
/// `draw_colors` color 1 is used as the fill color.
/// `draw_colors` color 2 is used as the outline color.
pub inline fn rect(pos: Vec2, width: u32, height: u32) void {
    imports.rect(pos.x, pos.y, width, height);
}

/// Draws text using the built-in system font.
/// The string may contain new-line (\n) characters.
/// The font is 8x8 pixels per character.
/// `draw_colors` color 1 is used as the text color.
/// `draw_colors` color 2 is used as the background color.
pub inline fn textUnformatted(str: []const u8, x: i32, y: i32) void {
    imports.textUtf8(str.ptr, str.len, x, y);
}

/// Draws text using the built-in system font.
/// The string may contain new-line (\n) characters.
/// The font is 8x8 pixels per character.
/// Uses a temporary buffer for allocation which can hold at most 1024 bytes.
/// Output will be truncated if the formatted string would be too long.
/// `draw_colors` color 1 is used as the text color.
/// `draw_colors` color 2 is used as the background color.
pub fn text(comptime fmt: []const u8, x: i32, y: i32, args: anytype) void {
    const str = std.fmt.bufPrint(&text_buf, fmt, args) catch |err| switch (err) {
        error.NoSpaceLeft => {
            imports.textUtf8(&text_buf, text_buf.len, x, y);
            traceUnformatted("WARNING: Rendered text was truncated because it was too long");
            return;
        },
    };

    textUnformatted(str, x, y);
}

// --- SOUND -------------------------------------------------------------------

pub const Channel = enum(u2) {
    pulse1 = 0,
    pulse2 = 1,
    triangle = 2,
    noise = 3,
};

pub const Duty = enum(u2) {
    @"1/8" = 0,
    @"1/4" = 1,
    @"1/2" = 2,
    @"3/4" = 3,
};

pub const Frequency = packed struct {
    start: u16,
    end: u16 = 0,
};

pub const Duration = packed struct {
    sustain: u8,
    release: u8 = 0,
    decay: u8 = 0,
    attack: u8 = 0,
};

pub fn adsr(attack: u8, decay: u8, sustain: u8, release: u8) Duration {
    return .{
        .attack = attack,
        .decay = decay,
        .sustain = sustain,
        .release = release,
    };
}

pub const Volume = packed struct {
    sustain: u8,
    peak: u8 = 0,
    _pad: u16 = 0,
};

pub const ToneFlags = packed struct {
    channel: Channel,
    duty: Duty = .@"1/8",
    _pad: u28 = 0,
};

/// Plays a sound tone.
pub inline fn tone(frequency: Frequency, duration: Duration, volume: Volume, flags: ToneFlags) void {
    const frequency_u32 = @bitCast(u32, frequency);
    const duration_u32 = @bitCast(u32, duration);
    const volume_u32 = @bitCast(u32, volume);
    const flags_u32 = @bitCast(u32, flags);
    imports.tone(frequency_u32, duration_u32, volume_u32, flags_u32);
}

// --- STORAGE -----------------------------------------------------------------

/// Reads up to `dest.len` bytes from persistent storage into `dest`.
/// Returns the number of bytes read, which may be less than `size`.
pub inline fn diskr(dest: []u8) usize {
    return @as(u32, imports.diskr(dest.ptr, @as(u32, dest.len)));
}

/// Writes up to `src.size` bytes from `src` into persistent storage.
/// Any previously saved data on the disk is replaced.
/// Returns the number of bytes written, which may be less than `size`.
pub inline fn diskw(src: []const u8) u32 {
    return @as(u32, imports.diskw(src.ptr, @as(u32, src.size)));
}

// --- OTHER -------------------------------------------------------------------

var trace_buf: [1024]u8 = undefined;

/// Prints a message to the debug console.
pub inline fn traceUnformatted(str: []const u8) void {
    imports.traceUtf8(str.ptr, str.len);
}

/// Prints a message to the debug console.
/// Uses a temporary buffer for allocation which can hold at most 1024 bytes.
/// Output will be truncated if the formatted string would be too long.
pub fn trace(comptime fmt: []const u8, args: anytype) void {
    const str = std.fmt.bufPrint(&trace_buf, fmt, args) catch |err| switch (err) {
        error.NoSpaceLeft => {
            imports.traceUtf8(&trace_buf, trace_buf.len);
            traceUnformatted("WARNING: Trace message was truncated because it was too long");
            return;
        },
    };

    traceUnformatted(str);
}
