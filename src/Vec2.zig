const std = @import("std");

x: i32,
y: i32,

const Vec2 = @This();

pub const zero = inits(0);
pub const one = inits(1);
pub const right = init(1, 0);
pub const down = init(0, 1);
pub const left = init(-1, 0);
pub const up = init(0, -1);

pub fn inits(s: i32) Vec2 { return Vec2{ .x = s, .y = s}; }
pub fn init(x: i32, y: i32) Vec2 { return Vec2{ .x = x, .y = y }; }

pub fn lengthSquared(a: Vec2) i32 { return a.x * a.x + a.y * a.y; }

pub fn dot(a: Vec2, b: Vec2) i32 { return a.x * b.x + a.y * b.y; }
pub fn cross(a: Vec2, b: Vec2) i32 { return a.x * b.y - a.y * b.x; }
pub fn lerp(a: Vec2, b: Vec2, k: f32) Vec2 {
    return init(
        @floatToInt(i32, @round(@intToFloat(f64, a.x) * (1 - @as(f64, k)) + @intToFloat(f64, b.x) * @as(f64, k))),
        @floatToInt(i32, @round(@intToFloat(f64, a.y) * (1 - @as(f64, k)) + @intToFloat(f64, b.y) * @as(f64, k))),
    );
}

pub fn min(a: Vec2, b: Vec2) Vec2 { return init(std.math.min(a.x, b.x), std.math.min(a.y, b.y)); }
pub fn max(a: Vec2, b: Vec2) Vec2 { return init(std.math.max(a.x, b.x), std.math.max(a.y, b.y)); }

pub fn add(a: Vec2, b: Vec2) Vec2 { return init(a.x + b.x, a.y + b.y); }
pub fn nadd(a: Vec2, b: Vec2) Vec2 { return init(-a.x + b.x, -a.y + b.y); }
pub fn sub(a: Vec2, b: Vec2) Vec2 { return init(a.x - b.x, a.y - b.y); }
pub fn nsub(a: Vec2, b: Vec2) Vec2 { return init(-a.x - b.x, -a.y - b.y); }
pub fn adds(a: Vec2, s: i32) Vec2 { return init(a.x + s, a.y + s); }
pub fn nadds(a: Vec2, s: i32) Vec2 { return init(-a.x + s, -a.y + s); }
pub fn subs(a: Vec2, s: i32) Vec2 { return init(a.x - s, a.y - s); }
pub fn nsubs(a: Vec2, s: i32) Vec2 { return init(-a.x - s, -a.y - s); }
pub fn mul(a: Vec2, k: i32) Vec2 { return init(a.x * k, a.y * k); }
pub fn mulf(a: Vec2, k: f32) Vec2 {
    return init(
        @floatToInt(i32, @round(@intToFloat(f64, a.x) * @as(f64, k))),
        @floatToInt(i32, @round(@intToFloat(f64, a.y) * @as(f64, k))),
    );
}
pub fn div(a: Vec2, k: i32) Vec2 { return init(@divFloor(a.x, k), @divFloor(a.y, k)); }
pub fn divf(a: Vec2, k: f32) Vec2 {
    return init(
        @floatToInt(i32, @round(@intToFloat(f64, a.x) / @as(f64, k))),
        @floatToInt(i32, @round(@intToFloat(f64, a.y) / @as(f64, k))),
    );
}
pub fn scale(a: Vec2, b: Vec2) Vec2 { return init(a.x * b.x, a.y * b.y); }
pub fn unscale(a: Vec2, b: Vec2) Vec2 { return init(@divFloor(a.x, b.x), @divFloor(a.y, b.y)); }
pub fn neg(a: Vec2) Vec2 { return init(-a.x, -a.y); }

pub fn equals(a: Vec2, b: Vec2) bool { return a.x == b.x and a.y == b.y; }
