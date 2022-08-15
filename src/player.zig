const std = @import("std");
const w4 = @import("wasm4.zig");

const camera = @import("camera.zig");
const level = @import("level.zig");

const Vec2 = @import("Vec2.zig");

const sprite = [8]u8{
    0b11000011,
    0b10000001,
    0b00100100,
    0b00100100,
    0b00000000,
    0b00100100,
    0b10011001,
    0b11000011,
};

const max_horizontal_speed_sp = 0x0120;
const acceleration_sp = 0x000C;
const stop_deceleration_sp = 0x0008;
const skid_deceleration_sp = 0x0028;

const gravity_hold_sp = 0x0018;
const gravity_release_sp = 0x0030;
const max_hold_vertical_speed_sp = 0x0218;
const max_release_vertical_speed_sp = 0x0230;

const jump_force_sp = [_]i32{
    0x0268, // 0x0000
    0x0278, // 0x0040
    0x0290, // 0x0080
    0x02A0, // 0x00C0
    0x02B8, // 0x0100
    0x02C8, // 0x0140
    0x02E0, // 0x0180
};

const State = enum {
    on_ground,
    air,
};

const sprite_offset_sp = Vec2.init(-0x0400, -0x0800);

const hitbox_horizontal_extent_sp = 0x0400;
const hitbox_height_sp = 0x0800;

pub var position_sp = Vec2.init(0x5000, 0x1800);
pub var speed_sp = Vec2.inits(0);
pub var state: State = .on_ground;
pub var platform_hspeed_sp: i32 = 0;

pub var sprite_hflip = false;
pub var last_jump = false;

fn currentJumpForcesp() i32 {
    const speed_abs_x_sp = std.math.absCast(speed_sp.x);

    const index = std.math.min(speed_abs_x_sp / 0x0040, jump_force_sp.len - 1);
    return jump_force_sp[index];
}

fn abs(x: i32) i32 {
    return if (x > 0) x else -%x;
}

fn sgn(x: i32) i32 {
    return @as(i32, @boolToInt(x != 0)) | (x >> 31);
}

pub fn update() void {
    const left = w4.gamepads[0].left;
    const right = w4.gamepads[0].right;
    //const up = w4.gamepads[0].up;
    //const down = w4.gamepads[0].down;
    const jump = w4.gamepads[0].z and !last_jump;

    const dx = @as(i32, @boolToInt(right)) - @as(i32, @boolToInt(left));

    // state transitions

    if (state == .on_ground and jump) {
        speed_sp.y = -currentJumpForcesp();
        state = .air;
    }

    switch (state) {

        // --- GROUND MOVEMENT -------------------------------------------------

        .on_ground => {

            // directional input
            if (dx != 0) {
                sprite_hflip = dx < 0;

                const hspeed_rel = dx * speed_sp.x;
                const target_speed_abs = max_horizontal_speed_sp;

                // skid accelerate to target_speed_abs
                if (hspeed_rel < 0) {
                    speed_sp.x = dx * std.math.min(hspeed_rel + skid_deceleration_sp, target_speed_abs);
                }
                // accelerate to target_speed_abs
                else if (hspeed_rel <= target_speed_abs) {
                    speed_sp.x = dx * std.math.min(hspeed_rel + acceleration_sp, target_speed_abs);
                }
                // decelerate to target_speed_abs
                else {
                    speed_sp.x = dx * std.math.max(hspeed_rel - stop_deceleration_sp, target_speed_abs);
                }
            }
            // neutral input
            else {
                const hspeed_abs = abs(speed_sp.x);
                const hspeed_sgn = sgn(speed_sp.x);

                speed_sp.x = hspeed_sgn * std.math.max(hspeed_abs - stop_deceleration_sp, 0);
            }

            moveAndConstrainHorizontally();

            // detach check

            const y_tile = @divFloor(position_sp.y, level.tile_size_sp);

            const x_tile_left = std.math.max(@divFloor(position_sp.x - hitbox_horizontal_extent_sp, level.tile_size_sp), 0);
            const x_tile_right = std.math.min(@divFloor(position_sp.x + hitbox_horizontal_extent_sp - 1, level.tile_size_sp), level.width - 1);

            // NOTE We shouldn't be on ground in the first place when y_tile >= level.height
            // Check anyway for safety
            if (y_tile < level.height) {
                var still_on_ground = false;
                var x = x_tile_left;
                while (x <= x_tile_right) : (x += 1) {
                    const tile_id = level.at(x, y_tile);
                    if (tile_id == 0) {
                        continue;
                    }

                    still_on_ground = true;
                }

                if (!still_on_ground) {
                    state = .air;
                }
            }
        },

        // --- AIR MOVEMENT ----------------------------------------------------

        .air => {
            const hold = w4.gamepads[0].z;

            // NOTE Same as ground movement, except ignoring neutral input
            if (dx != 0) {
                sprite_hflip = dx < 0;

                const hspeed_rel = dx * speed_sp.x;
                const target_speed_abs = max_horizontal_speed_sp;

                // skid accelerate to target_speed_abs
                if (hspeed_rel < 0) {
                    speed_sp.x = dx * std.math.min(hspeed_rel + skid_deceleration_sp, target_speed_abs);
                }
                // accelerate to target_speed_abs
                else if (hspeed_rel <= target_speed_abs) {
                    speed_sp.x = dx * std.math.min(hspeed_rel + acceleration_sp, target_speed_abs);
                }
                // decelerate to target_speed_abs
                else {
                    speed_sp.x = dx * std.math.max(hspeed_rel - stop_deceleration_sp, target_speed_abs);
                }
            }

            const gravity_sp: i32 = if (hold) gravity_hold_sp else gravity_release_sp;
            const max_vertical_speed_sp: i32 = if (hold) max_hold_vertical_speed_sp else max_release_vertical_speed_sp;

            speed_sp.y = std.math.min(speed_sp.y + gravity_sp, max_vertical_speed_sp);

            moveAndConstrainHorizontally();

            if (speed_sp.y > 0) {
                const y_tile = @divFloor(position_sp.y - 1, level.tile_size_sp);
                const y_tile_next = @divFloor(position_sp.y + speed_sp.y, level.tile_size_sp);

                // crossing tiles, possibility of collision
                if (y_tile_next > y_tile) {
                    const x_tile_left = std.math.max(@divFloor(position_sp.x - hitbox_horizontal_extent_sp, level.tile_size_sp), 0);
                    const x_tile_right = std.math.min(@divFloor(position_sp.x + hitbox_horizontal_extent_sp - 1, level.tile_size_sp), level.width - 1);

                    var y = y_tile + 1;
                    while (y <= y_tile_next) : (y += 1) {
                        if (y >= level.height) {
                            // TODO Die?
                            break;
                        }

                        var x = x_tile_left;
                        while (x <= x_tile_right) : (x += 1) {
                            const tile_id = level.at(x, y);
                            if (tile_id == 0) {
                                continue;
                            }

                            speed_sp.y = 0;
                            position_sp.y = y * level.tile_size_sp;
                            state = .on_ground;
                        }
                    }
                }
            } else if (speed_sp.y < 0) {
                const y_tile = @divFloor(position_sp.y - hitbox_height_sp, level.tile_size_sp);
                const y_tile_next = @divFloor(position_sp.y - hitbox_height_sp + speed_sp.y, level.tile_size_sp);

                // crossing tiles, possibility of collision
                if (y_tile_next < y_tile) {
                    const x_tile_left = std.math.max(@divFloor(position_sp.x - hitbox_horizontal_extent_sp, level.tile_size_sp), 0);
                    const x_tile_right = std.math.min(@divFloor(position_sp.x + hitbox_horizontal_extent_sp - 1, level.tile_size_sp), level.width - 1);

                    var y = y_tile - 1;
                    while (y >= y_tile_next) : (y -= 1) {
                        if (y < 0) {
                            speed_sp.y = 0;
                            position_sp.y = hitbox_height_sp;
                            break;
                        }

                        var x = x_tile_left;
                        while (x <= x_tile_right) : (x += 1) {
                            const tile_id = level.at(x, y);
                            if (tile_id == 0) {
                                continue;
                            }

                            speed_sp.y = 0;
                            position_sp.y = (y + 1) * level.tile_size_sp + hitbox_height_sp;
                        }
                    }
                }
            }

            position_sp.y += speed_sp.y;
        },
    }

    last_jump = w4.gamepads[0].z;
}

fn moveAndConstrainHorizontally() void {
    var horizontal_movement_sp = speed_sp.x + platform_hspeed_sp;

    if (horizontal_movement_sp == 0) {
        return;
    }

    const sx = if (horizontal_movement_sp > 0) @as(i32, 1) else @as(i32, -1);
    const ox = if (horizontal_movement_sp > 0) @as(i32, -1) else @as(i32, 0);
    const dx = if (horizontal_movement_sp > 0) @as(i32, 0) else @as(i32, 1);
    const x_bound_tl = if (horizontal_movement_sp > 0) @as(i32, level.width) else @as(i32, -1);
    const x_bound_sp = if (horizontal_movement_sp > 0) @as(i32, level.width * level.tile_size_sp) else @as(i32, 0);

    const x_tile = @divFloor(position_sp.x + sx * hitbox_horizontal_extent_sp + ox, level.tile_size_sp);
    const x_tile_next = @divFloor(position_sp.x + sx * hitbox_horizontal_extent_sp + horizontal_movement_sp + ox, level.tile_size_sp);

    const y_tile_top = std.math.max(@divFloor(position_sp.y - hitbox_height_sp, level.tile_size_sp), 0);
    const y_tile_bottom = std.math.min(@divFloor(position_sp.y - 1, level.tile_size_sp), level.width - 1);

    var x = x_tile + sx;
    while (x != x_tile_next + sx) : (x += sx) {
        if (x == x_bound_tl) {
            speed_sp.x = sx * std.math.min(sx * speed_sp.x, 0);
            horizontal_movement_sp = 0;
            position_sp.x = x_bound_sp - sx * hitbox_horizontal_extent_sp;
            break;
        }

        var collided = false;

        var y = y_tile_top;
        while (y <= y_tile_bottom) : (y += 1) {
            const tile_id = level.at(x, y);
            if (tile_id == 0) {
                continue;
            }

            speed_sp.x = sx * std.math.min(sx * speed_sp.x, 0);
            horizontal_movement_sp = 0;
            position_sp.x = (x + dx) * level.tile_size_sp - sx * hitbox_horizontal_extent_sp;
            collided = true; // NOTE We want to break only after checking all y coordinates for current x
        }

        if (collided) {
            break;
        }
    }

    position_sp.x += horizontal_movement_sp;
}

pub fn draw() void {
    const sprite_sp = position_sp.add(sprite_offset_sp);
    const sprite_px = sprite_sp.adds(128).div(256);

    //const screen_px = sprite_px.add(camera.getOffsetPX());
    const screen_px = sprite_px;

    w4.draw_colors.color1 = 2;
    w4.draw_colors.color2 = 0;
    w4.blit(&sprite, screen_px, 8, 8, .{});
}
