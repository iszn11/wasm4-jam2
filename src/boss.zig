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
    0b11_11_00_00, 0b00_00_01_11,
    0b11_11_00_00, 0b01_01_10_11,
    0b00_00_11_01, 0b10_10_11_10,
    0b00_00_01_11, 0b10_11_10_10,
    0b00_01_10_10, 0b11_10_10_10,
    0b00_01_10_11, 0b10_11_10_10,
    0b01_10_11_10, 0b10_10_11_10,
    0b11_11_10_10, 0b10_10_10_11,
};

const timer_period = 400;
const chunk_pos = Vec2.init(1, 3);
const chunk_corner_px = chunk_pos.scale(level.chunk_size_px);
const origin_sp = chunk_corner_px.add(Vec2.init(80, 84)).mul(256);
const start_hp = 30;
const extent_sp = Vec2.init(8, 8).mul(256);

pub var state: State = .before_battle;
var hp: u8 = start_hp;
var timer: u32 = 0;

pub fn shootDir(x: i32, y: i32, randomize: bool) void {
    const vec = Vec2.init(x, y);
    const len = @sqrt(@intToFloat(f32, vec.lengthSquared()));
    var vel_sp = vec.mulf(0x100 / len);
    if (randomize) {
        vel_sp.x += @intCast(i32, random.bounded(61)) - 30;
        vel_sp.y += @intCast(i32, random.bounded(61)) - 30;
    }

    bullets.spawn(origin_sp, vel_sp, .turret);
    sound.play(.shoot);
}

pub fn update() void {
    const player_chunk_pos = player.position_sp.unscale(level.chunk_size_sp);
    if (!player_chunk_pos.equals(chunk_pos)) {
        return;
    }

    switch (state) {
        .before_battle => {
            const player_rel_pos_sp = player.position_sp.sub(chunk_corner_px.mul(256));
            if (player_rel_pos_sp.y < 17 * level.tile_size_sp) {
                state = .during_battle;
                music.play(&music.boss_music);
            }
        },
        .during_battle => {

            switch (timer) {
                0 => shootDir(0, 1, true),
                5 => shootDir(1, 1, true),
                10 => shootDir(1, 0, true),
                15 => shootDir(1, -1, true),
                20 => shootDir(0, -1, true),
                25 => shootDir(-1, -1, true),
                30 => shootDir(-1, 0, true),
                35 => shootDir(-1, 1, true),

                50 => shootDir(-38, 92, true),
                55 => shootDir(-92, 38, true),
                60 => shootDir(-92, -38, true),
                65 => shootDir(-38, -92, true),
                70 => shootDir(38, -92, true),
                75 => shootDir(92, -38, true),
                80 => shootDir(92, 38, true),
                85 => shootDir(38, 92, true),

                145 => {
                    const to_player = Vec2.sub(player.position_sp, origin_sp);
                    shootDir(to_player.x, to_player.y, false);
                },

                200 => shootDir(-1, 1, true),
                205 => shootDir(-1, 0, true),
                210 => shootDir(-1, -1, true),
                215 => shootDir(0, -1, true),
                220 => shootDir(1, -1, true),
                225 => shootDir(1, 0, true),
                230 => shootDir(1, 1, true),
                235 => shootDir(0, 1, true),

                250 => shootDir(38, 92, true),
                255 => shootDir(92, 38, true),
                260 => shootDir(92, -38, true),
                265 => shootDir(38, -92, true),
                270 => shootDir(-38, -92, true),
                275 => shootDir(-92, -38, true),
                280 => shootDir(-92, 38, true),
                285 => shootDir(-38, 92, true),

                345 => {
                    const to_player = Vec2.sub(player.position_sp, origin_sp);
                    shootDir(to_player.x, to_player.y, false);
                },

                else => {},
            }

            var bullet_i: usize = 0;
            while (hp != 0 and bullet_i < bullets.bullet_count) {
                if (bullets.bullet_type[bullet_i] != .player) {
                    bullet_i += 1;
                    continue;
                }

                const bullet_pos_sp = bullets.bullet_pos_sp[bullet_i];
                if (
                    bullet_pos_sp.x >= origin_sp.x - extent_sp.x
                    and bullet_pos_sp.y >= origin_sp.y - extent_sp.y
                    and bullet_pos_sp.x <= origin_sp.x + extent_sp.x
                    and bullet_pos_sp.y <= origin_sp.y + extent_sp.y
                ) {
                    bullets.swapRemove(bullet_i);
                    hp -= 1;
                    sound.play(if (hp == 0) .explode else .hit);
                } else {
                    bullet_i += 1;
                }
            }

            timer += 1;
            if (timer > timer_period) {
                timer = 0;
            }

            if (hp == 0) {
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

    const origin_ss_px = origin_sp.div(256).add(offset_px);

    w4.blit(&sprite, origin_ss_px.add(Vec2.init(-8, -8)), 8, 8, .{.@"2bpp" = true});
    w4.blit(&sprite, origin_ss_px.add(Vec2.init( 0, -8)), 8, 8, .{.@"2bpp" = true, .flip_x = true});
    w4.blit(&sprite, origin_ss_px.add(Vec2.init(-8,  0)), 8, 8, .{.@"2bpp" = true, .flip_y = true});
    w4.blit(&sprite, origin_ss_px.add(Vec2.init( 0,  0)), 8, 8, .{.@"2bpp" = true, .flip_x = true, .flip_y = true});
}
