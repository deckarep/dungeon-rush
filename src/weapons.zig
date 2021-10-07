const std = @import("std");
const stdout = std.io.getStdOut().writer();

const c = @import("c_headers.zig").c;

// Extern for now.
extern var weapons: [c.WEAPONS_SIZE]c.Weapon;

// Extern.
extern var textures: [c.TILESET_SIZE]c.Texture;

pub fn initWeapon(self: *c.Weapon, birthTextureId: c_int, deathTextureId: c_int, flyTextureId: c_int) void {
    var birthAni: ?*c.Animation = null;
    var deathAni: ?*c.Animation = null;
    var flyAni: ?*c.Animation = null;

    if (birthTextureId != -1) {
        birthAni = c.createAnimation(&textures[@intCast(usize, birthTextureId)], null, c.LOOP_ONCE, c.SPRITE_ANIMATION_DURATION, 0, 0, c.SDL_FLIP_NONE, 0, c.AT_CENTER);
    }
    if (deathTextureId != -1) {
        deathAni = c.createAnimation(&textures[@intCast(usize, deathTextureId)], null, c.LOOP_ONCE, c.SPRITE_ANIMATION_DURATION, 0, 0, c.SDL_FLIP_NONE, 0, c.AT_BOTTOM_CENTER);
    }
    if (flyTextureId != -1) {
        flyAni = c.createAnimation(&textures[@intCast(usize, flyTextureId)], null, c.LOOP_INFI, c.SPRITE_ANIMATION_DURATION, 0, 0, c.SDL_FLIP_NONE, 0, c.AT_CENTER);
    }
    var w: c.Weapon = undefined;

    w.wp = c.WEAPON_SWORD_POINT;
    w.shootRange = 32 * 2;
    w.effectRange = 40;
    w.damage = 10;
    w.gap = 60;
    w.bulletSpeed = 6;
    w.birthAni = birthAni;
    w.deathAni = deathAni;
    w.flyAni = flyAni;
    w.birthAudio = 0;
    w.deathAudio = 0;

    self.* = w;
}

pub fn initWeapons() void {
    var now: *c.Weapon = undefined;

    now = &weapons[c.WEAPON_SWORD];
    initWeapon(now, -1, c.RES_SwordFx, -1);
    now.*.damage = 30;
    now.*.shootRange = 32 * 3;
    now.*.deathAni.*.scaled = false;
    now.*.deathAni.*.angle = -1;
    now.*.deathAudio = c.AUDIO_SWORD_HIT;

    now = &weapons[c.WEAPON_MONSTER_CLAW];
    initWeapon(now, -1, c.RES_CLAWFX2, -1);
    now.*.wp = c.WEAPON_SWORD_RANGE;
    now.*.shootRange = 32 * 3 + 16;
    now.*.damage = 24;
    now.*.deathAni.*.angle = -1;
    now.*.deathAni.*.at = c.AT_CENTER;
    now.*.deathAudio = c.AUDIO_CLAW_HIT_HEAVY;

    now = &weapons[c.WEAPON_FIREBALL];
    initWeapon(now, c.RES_Shine, c.RES_HALO_EXPLOSION1, c.RES_FIREBALL);
    now.*.wp = c.WEAPON_GUN_RANGE;
    now.*.damage = 45;
    now.*.effectRange = 50;
    now.*.shootRange = 256;
    now.*.gap = 180;
    now.*.deathAni.*.angle = -1;
    now.*.deathAni.*.at = c.AT_CENTER;
    now.*.birthAni.*.duration = 24;
    now.*.birthAudio = c.AUDIO_SHOOT;
    now.*.deathAudio = c.AUDIO_FIREBALL_EXP;

    now = &weapons[c.WEAPON_THUNDER];
    initWeapon(now, c.RES_BLOOD_BOUND, c.RES_Thunder, -1);
    now.*.wp = c.WEAPON_SWORD_RANGE;
    now.*.damage = 80;
    now.*.shootRange = 128;
    now.*.gap = 120;
    now.*.deathAni.*.angle = -1;
    now.*.deathAni.*.scaled = false;
    now.*.deathAudio = c.AUDIO_THUNDER;

    now = &weapons[c.WEAPON_THUNDER_STAFF];
    initWeapon(now, -1, c.RES_THUNDER_YELLOW, -1);
    now.*.wp = c.WEAPON_SWORD_RANGE;
    now.*.damage = 50;
    now.*.shootRange = 128;
    now.*.gap = 120;
    now.*.deathAni.*.angle = -1;
    now.*.deathAni.*.scaled = false;
    now.*.deathAudio = c.AUDIO_THUNDER;

    now = &weapons[c.WEAPON_ARROW];
    initWeapon(now, -1, c.RES_HALO_EXPLOSION2, c.RES_ARROW);
    now.*.wp = c.WEAPON_GUN_POINT;
    now.*.gap = 40;
    now.*.damage = 10;
    now.*.shootRange = 200;
    now.*.bulletSpeed = 10;
    now.*.deathAni.*.angle = -1;
    now.*.deathAni.*.at = c.AT_CENTER;
    now.*.flyAni.*.scaled = false;
    now.*.birthAudio = c.AUDIO_LIGHT_SHOOT;
    now.*.deathAudio = c.AUDIO_ARROW_HIT;

    now = &weapons[c.WEAPON_POWERFUL_BOW];
    initWeapon(now, -1, c.RES_HALO_EXPLOSION2, c.RES_ARROW);
    now.*.wp = c.WEAPON_GUN_POINT;
    now.*.gap = 60;
    now.*.damage = 25;
    now.*.shootRange = 320;
    now.*.bulletSpeed = 7;
    now.*.deathAni.*.angle = -1;
    now.*.deathAni.*.at = c.AT_CENTER;
    now.*.birthAudio = c.AUDIO_LIGHT_SHOOT;
    now.*.deathAudio = c.AUDIO_ARROW_HIT;
    now.*.effects[c.BUFF_ATTACK] = c.WeaponBuff{ .chance = 0.5, .duration = 240 };

    now = &weapons[c.WEAPON_MONSTER_CLAW2];
    initWeapon(now, -1, c.RES_CLAWFX, -1);

    now = &weapons[c.WEAPON_THROW_AXE];
    initWeapon(now, -1, c.RES_CROSS_HIT, c.RES_AXE);
    now.*.wp = c.WEAPON_GUN_POINT;
    now.*.damage = 12;
    now.*.shootRange = 160;
    now.*.bulletSpeed = 10;
    now.*.flyAni.*.duration = 24;
    now.*.flyAni.*.angle = -1;
    now.*.flyAni.*.scaled = false;
    now.*.deathAni.*.scaled = false;
    now.*.deathAni.*.at = c.AT_CENTER;
    now.*.birthAudio = c.AUDIO_LIGHT_SHOOT;
    now.*.deathAudio = c.AUDIO_ARROW_HIT;

    now = &weapons[c.WEAPON_MANY_AXES];
    initWeapon(now, -1, c.RES_CROSS_HIT, c.RES_AXE);
    now.*.wp = c.WEAPON_GUN_POINT_MULTI;
    now.*.shootRange = 180;
    now.*.gap = 70;
    now.*.effectRange = 50;
    now.*.damage = 50;
    now.*.bulletSpeed = 4;
    now.*.flyAni.*.duration = 24;
    now.*.flyAni.*.angle = -1;
    now.*.deathAni.*.at = c.AT_CENTER;
    now.*.birthAudio = c.AUDIO_LIGHT_SHOOT;
    now.*.deathAudio = c.AUDIO_ARROW_HIT;

    now = &weapons[c.WEAPON_SOLID];
    initWeapon(now, -1, c.RES_SOLIDFX, -1);
    now.*.deathAni.*.scaled = false;
    now.*.deathAni.*.angle = -1;
    now.*.effects[c.BUFF_SLOWDOWN] = c.WeaponBuff{ .chance = 0.3, .duration = 180 };

    now = &weapons[c.WEAPON_SOLID_GREEN];
    initWeapon(now, -1, c.RES_SOLID_GREENFX, -1);
    now.*.shootRange = 96;
    now.*.deathAni.*.scaled = false;
    now.*.deathAni.*.angle = -1;
    now.*.effects[c.BUFF_SLOWDOWN] = c.WeaponBuff{ .chance = 0.3, .duration = 180 };

    now = &weapons[c.WEAPON_SOLID_CLAW];
    initWeapon(now, -1, c.RES_SOLID_GREENFX, -1);
    now.*.wp = c.WEAPON_SWORD_RANGE;
    now.*.shootRange = 32 * 3 + 16;
    now.*.damage = 35;
    now.*.deathAni.*.scaled = false;
    now.*.deathAni.*.angle = -1;
    now.*.deathAudio = c.AUDIO_CLAW_HIT_HEAVY;
    now.*.effects[c.BUFF_SLOWDOWN] = c.WeaponBuff{ .chance = 0.7, .duration = 60 };

    now = &weapons[c.WEAPON_ICEPICK];
    initWeapon(now, -1, c.RES_ICESHATTER, c.RES_ICEPICK);
    now.*.wp = c.WEAPON_GUN_RANGE;
    now.*.damage = 30;
    now.*.effectRange = 50;
    now.*.shootRange = 256;
    now.*.gap = 180;
    now.*.bulletSpeed = 8;
    now.*.deathAni.*.angle = -1;
    now.*.flyAni.*.scaled = false;
    now.*.deathAni.*.at = c.AT_CENTER;
    now.*.effects[c.BUFF_FROZEN] = c.WeaponBuff{ .chance = 0.2, .duration = 60 };
    now.*.birthAudio = c.AUDIO_ICE_SHOOT;

    now = &weapons[c.WEAPON_PURPLE_BALL];
    initWeapon(now, -1, c.RES_PURPLE_EXP, c.RES_PURPLE_BALL);
    now.*.wp = c.WEAPON_GUN_RANGE;
    now.*.damage = 20;
    now.*.effectRange = 50;
    now.*.shootRange = 256;
    now.*.gap = 100;
    now.*.bulletSpeed = 6;
    now.*.deathAni.*.angle = -1;
    now.*.deathAni.*.scaled = false;
    now.*.flyAni.*.scaled = false;
    now.*.deathAni.*.at = c.AT_CENTER;
    now.*.birthAudio = c.AUDIO_ICE_SHOOT;
    now.*.deathAudio = c.AUDIO_ARROW_HIT;

    now = &weapons[c.WEAPON_PURPLE_STAFF];
    initWeapon(now, -1, c.RES_PURPLE_EXP, c.RES_PURPLE_BALL);
    now.*.wp = c.WEAPON_GUN_POINT_MULTI;
    now.*.damage = 45;
    now.*.effectRange = 50;
    now.*.shootRange = 256;
    now.*.gap = 100;
    now.*.bulletSpeed = 7;
    now.*.deathAni.*.angle = -1;
    now.*.deathAni.*.scaled = false;
    now.*.flyAni.*.scaled = false;
    now.*.deathAni.*.at = c.AT_CENTER;
    now.*.birthAudio = c.AUDIO_ICE_SHOOT;
    now.*.deathAudio = c.AUDIO_ARROW_HIT;

    now = &weapons[c.WEAPON_HOLY_SWORD];
    initWeapon(now, -1, c.RES_GOLDEN_CROSS_HIT, -1);
    now.*.wp = c.WEAPON_SWORD_RANGE;
    now.*.damage = 30;
    now.*.shootRange = 32 * 4;
    now.*.effects[c.BUFF_DEFFENCE] = c.WeaponBuff{ .chance = 0.6, .duration = 180 };

    now = &weapons[c.WEAPON_ICE_SWORD];
    initWeapon(now, -1, c.RES_ICESHATTER, -1);
    now.*.wp = c.WEAPON_SWORD_RANGE;
    now.*.shootRange = 32 * 3 + 16;
    now.*.damage = 80;
    now.*.gap = 30;
    now.*.deathAni.*.angle = -1;
    now.*.deathAni.*.at = c.AT_CENTER;
    now.*.effects[c.BUFF_FROZEN] = c.WeaponBuff{ .chance = 0.6, .duration = 80 };
    now.*.deathAudio = c.AUDIO_SWORD_HIT;

    //#ifdef DBG
    //  puts("weapon done");
    //#endif
}
