const std = @import("std");
const w4 = @import("wasm4.zig");

const camera = @import("camera.zig");
const level = @import("level.zig");
const main = @import("main.zig");
const player = @import("player.zig");

const Vec2 = @import("Vec2.zig");

const start_chunk_pos = Vec2.init(1, 0);
const jump_chunk_pos = Vec2.init(0, 2);
const hp_chunk_pos = Vec2.init(3, 3);
const weapon_chunk_pos = Vec2.init(4, 2);
const win_chunk_pos = Vec2.init(4, 0);

const extent_sp = Vec2.inits(4 * 256);

const jump_pos_sp = jump_chunk_pos.scale(level.chunk_size_sp).add(Vec2.init(80, 120).mul(256));
const hp_pos_sp = hp_chunk_pos.scale(level.chunk_size_sp).add(Vec2.init(80, 56).mul(256));
const weapons_pos_sp = weapon_chunk_pos.scale(level.chunk_size_sp).add(Vec2.init(28, 20).mul(256));
const win_pos_sp = win_chunk_pos.scale(level.chunk_size_sp).add(Vec2.init(80, 120).mul(256));

pub var hp_upgrade_get = false;

const sprite = [_]u8{
    0b00_00_01_01, 0b01_01_00_00,
    0b00_01_10_10, 0b10_10_01_00,
    0b01_10_10_10, 0b10_10_10_01,
    0b01_10_10_10, 0b10_10_10_01,
    0b01_10_10_10, 0b10_10_10_01,
    0b01_10_10_10, 0b10_10_10_01,
    0b00_01_10_10, 0b10_10_01_00,
    0b00_00_01_01, 0b01_01_00_00,
};

fn checkCollision(pos: Vec2) bool {
    const player_min = player.position_sp.add(Vec2.init(-player.hitbox_horizontal_extent_sp, -player.hitbox_height_sp));
    const player_max = player.position_sp.add(Vec2.init(player.hitbox_horizontal_extent_sp, 0));

    const upgrade_min = pos.sub(extent_sp);
    const upgrade_max = pos.add(extent_sp);

    return
        player_min.x < upgrade_max.x
        and player_min.y < upgrade_max.y
        and player_max.x > upgrade_min.x
        and player_max.y > upgrade_min.y;
}

pub fn update() void {

    if (!player.infinite_jump and checkCollision(jump_pos_sp)) {
        player.infinite_jump = true;
    }

    if (!player.has_weapon and checkCollision(weapons_pos_sp)) {
        player.has_weapon = true;
    }

    if (!hp_upgrade_get and checkCollision(hp_pos_sp)) {
        player.max_hp += 2;
        player.hp = player.max_hp;
        hp_upgrade_get = true;
    }

    if (checkCollision(win_pos_sp)) {
        main.state = .win;
    }

}

fn drawSprite(pos_sp: Vec2) void {
    const camera_offset_px = camera.getOffsetPX();

    w4.draw_colors.color1 = 0;
    w4.draw_colors.color2 = 2;
    w4.draw_colors.color3 = 3;

    const pos_px = pos_sp.sub(extent_sp).div(256);
    w4.blit(&sprite, pos_px.add(camera_offset_px), 8, 8, .{.@"2bpp" = true});
}

pub fn draw() void {
    const player_chunk_pos = player.position_sp.unscale(level.chunk_size_sp);
    const camera_offset_px = camera.getOffsetPX();

    const d = camera_offset_px.add(player_chunk_pos.scale(level.chunk_size_px)).add(Vec2.init(0, -8));

    if (player_chunk_pos.equals(start_chunk_pos)) {
        w4.draw_colors.color1 = 2;
        w4.draw_colors.color2 = 0;

        w4.textUnformatted("Arrows to move", 24 + d.x, 24 + d.y);
        w4.textUnformatted("Z to jump", 24 + d.x, 32 + d.y);
        w4.textUnformatted("Good luck!", 24 + d.x, 48 + d.y);
    } else if (player_chunk_pos.equals(jump_chunk_pos)) {
        if (player.infinite_jump) {
            w4.draw_colors.color1 = 2;
            w4.draw_colors.color2 = 0;

            w4.textUnformatted("Infinite jump", 24 + d.x, 32 + d.y);
            w4.textUnformatted("get!", 24 + d.x, 40 + d.y);
            w4.textUnformatted("Press Z in the", 24 + d.x, 56 + d.y);
            w4.textUnformatted("air repeatedly", 24 + d.x, 64 + d.y);
        } else {
            drawSprite(jump_pos_sp);
        }
    } else if (player_chunk_pos.equals(weapon_chunk_pos)) {
        if (player.has_weapon) {
            w4.draw_colors.color1 = 2;
            w4.draw_colors.color2 = 0;

            w4.textUnformatted("Weapon get!", 24 + d.x, 24 + d.y);
            w4.textUnformatted("X to shoot", 8 + d.x, 120 + d.y);
            w4.textUnformatted("Aim with", 8 + d.x, 128 + d.y);
            w4.textUnformatted("arrows", 8 + d.x, 136 + d.y);
        } else {
            drawSprite(weapons_pos_sp);
        }
    } else if (player_chunk_pos.equals(hp_chunk_pos)) {
        if (hp_upgrade_get) {
            w4.draw_colors.color1 = 2;
            w4.draw_colors.color2 = 0;

            w4.textUnformatted("HP upgrade get!", 8 + d.x, 32 + d.y);
            w4.textUnformatted("HP restored", 8 + d.x, 40 + d.y);
        } else {
            drawSprite(hp_pos_sp);
        }
    } else if (player_chunk_pos.equals(win_chunk_pos)) {
        drawSprite(win_pos_sp);
    }
}
