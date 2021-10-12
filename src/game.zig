const std = @import("std");
const stdout = std.io.getStdOut().writer();

const c = @import("c_headers.zig").c;
const rand = @import("std").rand;
const meta = @import("std").meta;

// Extern for now.
pub extern var bullets: ?*c.LinkList;

pub fn destroySnake(snake: *c.Snake) void {
    if (bullets) |someBullets| {
        var p: ?*c.LinkNode = someBullets.*.head;
        while (p) |someP| {
            var bullet: *c.Bullet = @ptrCast(*c.Bullet, @alignCast(meta.alignment(*c.Bullet), someP.*.element));
            if (bullet.*.owner == snake) {
                bullet.*.owner = null;
            }
            p = someP.*.nxt;
        }
    }

    var p: ?*c.LinkNode = snake.*.sprites.*.head;
    while (p) |someP| {
        var sprite: *c.Sprite = @ptrCast(*c.Sprite, @alignCast(meta.alignment(*c.Sprite), someP.*.element));
        c.free(sprite);
        someP.*.element = null;
        p = someP.*.nxt;
    }

    c.destroyLinkList(snake.*.sprites);
    snake.*.sprites = null;
    c.destroyScore(snake.*.score);
    snake.*.score = null;
    c.free(snake);
}
