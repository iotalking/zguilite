const std = @import("std");
const xlib = @cImport({
    @cInclude("X11/Xlib.h");
    @cInclude("X11/Xutil.h");
});
const truetype = @import("./true_type/TrueType.zig");

const int = c_int;
const assert = std.debug.assert;

var appWindow: ?xlib.Window = null;
var display: ?*xlib.Display = null;
var screen: int = 0;
var winImage: ?*xlib.XImage = null;
var winWidth: c_uint = 0;
var winHeight: c_uint = 0;
var allocator: ?std.mem.Allocator = null;

pub fn createFrameBuffer(_allocator: std.mem.Allocator, w: int, h: int, colorBytes: *int) ![]u8 {
    allocator = _allocator;
    display = xlib.XOpenDisplay(null);
    var buffer: []u8 = undefined;
    if (display) |_display| {
        screen = xlib.DefaultScreen(_display);
        if (screen < 0) {
            return error.default_screen;
        }
        colorBytes.* = 4;
        std.log.debug("colorBytes:{}", .{colorBytes.*});

        buffer = try _allocator.alloc(u8, @intCast(@as(c_uint, @bitCast(w * h * colorBytes.*))));
        errdefer _allocator.free(buffer);

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
        assert(rootWindow != 0);

        // var attributes = xlib.XWindowAttributes{
        //     .backing_store = xlib.Always,
        //     .your_event_mask = xlib.ExposureMask,
        // };
        const uw: c_uint = @bitCast(w);
        const uh: c_uint = @bitCast(h);

        appWindow = xlib.XCreateSimpleWindow(_display, rootWindow, 50, 50, uw, uh, 1, 0, 0);
        if (appWindow) |win| {
            _ = xlib.XMapWindow(_display, win);
        } else {
            return error.create_window;
        }
    } else {
        return error.open_display;
    }
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

    try showFont();
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
    defer _ = XDestroyImage(winImage.?);

    _ = xlib.XClearWindow(_display, win);

    // try refreshApp();
    var xevent: xlib.XEvent = undefined;

    if (xlib.XSelectInput(display, win, xlib.ExposureMask | xlib.KeyPressMask | xlib.StructureNotifyMask | xlib.ButtonPressMask | xlib.ButtonReleaseMask | xlib.SubstructureNotifyMask) == 0) {
        return error.xselect_input;
    }
    while (true) {
        std.log.debug("wait xevent", .{});
        _ = xlib.XNextEvent(_display, &xevent);
        switch (xevent.type) {
            else => {},
            xlib.MapNotify => {
                std.log.debug("appLoop MapNotify", .{});
            },
            xlib.Expose => {
                std.log.debug("appLoop onPaint", .{});
                try onPaint();
            },
            xlib.DestroyNotify => {
                std.log.debug("appLoop DestroyNotify", .{});
            },
        }
    }
}
extern fn XDestroyImage([*c]xlib.XImage) c_int;
fn onPaint() !void {
    assert(winImage != null);
    // const image = winImage.?;

    try refreshApp();
}
pub fn showFont() !void {
    assert(winImage != null);
    assert(allocator != null);
    assert(appWindow != null);
    const win = appWindow.?;

    const _allocator = allocator.?;

    const image = winImage.?;

    // _ = surface;
    const tf = try truetype.load(@embedFile("./font.ttf"));
    const codepoint = try std.unicode.utf8Decode("国");
    const gIdx = tf.codepointGlyphIndex(codepoint);
    if (gIdx) |idx| {
        const fontHeight = 100;
        // var fontCount: usize = 0;
        const scale = tf.scaleForPixelHeight(@floatFromInt(fontHeight));

        var buffer: std.ArrayListUnmanaged(u8) = .{};
        defer buffer.deinit(_allocator);
        const ftBitmap = try tf.glyphBitmapSubpixel(_allocator, &buffer, idx, scale, scale, 100, 100);
        const pixels = buffer.items;
        std.log.debug("ftBitmap:{any}", .{ftBitmap});
        //draw font box
        const off_x: usize = @as(u16, @bitCast(ftBitmap.off_x));
        const off_y: usize = @as(u16, @bitCast(ftBitmap.off_y));

        // const gc = xlib.XCreateGC(display, appWindow.?, 0, null);
        // if (gc == null) {
        //     return error.XCreateGC;
        // }
        // defer _ = xlib.XFreeGC(display, gc);

        const gc = xlib.DefaultGC(display, screen);

        // // 获取颜色
        // XColor color;
        // color.red = 0xffff;
        // color.green = 0x0000;
        // color.blue = 0x0000;
        // XAllocColor(display, DefaultColormap(display, DefaultScreen(display)), &color);

        // // 设置GC的前景色为红色
        // XSetForeground(display, gc, color.pixel);
        // var color: xlib.XColor = .{
        //     .red = 0xffff,
        //     .green = 0x0000,
        //     .blue = 0x0000,
        // };
        // const colormap = xlib.DefaultColormap(display, screen);
        // if (xlib.XAllocColor(display, colormap, &color) == 0) {
        //     return error.XAllocColor;
        // }
        // defer _ = xlib.XFreeColors(display, colormap, &color.pixel, 1, xlib.AllPlanes);

        if (xlib.XSetForeground(display, gc, xlib.WhitePixel(display, screen)) == 0) {
            return error.XSetForeground;
        }
        if (xlib.XSetLineAttributes(display, gc, 2, xlib.LineSolid, xlib.CapRound, xlib.JoinRound) == 0) {
            return error.XSetLineAttributes;
        }
        if (xlib.XDrawRectangle(display, win, gc, 0, 0, fontHeight, fontHeight) == 0) {
            return error.XDrawRectangle;
        }

        // if (xlib.XFillRectangle(display, win, gc, 0, 0, 100, 100) == 0) {
        //     return error.XFillRectangle;
        // }
        // if (xlib.XDrawLine(display, win, gc, 0, 0, 100, 100) == 0) {
        //     return error.XDrawLine;
        // }
        for (off_y..(off_y + ftBitmap.height)) |y| {
            for (off_x..(off_x + ftBitmap.width)) |x| {
                const ix = x - off_x;
                const iy = y - off_y;
                const pixel = pixels[iy * ftBitmap.width + ix];
                if (pixel > 0) {
                    if (XPutPixel(image, @truncate(@as(isize, @bitCast(x))), @truncate(@as(isize, @bitCast(y))), pixel) == 0) {
                        return error.XPutPixel;
                    }
                    // if (xlib.XDrawPoint(display, win, gc, @truncate(@as(isize, @bitCast(x))), @truncate(@as(isize, @bitCast(y)))) == 0) {
                    //     return error.XDrawPoint;
                    // }
                }
            }
        }
        // _ = off_x;
        // _ = off_y;
        // _ = pixels;
        // _ = image;

        if (xlib.XFlush(display) == 0) {
            return error.XFlush;
        }
    }
}

extern fn XPutPixel([*c]xlib.XImage, c_int, c_int, c_ulong) callconv(.C) c_int;
