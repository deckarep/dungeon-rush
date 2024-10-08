const std = @import("std");
const stdout = std.io.getStdOut().writer();

const c = @import("c_headers.zig").c;

// Extern for now.
extern var weapons: [c.WEAPONS_SIZE]c.Weapon;

// Extern.
extern var textures: [c.TILESET_SIZE]c.Texture;

pub fn initWeapon(wep: *c.Weapon, birthTextureId: c_int, deathTextureId: c_int, flyTextureId: c_int) void {
    var birthAni: ?*c.Animation = null;
    var deathAni: ?*c.Animation = null;
    var flyAni: ?*c.Animation = null;

    if (birthTextureId != -1) {
        birthAni = c.createAnimation(&textures[@intCast(birthTextureId)], null, c.LOOP_ONCE, c.SPRITE_ANIMATION_DURATION, 0, 0, c.SDL_FLIP_NONE, 0, c.AT_CENTER);
    }
    if (deathTextureId != -1) {
        deathAni = c.createAnimation(&textures[@intCast(deathTextureId)], null, c.LOOP_ONCE, c.SPRITE_ANIMATION_DURATION, 0, 0, c.SDL_FLIP_NONE, 0, c.AT_BOTTOM_CENTER);
    }
    if (flyTextureId != -1) {
        flyAni = c.createAnimation(&textures[@intCast(flyTextureId)], null, c.LOOP_INFI, c.SPRITE_ANIMATION_DURATION, 0, 0, c.SDL_FLIP_NONE, 0, c.AT_CENTER);
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

    wep.* = w;
}

pub fn initWeapons() void {
    var wp: *c.Weapon = undefined;

    wp = &weapons[c.WEAPON_SWORD];
    initWeapon(wp, -1, c.RES_SwordFx, -1);
    wp.*.damage = 30;
    wp.*.shootRange = 32 * 3;
    wp.*.deathAni.*.scaled = false;
    wp.*.deathAni.*.angle = -1;
    wp.*.deathAudio = c.AUDIO_SWORD_HIT;

    wp = &weapons[c.WEAPON_MONSTER_CLAW];
    initWeapon(wp, -1, c.RES_CLAWFX2, -1);
    wp.*.wp = c.WEAPON_SWORD_RANGE;
    wp.*.shootRange = 32 * 3 + 16;
    wp.*.damage = 24;
    wp.*.deathAni.*.angle = -1;
    wp.*.deathAni.*.at = c.AT_CENTER;
    wp.*.deathAudio = c.AUDIO_CLAW_HIT_HEAVY;

    wp = &weapons[c.WEAPON_FIREBALL];
    initWeapon(wp, c.RES_Shine, c.RES_HALO_EXPLOSION1, c.RES_FIREBALL);
    wp.*.wp = c.WEAPON_GUN_RANGE;
    wp.*.damage = 45;
    wp.*.effectRange = 50;
    wp.*.shootRange = 256;
    wp.*.gap = 180;
    wp.*.deathAni.*.angle = -1;
    wp.*.deathAni.*.at = c.AT_CENTER;
    wp.*.birthAni.*.duration = 24;
    wp.*.birthAudio = c.AUDIO_SHOOT;
    wp.*.deathAudio = c.AUDIO_FIREBALL_EXP;

    wp = &weapons[c.WEAPON_THUNDER];
    initWeapon(wp, c.RES_BLOOD_BOUND, c.RES_Thunder, -1);
    wp.*.wp = c.WEAPON_SWORD_RANGE;
    wp.*.damage = 80;
    wp.*.shootRange = 128;
    wp.*.gap = 120;
    wp.*.deathAni.*.angle = -1;
    wp.*.deathAni.*.scaled = false;
    wp.*.deathAudio = c.AUDIO_THUNDER;

    wp = &weapons[c.WEAPON_THUNDER_STAFF];
    initWeapon(wp, -1, c.RES_THUNDER_YELLOW, -1);
    wp.*.wp = c.WEAPON_SWORD_RANGE;
    wp.*.damage = 50;
    wp.*.shootRange = 128;
    wp.*.gap = 120;
    wp.*.deathAni.*.angle = -1;
    wp.*.deathAni.*.scaled = false;
    wp.*.deathAudio = c.AUDIO_THUNDER;

    wp = &weapons[c.WEAPON_ARROW];
    initWeapon(wp, -1, c.RES_HALO_EXPLOSION2, c.RES_ARROW);
    wp.*.wp = c.WEAPON_GUN_POINT;
    wp.*.gap = 40;
    wp.*.damage = 10;
    wp.*.shootRange = 200;
    wp.*.bulletSpeed = 10;
    wp.*.deathAni.*.angle = -1;
    wp.*.deathAni.*.at = c.AT_CENTER;
    wp.*.flyAni.*.scaled = false;
    wp.*.birthAudio = c.AUDIO_LIGHT_SHOOT;
    wp.*.deathAudio = c.AUDIO_ARROW_HIT;

    wp = &weapons[c.WEAPON_POWERFUL_BOW];
    initWeapon(wp, -1, c.RES_HALO_EXPLOSION2, c.RES_ARROW);
    wp.*.wp = c.WEAPON_GUN_POINT;
    wp.*.gap = 60;
    wp.*.damage = 25;
    wp.*.shootRange = 320;
    wp.*.bulletSpeed = 7;
    wp.*.deathAni.*.angle = -1;
    wp.*.deathAni.*.at = c.AT_CENTER;
    wp.*.birthAudio = c.AUDIO_LIGHT_SHOOT;
    wp.*.deathAudio = c.AUDIO_ARROW_HIT;
    wp.*.effects[c.BUFF_ATTACK] = c.WeaponBuff{ .chance = 0.5, .duration = 240 };

    wp = &weapons[c.WEAPON_MONSTER_CLAW2];
    initWeapon(wp, -1, c.RES_CLAWFX, -1);

    wp = &weapons[c.WEAPON_THROW_AXE];
    initWeapon(wp, -1, c.RES_CROSS_HIT, c.RES_AXE);
    wp.*.wp = c.WEAPON_GUN_POINT;
    wp.*.damage = 12;
    wp.*.shootRange = 160;
    wp.*.bulletSpeed = 10;
    wp.*.flyAni.*.duration = 24;
    wp.*.flyAni.*.angle = -1;
    wp.*.flyAni.*.scaled = false;
    wp.*.deathAni.*.scaled = false;
    wp.*.deathAni.*.at = c.AT_CENTER;
    wp.*.birthAudio = c.AUDIO_LIGHT_SHOOT;
    wp.*.deathAudio = c.AUDIO_ARROW_HIT;

    wp = &weapons[c.WEAPON_MANY_AXES];
    initWeapon(wp, -1, c.RES_CROSS_HIT, c.RES_AXE);
    wp.*.wp = c.WEAPON_GUN_POINT_MULTI;
    wp.*.shootRange = 180;
    wp.*.gap = 70;
    wp.*.effectRange = 50;
    wp.*.damage = 50;
    wp.*.bulletSpeed = 4;
    wp.*.flyAni.*.duration = 24;
    wp.*.flyAni.*.angle = -1;
    wp.*.deathAni.*.at = c.AT_CENTER;
    wp.*.birthAudio = c.AUDIO_LIGHT_SHOOT;
    wp.*.deathAudio = c.AUDIO_ARROW_HIT;

    wp = &weapons[c.WEAPON_SOLID];
    initWeapon(wp, -1, c.RES_SOLIDFX, -1);
    wp.*.deathAni.*.scaled = false;
    wp.*.deathAni.*.angle = -1;
    wp.*.effects[c.BUFF_SLOWDOWN] = c.WeaponBuff{ .chance = 0.3, .duration = 180 };

    wp = &weapons[c.WEAPON_SOLID_GREEN];
    initWeapon(wp, -1, c.RES_SOLID_GREENFX, -1);
    wp.*.shootRange = 96;
    wp.*.deathAni.*.scaled = false;
    wp.*.deathAni.*.angle = -1;
    wp.*.effects[c.BUFF_SLOWDOWN] = c.WeaponBuff{ .chance = 0.3, .duration = 180 };

    wp = &weapons[c.WEAPON_SOLID_CLAW];
    initWeapon(wp, -1, c.RES_SOLID_GREENFX, -1);
    wp.*.wp = c.WEAPON_SWORD_RANGE;
    wp.*.shootRange = 32 * 3 + 16;
    wp.*.damage = 35;
    wp.*.deathAni.*.scaled = false;
    wp.*.deathAni.*.angle = -1;
    wp.*.deathAudio = c.AUDIO_CLAW_HIT_HEAVY;
    wp.*.effects[c.BUFF_SLOWDOWN] = c.WeaponBuff{ .chance = 0.7, .duration = 60 };

    wp = &weapons[c.WEAPON_ICEPICK];
    initWeapon(wp, -1, c.RES_ICESHATTER, c.RES_ICEPICK);
    wp.*.wp = c.WEAPON_GUN_RANGE;
    wp.*.damage = 30;
    wp.*.effectRange = 50;
    wp.*.shootRange = 256;
    wp.*.gap = 180;
    wp.*.bulletSpeed = 8;
    wp.*.deathAni.*.angle = -1;
    wp.*.flyAni.*.scaled = false;
    wp.*.deathAni.*.at = c.AT_CENTER;
    wp.*.effects[c.BUFF_FROZEN] = c.WeaponBuff{ .chance = 0.2, .duration = 60 };
    wp.*.birthAudio = c.AUDIO_ICE_SHOOT;

    wp = &weapons[c.WEAPON_PURPLE_BALL];
    initWeapon(wp, -1, c.RES_PURPLE_EXP, c.RES_PURPLE_BALL);
    wp.*.wp = c.WEAPON_GUN_RANGE;
    wp.*.damage = 20;
    wp.*.effectRange = 50;
    wp.*.shootRange = 256;
    wp.*.gap = 100;
    wp.*.bulletSpeed = 6;
    wp.*.deathAni.*.angle = -1;
    wp.*.deathAni.*.scaled = false;
    wp.*.flyAni.*.scaled = false;
    wp.*.deathAni.*.at = c.AT_CENTER;
    wp.*.birthAudio = c.AUDIO_ICE_SHOOT;
    wp.*.deathAudio = c.AUDIO_ARROW_HIT;

    wp = &weapons[c.WEAPON_PURPLE_STAFF];
    initWeapon(wp, -1, c.RES_PURPLE_EXP, c.RES_PURPLE_BALL);
    wp.*.wp = c.WEAPON_GUN_POINT_MULTI;
    wp.*.damage = 45;
    wp.*.effectRange = 50;
    wp.*.shootRange = 256;
    wp.*.gap = 100;
    wp.*.bulletSpeed = 7;
    wp.*.deathAni.*.angle = -1;
    wp.*.deathAni.*.scaled = false;
    wp.*.flyAni.*.scaled = false;
    wp.*.deathAni.*.at = c.AT_CENTER;
    wp.*.birthAudio = c.AUDIO_ICE_SHOOT;
    wp.*.deathAudio = c.AUDIO_ARROW_HIT;

    wp = &weapons[c.WEAPON_HOLY_SWORD];
    initWeapon(wp, -1, c.RES_GOLDEN_CROSS_HIT, -1);
    wp.*.wp = c.WEAPON_SWORD_RANGE;
    wp.*.damage = 30;
    wp.*.shootRange = 32 * 4;
    wp.*.effects[c.BUFF_DEFFENCE] = c.WeaponBuff{ .chance = 0.6, .duration = 180 };

    wp = &weapons[c.WEAPON_ICE_SWORD];
    initWeapon(wp, -1, c.RES_ICESHATTER, -1);
    wp.*.wp = c.WEAPON_SWORD_RANGE;
    wp.*.shootRange = 32 * 3 + 16;
    wp.*.damage = 80;
    wp.*.gap = 30;
    wp.*.deathAni.*.angle = -1;
    wp.*.deathAni.*.at = c.AT_CENTER;
    wp.*.effects[c.BUFF_FROZEN] = c.WeaponBuff{ .chance = 0.6, .duration = 80 };
    wp.*.deathAudio = c.AUDIO_SWORD_HIT;

    //#ifdef DBG
    //  puts("weapon done");
    //#endif
}
