const Circle = @This();
const std = @import("std");
const rl = @import("raylib");
const globals = @import("globals.zig");
const constants = @import("constants.zig");
const CollisionSystem = @import("collision_system.zig");

pos: rl.Vector2,
starting_pos: rl.Vector2,
direction: rl.Vector2,
color: rl.Color,
base_color: rl.Color,
base_color_vec: rl.Vector4,
radius: f32,

// Debug stuff
collision_debug: ?struct { normal: rl.Vector2, point: rl.Vector2, diff_vec: rl.Vector2, display_time: f32, old_dir: rl.Vector2, new_dir: rl.Vector2 } = null,

pub fn init(starting_pos: rl.Vector2, direction: rl.Vector2, color: rl.Color, radius: f32) Circle {
    return Circle{
        .pos = starting_pos,
        .starting_pos = starting_pos,
        .direction = direction,
        .color = color,
        .base_color = color,
        .base_color_vec = color.normalize(),
        .radius = radius,
    };
}

pub fn spawnInRandomLocation(bounds: rl.Rectangle, color: rl.Color) Circle {
    const radius = globals.rand.float(f32) * 60 + 40;

    const min_x: f32 = bounds.x + (radius * 2);
    const min_y: f32 = bounds.y + (radius * 2);
    const max_x: f32 = bounds.x + bounds.width - (radius * 2);
    const max_y: f32 = bounds.y + bounds.height - (radius * 2);

    const pos_x = min_x + (globals.rand.float(f32) * (max_x - min_x));
    const pos_y = min_y + (globals.rand.float(f32) * (max_y - min_y));

    std.debug.print("spawning {d},{d},{d} circle at ({d}, {d})\n", .{ color.r, color.g, color.b, pos_x, pos_y });

    const pos = rl.Vector2.init(pos_x, pos_y);

    const dir_x: f32 = if (globals.rand.boolean() == true) 0.5 else -0.5;
    const dir_y: f32 = if (globals.rand.boolean() == true) 0.5 else -0.5;
    const direction = rl.Vector2.init(dir_x, dir_y);

    return Circle.init(pos, direction, color, radius);
}

pub fn spawnAllColors(bounds: rl.Rectangle, allocator: std.mem.Allocator) ![]*Circle {
    var circles = std.ArrayList(*Circle).init(allocator);

    inline for (constants.colors) |color| {
        const circle = try allocator.create(Circle);
        circle.* = Circle.spawnInRandomLocation(bounds, color);
        try circles.append(circle);
    }

    return circles.toOwnedSlice();
}

pub fn clear(self: *Circle, delta_time: f32) void {
    if (self.collision_debug) |touch| {
        if (delta_time > touch.display_time) {
            self.collision_debug = null;
            return;
        }
        self.collision_debug.?.display_time = touch.display_time - delta_time;
    }
}

pub fn update(self: *Circle, delta_time: f32) !void {
    var has_collided = false;

    if (globals.collision_system.isCollidingWithBounds(self, CollisionSystem.BoundCollisionType.X)) {
        has_collided = true;
        self.direction = self.direction.reflect(rl.Vector2.init(1, 0));
    }

    if (globals.collision_system.isCollidingWithBounds(self, CollisionSystem.BoundCollisionType.Y)) {
        has_collided = true;
        self.direction = self.direction.reflect(rl.Vector2.init(0, 1));
    }

    const collisions = globals.collision_system.getCollidingCircles(self);
    var it = CollisionSystem.CollisionIterator.init(collisions);

    while (it.next()) |entry| {
        const circle = entry.key_ptr;
        const collision = entry.value_ptr;

        const is_handled = collision.is_handled;
        const touch_point = collision.touch_point;

        if (is_handled) {
            continue;
        }

        has_collided = true;

        const diff_vec = touch_point.subtract(self.pos);
        const normal = diff_vec.normalize();
        const old_dir = self.direction;

        self.direction = self.direction.reflect(normal);

        self.collision_debug = .{ .normal = normal, .point = touch_point, .diff_vec = diff_vec, .display_time = 1, .old_dir = old_dir, .new_dir = self.direction };

        try collisions.?.put(circle.*, .{
            .touch_point = touch_point,
            .is_handled = true,
        });
    }

    if (has_collided) {
        self.color = self.base_color.brightness(0.4);
    }

    if (self.color.r != self.base_color.r or self.color.g != self.base_color.g or self.color.b != self.base_color.b) {
        var circle_color_vec = self.color.normalize();
        circle_color_vec = circle_color_vec.lerp(self.base_color_vec, delta_time * 2);
        self.color = rl.Color.fromNormalized(circle_color_vec);
    }

    self.pos = self.pos.add(self.direction.scale(globals.speed * delta_time));
}

pub fn draw(self: *Circle) void {
    const cp_x: i32 = @intFromFloat(self.pos.x);
    const cp_y: i32 = @intFromFloat(self.pos.y);

    rl.drawCircle(cp_x, cp_y, self.radius, self.color);
}

pub fn drawDebug(self: *Circle) void {
    if (self.collision_debug) |touch| {
        const scaled_normal = touch.normal.scale(100);
        const scaled_new_dir = touch.new_dir.scale(40);
        const scaled_old_dir = touch.old_dir.scale(40);
        const normal_dest = touch.point.add(scaled_normal);

        // Draw collision points
        rl.drawCircle(@intFromFloat(touch.point.x), @intFromFloat(touch.point.y), 10, rl.Color.red);
        // Draw distance between position and collision point
        // rl.drawLine(cp_x, cp_y, tp_x, tp_y, rl.Color.dark_green);
        // Draw reflection vector
        rl.drawLineEx(touch.point, touch.point.add(scaled_new_dir), 8, self.base_color);
        rl.drawLineEx(touch.point, touch.point.add(scaled_old_dir), 4, self.base_color);
        // Draw normal
        rl.drawLineEx(touch.point.subtract(scaled_normal), normal_dest, 5, self.base_color);
        rl.drawCircle(@intFromFloat(normal_dest.x), @intFromFloat(normal_dest.y), 5, self.base_color);
        // Draw distance between position and collision point (diff vec)
        // rl.drawLineEx(self.pos, self.pos.add(touch.diff_vec), 5, rl.Color.yellow);
    }
}
