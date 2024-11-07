const std = @import("std");
const xlib = @cImport({
    @cInclude("X11/Xlib.h");
});
const int = c_int;
var appWindow: ?xlib.Window = null;
var display: ?*xlib.Display = null;
var screen: int = 0;
var winImage: ?*xlib.XImage = null;
var winWidth: c_uint = 0;
var winHeight: c_uint = 0;

pub fn createFrameBuffer(allocator: std.mem.Allocator, w: int, h: int, colorBytes: *int) ![]u8 {
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

    if (xlib.XSelectInput(display, win, xlib.ExposureMask | xlib.KeyPressMask | xlib.StructureNotifyMask | xlib.ButtonPressMask | xlib.ButtonReleaseMask | xlib.SubstructureNotifyMask) == 0) {
        return error.xselect_input;
    }
    try refreshApp();
    while (true) {
        std.log.debug("wait xevent", .{});
        _ = xlib.XNextEvent(_display, &xevent);
        std.log.debug("got xevent type:{any}", .{xevent.type});

        if (xevent.type == xlib.Expose) {
            std.log.debug("appLoop Expose", .{});
            try refreshApp();
        }
    }
}
