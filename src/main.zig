const rl = @import("raylib");
const std = @import("std");
const helpers = @import("helpers.zig");
const globals = @import("globals.zig");
const BoundingBox = @import("bounding_box.zig");
const Circle = @import("circle.zig");
const Player = @import("player.zig");
const CollisionSystem = @import("collision_system.zig");

pub fn main() anyerror!void {
    globals.rand = try helpers.createRandomizer();

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    // Initialization
    //--------------------------------------------------------------------------------------
    const display = rl.getCurrentMonitor();

    rl.initWindow(rl.getMonitorWidth(display), rl.getMonitorHeight(display), "raylib-zig [core] example - basic window");
    defer rl.closeWindow(); // Close window and OpenGL context

    rl.setTargetFPS(120); // Set our game to run at 60 frames-per-second
    rl.toggleFullscreen();
    //--------------------------------------------------------------------------------------

    const screen_width = rl.getMonitorWidth(display);
    const screen_height = rl.getMonitorHeight(display);
    std.debug.print("Current monitor: {s}\n", .{rl.getMonitorName(display)});
    std.debug.print("screen width: {}, screen height: {}\n", .{ screen_width, screen_height });

    const screen_width_float: f32 = @floatFromInt(screen_width);
    const screen_height_float: f32 = @floatFromInt(screen_height);
    //
    const circle_bounds = rl.Rectangle.init(0, 0, screen_width_float, screen_height_float);
    var bounding_box = BoundingBox.init(circle_bounds);

    const player_radius = 70;
    var player_circle = Circle.init(rl.Vector2.init(player_radius, player_radius), rl.Vector2.init(0, 0), rl.Color.white, player_radius);
    var player = Player.init(&player_circle);

    const bouncing_circles = try Circle.spawnAllColors(circle_bounds, allocator);
    var collidable_circles = std.ArrayList(*Circle).init(allocator);

    try collidable_circles.appendSlice(bouncing_circles);
    try collidable_circles.append(&player_circle);

    globals.collision_system = CollisionSystem.init(try collidable_circles.toOwnedSlice(), circle_bounds, allocator);

    while (!rl.windowShouldClose()) { // Detect window close button or ESC key
        // Update
        //----------------------------------------------------------------------------------
        // TODO: Update your variables here
        //----------------------------------------------------------------------------------
        const delta_time = rl.getFrameTime();

        if (rl.isKeyPressed(rl.KeyboardKey.key_p)) {
            globals.is_paused = !globals.is_paused;
        }

        if (rl.isKeyPressed(rl.KeyboardKey.key_equal)) {
            globals.speed += 10;
        }

        if (rl.isKeyPressed(rl.KeyboardKey.key_minus)) {
            globals.speed -= 10;
        }

        try globals.collision_system.updateCollisions(delta_time);

        if (!globals.is_paused) {
            try player.update(delta_time);

            for (bouncing_circles) |circle| {
                circle.clear(delta_time);
            }

            for (bouncing_circles) |circle| {
                try circle.update(delta_time);
            }
        }

        // std.debug.print("FPS: {}\n", .{rl.getFPS()});

        // Draw
        //----------------------------------------------------------------------------------
        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(rl.Color.black);

        var player_dir_str: [64]u8 = undefined;
        rl.drawText(try std.fmt.bufPrintZ(&player_dir_str, "player direction: ({d},{d})", .{ player_circle.direction.x, player_circle.direction.y }), 0, 0, 32, rl.Color.yellow);
        rl.drawText(try std.fmt.bufPrintZ(&player_dir_str, "fps: {d}", .{rl.getFPS()}), 0, rl.getMonitorHeight(display) - 32, 32, rl.Color.yellow);

        bounding_box.draw();

        for (bouncing_circles) |circle| {
            circle.draw();
        }

        for (bouncing_circles) |circle| {
            circle.drawDebug();
        }

        player.draw();
        player.drawDebug();

        //----------------------------------------------------------------------------------
    }
}
