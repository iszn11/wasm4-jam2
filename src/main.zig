const std = @import("std");
const w4 = @import("wasm4.zig");

const camera = @import("camera.zig");
const level = @import("level.zig");
const player = @import("player.zig");

export fn start() void {
    w4.palette[0] = w4.Color.init(8, 8, 16);
    w4.palette[1] = w4.Color.init(240, 255, 255);
    w4.palette[2] = w4.Color.init(255, 243, 168);
    w4.palette[3] = w4.Color.init(48, 48, 96);
}

export fn update() void {
    player.update();
    camera.update();

    w4.draw_colors.color1 = 1;
    w4.draw_colors.color2 = 1;
    w4.rect(0, 0, w4.screen_size, w4.screen_size);

    level.draw();
    player.draw();
}
