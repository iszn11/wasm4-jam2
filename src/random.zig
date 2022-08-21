// Based on PGC Random Number Generator at http://www.pcg-random.org
// Original by Melissa O'Neill <oneill@pcg-random.org>, licensed under Apache
// License, Version 2.0

pub const Rng = struct {
    state: u64,
    inc: u64,

    pub fn init(seed: u64, seq: u64) Rng {
        var rng = Rng{.state = 0, .inc = (seq << 1) | 1};
        _ = rng.next();
        rng.state +%= seed;
        _ = rng.next();
        return rng;
    }

    pub fn next(self: *Rng) u32 {
        const old_state = self.state;
        self.state = old_state *% 6364136223846793005 +% self.inc;
        const xorshifted = @intCast(u32, ((old_state >> 18) ^ old_state) >> 27);
        const rot = @intCast(u5, old_state >> 59);
        return (xorshifted >> rot) | (xorshifted << -%rot);
    }

    pub fn bounded(self: *Rng, bound: u32) u32 {
        const threshold = -%bound % bound;

        while (true) {
            const r = self.next();
            if (r >= threshold) {
                return r % bound;
            }
        }
    }
};

var global_rng = Rng.init(1337, 0);

pub fn next() u32 {
    return global_rng.next();
}

pub fn bounded(bound: u32) u32 {
    return global_rng.bounded(bound);
}
