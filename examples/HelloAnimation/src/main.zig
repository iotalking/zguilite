const std = @import("std");
const zguilite = @import("zguilite");
const KaiTi_19 = @import("./KaiTi_19.zig");
const x11 = @import("x11");
// comptime{
//     inline for(0..24)|i|{

//     }
// }
const frame_00_bmp = @import("./frame_00_bmp.zig").frame_00_bmp;
const frame_01_bmp = @import("./frame_01_bmp.zig").frame_01_bmp;
const frame_02_bmp = @import("./frame_02_bmp.zig").frame_02_bmp;
const frame_03_bmp = @import("./frame_03_bmp.zig").frame_03_bmp;
const frame_04_bmp = @import("./frame_04_bmp.zig").frame_04_bmp;
const frame_05_bmp = @import("./frame_05_bmp.zig").frame_05_bmp;
const frame_06_bmp = @import("./frame_06_bmp.zig").frame_06_bmp;
const frame_07_bmp = @import("./frame_07_bmp.zig").frame_07_bmp;
const frame_08_bmp = @import("./frame_08_bmp.zig").frame_08_bmp;
const frame_09_bmp = @import("./frame_09_bmp.zig").frame_09_bmp;
const frame_10_bmp = @import("./frame_10_bmp.zig").frame_10_bmp;
const frame_11_bmp = @import("./frame_11_bmp.zig").frame_11_bmp;
const frame_12_bmp = @import("./frame_12_bmp.zig").frame_12_bmp;
const frame_13_bmp = @import("./frame_13_bmp.zig").frame_13_bmp;
const frame_14_bmp = @import("./frame_14_bmp.zig").frame_14_bmp;
const frame_15_bmp = @import("./frame_15_bmp.zig").frame_15_bmp;
const frame_16_bmp = @import("./frame_16_bmp.zig").frame_16_bmp;
const frame_17_bmp = @import("./frame_17_bmp.zig").frame_17_bmp;
const frame_18_bmp = @import("./frame_18_bmp.zig").frame_18_bmp;
const frame_19_bmp = @import("./frame_19_bmp.zig").frame_19_bmp;
const frame_20_bmp = @import("./frame_20_bmp.zig").frame_20_bmp;
const frame_21_bmp = @import("./frame_21_bmp.zig").frame_21_bmp;
const frame_22_bmp = @import("./frame_22_bmp.zig").frame_22_bmp;
const frame_23_bmp = @import("./frame_23_bmp.zig").frame_23_bmp;

const s_frames = [_]*const zguilite.BITMAP_INFO{
    &frame_00_bmp,
    &frame_01_bmp,
    &frame_02_bmp,
    &frame_03_bmp,
    &frame_04_bmp,
    &frame_05_bmp,
    &frame_06_bmp,
    &frame_07_bmp,
    &frame_08_bmp,
    &frame_09_bmp,
    &frame_10_bmp,
    &frame_11_bmp,
    &frame_12_bmp,
    &frame_13_bmp,
    &frame_14_bmp,
    &frame_15_bmp,
    &frame_16_bmp,
    &frame_17_bmp,
    &frame_18_bmp,
    &frame_19_bmp,
    &frame_20_bmp,
    &frame_21_bmp,
    &frame_22_bmp,
    &frame_23_bmp,
};
const Main = struct {
    wnd: zguilite.Wnd = .{ .m_class = "Main", .m_vtable = .{
        .on_paint = Main.on_paint,
    } },

    fn on_paint(w: *zguilite.Wnd) !void {
        var rect = zguilite.Rect.init();
        w.get_screen_rect(&rect);
        try zguilite.Theme.add_bmp(.BITMAP_CUSTOM1, &frame_00_bmp);
        // c_bitmap::draw_bitmap(m_surface, m_z_order, c_theme::get_bmp(BITMAP_CUSTOM1), rect.m_left, rect.m_top);
        if (w.m_surface) |surface| {
            zguilite.Bitmap.draw_bitmap(surface, w.m_z_order, try zguilite.Theme.get_bmp(.BITMAP_CUSTOM1), rect.m_left, rect.m_top, 0);
        }
    }
};
pub fn main() !void {
    std.log.debug("main begin", .{});
    try loadResource();
    // zguilite.init();

    const screen_width: u32 = 1024;
    const screen_height: u32 = 800;
    var color_bytes: u32 = 0;
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    const frameBuffer = try x11.createFrameBuffer(allocator, screen_width, screen_height, &color_bytes);
    defer allocator.free(frameBuffer);

    var _display: zguilite.Display = .{};
    try _display.init2(frameBuffer.ptr, screen_width, screen_height, screen_width, screen_height, color_bytes, 3, null);
    const surface = try _display.alloSurface(.Z_ORDER_LEVEL_1, zguilite.Rect.init2(0, 0, screen_width, screen_height));
    surface.set_active(true);

    var btn = zguilite.Button{};
    const ID_DESKTOP = 1;
    const ID_BTN = 2;

    var s_desktop_children = [_]?*const zguilite.WND_TREE{
        &.{
            .p_wnd = btn.asWnd(), //
            .resource_id = ID_BTN,
            .str = "变形",
            .x = 0,
            .y = 169,
            .width = 40,
            .height = 20,
            .p_child_tree = null,
        },
    };

    var mainWnd = Main{};
    mainWnd.wnd.set_surface(surface);

    x11.onTouchCallbackObj = x11.onTouchCallback.init(&mainWnd, &struct {
        pub fn onTouch(user: *const anyopaque, x: usize, y: usize, action: zguilite.TOUCH_ACTION) anyerror!void {
            // std.log.debug("onTouch(x:{},y:{})",.{x,y});
            var _mainWnd: *Main = @constCast(@alignCast(@ptrCast(user)));
            try _mainWnd.wnd.on_touch(@intCast(x), @intCast(y), action);
        }
    }.onTouch);

    std.log.debug("main set button on_click", .{});
    btn.set_on_click(zguilite.WND_CALLBACK.init(&btn, struct {
        fn onClick(this: *zguilite.Button, id: i32, param: i32) !void {
            _ = id; // autofix
            _ = param; // autofix
            std.log.debug("btn.on_click ", .{});
            const w = this.asWnd();
            var rect = zguilite.Rect.init();
            w.get_screen_rect(&rect);
            for (s_frames) |bmp| {
                try zguilite.Theme.add_bmp(.BITMAP_CUSTOM1, bmp);
                if (w.m_surface) |m_surface| {
                    zguilite.Bitmap.draw_bitmap(m_surface, w.m_z_order, try zguilite.Theme.get_bmp(.BITMAP_CUSTOM1), 0, 0, 0);
                    try x11.refreshApp();
                    std.time.sleep(60 * std.time.ns_per_ms);
                }
            }
        }
    }.onClick));
    try mainWnd.wnd.connect(null, ID_DESKTOP, null, 0, 0, screen_width, screen_height, &s_desktop_children);
    try mainWnd.wnd.show_window();
    try x11.appLoop();
}

fn loadResource() !void {
    _ = zguilite.Theme.add_font(.FONT_DEFAULT, @ptrCast(@constCast(&KaiTi_19.KaiTi_19)));
    _ = zguilite.Theme.add_color(.COLOR_WND_FONT, zguilite.GL_RGB(255, 255, 255));
    _ = zguilite.Theme.add_color(.COLOR_WND_NORMAL, zguilite.GL_RGB(59, 75, 94));
    _ = zguilite.Theme.add_color(.COLOR_WND_PUSHED, zguilite.GL_RGB(33, 42, 53));
    _ = zguilite.Theme.add_color(.COLOR_WND_FOCUS, zguilite.GL_RGB(43, 118, 219));
    _ = zguilite.Theme.add_color(.COLOR_WND_BORDER, zguilite.GL_RGB(46, 59, 73));
}
