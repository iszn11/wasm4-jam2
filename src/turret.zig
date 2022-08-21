const std = @import("std");
const w4 = @import("wasm4.zig");

const bullets = @import("bullets.zig");
const camera = @import("camera.zig");
const level = @import("level.zig");
const music = @import("music.zig");
const player = @import("player.zig");
const random = @import("random.zig");
const sound = @import("sound.zig");

const Vec2 = @import("Vec2.zig");

const State = enum {
    before_battle,
    during_battle,
    defeated,
};

const sprite = [_]u8{
    0b01_10_10_10, 0b10_10_10_01,
    0b01_10_10_10, 0b10_10_10_01,
    0b00_01_10_10, 0b10_10_01_00,
    0b00_00_01_11, 0b11_01_00_00,
    0b00_00_00_11, 0b11_00_00_00,
    0b00_00_00_00, 0b00_00_00_00,
    0b00_00_00_00, 0b00_00_00_00,
    0b00_00_00_00, 0b00_00_00_00,
};

const bullet_offset_px = Vec2.init(4, 4);
const chunk_pos = Vec2.init(4, 3);
const chunk_corner_px = chunk_pos.scale(level.chunk_size_px);
const start_hp = 4;
const count = 7;

const pos_px = [count]Vec2{
    chunk_corner_px.add(Vec2.init(76, 40)),
    chunk_corner_px.add(Vec2.init(48, 48)),
    chunk_corner_px.add(Vec2.init(104, 48)),
    chunk_corner_px.add(Vec2.init(40, 80)),
    chunk_corner_px.add(Vec2.init(112, 80)),
    chunk_corner_px.add(Vec2.init(48, 112)),
    chunk_corner_px.add(Vec2.init(104, 112)),
};

const rotate_flags = [count]w4.BlitFlags{
    .{},
    .{.rotate = true},
    .{.rotate = true, .flip_y = true},
    .{.rotate = true},
    .{.rotate = true, .flip_y = true},
    .{.rotate = true},
    .{.rotate = true, .flip_y = true},
};

pub var state: State = .before_battle;

var timer = [_]u32{0} ** count;
var hp = [_]u8{start_hp} ** count;

pub fn update() void {
    const player_chunk_pos = player.position_sp.unscale(level.chunk_size_sp);
    if (!player_chunk_pos.equals(chunk_pos)) {
        return;
    }

    switch (state) {
        .before_battle => {
            const player_rel_pos_sp = player.position_sp.sub(chunk_corner_px.mul(256));
            if (player_rel_pos_sp.y > 16 * level.tile_size_sp) {
                state = .during_battle;
                music.play(&music.boss_music);
            }
        },
        .during_battle => {
            var i: usize = 0;
            while (i < count) : (i += 1) {
                if (hp[i] == 0) {
                    continue;
                }

                if (timer[i] == 0) {
                    const origin_sp = pos_px[i].add(bullet_offset_px).mul(256);
                    const turret_to_player = Vec2.sub(player.position_sp, origin_sp);
                    const len = @sqrt(@intToFloat(f32, turret_to_player.lengthSquared()));
                    const vel_sp = turret_to_player.mulf(0x80 / len);
                    bullets.spawn(origin_sp, vel_sp, .turret);
                    sound.play(.shoot);
                    timer[i] = random.bounded(120) + 180;
                }

                var bullet_i: usize = 0;
                while (hp[i] != 0 and bullet_i < bullets.bullet_count) {
                    if (bullets.bullet_type[bullet_i] != .player) {
                        bullet_i += 1;
                        continue;
                    }

                    const bullet_pos_px = bullets.bullet_pos_sp[bullet_i].div(256);
                    // NOTE This check is not correct with subpixels, but I don't care
                    if (
                        bullet_pos_px.x >= pos_px[i].x
                        and bullet_pos_px.y >= pos_px[i].y
                        and bullet_pos_px.x < pos_px[i].x + 8
                        and bullet_pos_px.y < pos_px[i].y + 8
                    ) {
                        bullets.swapRemove(bullet_i);
                        hp[i] -= 1;
                        sound.play(if (hp[i] == 0) .explode else .hit);
                    } else {
                        bullet_i += 1;
                    }
                }

                timer[i] -= 1;
            }

            var all_dead = true;
            i = 0;
            while (i < count) : (i += 1) {
                if (hp[i] > 0) {
                    all_dead = false;
                    break;
                }
            }

            if (all_dead) {
                state = .defeated;
                music.play(&music.overworld_music);
            }
        },
        .defeated => {},
    }
}

pub fn draw() void {
    const player_chunk_pos = player.position_sp.unscale(level.chunk_size_sp);
    if (state != .during_battle or !player_chunk_pos.equals(chunk_pos)) {
        return;
    }

    const offset_px = camera.getOffsetPX();

    w4.draw_colors.color1 = 0;
    w4.draw_colors.color2 = 2;
    w4.draw_colors.color3 = 4;
    w4.draw_colors.color4 = 3;

    var i: usize = 0;
    while (i < count) : (i += 1) {
        if (hp[i] == 0) {
            continue;
        }

        var flags = rotate_flags[i];
        flags.@"2bpp" = true;
        w4.blit(&sprite, pos_px[i].add(offset_px), 8, 8, flags);
    }
}
