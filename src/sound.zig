const w4 = @import("wasm4.zig");

pub const Sfx = enum {
    jump,
    shoot,
};

pub fn play(sfx: Sfx) void {
    switch (sfx) {
        .jump => {
            w4.tone(
                .{.start = 270, .end = 870},
                w4.adsr(0, 0, 15, 2),
                .{.sustain = 100},
                .{.channel = .triangle},
            );
        },
        .shoot => {
            w4.tone(
                .{.start = 860, .end = 150},
                w4.adsr(0, 0, 6, 5),
                .{.sustain = 100},
                .{.channel = .pulse2, .duty = .@"1/8"},
            );
        },
    }
}
