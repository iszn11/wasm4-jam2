const std = @import("std");
const w4 = @import("wasm4.zig");

const camera = @import("camera.zig");
const level = @import("level.zig");

const Vec2 = @import("Vec2.zig");

pub const bullet_cap = 100;
pub var bullet_pos_sp: [bullet_cap]Vec2 = undefined;
pub var bullet_vel_sp: [bullet_cap]Vec2 = undefined;
pub var bullet_count: usize = 0;

pub fn spawn(pos_sp: Vec2, vel_sp: Vec2) void {
    if (bullet_count >= bullet_cap) {
        return;
    }

    bullet_pos_sp[bullet_count] = pos_sp;
    bullet_vel_sp[bullet_count] = vel_sp;

    bullet_count += 1;
}

pub fn update() void {
    var i: usize = 0;
    while (i < bullet_count) {
        bullet_pos_sp[i] = bullet_pos_sp[i].add(bullet_vel_sp[i]);

        const pos_tl = bullet_pos_sp[i].div(level.tile_size_sp);
        if (level.at(pos_tl.x, pos_tl.y) != 0) {
            bullet_count -= 1;
            bullet_pos_sp[i] = bullet_pos_sp[bullet_count];
            bullet_vel_sp[i] = bullet_vel_sp[bullet_count];
        } else {
            i += 1;
        }
    }
}

pub fn draw() void {
    const offset_px = camera.getOffsetPX();

    var i: usize = 0;
    while (i < bullet_count) : (i += 1) {
        const pos_sp = bullet_pos_sp[i];
        const pos_px = pos_sp.adds(128).div(256);

        w4.draw_colors.color1 = 3;
        w4.draw_colors.color2 = 3;

        w4.rect(pos_px.subs(1).add(offset_px), 2, 2);
    }
}
