const w4 = @import("wasm4.zig");

pub const Sfx = enum {
    jump,
    shoot,
    hit,
    explode,
};

var pulse1_timer: u8 = 0;
var pulse2_timer: u8 = 0;
var triangle_timer: u8 = 0;
var noise_timer: u8 = 0;

pub fn channelTaken(channel: w4.Channel) bool {
    switch (channel) {
        .pulse1 => return pulse1_timer > 0,
        .pulse2 => return pulse2_timer > 0,
        .triangle => return triangle_timer > 0,
        .noise => return noise_timer > 0,
    }
}

pub fn update() void {
    pulse1_timer -|= 1;
    pulse2_timer -|= 1;
    triangle_timer -|= 1;
    noise_timer -|= 1;
}

pub fn play(sfx: Sfx) void {
    switch (sfx) {
        .jump => {
            w4.tone(
                .{.start = 270, .end = 870},
                w4.adsr(0, 0, 15, 2),
                .{.sustain = 100},
                .{.channel = .triangle},
            );
            triangle_timer = 17;
        },
        .shoot => {
            w4.tone(
                .{.start = 860, .end = 150},
                w4.adsr(0, 0, 6, 5),
                .{.sustain = 100},
                .{.channel = .pulse2, .duty = .@"1/8"},
            );
            pulse2_timer = 11;
        },
        .hit => {
            w4.tone(
                .{.start = 550, .end = 60},
                w4.adsr(0, 0, 6, 2),
                .{.sustain = 100},
                .{.channel = .noise},
            );
            noise_timer = 8;
        },
        .explode => {
            w4.tone(
                .{.start = 150, .end = 250},
                w4.adsr(0, 0, 20, 20),
                .{.sustain = 100},
                .{.channel = .noise},
            );
            noise_timer = 40;
        },
    }
}
