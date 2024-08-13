const std = @import("std");
const rl = @import("raylib");
const Circle = @import("circle.zig");
const CollisionSystem = @This();
const globals = @import("globals.zig");

pub const BoundCollisionType = enum { X, Y };

pub const Collision = struct {
    touch_point: rl.Vector2,
    is_handled: bool,
};

const InnerCollisionMap = std.AutoHashMap(*Circle, Collision);
const OuterCollisionMap = std.AutoHashMap(*Circle, InnerCollisionMap);

pub const CollisionIterator = struct {
    map: ?*InnerCollisionMap,

    pub fn init(map: ?*InnerCollisionMap) CollisionIterator {
        return .{ .map = map };
    }

    pub fn next(self: CollisionIterator) ?InnerCollisionMap.Entry {
        if (self.map) |map| {
            var it = map.iterator();

            while (it.next()) |entry| {
                if (entry.value_ptr.is_handled) {
                    continue;
                }
                return entry;
            }
        }
        return null;
    }
};

bounds: rl.Rectangle,
circles: []*Circle,
ongoing_x_bound_collissions: std.ArrayList(*Circle),
ongoing_y_bound_collissions: std.ArrayList(*Circle),
ongoing_collisions: OuterCollisionMap,
root_allocator: std.mem.Allocator,

pub fn init(circles: []*Circle, bounds: rl.Rectangle, allocator: std.mem.Allocator) CollisionSystem {
    return CollisionSystem{
        .bounds = bounds,
        .circles = circles,
        .ongoing_collisions = OuterCollisionMap.init(allocator),
        .ongoing_x_bound_collissions = std.ArrayList(*Circle).init(allocator),
        .ongoing_y_bound_collissions = std.ArrayList(*Circle).init(allocator),
        .root_allocator = allocator,
    };
}

inline fn addLTRCollision(self: *CollisionSystem, circle_l: *Circle, circle_r: *Circle, touch_point: rl.Vector2) !void {
    const contains = self.ongoing_collisions.contains(circle_l);
    var map: std.AutoHashMap(*Circle, Collision) = blk: {
        if (contains) {
            break :blk self.ongoing_collisions.get(circle_l).?;
        }
        const map = std.AutoHashMap(*Circle, Collision).init(self.root_allocator);
        try self.ongoing_collisions.put(circle_l, map);
        break :blk map;
    };
    if (map.contains(circle_r)) {
        return;
    }
    try map.put(circle_r, .{ .touch_point = touch_point, .is_handled = false });
    if (!contains) {
        try self.ongoing_collisions.put(circle_l, map);
    }
}

inline fn addMutualCollision(self: *CollisionSystem, circle_a: *Circle, circle_b: *Circle) !void {
    const radius_a = circle_a.radius;
    const radius_b = circle_b.radius;
    const ratio = radius_a / radius_b;
    const mx = (circle_a.pos.x + ratio * circle_b.pos.x) / (1 + ratio);
    const my = (circle_a.pos.y + ratio * circle_b.pos.y) / (1 + ratio);

    const touch_point = rl.Vector2.init(mx, my);
    try self.addLTRCollision(circle_a, circle_b, touch_point);
    try self.addLTRCollision(circle_b, circle_a, touch_point);
}

inline fn addBoundCollision(self: *CollisionSystem, circle: *Circle, bound_collision_type: BoundCollisionType) !void {
    const list = switch (bound_collision_type) {
        .X => &self.ongoing_x_bound_collissions,
        .Y => &self.ongoing_y_bound_collissions,
    };

    for (list.items) |item| {
        if (item == circle) {
            return;
        }
    }
    try list.append(circle);
}

inline fn removeLTRCollision(self: *CollisionSystem, circle_l: *Circle, circle_r: *Circle) void {
    var map: std.AutoHashMap(*Circle, Collision) = self.ongoing_collisions.get(circle_l) orelse {
        return;
    };
    if (!map.contains(circle_r)) {
        return;
    }
    _ = map.remove(circle_r);
}

inline fn removeMutualCollision(self: *CollisionSystem, circle_a: *Circle, circle_b: *Circle) void {
    self.removeLTRCollision(circle_a, circle_b);
    self.removeLTRCollision(circle_b, circle_a);
}

inline fn removeBoundCollision(self: *CollisionSystem, circle: *Circle, comptime bound_collision_type: BoundCollisionType) void {
    const list = switch (bound_collision_type) {
        .X => &self.ongoing_x_bound_collissions,
        .Y => &self.ongoing_y_bound_collissions,
    };
    const idx: ?usize = blk: {
        for (list.items, 0..) |item, idx| {
            if (item == circle) {
                break :blk idx;
            }
        }
        break :blk null;
    };
    if (idx) |index| {
        _ = list.swapRemove(index);
    }
}

fn checkCollidingWithXBounds(self: *CollisionSystem, circle: *Circle, delta_time: f32) bool {
    const nextPositionX = circle.pos.x + (circle.direction.x * globals.speed * delta_time);

    const radius = circle.radius;

    if (nextPositionX + radius > self.bounds.x + self.bounds.width or nextPositionX - radius < self.bounds.x) {
        return true;
    }

    return false;
}

fn checkCollidingWithYBounds(self: *CollisionSystem, circle: *Circle, delta_time: f32) bool {
    const nextPositionY = circle.pos.y + (circle.direction.y * globals.speed * delta_time);
    const radius = circle.radius;
    if (nextPositionY + radius > self.bounds.y + self.bounds.height or nextPositionY - radius < self.bounds.y) {
        return true;
    }

    return false;
}

pub fn isCollidingWithBounds(self: *CollisionSystem, circle: *Circle, comptime bound_collision_type: BoundCollisionType) bool {
    const list = switch (bound_collision_type) {
        .X => &self.ongoing_x_bound_collissions,
        .Y => &self.ongoing_y_bound_collissions,
    };
    for (list.items) |item| {
        if (item == circle) {
            return true;
        }
    }
    return false;
}

pub fn isCollidingWithYBounds(self: *CollisionSystem, circle: *Circle) bool {
    for (self.ongoing_y_bound_collissions.items) |item| {
        if (item == circle) {
            return true;
        }
    }
    return false;
}

pub fn getCollidingCircles(self: *CollisionSystem, circle: *Circle) ?*std.AutoHashMap(*Circle, Collision) {
    return self.ongoing_collisions.getPtr(circle);
}

pub fn updateCollisions(self: *CollisionSystem, delta_time: f32) !void {
    for (self.circles, 0..) |circle, idx| {
        if (self.checkCollidingWithXBounds(circle, delta_time)) {
            try self.addBoundCollision(circle, BoundCollisionType.X);
        } else {
            self.removeBoundCollision(circle, BoundCollisionType.X);
        }
        if (self.checkCollidingWithYBounds(circle, delta_time)) {
            try self.addBoundCollision(circle, BoundCollisionType.Y);
        } else {
            self.removeBoundCollision(circle, BoundCollisionType.Y);
        }
        for (self.circles[idx + 1 ..]) |other_circle| {
            if (circle == other_circle) {
                continue;
            }
            const r1 = circle.radius;
            const r2 = other_circle.radius;

            if (rl.checkCollisionCircles(circle.pos, r1, other_circle.pos, r2)) {
                try self.addMutualCollision(circle, other_circle);
            } else if (self.ongoing_collisions.contains(circle)) {
                self.removeMutualCollision(circle, other_circle);
            }
        }
    }
}
