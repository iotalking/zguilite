const std = @import("std");
const zguilite = @import("zguilite");
const x11 = @import("x11");
const UI_WIDTH: i32 = 240; // 示例值，根据实际情况修改
const UI_HEIGHT: i32 = 320; // 示例值，根据实际情况修改

const Z_ORDER_LEVEL_0 = zguilite.Z_ORDER_LEVEL_0;

const Main = struct {
    wnd: zguilite.Wnd = .{ .m_class = "Main", .m_vtable = .{
        .on_paint = Main.on_paint,
    } },

    fn on_paint(w: *zguilite.Wnd) !void {
        if (w.m_surface) |surface| {
            _ = surface; // autofix
        }
    }
};
pub fn main() !void {
    std.log.debug("main begin", .{});
    try loadResource();

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

    var label1 = zguilite.Label{};
    _ = &label1; // autofix
    var label2 = zguilite.Label{};
    _ = &label2; // autofix
    var label3 = zguilite.Label{};
    _ = &label3; // autofix
    var button1 = zguilite.Button{};
    _ = &button1; // autofix
    var button2 = zguilite.Button{};
    _ = &button2; // autofix
    var button3 = zguilite.Button{};
    _ = &button3; // autofix
    const ID_DESKTOP = 1;
    const ID_LABEL1 = 2;
    const ID_LABEL2 = 3;
    const ID_LABEL3 = 4;
    const ID_BUTTON1 = 5;
    const ID_BUTTON2 = 6;
    const ID_BUTTON3 = 7;

    var s_desktop_children = [_]?*const zguilite.WND_TREE{
        &.{
            .p_wnd = label1.asWnd(),
            .resource_id = ID_LABEL1,
            .str = "a: <<",
            .x = 20,
            .y = 20,
            .width = 80,
            .height = 20,
            .p_child_tree = null,
        },
        &.{
            .p_wnd = label2.asWnd(),
            .resource_id = ID_LABEL2,
            .str = "d: >>",
            .x = 20,
            .y = 140,
            .width = 80,
            .height = 20,
            .p_child_tree = null,
        },
        &.{
            .p_wnd = label3.asWnd(),
            .resource_id = ID_LABEL3,
            .str = "s: click",
            .x = 20,
            .y = 260,
            .width = 120,
            .height = 20,
            .p_child_tree = null,
        },
        &.{
            .p_wnd = button1.asWnd(),
            .resource_id = ID_BUTTON1,
            .str = "0",
            .x = 140,
            .y = 20,
            .width = 80,
            .height = 40,
            .p_child_tree = null,
        },
        &.{
            .p_wnd = button2.asWnd(),
            .resource_id = ID_BUTTON2,
            .str = "0",
            .x = 140,
            .y = 140,
            .width = 80,
            .height = 40,
            .p_child_tree = null,
        },
        &.{
            .p_wnd = button3.asWnd(),
            .resource_id = ID_BUTTON3,
            .str = "0",
            .x = 140,
            .y = 260,
            .width = 80,
            .height = 40,
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

    const ButtonOnClick = struct {
        btn: *zguilite.Button,
        sum: u32 = 0,
        strBuf: [20]u8 = undefined,
        const Self = @This();
        fn onClick(this: *Self, id: i32, param: i32) !void {
            _ = id; // autofix
            _ = param; // autofix
            this.sum += 1;
            const str = try std.fmt.bufPrint(&this.strBuf, "{d}", .{this.sum});
            this.btn.asWnd().set_str(str);
        }
    };

    button1.set_on_click(zguilite.WND_CALLBACK.init(&ButtonOnClick{
        .btn = &button1,
    }, ButtonOnClick.onClick));
    button2.set_on_click(zguilite.WND_CALLBACK.init(&ButtonOnClick{
        .btn = &button2,
    }, ButtonOnClick.onClick));
    button3.set_on_click(zguilite.WND_CALLBACK.init(&ButtonOnClick{
        .btn = &button3,
    }, ButtonOnClick.onClick));
    try x11.appLoop();
}

fn loadResource() !void {
    _ = zguilite.Theme.add_font(.FONT_DEFAULT, @ptrCast(@constCast(&zguilite.Consolas_24B.Consolas_24B)));
    _ = zguilite.Theme.add_color(.COLOR_WND_FONT, zguilite.GL_RGB(255, 255, 255));
    _ = zguilite.Theme.add_color(.COLOR_WND_NORMAL, zguilite.GL_RGB(59, 75, 94));
    _ = zguilite.Theme.add_color(.COLOR_WND_PUSHED, zguilite.GL_RGB(33, 42, 53));
    _ = zguilite.Theme.add_color(.COLOR_WND_FOCUS, zguilite.GL_RGB(43, 118, 219));
    _ = zguilite.Theme.add_color(.COLOR_WND_BORDER, zguilite.GL_RGB(46, 59, 73));
}
