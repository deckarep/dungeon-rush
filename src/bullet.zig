const c_dr = @cImport({
    //@cInclude("bullet.h");
    @cInclude("types.h");
    @cInclude("weapon.h");
    @cInclude("player.h");

    @cInclude("helper.h");
});

const c_stdlib = @cImport({
    @cInclude("stdlib.h");
});

const meta = @import("std").meta;

pub const Bullet = extern struct {
    parent: *c_dr.Weapon,
    x: c_int,
    y: c_int,
    team: c_int,
    owner: *c_dr.Snake,
    rad: f64,
    ani: *c_dr.Animation,
};

pub export fn createBullet(argOwner: c_dr.Snake, argParent: c_dr.Weapon, argX: c_int, argY: c_int, argRad: f64, argTeam: c_int, argAni: c_dr.Animation) Bullet {
    var bullet: [*c]Bullet = @ptrCast([*c]Bullet, @alignCast(meta.alignment(Bullet), c_stdlib.malloc(@sizeOf(Bullet))));

    bullet.* = Bullet{
        .parent = argParent,
        .x = argX,
        .y = argY,
        .owner = argOwner,
        .team = argTeam,
        .rad = argRad,
        .ani = argAni,
    };

    c_dr.copyAnimation(argAni, bullet.*.ani);

    bullet.*.ani.*.x = argX;
    bullet.*.ani.*.y = argY;
    bullet.*.ani.*.angle = argRad * 180 / 3.14;
    return bullet;
}

pub export fn moveBullet(bullet: [*c]Bullet) void {
    const speed: c_int = bullet.*.parent.*.bulletSpeed;

    bullet.*.x += @cos(bullet.*.rad) * @intToFloat(f64, speed);
    bullet.*.y += @sin(bullet.*.rad) * @intToFloat(f64, speed);
    bullet.*.ani.*.x = bullet.*.x;
    bullet.*.ani.*.y = bullet.*.y;
}

pub export fn destroyBullet(arg_bullet: [*c]Bullet) void {
    var bullet = arg_bullet;
    c_stdlib.free(@ptrCast(?*c_void, bullet));
}
