const std = @import("std");
const CollisionSystem = @import("collision_system.zig");

pub var rand: std.Random = undefined;
pub var is_paused: bool = false;
pub var speed: f32 = 120;
pub var collision_system: CollisionSystem = undefined;
