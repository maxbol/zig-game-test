const rl = @import("raylib");

pub const colors = .{
    rl.Color.blue,
    rl.Color.red,
    rl.Color.light_gray,
    rl.Color.gray,
    rl.Color.gold,
    rl.Color.pink,
    rl.Color.lime,
};

pub const MovementKeyBitmask = enum(u4) {
    None = 0,
    Up = 1,
    Left = 2,
    Down = 4,
    Right = 8,
};
