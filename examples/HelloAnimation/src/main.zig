const std = @import("std");
const zguilite = @import("zguilite");
const KaiTi_19 = @import("./KaiTi_19.zig");
const x11 = @import("x11");
pub fn main() !void {
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
            .y = 149,
            .width = 40,
            .height = 60,
            .p_child_tree = null,
        },
    };

    var desktop = zguilite.Wnd{};
    desktop.m_class = "desktop";
    desktop.set_surface(surface);
    try desktop.connect(null, ID_DESKTOP, null, 0, 0, screen_width, screen_height, &s_desktop_children);
    try desktop.show_window();
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
