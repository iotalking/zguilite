const std = @import("std");
const xlib = @cImport({
    @cInclude("X11/Xlib.h");
});
const zguilite = @import("zguilite");
pub const wave_demo = @import("./wave_demo.zig");

const int = c_int;
const uint = c_uint;
var appWindow: ?xlib.Window = null;
var display: ?*xlib.Display = null;
var screen: int = 0;
var winImage: ?*xlib.XImage = null;
var winWidth: c_uint = 0;
var winHeight: c_uint = 0;

pub fn createFrameBuffer(allocator: std.mem.Allocator, w: uint, h: uint, colorBytes: *uint) ![]u8 {
    display = xlib.XOpenDisplay("");
    var buffer: []u8 = undefined;
    if (display) |_display| {
        screen = xlib.DefaultScreen(_display);
        if (screen < 0) {
            return error.default_screen;
        }
        colorBytes.* = 4;
        std.log.debug("colorBytes:{}", .{colorBytes.*});

        buffer = try allocator.alloc(u8, @intCast(@as(c_uint, @bitCast(w * h * colorBytes.*))));
        errdefer allocator.free(buffer);

        winWidth = @bitCast(w);
        winHeight = @bitCast(h);

        const depth: c_uint = @bitCast(xlib.DefaultDepth(display, screen));
        const visual = xlib.DefaultVisual(display, screen);
        winImage = xlib.XCreateImage(display, visual, depth, xlib.ZPixmap, 0, @ptrCast(buffer.ptr), winWidth, winHeight, 32, 0);
        if (winImage == null) {
            return error.create_iamge;
        }
        if (0 == xlib.XInitImage(winImage.?)) {
            return error.init_image;
        }
        const rootWindow = xlib.RootWindow(_display, screen);

        const uw: c_uint = @bitCast(w);
        const uh: c_uint = @bitCast(h);

        appWindow = xlib.XCreateSimpleWindow(_display, rootWindow, 50, 50, uw, uh, 1, 0, 0);
        _ = xlib.XMapWindow(_display, appWindow.?);
    } else {
        return error.open_display;
    }
    @memset(buffer, 0xff);
    return buffer;
}

pub fn refreshApp() !void {
    if (appWindow == null) {
        return error.app_window;
    }
    const win = appWindow.?;
    if (display == null) {
        return error.display;
    }

    if (winImage == null) {
        return error.image;
    }
    const image = winImage.?;

    const gc = xlib.DefaultGC(display, screen);

    std.log.debug("appscreen {d}x{d}", .{ winWidth, winHeight });
    if (xlib.XPutImage(display, win, gc, image, 0, 0, 0, 0, winWidth, winHeight) < 0) {
        return error.put_image;
    }
}

pub const onTouchCallback = struct {
    index: u32 = 0,
    obj: *anyopaque,
    callback: CALLBACK,
    const CALLBACK = *const fn (user: *anyopaque, x: i32, y: i32, action: zguilite.TOUCH_ACTION) anyerror!void;

    pub fn init(obj: *anyopaque, callback: anytype) onTouchCallback {
        return .{
            .obj = obj,
            .callback = @ptrCast(callback),
        };
    }
    pub fn onTouch(this: *onTouchCallback, x: i32, y: i32, action: zguilite.TOUCH_ACTION) !void {
        std.log.debug("onTouchCallback onTouch ({},{}) {} index:{}", .{ x, y, action, this.index });
        switch (action) {
            .TOUCH_DOWN => {
                this.index = 0;
            },
            .TOUCH_MOVE => {
                this.index +|= 1;
            },
            .TOUCH_UP => {},
        }
        try this.callback(this.obj, x, y, action);
    }
};

pub var onTouchCallbackObj: ?onTouchCallback = null;
pub var onIdleCallback: ?zguilite.WND_CALLBACK = null;

pub fn appLoop() !void {
    std.log.debug("apploop enter", .{});
    if (appWindow == null) {
        return error.app_window;
    }
    const win = appWindow.?;
    if (display == null) {
        return error.display;
    }
    const _display = display.?;

    if (winImage == null) {
        return error.image;
    }

    defer _ = xlib.XCloseDisplay(display);
    // _ = xlib.XClearWindow(_display, win);

    // try refreshApp();
    var xevent: xlib.XEvent = undefined;

    if (xlib.XSelectInput(display, win, xlib.ExposureMask | xlib.PointerMotionMask | xlib.ButtonPressMask | xlib.ButtonReleaseMask | xlib.KeyPressMask | xlib.StructureNotifyMask | xlib.ButtonPressMask | xlib.ButtonReleaseMask | xlib.SubstructureNotifyMask) == 0) {
        return error.xselect_input;
    }
    try refreshApp();
    var touchDown = false;
    while (true) {
        if (xlib.XPending(_display) != 0) {
            // std.log.debug("wait xevent", .{});
            _ = xlib.XNextEvent(_display, &xevent);
            // std.log.debug("got xevent type:{any}", .{xevent.type});
        } else {
            // std.log.debug("no pending xevent", .{});
            if (onIdleCallback) |*cb| {
                try cb.on(0, 0);
            }
        }

        switch (xevent.type) {
            xlib.Expose => {
                std.log.debug("appLoop Expose", .{});
                try refreshApp();
            },
            xlib.MotionNotify => {
                if (onTouchCallbackObj) |*_cb| {
                    var cb = @constCast(_cb);
                    if (touchDown) {
                        cb.onTouch(@intCast(xevent.xmotion.x), @intCast(xevent.xmotion.y), .TOUCH_MOVE) catch {};
                    }
                    try refreshApp();
                }
            },
            xlib.ButtonPress => {
                if (onTouchCallbackObj) |*_cb| {
                    var cb = @constCast(_cb);
                    if (touchDown == false) {
                        touchDown = true;
                        cb.onTouch(@intCast(xevent.xmotion.x), @intCast(xevent.xmotion.y), .TOUCH_DOWN) catch {};
                    }
                }
                try refreshApp();
            },
            xlib.ButtonRelease => {
                if (onTouchCallbackObj) |*_cb| {
                    var cb = @constCast(_cb);
                    if (touchDown) {
                        touchDown = false;
                        cb.onTouch(@intCast(xevent.xmotion.x), @intCast(xevent.xmotion.y), .TOUCH_UP) catch {};
                    }
                }
                try refreshApp();
            },
            else => {
                try wave_demo.refrushWaveCtrl();
                try refreshApp();
                std.time.sleep(17 * std.time.ns_per_ms);
            },
        }
    }
}
