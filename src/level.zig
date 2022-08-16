const std = @import("std");
const w4 = @import("wasm4.zig");

const camera = @import("camera.zig");
const player = @import("player.zig");

const Vec2 = @import("Vec2.zig");

pub const tile_size_px = 8;
pub const tile_size_sp = tile_size_px * 256;

const tiles = [5][8]u8{
    [_]u8{
        0b10101010,
        0b00000001,
        0b10000000,
        0b00000001,
        0b10000000,
        0b00000001,
        0b10000000,
        0b01010101,
    },
    [_]u8{
        0b00000001,
        0b00000001,
        0b01001001,
        0b00100101,
        0b00100101,
        0b01001001,
        0b00000001,
        0b00000001,
    },
    [_]u8{
        0b00000000,
        0b00100100,
        0b00011000,
        0b00000000,
        0b00100100,
        0b00011000,
        0b00000000,
        0b11111111,
    },
    [_]u8{
        0b10000000,
        0b10000000,
        0b10010010,
        0b10100100,
        0b10100100,
        0b10010010,
        0b10000000,
        0b10000000,
    },
    [_]u8{
        0b11111111,
        0b00000000,
        0b00011000,
        0b00100100,
        0b00000000,
        0b00011000,
        0b00100100,
        0b00000000,
    },
};

const tile_mapping: [256]u8 = blk: {
    var ret: [256]u8 = undefined;
    ret[' '] = 0;
    ret['X'] = 1;
    ret['>'] = 2;
    ret['v'] = 3;
    ret['<'] = 4;
    ret['^'] = 5;
    break :blk ret;
};

pub const chunk_width_tl = 20;
pub const chunk_height_tl = 20;
pub const chunk_size = chunk_width_tl * chunk_height_tl;
pub const chunk_width_px = chunk_width_tl * tile_size_px;
pub const chunk_height_px = chunk_height_tl * tile_size_px;
pub const chunk_width_sp = chunk_width_px * 256;
pub const chunk_height_sp = chunk_height_px * 256;
const chunks = [_]*const [chunk_size]u8{
    "XX                  " ++
    "XX                  " ++
    "XX                  " ++
    "XX                  " ++
    "XX                  " ++
    "XX                  " ++
    "XX                  " ++
    "XX                  " ++
    "XX                  " ++
    "XX                  " ++
    "XX                  " ++
    "XX                  " ++
    "XX                  " ++
    "XX                  " ++
    "XX                  " ++
    "XX                  " ++
    "XX                  " ++
    "XX                  " ++
    "XXXXXXXXXXXXXXXXXXXX" ++
    "XXXXXXXXXXXXXXXXXXXX"
    ,
    "      XXXXXXXXXXXXXX" ++
    "      XXXXXXXXXXXXXX" ++
    "       XXXXXXXXXXXXX" ++
    "        XXXXXXXXXXXX" ++
    "         XXXXXXXXXXX" ++
    "          XXXXXXXXXX" ++
    "           XXXXXXXXX" ++
    "            XXXXXXXX" ++
    "             XXXXXXX" ++
    "              XXXXXX" ++
    "               XXXXX" ++
    "                XXXX" ++
    "                 XXX" ++
    "                  XX" ++
    "                    " ++
    "                    " ++
    "                    " ++
    "   X            X   " ++
    "XXXX            XXXX" ++
    "XX                XX"
    ,
    "XXXXXXXXXXXXXXXXXXXX" ++
    "XXXXXXXXXXXXXXXXXXXX" ++
    "XXXXXXXXXXXXXXXXXXXX" ++
    "XXXXXXXXXXXXXXXXXXXX" ++
    "XXXXXXXXXXXXXXXXXXXX" ++
    "XXXXXXXXXXXXXXXXXXXX" ++
    "XXXXXXXXXXXXXXXXXXXX" ++
    "XXXXXXXXXXXXXXXXXXXX" ++
    "XXXXXXXXXXXXXXXXXXXX" ++
    "XXXXXXXXXXXXXXXXXXXX" ++
    "XXXXXXXXXXXXXXXXXXXX" ++
    "XXXXXXXXXXXXXXXXXXXX" ++
    "XXXXXXXXXXXXXXXXXXXX" ++
    "XXXXXXXXXXXXXXXXXXXX" ++
    "                    " ++
    "                    " ++
    "                    " ++
    "                    " ++
    "XXXXXXXXXXXXXXXXXXXX" ++
    "XXXXXXXXXXXXXXXXXXXX"
    ,
    "XXXXXXXXXXXXXXXXXXXX" ++
    "XXXXXXXXXXXXXXXXXXXX" ++
    "XX                XX" ++
    "XX                XX" ++
    "XX                XX" ++
    "XX                XX" ++
    "XX      XXXX      XX" ++
    "XX      XXXX      XX" ++
    "XX      XXXX      XX" ++
    "XX      XXXX      XX" ++
    "XX      XXXX      XX" ++
    "XX      XXXX      XX" ++
    "XX      XXXX      XX" ++
    "XX      XXXX      XX" ++
    "XX      XXXX      XX" ++
    "XX      XXXX      XX" ++
    "XX      XXXX      XX" ++
    "XX      XXXX      XX" ++
    "XX      XXXX      XX" ++
    "XX      XXXX      XX"
    ,
    "XX                XX" ++
    "XX                XX" ++
    "XX                XX" ++
    "XX                XX" ++
    "XX                XX" ++
    "XX                XX" ++
    "XX                XX" ++
    "XX                XX" ++
    "XX                XX" ++
    "XX                XX" ++
    "XX                XX" ++
    "XX                XX" ++
    "XX                XX" ++
    "XX                XX" ++
    "XX                XX" ++
    "XX                XX" ++
    "XX                XX" ++
    "XX                XX" ++
    "XX                XX" ++
    "XX                XX"
    ,
    "XXXXXXXXXXXXXXXXXXXX" ++
    "XXXXXXXXXXXXXXXXXXXX" ++
    "XX                  " ++
    "XX                  " ++
    "XX                  " ++
    "XX                  " ++
    "XX                XX" ++
    "XX                XX" ++
    "XX                XX" ++
    "XX                XX" ++
    "XX                XX" ++
    "XX                XX" ++
    "XX                XX" ++
    "XX                XX" ++
    "XX                XX" ++
    "XX                XX" ++
    "XX                XX" ++
    "XX                XX" ++
    "XXXXXXXXXXXXXXXXXXXX" ++
    "XXXXXXXXXXXXXXXXXXXX"
    ,
    "XX      XXXX      XX" ++
    "XX      XXXX      XX" ++
    "        XXXX      XX" ++
    "        XXXX      XX" ++
    "        XXXX      XX" ++
    "        XXXX      XX" ++
    "XXXX    XXXX      XX" ++
    "XX      XXXX      XX" ++
    "XX      XXXX      XX" ++
    "XX    XXXXXX      XX" ++
    "XX      XXXX      XX" ++
    "XX      XXXX      XX" ++
    "XXXX    XXXX      XX" ++
    "XX      XXXX      XX" ++
    "XX      XXXX        " ++
    "XX    XXXXXX        " ++
    "XX      XXXX        " ++
    "XX      XXXX        " ++
    "XXXX    XXXXXXXXXXXX" ++
    "XX      XXXXXXXXXXXX"
    ,
    "XX                XX" ++
    "XX                XX" ++
    "XX                XX" ++
    "XX                XX" ++
    "XX                XX" ++
    "XX                XX" ++
    "XX                XX" ++
    "XX                XX" ++
    "XX                XX" ++
    "XX                XX" ++
    "XX                XX" ++
    "XX                XX" ++
    "XX                XX" ++
    "XX                XX" ++
    "                    " ++
    "                    " ++
    "                    " ++
    "                    " ++
    "XXXXXXXXXXXXXXXXXXXX" ++
    "XXXXXXXXXXXXXXXXXXXX"
    ,
    "XXXXXXXXXXXXXXXXXXXX" ++
    "XXXXXXXXXXXXXXXXXXXX" ++
    "XXXXXXXXXXXXXXXXXXXX" ++
    "XXXXXXXXXXXXXXXXXXXX" ++
    "XXXXXXXXXXXXXXXXXXXX" ++
    "XXXXXXXXXXXXXXXXXXXX" ++
    "XXXXXXXXXXXXXXXXXXXX" ++
    "XXXXXXXXXXXXXXXXXXXX" ++
    "XXXXXXXXXXXXXXXXXXXX" ++
    "XXXXXXXXXXXXXXXXXXXX" ++
    "XXXXXXXXXXXXXXXXXXXX" ++
    "XXXXXXXXXXXXXXXXXXXX" ++
    "XXXXXXXXXXXXXXXXXXXX" ++
    "XXXXXXXXXXXXXXXXXXXX" ++
    "                    " ++
    "                    " ++
    "                    " ++
    "                    " ++
    "XXXXXXXXXXXXXXXXXXXX" ++
    "XXXXXXXXXXXXXXXXXXXX"
    ,
    "XXXXXXXXXXXXXXXXXXXX" ++
    "XX                XX" ++
    "XX                XX" ++
    "XX                XX" ++
    "XX                XX" ++
    "XXXXX         XX  XX" ++
    "XX            XX  XX" ++
    "XX         XXXXX  XX" ++
    "XX            XX  XX" ++
    "XXXXX         XX  XX" ++
    "XX            XX  XX" ++
    "XX         XXXXX  XX" ++
    "XX            XX  XX" ++
    "XXXXX         XX  XX" ++
    "              XX  XX" ++
    "           XXXXX  XX" ++
    "              XX  XX" ++
    "              XX  XX" ++
    "XXXXXXXXXXXXXXXX  XX" ++
    "XXXXXXXXXXXXXXXX  XX"
    ,
    "XX      XXXXXXXXXXXX" ++
    "XX    XXXXXXXXXXXXXX" ++
    "XX              XXXX" ++
    "XX               XXX" ++
    "XXXX    XXXX      XX" ++
    "XX                XX" ++
    "XX   X        X   XX" ++
    "XX                XX" ++
    "XX                XX" ++
    "XX                XX" ++
    "XX  X          X  XX" ++
    "XX                XX" ++
    "XX                XX" ++
    "XX                XX" ++
    "XX   X        X   XX" ++
    "XX                XX" ++
    "XXX     XXXX     XXX" ++
    "XXXX            XXXX" ++
    "XXXXXXX      XXXXXXX" ++
    "XXXXXXXX    XXXXXXXX"
    ,
    "XXXXXXXXXXXXXXXXXXXX" ++
    "XXXXXXXXXXXXXXXXXXXX" ++
    "XX                  " ++
    "XX                  " ++
    "XX                  " ++
    "XX                  " ++
    "XX                XX" ++
    "XX                XX" ++
    "XX                XX" ++
    "XX                XX" ++
    "XX                XX" ++
    "XX                XX" ++
    "XX                XX" ++
    "XX                XX" ++
    "XX                XX" ++
    "XX                XX" ++
    "XX                XX" ++
    "XX                XX" ++
    "XX                XX" ++
    "XX       XX       XX"
    ,
    "XXXXXXXXXXXXXXXXXXXX" ++
    "XXXXXXXXXXXXXXXXXXXX" ++
    "                  XX" ++
    "                  XX" ++
    "                  XX" ++
    "                  XX" ++
    "XX                XX" ++
    "XXX              XXX" ++
    "XXXX            XXXX" ++
    "XXXXXXXXXXXXXXXXXXXX" ++
    "XXXXXXXXXXXXXXXXXXXX" ++
    "XXXXXXXXXXXXXXXXXXXX" ++
    "XXXXXXXXXXXXXXXXXXXX" ++
    "XXXXXXXXXXXXXXXXXXXX" ++
    "XXXXXXXXXXXXXXXXXXXX" ++
    "XXXXXXXXXXXXXXXXXXXX" ++
    "XXXXXXXXXXXXXXXXXXXX" ++
    "XXXXXXXXXXXXXXXXXXXX" ++
    "XXXXXXXXXXXXXXXXXXXX" ++
    "XXXXXXXXXXXXXXXXXXXX"
    ,
    "XXXXXXXXXXXXXXXX  XX" ++
    "XXXXXXXXXXXXXXXX  XX" ++
    "XXXX              XX" ++
    "XXX               XX" ++
    "XX      XXXX      XX" ++
    "XX                XX" ++
    "XX   X        X   XX" ++
    "XX                XX" ++
    "XX                XX" ++
    "XX                XX" ++
    "XX  X          X  XX" ++
    "XX                XX" ++
    "XX                XX" ++
    "XX                XX" ++
    "XX   X        X   XX" ++
    "XX                XX" ++
    "XXX     XXXX     XXX" ++
    "XXXX            XXXX" ++
    "XXXXXXX      XXXXXXX" ++
    "XXXXXXXX    XXXXXXXX"
    ,
    "XXXXXXXX    XXXXXXXX" ++
    "XXXXXXXXX  XXXXXXXXX" ++
    "XXX              XXX" ++
    "XX            X   XX" ++
    "XX   X   X        XX" ++
    "XX                XX" ++
    "XX           X    XX" ++
    "XX       X        XX" ++
    "XX  X            XXX" ++
    "XX                XX" ++
    "XX   X        X   XX" ++
    "XX        X       XX" ++
    "XX                XX" ++
    "XX      X         XX" ++
    "XX            X     " ++
    "XX   X              " ++
    "XX       X          " ++
    "XXX                 " ++
    "XXXXXXXXXXXXXXXXXXXX" ++
    "XXXXXXXXXXXXXXXXXXXX"
    ,
    "XX                XX" ++
    "XX                XX" ++
    "XX  XX            XX" ++
    "XX                XX" ++
    "XX                XX" ++
    "XX       XX       XX" ++
    "XX                XX" ++
    "XX                XX" ++
    "XX            XX  XX" ++
    "XX                XX" ++
    "XX                XX" ++
    "XX       XX       XX" ++
    "XX                XX" ++
    "XX                XX" ++
    "    XX              " ++
    "                    " ++
    "                    " ++
    "                    " ++
    "XXXXXXXXXXXXXXXXXXXX" ++
    "XXXXXXXXXXXXXXXXXXXX"
    ,
    "XXXXXXXXXXXXXXXXXXXX" ++
    "XXXXXXXXXXXXXXXXXXXX" ++
    "XXXXXXXXXXXXXXXXXXXX" ++
    "XXXXXXXXXXXXXXXXXXXX" ++
    "XXXXXXXXXXXXXXXXXXXX" ++
    "XXXXXXXXXXXXXXXXXXXX" ++
    "XXXXXXXXXXXXXXXXXXXX" ++
    "XXXXXXXXXXXXXXXXXXXX" ++
    "XXXXXXXXXXXXXXXXXXXX" ++
    "XXXXXXXXXXXXXXXXXXXX" ++
    "XXXXXXXXXXXXXXXXXXXX" ++
    "XXXXXXXXXXXXXXXXXXXX" ++
    "XXXXXXXXXXXXXXXXXXXX" ++
    "XXXXXXXXXXXXXXXXXXXX" ++
    "                    " ++
    "                    " ++
    "                    " ++
    "                    " ++
    "XXXXXXXXXXXXXXXXXXXX" ++
    "XXXXXXXXXXXXXXXXXXXX"
    ,
    "XXXXXXXX    XXXXXXXX" ++
    "XXXXXXXX    XXXXXXXX" ++
    "XXXXXXXX    XXXXXXXX" ++
    "XXXXXXXX    XXXXXXXX" ++
    "XXXXXXXX    XXXXXXXX" ++
    "XXXXXXXX    XXXXXXXX" ++
    "XXXXXXXX    XXXXXXXX" ++
    "XXXXXXXX    XXXXXXXX" ++
    "XX                XX" ++
    "XX                XX" ++
    "XX                XX" ++
    "XX                XX" ++
    "XX    XXXXXXXX    XX" ++
    "XX    XXXXXXXX    XX" ++
    "                  XX" ++
    "                  XX" ++
    "                  XX" ++
    "                  XX" ++
    "XXXXXXXXXXXXXXXXXXXX" ++
    "XXXXXXXXXXXXXXXXXXXX"
};

const map_width = 5;
const map_height = 5;
const map = [_]u8{
    0,  1,  2,  3, 255,
    0,  4,  5,  0,   0,
    6,  7,  8,  9,  10,
    0, 11, 12, 13,  14,
    0, 15, 16, 17,  18,
};

pub fn atChunk(chunk_x: i32, chunk_y: i32, local_x: i32, local_y: i32) u8 {
    const chunk_id = map[@intCast(usize, chunk_y * map_width + chunk_x)];

    const chunk = chunks[chunk_id - 1];
    const tile_char = chunk[@intCast(usize, local_y * chunk_width_tl + local_x)];
    const tile_id = tile_mapping[tile_char];
    return tile_id;
}

pub fn at(x: i32, y: i32) u8 {
    const chunk_x = @divFloor(x, chunk_width_tl);
    const chunk_y = @divFloor(y, chunk_height_tl);

    if (chunk_x < 0 or chunk_x >= map_width) {
        return 1;
    }
    if (chunk_y < 0 or chunk_y >= map_height) {
        return 1;
    }

    const chunk_id = map[@intCast(usize, chunk_y * map_width + chunk_x)];
    if (chunk_id == 0 or chunk_id == 255) {
        return 1;
    }

    const local_x = x - chunk_x * chunk_width_tl;
    const local_y = y - chunk_y * chunk_height_tl;

    const chunk = chunks[chunk_id - 1];
    const tile_char = chunk[@intCast(usize, local_y * chunk_width_tl + local_x)];
    const tile_id = tile_mapping[tile_char];
    return tile_id;
}

pub fn draw() void {
    w4.draw_colors.color1 = 4;
    w4.draw_colors.color2 = 2;

    var min_tl: Vec2 = undefined;
    var max_tl: Vec2 = undefined;
    camera.getBoundsTL(&min_tl, &max_tl);

    const offset_px = camera.getOffsetPX();

    var y: i32 = min_tl.y;
    while (y <= max_tl.y) : (y += 1) {
        var x: i32 = min_tl.x;
        while (x <= max_tl.x) : (x += 1) {
            const tile_id = at(x, y);
            if (tile_id == 0) continue;
            w4.blit(&tiles[tile_id - 1], Vec2.init(x, y).mul(8).add(offset_px), tile_size_px, tile_size_px, .{});
        }
    }
}
