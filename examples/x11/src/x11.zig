const std = @import("std");
const xlib = @cImport({
    @cInclude("X11/Xlib.h");
    @cInclude("X11/extensions/Xdbe.h");
});
const zguilite = @import("zguilite");
pub const wave_demo = @import("./wave_demo.zig");

const int = c_int;
const uint = c_uint;

id:u32 = 0,
appWindow: ?xlib.Window = null,
display: ?*xlib.Display = null,
screen: int = 0,
winImage: ?*xlib.XImage = null,
winWidth: c_uint = 0,
winHeight: c_uint = 0,
onTouchCallbackObj: ?*onTouchCallback = null,
onIdleCallback: ?zguilite.WND_CALLBACK = null,
allocator:?std.mem.Allocator = null,
frameBuffer:?[]u8 = null,

const Self = @This();

pub fn setTouchCallback(self:*Self,cb:?*onTouchCallback)void{
    self.onTouchCallbackObj = cb;
}
pub fn setIdleCallback(self:*Self,cb:?zguilite.WND_CALLBACK)void{
    self.onIdleCallback = cb;
}

pub fn deinit(self:*Self)void{
    if(self.allocator)|allocator|{
        if(self.frameBuffer)|fb|{
            allocator.free(fb);
        }
    }
}
pub fn init(self:*Self,allocator: std.mem.Allocator,id:?[]const u8, w: uint, h: uint, colorBytes: *uint) ![]u8 {
    const _id = id orelse return error.IdNull;
    const _display = xlib.XOpenDisplay(null) orelse return error.DisplayNull;
    self.display = _display;
    errdefer {
        _ = xlib.XCloseDisplay(_display);
        self.display = null;
    }
    std.log.debug("x11 init display:{d}",.{_display});
    self.allocator = allocator;
    errdefer self.allocator = null;

    var buffer: []u8 = undefined;
    self.screen = xlib.DefaultScreen(_display);
    if (self.screen < 0) {
        return error.default_screen;
    }
    
    colorBytes.* = 4;
    std.log.debug("colorBytes:{}", .{colorBytes.*});

    buffer = try allocator.alloc(u8, @intCast(@as(c_uint, @bitCast(w * h * colorBytes.*))));
    self.frameBuffer = buffer;
    errdefer {
        self.frameBuffer = null;
        allocator.free(buffer);
    }
    self.winWidth = @bitCast(w);
    self.winHeight = @bitCast(h);

    const depth: c_uint = @bitCast(xlib.DefaultDepth(_display, self.screen));
    const visual = xlib.DefaultVisual(_display, self.screen);
    const winImage = xlib.XCreateImage(_display, visual, depth, xlib.ZPixmap, 0, @ptrCast(buffer.ptr), self.winWidth, self.winHeight, 32, 0) orelse return error.XCreateImage;
    self.winImage = winImage;
    if (0 == xlib.XInitImage(self.winImage.?)) {
        return error.init_image;
    }

    const rootWindow = xlib.RootWindow(_display, self.screen);

    const uw: c_uint = @bitCast(w);
    const uh: c_uint = @bitCast(h);

    const appWindow = xlib.XCreateSimpleWindow(_display, rootWindow, 50, 50, uw, uh, 1, 0, 0);
    self.appWindow = appWindow;
    _ = xlib.XMapWindow(_display, appWindow);
    errdefer {
        _ = xlib.XDestroyWindow(_display,appWindow);
        self.appWindow = null;
    }
    if(xlib.XStoreName(_display,appWindow,_id.ptr) == 0 ){
        return error.XStoreName;
    }
    @memset(buffer, 0x0);
    return buffer;
}

pub fn initThreads()void{
    _ = xlib.XInitThreads();
}
pub fn refresh(self:*Self) !void {
    const win = self.appWindow orelse return error.app_window;
    const _display = self.display orelse return error.display;

    const image = self.winImage orelse return error.image;

    const gc = xlib.DefaultGC(_display, self.screen);

    std.log.debug("refreshApp {d}x{d}", .{ self.winWidth, self.winHeight });
    if (xlib.XPutImage(_display, win, gc, image, 0, 0, 0, 0, self.winWidth, self.winHeight) < 0) {
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


pub fn loop(self:*Self) !void {
    std.log.debug("apploop enter", .{});
    const win = self.appWindow orelse return error.appWindow;
   
    const _display = self.display orelse return error.display;

    if (self.winImage == null) {
        return error.image;
    }

    defer _ = xlib.XCloseDisplay(_display);
    // _ = xlib.XClearWindow(_display, win);
    var msg = xlib.XInternAtom(_display, "WM_DELETE_WINDOW", 0);
    _ = xlib.XSetWMProtocols(_display,win,&msg,1);

    // try refreshApp();
    var xevent: xlib.XEvent = undefined;

    if (xlib.XSelectInput(_display, win, xlib.ExposureMask | xlib.PointerMotionMask | xlib.ButtonPressMask | xlib.ButtonReleaseMask | xlib.KeyPressMask | xlib.StructureNotifyMask | xlib.ButtonPressMask | xlib.ButtonReleaseMask | xlib.SubstructureNotifyMask) == 0) {
        return error.xselect_input;
    }
    var touchDown = false;
    var exit = false;
    while (!exit) {
        if (xlib.XPending(_display) != 0) {
            std.log.debug("wait xevent", .{});
            _ = xlib.XNextEvent(_display, &xevent);
            std.log.debug("got xevent id:{d} type:{any}", .{_display,xevent.type});
        } else {
            std.log.debug("no pending xevent id:{d}", .{_display});
            if (self.onIdleCallback) |*cb| {
                try cb.on(0, 0);
            }
            // try wave_demo.refrushWaveCtrl();
            try self.refresh();
            std.time.sleep(17 * std.time.ns_per_ms);
        }

        switch (xevent.type) {
            xlib.Expose => {
                std.log.debug("appLoop Expose", .{});
                try self.refresh();
            },
            xlib.ClientMessage => {
                exit = true;
            },
            xlib.MotionNotify => {
                if (self.onTouchCallbackObj) |_cb| {
                    var cb = @constCast(_cb);
                    if (touchDown) {
                        cb.onTouch(@intCast(xevent.xmotion.x), @intCast(xevent.xmotion.y), .TOUCH_MOVE) catch {};
                    }
                }
            },
            xlib.ButtonPress => {
                if (self.onTouchCallbackObj) |_cb| {
                    var cb = @constCast(_cb);
                    if (touchDown == false) {
                        touchDown = true;
                        cb.onTouch(@intCast(xevent.xmotion.x), @intCast(xevent.xmotion.y), .TOUCH_DOWN) catch {};
                    }
                }
            },
            xlib.ButtonRelease => {
                if (self.onTouchCallbackObj) |_cb| {
                    var cb = @constCast(_cb);
                    if (touchDown) {
                        touchDown = false;
                        cb.onTouch(@intCast(xevent.xmotion.x), @intCast(xevent.xmotion.y), .TOUCH_UP) catch {};
                    }
                }
            },
            else => {
                try self.refresh();
            },
        }
    }
}
