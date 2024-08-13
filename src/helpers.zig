const rl = @import("raylib");
const std = @import("std");

pub fn orthoNormalizeVector(v: rl.Vector2) rl.Vector2 {
    const v2 = rl.Vector2.init(-v.y, v.x).normalize();
    std.debug.print("ortho normal vector: original={d}, {d}\n", .{ v.x, v.y });
    std.debug.print("ortho normal vector: normal={d}, {d}\n", .{ v2.x, v2.y });
    return v2;
}

pub inline fn createRandomizer() !std.Random {
    var prng = std.rand.DefaultPrng.init(blk: {
        var seed: u64 = undefined;
        try std.posix.getrandom(std.mem.asBytes(&seed));
        break :blk seed;
    });
    return prng.random();
}
