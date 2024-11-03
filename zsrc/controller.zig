const std = @import("std");
const c = @import("cdefs.zig").c;

// Buffalo Classic USB Gamepad - bug!!!
// I should go play the lottery as I burned like 4 hours trying to get this damn controller working.
// Or better yet, don't play the lottery.
// Had to manually force this mapping on it, it just doesn't work correctly.
const BuffaloClassicUSBMapping = "0500c2f8ac0500000400000050f16d04,Retro Controller,dpup:+a1,dpdown:-a1,dpleft:-a0,dpright:+a0,platform:Mac OS X,a:b1,b:b0,x:b5,y:b4,start:b3,back:b2,rightshoulder:b7,leftshoulder:b6,";

pub var controller = Controller.init();

pub const ControllerState = struct {
    DPad: struct {
        Up: bool = false,
        Down: bool = false,
        Left: bool = false,
        Right: bool = false,
    },

    Button: struct {
        Back: bool = false,
        Start: bool = false,

        X: bool = false,
        Y: bool = false,
        A: bool = false,
        B: bool = false,

        LeftShoulder: bool = false,
        RightShoulder: bool = false,
    },
};

pub const Controller = struct {
    sdlController: ?*c.SDL_GameController = null,
    states: ControllerState = ControllerState{ .DPad = .{}, .Button = .{} },

    pub fn init() Controller {
        return .{};
    }

    fn checkButton(self: Controller, btn: c_int) bool {
        if (self.sdlController) |ctrl| {
            return c.SDL_GameControllerGetButton(ctrl, btn) == 1;
        }
        return false;
    }

    pub fn updateStates(self: *Controller) void {
        var st = ControllerState{ .DPad = .{}, .Button = .{} };

        // Check directional pad.
        if (self.checkButton(c.SDL_CONTROLLER_BUTTON_DPAD_UP)) {
            st.DPad.Up = true;
        }
        if (self.checkButton(c.SDL_CONTROLLER_BUTTON_DPAD_DOWN)) {
            st.DPad.Down = true;
        }
        if (self.checkButton(c.SDL_CONTROLLER_BUTTON_DPAD_LEFT)) {
            st.DPad.Left = true;
        }
        if (self.checkButton(c.SDL_CONTROLLER_BUTTON_DPAD_RIGHT)) {
            st.DPad.Right = true;
        }

        // Check buttons
        if (self.checkButton(c.SDL_CONTROLLER_BUTTON_X)) {
            st.Button.X = true;
        }
        if (self.checkButton(c.SDL_CONTROLLER_BUTTON_Y)) {
            st.Button.Y = true;
        }
        if (self.checkButton(c.SDL_CONTROLLER_BUTTON_A)) {
            st.Button.A = true;
        }
        if (self.checkButton(c.SDL_CONTROLLER_BUTTON_B)) {
            st.Button.B = true;
        }
        if (self.checkButton(c.SDL_CONTROLLER_BUTTON_BACK)) {
            st.Button.Back = true;
        }
        if (self.checkButton(c.SDL_CONTROLLER_BUTTON_START)) {
            st.Button.Start = true;
        }
        if (self.checkButton(c.SDL_CONTROLLER_BUTTON_LEFTSHOULDER)) {
            st.Button.LeftShoulder = true;
        }
        if (self.checkButton(c.SDL_CONTROLLER_BUTTON_RIGHTSHOULDER)) {
            st.Button.RightShoulder = true;
        }

        self.states = st;
    }

    /// reset clears all states, call this with defer immediately after invoking poll().
    /// Calling this ensures the state is already read from SDL in a fresh event loop.
    pub fn reset(self: *Controller) void {
        self.states = .{ .DPad = .{}, .Button = .{} };
    }

    /// poll must be called within an SDL2 event loop and it handles all the SDL2 magic
    /// internally to ensure the controller state is read.
    pub fn poll(self: *Controller, e: c.SDL_Event) void {
        switch (e.type) {
            c.SDL_CONTROLLERDEVICEADDED => {
                std.log.debug("{d} controllers have been detected!", .{c.SDL_NumJoysticks()});
                std.log.debug("IsGameController => {}", .{c.SDL_IsGameController(0) == 1});

                if (c.SDL_GameControllerOpen(0)) |ctrl| {
                    self.sdlController = ctrl;
                    std.log.debug("Controller is bound => {?}", .{ctrl});
                    const addResult = c.SDL_GameControllerAddMapping(BuffaloClassicUSBMapping);
                    std.log.debug("addMapping result => {d}", .{addResult});
                } else {
                    std.log.debug("WARN: A gamepad was added but couldn't be opened!", .{});
                }
            },
            c.SDL_CONTROLLERDEVICEREMOVED => {
                std.log.debug("a controller was REMOVED sucka!", .{});
                self.sdlController = null;
            },
            c.SDL_CONTROLLERBUTTONDOWN => {
                const ctrl = self.sdlController;
                if (ctrl == null) {
                    std.log.debug("ctrl is null, returning...", .{});
                    return;
                }

                const buttonStr: []const u8 = std.mem.span(c.SDL_GameControllerGetStringForButton(e.cbutton.button));
                std.log.debug("button => {s}", .{buttonStr});

                // Update all button + dpad states.
                self.updateStates();
            },
            else => {},
        }
    }
};
