const std = @import("std");
const w4 = @import("wasm4.zig");

const level = @import("level.zig");
const player = @import("player.zig");

const Vec2 = @import("Vec2.zig");

pub const extent_px = Vec2.init(80, 76);
pub const ease: f32 = 0.2;

pub var center_sp = Vec2.init(240, 76).mul(256);

pub fn getOffsetPX() Vec2 {
    return getCenterPX().nadd(Vec2.init(80, 84));
}

/// Represents the pixel at position (80, 84) in screen-space, i.e. one to the
/// bottom-right of the center of the level view.
pub fn getCenterPX() Vec2 {
    return center_sp.adds(128).div(256);
}

/// Bounds are inclusive.
pub fn getBoundsTL(min: *Vec2, max: *Vec2) void {
    const center_px = getCenterPX();

    min.* = center_px.sub(extent_px).div(8);
    max.* = center_px.add(extent_px.subs(1)).div(8);
}

pub fn update() void {
    const chunk_pos = player.position_sp.sub(Vec2.init(0, 1)).unscale(level.chunk_size_sp);
    const desired_center_sp = chunk_pos.mul(2).adds(1).scale(level.chunk_size_sp).div(2);
    center_sp = Vec2.lerp(center_sp, desired_center_sp, 1 - @exp(-ease));
}
