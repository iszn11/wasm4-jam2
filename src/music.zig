const w4 = @import("wasm4.zig");

const sound = @import("sound.zig");

// Because of rounding to integer Hz, entire music is out of tune. After very
// little research, the following tuning was found to result in the least amount
// of out of tune pitches (according to equal temperament).

// C2 = 65.09 Hz
// A4 ≈ 437.872 Hz

const tuning = [61]u16 {
    65,   // C2  -2.4
    69,   // C#2 +1.0
    73,   // D2  -1.4
    77,   // D#2 -9.1 (!)
    82,   // E2  -0.2
    87,   // F2  +2.3
    92,   // F#2 -1.0
    98,   // G2  +8.4 (!)
    103,  // G#2 -5.4 (!)
    109,  // A2  -7.4 (!)
    116,  // A#2 +0.3
    123,  // B2  +1.8
    130,  // C3  -2.4
    138,  // C#3 +1.0
    146,  // D3  -1.4
    155,  // D#3 +2.1
    164,  // E3  -0.2
    174,  // F3  +2.3
    184,  // F#3 -1.0
    195,  // G3  -0.4
    207,  // G#3 +2.9
    219,  // A3  +0.5
    232,  // A#3 +0.3
    246,  // B3  +1.8
    260,  // C4  -2.4
    276,  // C#4 +1.0
    292,  // D4  -1.4
    310,  // D#4 +2.1
    328,  // E4  -0.2
    348,  // F4  +2.3
    368,  // F#4 -1.0
    390,  // G4  -0.4
    413,  // G#4 -1.2
    438,  // A4  +0.5
    464,  // A#4 +0.3
    491,  // B4  -1.7
    521,  // C5  +0.9
    552,  // C#5 +1.0
    584,  // D5  -1.4
    619,  // D#5 -0.7
    656,  // E5  -0.2
    695,  // F5  -0.2
    736,  // F#5 -1.0
    780,  // G5  -0.4
    827,  // G#5 +0.9
    876,  // A5  +0.5
    928,  // A#5 +0.3
    983,  // B5  +0.0
    1041, // C6  -0.7
    1103, // C#6 -0.6
    1169, // D6  +0.0
    1238, // D#6 -0.7
    1312, // E6  -0.2
    1390, // F6  -0.2
    1473, // F#6 +0.2
    1560, // G6  -0.4
    1653, // G#6 -0.2
    1751, // A6  -0.5
    1856, // A#6 +0.3
    1966, // B6  +0.0
    2083, // C7  +0.1
};

const C2 = 0;
const Ch2 = 1;
const D2 = 2;
const Dh2 = 3;
const E2 = 4;
const F2 = 5;
const Fh2 = 6;
const G2 = 7;
const Gh2 = 8;
const A2 = 9;
const Ah2 = 10;
const B2 = 11;
const C3 = 12;
const Ch3 = 13;
const D3 = 14;
const Dh3 = 15;
const E3 = 16;
const F3 = 17;
const Fh3 = 18;
const G3 = 19;
const Gh3 = 20;
const A3 = 21;
const Ah3 = 22;
const B3 = 23;
const C4 = 24;
const Ch4 = 25;
const D4 = 26;
const Dh4 = 27;
const E4 = 28;
const F4 = 29;
const Fh4 = 30;
const G4 = 31;
const Gh4 = 32;
const A4 = 33;
const Ah4 = 34;
const B4 = 35;
const C5 = 36;
const Ch5 = 37;
const D5 = 38;
const Dh5 = 39;
const E5 = 40;
const F5 = 41;
const Fh5 = 42;
const G5 = 43;
const Gh5 = 44;
const A5 = 45;
const Ah5 = 46;
const B5 = 47;
const C6 = 48;
const Ch6 = 49;
const D6 = 50;
const Dh6 = 51;
const E6 = 52;
const F6 = 53;
const Fh6 = 54;
const G6 = 55;
const Gh6 = 56;
const A6 = 57;
const Ah6 = 58;
const B6 = 59;
const C7 = 60;

const Db2 = 1;
const Eb2 = 3;
const Gb2 = 6;
const Ab2 = 8;
const Bb2 = 10;
const Db3 = 13;
const Eb3 = 15;
const Gb3 = 18;
const Ab3 = 20;
const Bb3 = 22;
const Db4 = 25;
const Eb4 = 27;
const Gb4 = 30;
const Ab4 = 32;
const Bb4 = 34;
const Db5 = 37;
const Eb5 = 39;
const Gb5 = 42;
const Ab5 = 44;
const Bb5 = 46;
const Db6 = 49;
const Eb6 = 51;
const Gb6 = 54;
const Ab6 = 56;
const Bb6 = 58;

const Note = union (enum) {
    note: struct {
        pitch: u8,
        length: u8,
    },

    pause: u8,
    volume: w4.Volume,
    release: u8,
};

fn n(pitch: u8, length: u8) Note {
    return .{ .note = .{ .pitch = pitch, .length = length } };
}

fn p(length: u8) Note {
    return .{ .pause = length };
}

fn v(sustain: u8) Note {
    return .{ .volume = .{.sustain = sustain} };
}

fn r(length: u8) Note {
    return .{ .release = length };
}

const Frame = []Note;

const FrameIndices = struct {
    pulse1: u8,
    pulse2: u8,
    triangle: u8,
    noise: u8,
};

fn fi(p1: u8, p2: u8, tr: u8, no: u8) FrameIndices {
    return .{ .pulse1 = p1, .pulse2 = p2, .triangle = tr, .noise = no };
}

const MusicTrack = struct {
    beat_length: u8, // beat length in game frames
    frame_length: u8, // music frame length in beats
    loop_frame: u8, // frame index to start of loop

    frames: []const []const Note,
    track: []const FrameIndices,
};

pub const overworld_music = MusicTrack{
    .beat_length = 8,
    .frame_length = 16, // time signature of 16/16
    .loop_frame = 0,

    .frames = &[_][]const Note{
        &[_]Note{ p(16) },

        &[_]Note{ r(16), n(C3, 3), p(1), n(G3, 3), p(1), n(C4, 3), p(5) },       // 1
        &[_]Note{ r(16), n(Ab2, 3), p(1), n(Eb3, 3), p(1), n(Ab3, 3), p(5) },    // 2
        &[_]Note{ r(16), n(G2, 3), p(1), n(D3, 3), p(1), n(G3, 3), p(5) },       // 3

        &[_]Note{ v(80), r(4), p(12), n(C4, 2), n(D4, 2) },                      // 4
        &[_]Note{ v(80), r(64), n(Eb4, 16) },                                    // 5
        &[_]Note{ v(80), r(64), n(D4, 12), r(4), n(C4, 2), n(D4, 2) },           // 6
        &[_]Note{ v(80), r(64), n(D4, 16) },                                     // 7
        &[_]Note{ v(80), r(64), n(C4, 16) },                                     // 8

    },

    .track = &[_]FrameIndices {
        fi(0, 0, 1, 0),
        fi(0, 0, 1, 0),
        fi(0, 0, 2, 0),
        fi(4, 0, 3, 0),

        fi(5, 0, 1, 0),
        fi(4, 0, 1, 0),
        fi(5, 0, 2, 0),
        fi(6, 0, 3, 0),

        fi(5, 0, 1, 0),
        fi(4, 0, 1, 0),
        fi(5, 0, 2, 0),
        fi(7, 0, 3, 0),

        fi(8, 0, 1, 0),
        fi(0, 0, 1, 0),
        fi(0, 0, 2, 0),
        fi(0, 0, 3, 0),
    },
};

pub const boss_music = MusicTrack{
    .beat_length = 4,
    .frame_length = 20, // time signature of 20/16 (6+6+4+4)
    .loop_frame = 4,

    .frames = &[_][]const Note{
        &[_]Note{ p(20) },

        &[_]Note{ n(C3, 1), p(5), n(C3, 1), p(5), n(C3, 1), p(3), n(C3, 3), p(1) },           // 1
        &[_]Note{ n(Ab2, 1), p(5), n(Ab2, 1), p(5), n(Ab2, 1), p(3), n(Ab2, 3), p(1) },       // 2
        &[_]Note{ n(G2, 1), p(5), n(G2, 1), p(5), n(G2, 1), p(3), n(G2, 3), p(1) },           // 3
        &[_]Note{ n(F2, 1), p(5), n(F2, 1), p(5), n(F2, 1), p(3), n(F2, 3), p(1) },           // 4
        &[_]Note{ n(B2, 1), p(5), n(B2, 1), p(5), n(B2, 1), p(3), n(B2, 3), p(1) },           // 5

        &[_]Note{ n(C4, 1), p(5), n(C4, 1), p(5), n(C4, 1), p(3), n(C4, 3), p(1) },           // 6
        &[_]Note{ n(Eb3, 1), p(5), n(Eb3, 1), p(5), n(G3, 1), p(3), n(G3, 3), p(1) },         // 7

        &[_]Note{ n(C4, 1), p(5), n(C4, 1), p(5), n(C4, 1), p(3), n(C4, 3), p(1) },           // 8
        &[_]Note{ n(G3, 1), p(5), n(G3, 1), p(5), n(G3, 1), p(3), n(G3, 3), p(1) },           // 9

        &[_]Note{ n(Bb3, 1), p(5), n(Bb3, 1), p(5), n(Bb3, 1), p(3), n(Bb3, 3), p(1) },       // 10
        &[_]Note{ n(F3, 1), p(5), n(F3, 1), p(5), n(F3, 1), p(3), n(F3, 3), p(1) },           // 11

        &[_]Note{ n(Ab3, 1), p(5), n(Ab3, 1), p(5), n(Ab3, 1), p(3), n(Ab3, 3), p(1) },       // 12
        &[_]Note{ n(F3, 1), p(5), n(F3, 1), p(5), n(F3, 1), p(3), n(F3, 3), p(1) },           // 13

        &[_]Note{ n(B3, 1), p(5), n(B3, 1), p(5), n(B3, 1), p(3), n(B3, 3), p(1) },           // 14
        &[_]Note{ n(D3, 1), p(5), n(D3, 1), p(5), n(D3, 1), p(3), n(D3, 3), p(1) },           // 15

        &[_]Note{
            r(3),
            v(80), n(C6, 1), p(1), // 1
            v(20), n(C6, 1), p(1),
            v(80), n(C6, 1), p(1), // 2
            v(20), n(C6, 1), p(1),
                   n(C6, 1), p(1), // 3
            v(80), n(C6, 1), p(1),
                   n(C6, 1), p(1), // 4
            v(20), n(C6, 1), p(1),
            v(80), n(C6, 1), p(1), // 5
            v(40), n(C6, 1),
            v(60), n(C6, 1)
        },
    },

    .track = &[_]FrameIndices {
        fi( 0,  0, 0, 16),
        fi( 0,  0, 0, 16),
        fi( 0,  0, 0, 16),
        fi( 0,  0, 0, 16),
        fi( 6,  7, 1, 16),
        fi( 8,  9, 2, 16),
        fi(10, 11, 3, 16),
        fi(12, 13, 4, 16),
        fi( 6,  7, 1, 16),
        fi( 8,  9, 2, 16),
        fi(10, 11, 3, 16),
        fi(14, 15, 5, 16),
    },
};

fn ChannelCtx(comptime channel: w4.Channel) type {
    return struct {
        const Self = @This();

        note_ptr: u8,
        note_timer: u8,

        volume: w4.Volume,
        release: u8,
        duty: w4.Duty,

        pub fn reset(self: *Self) void {
            self.note_ptr = 0;
            self.note_timer = 0;
            self.volume = .{.sustain = 100};
            self.release = 0;
            self.duty = .@"1/4";
        }

        pub fn onBeat(self: *Self, frame: []const Note, beat_length: u8) void {
            while (self.note_timer == 0) {
                switch (frame[self.note_ptr]) {
                    .note => |note| {
                        if (!sound.channelTaken(channel)) {
                            const note_length = note.length * beat_length;
                            const freq: w4.Frequency = .{.start = tuning[note.pitch]};

                            const sustain = note_length -| self.release;
                            const release = note_length - sustain;
                            const duration = w4.adsr(0, 0, sustain, release);

                            const flags: w4.ToneFlags = .{.channel = channel, .duty = self.duty};
                            w4.tone(freq, duration, self.volume, flags);
                        }

                        self.note_timer = note.length;
                    },
                    .pause => |pause| {
                        self.note_timer = pause;
                    },
                    .volume => |volume| {
                        self.volume = volume;
                    },
                    .release => |length| {
                        self.release = length;
                    }
                }
                self.note_ptr += 1;
            }

            self.note_timer -= 1;
        }
    };
}

pub var current_track: ?*const MusicTrack = null;
pub var beat: u8 = undefined;
pub var beat_time: u8 = undefined;
pub var frame_ptr: u8 = undefined;

pub var pulse1: ChannelCtx(.pulse1) = undefined;
pub var pulse2: ChannelCtx(.pulse2) = undefined;
pub var triangle: ChannelCtx(.triangle) = undefined;
pub var noise: ChannelCtx(.noise) = undefined;

pub fn play(track: ?*const MusicTrack) void {
    current_track = track;

    if (track != null) {
        beat = 0;
        beat_time = 0;
        frame_ptr = 0;
        pulse1.reset();
        pulse2.reset();
        triangle.reset();
        noise.reset();
    }
}

pub fn update() void {
    if (current_track == null) {
        return;
    }

    const track = current_track.?;
    if (beat_time == 0) {
        const frame_indices = track.track[frame_ptr];

        pulse1.onBeat(track.frames[frame_indices.pulse1], track.beat_length);
        pulse2.onBeat(track.frames[frame_indices.pulse2], track.beat_length);
        triangle.onBeat(track.frames[frame_indices.triangle], track.beat_length);
        noise.onBeat(track.frames[frame_indices.noise], track.beat_length);
    }

    beat_time += 1;
    if (beat_time >= track.beat_length) {
        beat_time = 0;
        beat += 1;

        if (beat >= track.frame_length) {
            beat = 0;
            frame_ptr += 1;

            pulse1.reset();
            pulse2.reset();
            triangle.reset();
            noise.reset();

            if (frame_ptr >= track.track.len) {
                frame_ptr = track.loop_frame;
            }
        }
    }
}
