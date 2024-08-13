const BoundingBox = @This();
const rl = @import("raylib");

rect: rl.Rectangle,

pub fn init(rect: rl.Rectangle) BoundingBox {
    return BoundingBox{ .rect = rect };
}

pub fn draw(self: *BoundingBox) void {
    rl.drawRectangleLinesEx(self.rect, 1, rl.Color.white);
}
