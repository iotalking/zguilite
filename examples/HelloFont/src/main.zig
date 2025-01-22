const std = @import("std");
const zguilite = @import("zguilite");
const KaiTi_33B = @import("./KaiTi_33B.zig");
const x11 = @import("x11");
const bmp = @import("./background_bmp.zig");
const UI_WIDTH: i32 = 1400; // 示例值，根据实际情况修改
const UI_HEIGHT: i32 = 580; // 示例值，根据实际情况修改

const Z_ORDER_LEVEL_0 = zguilite.Z_ORDER_LEVEL_0;

const Main = struct {
    wnd: zguilite.Wnd = .{ .m_class = "Main", .m_vtable = .{
        .on_paint = Main.on_paint,
    } },

    fn on_paint(w: *zguilite.Wnd) !void {
        if (w.m_surface) |surface| {
            try zguilite.Bitmap.draw_bitmap(surface, w.m_z_order, try zguilite.Theme.get_bmp(.BITMAP_CUSTOM1), 0, 0, 0);
        }
    }
};
pub fn main() !void {
    std.log.debug("main begin", .{});
    try loadResource();
    // zguilite.init();

    const screen_width: i32 = UI_WIDTH;
    const screen_height: i32 = UI_HEIGHT;
    var color_bytes: u32 = 0;
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    const frameBuffer = try x11.createFrameBuffer(allocator, screen_width, screen_height, &color_bytes);
    defer allocator.free(frameBuffer);

    var _display: zguilite.Display = .{};
    try _display.init2(frameBuffer.ptr, screen_width, screen_height, screen_width, screen_height, color_bytes, 3, null);
    const surface = try _display.allocSurface(.Z_ORDER_LEVEL_1, zguilite.Rect.init2(0, 0, screen_width, screen_height));
    surface.set_active(true);

    var mainWnd = Main{};
    mainWnd.wnd.set_surface(surface);

    var btn = zguilite.Button{};
    const ID_DESKTOP = 1;
    const ID_BTN = 2;

    var s_desktop_children = [_]?*const zguilite.WND_TREE{
        &.{
            .p_wnd = btn.asWnd(), //
            .resource_id = ID_BTN,
            .str = "PLAY",
            .x = 0,
            .y = 169,
            .width = 40,
            .height = 20,
            .p_child_tree = null,
        },
    };

    try mainWnd.wnd.connect(null, ID_DESKTOP, null, 0, 0, screen_width, screen_height, &s_desktop_children);
    try mainWnd.wnd.show_window();

    x11.onTouchCallbackObj = x11.onTouchCallback.init(&mainWnd, &struct {
        pub fn onTouch(user: *const anyopaque, x: usize, y: usize, action: zguilite.TOUCH_ACTION) anyerror!void {
            // std.log.debug("onTouch(x:{},y:{})",.{x,y});
            var _mainWnd: *Main = @constCast(@alignCast(@ptrCast(user)));
            try _mainWnd.wnd.on_touch(@intCast(x), @intCast(y), action);
        }
    }.onTouch);

    btn.set_on_click(zguilite.WND_CALLBACK.init(&btn, struct {
        fn onClick(this: *zguilite.Button, id: i32, param: i32) !void {
            _ = id; // autofix
            _ = param; // autofix
            std.log.debug("btn.on_click ", .{});
            const w = this.asWnd();
            var rect = zguilite.Rect.init();
            w.get_screen_rect(&rect);
            const s_text = "朝辞白帝彩云间千里江陵一日还两岸猿声啼不住轻舟已过万重山";
            const FONT_SIZE = 57;
            const START_X = 300;
            const START_Y = 20;
            if (w.m_surface) |m_surface| {
                zguilite.Bitmap.draw_bitmap_from_rect(m_surface, w.m_z_order, @constCast(try zguilite.Theme.get_bmp(.BITMAP_CUSTOM1)), 100, 0, 100, 0, 300, UI_HEIGHT, 0);
                var i: usize = 0;
                for (0..4) |x| {
                    for (0..7) |y| {
                        if (zguilite.Theme.get_font(.FONT_DEFAULT)) |font| {
                            const ix: i32 = @intCast(@as(u32, @truncate(x)));
                            const iy: i32 = @intCast(@as(u32, @truncate(y)));
                            const _x: i32 = START_X - ix * FONT_SIZE;
                            const _y: i32 = START_Y + iy * FONT_SIZE;
                            std.log.debug("draw string:({},{}){s}", .{ _x, _y, s_text[i .. i + 3] });
                            zguilite.Word.draw_string(m_surface, w.m_z_order, s_text[i .. i + 3], _x, _y, font, zguilite.GL_RGB(0, 0, 0), zguilite.GL_ARGB(0, 0, 0, 0));
                        }
                        i += 3;
                        try x11.refreshApp();
                        std.time.sleep(500 * std.time.ns_per_ms);
                    }
                }
            }
        }
    }.onClick));
    try x11.appLoop();
}

fn loadResource() !void {
    try zguilite.Theme.add_bmp(.BITMAP_CUSTOM1, &bmp.background_bmp);
    _ = zguilite.Theme.add_font(.FONT_DEFAULT, @ptrCast(@constCast(&KaiTi_33B.KaiTi_33B)));
    _ = zguilite.Theme.add_color(.COLOR_WND_FONT, zguilite.GL_RGB(255, 255, 255));
    _ = zguilite.Theme.add_color(.COLOR_WND_NORMAL, zguilite.GL_RGB(59, 75, 94));
    _ = zguilite.Theme.add_color(.COLOR_WND_PUSHED, zguilite.GL_RGB(33, 42, 53));
    _ = zguilite.Theme.add_color(.COLOR_WND_FOCUS, zguilite.GL_RGB(43, 118, 219));
    _ = zguilite.Theme.add_color(.COLOR_WND_BORDER, zguilite.GL_RGB(46, 59, 73));
}
