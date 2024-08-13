const Player = @This();
const Circle = @import("circle.zig");
const rl = @import("raylib");
const std = @import("std");
const constants = @import("constants.zig");

circle: *Circle,

movement_vectors: [16]rl.Vector2,

pub fn init(circle: *Circle) Player {
    // This constant can't be run in comptime because it uses extern calls to raylib.
    // I'm not sure if there is a better way of solving this.
    const movement_vectors: [16]rl.Vector2 = .{
        // 0 - None
        rl.Vector2.init(0, 0),
        // 1 - Up
        rl.Vector2.init(0, -1),
        // 2 - Left
        rl.Vector2.init(-1, 0),
        // 3 - Up + Left
        rl.Vector2.init(-1, -1).scale(std.math.sqrt2).normalize(),
        // 4 - Down
        rl.Vector2.init(0, 1),
        // 5 - Up + Down (invalid)
        rl.Vector2.init(0, 0),
        // 6 - Left + Down
        rl.Vector2.init(-1, 1).scale(std.math.sqrt2).normalize(),
        // 7 - Up + Left + Down (invalid)
        rl.Vector2.init(0, 0),
        // 8 - Right
        rl.Vector2.init(1, 0),
        // 9 - Up + Right
        rl.Vector2.init(1, -1).scale(std.math.sqrt2).normalize(),
        // 10 - Left + Right (invalid)
        rl.Vector2.init(0, 0),
        // 11 - Up + Left + Right (invalid)
        rl.Vector2.init(0, 0),
        // 12 - Down + Right
        rl.Vector2.init(1, 1).scale(std.math.sqrt2).normalize(),
        // 13 - Up + Down + Right (invalid)
        rl.Vector2.init(0, 0),
        // 14 - Left + Down + Right (invalid)
        rl.Vector2.init(0, 0),
        // 15 - Up + Left + Down + Right (invalid)
        rl.Vector2.init(0, 0),
    };

    return .{ .circle = circle, .movement_vectors = movement_vectors };
}

pub fn update(self: *Player, delta_time: f32) !void {
    var new_player_mov_mask: u4 = @intFromEnum(constants.MovementKeyBitmask.None);

    if (rl.isKeyDown(rl.KeyboardKey.key_left)) {
        new_player_mov_mask = new_player_mov_mask | @intFromEnum(constants.MovementKeyBitmask.Left);
    } else if (rl.isKeyDown(rl.KeyboardKey.key_right)) {
        new_player_mov_mask = new_player_mov_mask | @intFromEnum(constants.MovementKeyBitmask.Right);
    }

    if (rl.isKeyDown(rl.KeyboardKey.key_down)) {
        new_player_mov_mask = new_player_mov_mask | @intFromEnum(constants.MovementKeyBitmask.Down);
    } else if (rl.isKeyDown(rl.KeyboardKey.key_up)) {
        new_player_mov_mask = new_player_mov_mask | @intFromEnum(constants.MovementKeyBitmask.Up);
    }

    self.circle.direction = self.movement_vectors[new_player_mov_mask];

    try self.circle.update(delta_time);
}

pub fn drawDebug(self: *Player) void {
    self.circle.drawDebug();
}

pub fn draw(self: *Player) void {
    self.circle.draw();
}
