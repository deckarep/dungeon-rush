const std = @import("std");
const stdout = std.io.getStdOut().writer();

const c = @import("c_headers.zig").c;
const rand = @import("std").rand;
const meta = @import("std").meta;

// Extern for now.
pub extern var bullets: [*c]c.LinkList;

pub fn destroySnake(snake: *c.Snake) void {
    if (bullets != null) {
        var p: [*c]c.LinkNode = bullets.*.head;
        while (p != null) : (p = p.*.nxt) {
            var bullet: [*c]c.Bullet = @ptrCast([*c]c.Bullet, @alignCast(meta.alignment([*c]c.Bullet), p.*.element));
            if (bullet.*.owner == snake) {
                bullet.*.owner = null;
            }
        }
    }

    var p: [*c]c.LinkNode = snake.*.sprites.*.head;
    while (p != null) : (p = p.*.nxt) {
        var sprite: [*c]c.Sprite = @ptrCast([*c]c.Sprite, @alignCast(meta.alignment([*c]c.Sprite), p.*.element));
        c.free(sprite);
        p.*.element = null;
    }

    c.destroyLinkList(snake.*.sprites);
    snake.*.sprites = null;
    c.destroyScore(snake.*.score);
    snake.*.score = null;
    c.free(snake);
}
