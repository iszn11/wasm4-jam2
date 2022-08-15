const std = @import("std");
const w4 = @import("wasm4.zig");

const smiley = [8]u8{
    0b11000011,
    0b10000001,
    0b00100100,
    0b00100100,
    0b00000000,
    0b00100100,
    0b10011001,
    0b11000011,
};

export fn start() void {

}

export fn update() void {
    w4.draw_colors.color1 = 2;
    w4.draw_colors.color2 = 0;
    w4.textUnformatted("Hello from Zig!", 10, 10);

    if (w4.gamepads[0].x) {
        w4.draw_colors.color1 = 1;
        w4.draw_colors.color2 = 2;
    }

    w4.blit(&smiley, 76, 76, 8, 8, .{});
    w4.textUnformatted("Press X to blink", 16, 90);
}
