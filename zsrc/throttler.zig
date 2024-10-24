const c = @import("cdefs.zig").c;

/// This is a simple frame-rate throttler to get a consistent framerate across
/// all machines instead of relying on VSync. Also, this is friendly on the
/// CPU because it forces SDL to sleep a bit using the SDL_Delay call.
/// r.c. - This is new Zig code that is not a part of the original C-based game.
/// This code is used in the main Game.gameLoop() function and also in the UI
/// menu screen which houses another temporary event loop.
pub const Throttler = struct {
    const DELAY = 17;

    newTicks: u32 = undefined,
    lastTicks: u32 = 0,

    // For framerate
    frameCount: u32 = 0,
    fps: f32 = 0.0,
    lastFpsTicks: u32 = 0,

    pub fn init() Throttler {
        return .{
            .newTicks = 0,
            .lastTicks = 0,
            .frameCount = 0,
            .fps = 0.0,
            .lastFpsTicks = c.SDL_GetTicks(),
        };
    }

    pub fn shouldWait(self: *Throttler) bool {
        // Get ticks
        self.newTicks = c.SDL_GetTicks();

        // Get ticks from last frame and compare with framerate
        if (self.newTicks - self.lastTicks < DELAY) {
            c.SDL_Delay(DELAY - (self.newTicks - self.lastTicks));
            return true;
        }

        return false;
    }

    pub fn tick(self: *Throttler) void {
        self.lastTicks = self.newTicks;

        // Below is for fps calcualation.
        self.frameCount += 1;

        // Update the frame rate every second
        const currentTicks = c.SDL_GetTicks();
        if (currentTicks - self.lastFpsTicks >= 1000) {
            self.fps = @as(f32, @floatFromInt(self.frameCount)) * 1000.0 /
                (@as(f32, @floatFromInt(currentTicks)) - @as(f32, @floatFromInt(self.lastFpsTicks)));
            self.frameCount = 0;
            self.lastFpsTicks = currentTicks;
        }
    }

    /// Returns the current frame rate (FPS).
    pub fn frameRate(self: Throttler) f32 {
        return self.fps;
    }
};
