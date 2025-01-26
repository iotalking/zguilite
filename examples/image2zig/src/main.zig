const std = @import("std");
const zguilite = @import("zguilite");
const X11 = @import("x11");
const UI_WIDTH: i32 = 1920; // 示例值，根据实际情况修改
const UI_HEIGHT: i32 = 1080; // 示例值，根据实际情况修改
const zigimg = @import("zigimg");

var image:zigimg.Image = undefined;


fn outZigSource(filename:[]const u8)!void{
    const imageId = std.fs.path.stem(filename);
    const writer = std.io.getStdOut().writer();
    try writer.print(
        \\const zguilite = @import("zguilite");
        \\var raw_data = [_]u16{{
        ,
        .{});
    for(0..image.height)|y|{
        for(0..image.width)|x|{
            const ix:i32 = @truncate(@as(i64,@bitCast(x)));
            _ = ix; // autofix
            const iy:i32 = @truncate(@as(i64,@bitCast(y)));
            _ = iy; // autofix
            const rgb = image.pixels.rgb24[x+y*image.width];
            const u32rgb:u32 = zguilite.GL_RGB(rgb.r,rgb.g,rgb.b);
            const u16rgb = zguilite.GL_RGB_32_to_16(u32rgb);
            try writer.print("{d},",.{u16rgb});
        }
    }
    try writer.print(
        \\}};
        \\pub const _{s} = zguilite.BITMAP_INFO{{
        \\    .width = {d},
        \\    .height = {d},
        \\    .color_bits = 16,
        \\    .pixel_color_array = &raw_data,
        \\}};
        ,
        .{imageId,image.width,image.height}
    );
}
const Main = struct {
    wnd: zguilite.Wnd = .{ .m_class = "Main", .m_vtable = .{
        .on_paint = Main.on_paint,
    } },

    fn on_paint(w: *zguilite.Wnd) !void {
        if (w.m_surface) |surface| {
            for(0..image.height)|y|{
                for(0..image.width)|x|{
                    const ix:i32 = @truncate(@as(i64,@bitCast(x)));
                    const iy:i32 = @truncate(@as(i64,@bitCast(y)));
                    const rgb = image.pixels.rgb24[x+y*image.width];
                    surface.draw_pixel(ix,iy,zguilite.GL_RGB(rgb.r,rgb.g,rgb.b),.Z_ORDER_LEVEL_0);
                }
            }

        }
    }
};

var app = X11{};
pub fn main() !void {
    std.log.debug("main begin", .{});


    try loadResource();
    // zguilite.init();

    const screen_width: i32 = UI_WIDTH;
    const screen_height: i32 = UI_HEIGHT;
    var color_bytes: u32 = 0;
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    var args = std.process.args();
    _ = args.skip();
    const imagePath = args.next() orelse return error.no_image_filename;
    image = try zigimg.Image.fromFilePath(allocator, imagePath);
    defer image.deinit();
    try outZigSource(imagePath);

    const frameBuffer = try app.init(allocator,"main", screen_width, screen_height, &color_bytes);
    defer app.deinit();

    var _display: zguilite.Display = .{};
    try _display.init2(frameBuffer.ptr, screen_width, screen_height, screen_width, screen_height, color_bytes, 3, null);
    var surface = try _display.allocSurface(.Z_ORDER_LEVEL_1, zguilite.Rect.init2(0, 0, screen_width, screen_height));
    surface.set_active(true);

    const rect = zguilite.Rect.init2(0, 0, UI_WIDTH, UI_HEIGHT);

    surface.fill_rect(rect, zguilite.COLORS.BLACK, zguilite.Z_ORDER_LEVEL_0); // clear previous image

    var mainWnd = Main{};
    mainWnd.wnd.set_surface(surface);

    const ID_DESKTOP = 1;
    try mainWnd.wnd.connect(null, ID_DESKTOP, null, 0, 0, screen_width, screen_height, null);
    try mainWnd.wnd.show_window();

    const onIdleCallback = zguilite.WND_CALLBACK.init(&mainWnd, struct {
        fn onIdle(user: *const Main, id: i32, param: i32) !void {
            _ = user; // autofix
            _ = id;
            _ = param;
        }
    }.onIdle);
    app.setIdleCallback(onIdleCallback);

    try app.loop();
}

fn loadResource() !void {
    _ = zguilite.Theme.add_color(.COLOR_WND_FONT, zguilite.GL_RGB(255, 255, 255));
    _ = zguilite.Theme.add_color(.COLOR_WND_NORMAL, zguilite.GL_RGB(59, 75, 94));
    _ = zguilite.Theme.add_color(.COLOR_WND_PUSHED, zguilite.GL_RGB(33, 42, 53));
    _ = zguilite.Theme.add_color(.COLOR_WND_FOCUS, zguilite.GL_RGB(43, 118, 219));
    _ = zguilite.Theme.add_color(.COLOR_WND_BORDER, zguilite.GL_RGB(46, 59, 73));
}
