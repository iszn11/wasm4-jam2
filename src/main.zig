const std = @import("std");
const w4 = @import("wasm4.zig");

const boss = @import("boss.zig");
const bullets = @import("bullets.zig");
const camera = @import("camera.zig");
const level = @import("level.zig");
const music = @import("music.zig");
const player = @import("player.zig");
const sound = @import("sound.zig");
const turret = @import("turret.zig");
const upgrades = @import("upgrades.zig");

const Vec2 = @import("Vec2.zig");

pub const State = enum {
    alive,
    dead,
    win,
};

pub var state: State = .alive;

export fn start() void {
    w4.palette[0] = w4.Color.init(8, 8, 16);      // Color 1 (black)
    w4.palette[1] = w4.Color.init(240, 255, 255); // Color 2 (white)
    w4.palette[2] = w4.Color.init(255, 243, 168); // Color 3 (yellow)
    w4.palette[3] = w4.Color.init(48, 48, 96);    // Color 4 (dark blue)

    music.play(&music.overworld_music);
}

export fn update() void {

    switch (state) {
        .alive => {
            player.update();
            bullets.update();
            boss.update();
            turret.update();
            upgrades.update();
            camera.update();
        },
        .dead => {},
        .win => {},
    }

    music.update();
    sound.update();

    w4.draw_colors.color1 = 1;
    w4.draw_colors.color2 = 1;
    w4.rect(Vec2.zero, w4.screen_size, w4.screen_size);

    switch (state) {
        .alive => {
            level.draw();
            player.draw();
            bullets.draw();
            boss.draw();
            turret.draw();
            upgrades.draw();

            drawUI();
        },
        .dead => drawDeathScreen(),
        .win => drawWinScreen(),
    }
}

fn drawUI() void {
    w4.draw_colors.color1 = 1;
    w4.draw_colors.color2 = 1;
    w4.rect(Vec2.zero, 160, 8);

    w4.draw_colors.color1 = 2;
    w4.draw_colors.color2 = 0;
    w4.text("HP {}/{}", 0, 0, .{player.hp, player.max_hp});
}

fn drawDeathScreen() void {
    w4.draw_colors.color1 = 2;
    w4.draw_colors.color2 = 0;

    w4.textUnformatted("Oh no!", 8, 8);
    w4.textUnformatted("You are dead...", 8, 16);
    w4.textUnformatted("Anyway,", 8, 32);
    w4.textUnformatted("Press R to restart", 8, 40);
}

fn drawWinScreen() void {
    w4.draw_colors.color1 = 2;
    w4.draw_colors.color2 = 0;


    w4.textUnformatted("GG", 8, 8);
    w4.textUnformatted("You win!", 8, 16);
    w4.textUnformatted("Press R to restart", 8, 32);
}
