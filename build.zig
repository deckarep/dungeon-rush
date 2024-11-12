const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "dungeonrush-zig",
        .root_source_file = b.path("zsrc/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    //exe.linkSystemLibrary("objc");
    // exe.linkFramework("Cocoa");
    // exe.linkFramework("CoreAudio");
    // exe.linkFramework("Carbon");
    // exe.linkFramework("Metal");
    // exe.linkFramework("QuartzCore");
    // exe.linkFramework("AudioToolbox");
    // exe.linkFramework("ForceFeedback");
    // exe.linkFramework("GameController");
    // exe.linkFramework("CoreHaptics");
    // exe.linkFramework("IOKit");

    // exe.linkSystemLibrary("iconv");

    // Proper: Link SDL2 and friends.
    exe.linkSystemLibrary("SDL2");
    exe.linkSystemLibrary("SDL2_mixer");
    exe.linkSystemLibrary("SDL2_image");
    exe.linkSystemLibrary("SDL2_ttf");
    exe.linkSystemLibrary("SDL2_net");

    // Proper: Link SDL3 and friends
    exe.addIncludePath(b.path("lib/SDL3.framework/include"));
    exe.addFrameworkPath(b.path("lib"));
    exe.addRPath(b.path("lib"));
    exe.linkFramework("SDL3");
    // Strategy is to upgrade to these later...I think I can use
    // SDL2 functions for now with SDL3.
    // exe.linkFramework("SDL3_mixer");
    // exe.linkFramework("SDL3_image");
    // exe.linkFramework("SDL3_ttf");
    // exe.linkFramework("SDL3_net");

    // exe.linkSystemLibrary2("SDL2", .{ .preferred_link_mode = .static });
    // exe.linkSystemLibrary2("SDL2_mixer", .{ .preferred_link_mode = .static });
    // exe.linkSystemLibrary2("SDL2_image", .{ .preferred_link_mode = .static });
    // exe.linkSystemLibrary2("SDL2_ttf", .{ .preferred_link_mode = .static });
    // exe.linkSystemLibrary2("SDL2_net", .{ .preferred_link_mode = .static });

    // exe.linkSystemLibrary("freetype");
    // exe.linkSystemLibrary("harfbuzz");
    // exe.linkSystemLibrary("bz2");
    // exe.linkSystemLibrary("zlib");
    // exe.linkSystemLibrary("graphite2");

    // Link C
    //exe.linkSystemLibrary2("c", .{ .preferred_link_mode = .static });
    exe.linkSystemLibrary("c");

    // This declares intent for the executable to be installed into the
    // standard location when the user invokes the "install" step (the default
    // step when running `zig build`).
    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}
