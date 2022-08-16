const std = @import("std");
const w4 = @import("wasm4.zig");

const level = @import("level.zig");
const player = @import("player.zig");

const Vec2 = @import("Vec2.zig");

pub const extent_px: i32 = @divExact(w4.screen_size, 2);
pub const extent_tl: i32 = extent_px * 8;
pub const extent_sp: i32 = extent_tl * 256;

pub const ease: f32 = 0.2;

pub var center_sp = Vec2.inits(80 * 256);

pub fn getOffsetPX() Vec2 {
    return getCenterPX().nadds(80);
}

/// Represents the pixel at position (80, 80) in screen-space, i.e. one to the
/// bottom-right of the exact screen center.
pub fn getCenterPX() Vec2 {
    return center_sp.adds(128).div(256);
}

/// Bounds are inclusive.
pub fn getBoundsTL(min: *Vec2, max: *Vec2) void {
    const center_px = getCenterPX();

    min.* = center_px.subs(extent_px).div(8);
    max.* = center_px.adds(extent_px - 1).div(8);
}

pub fn update() void {
    const chunk_x = @divFloor(player.position_sp.x, level.chunk_width_sp);
    const chunk_y = @divFloor(player.position_sp.y, level.chunk_height_sp);

    const desired_center_sp_x = @divFloor((2 * chunk_x + 1) * level.chunk_width_sp, 2);
    const desired_center_sp_y = @divFloor((2 * chunk_y + 1) * level.chunk_width_sp, 2);

    const desired_center_sp = Vec2.init(desired_center_sp_x, desired_center_sp_y);

    center_sp = Vec2.lerp(center_sp, desired_center_sp, 1 - @exp(-ease));
}
