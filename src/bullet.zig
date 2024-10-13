const std = @import("std");
const wp = @import("weapons.zig");
const pl = @import("player.zig");
const tps = @import("types.zig");
const c = @import("cdefs.zig").c;

pub const Bullet = struct {
    parent: *wp.Weapon,
    x: c_int,
    y: c_int,
    team: c_int,
    owner: ?*pl.Snake,
    rad: f64,
    ani: *tps.Animation,
};

pub fn createBullet(
    owner: *pl.Snake,
    parent: *wp.Weapon,
    x: c_int,
    y: c_int,
    rad: f64,
    team: c_int,
    ani: *tps.Animation,
) *Bullet {
    const bullet: *Bullet = @alignCast(@ptrCast(c.malloc(@sizeOf(Bullet))));
    bullet.* = .{
        .parent = parent,
        .x = x,
        .y = y,
        .team = team,
        .owner = owner,
        .rad = rad,
        .ani = @alignCast(@ptrCast(c.malloc(@sizeOf(tps.Animation)))),
    };
    tps.copyAnimation(ani, bullet.ani);
    bullet.ani.x = x;
    bullet.ani.y = y;
    bullet.ani.angle = rad * 180 / std.math.pi;
    return bullet;
}

pub fn moveBullet(bullet: *Bullet) void {
    const speed: f64 = @floatFromInt(bullet.parent.bulletSpeed);
    bullet.x += @intFromFloat(@cos(bullet.rad) * speed);
    bullet.y += @intFromFloat(@sin(bullet.rad) * speed);
    bullet.ani.x = bullet.x;
    bullet.ani.y = bullet.y;
}

pub fn destroyBullet(bullet: *Bullet) void {
    c.free(bullet);
}
