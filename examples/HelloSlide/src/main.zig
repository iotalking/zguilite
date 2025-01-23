const std = @import("std");
const zguilite = @import("zguilite");
const X11 = @import("x11");

const UI_WIDTH: i32 = 512; // 示例值，根据实际情况修改
const UI_HEIGHT: i32 = 768; // 示例值，根据实际情况修改

const Z_ORDER_LEVEL_0 = zguilite.Z_ORDER_LEVEL_0;
const GL_RGB = zguilite.GL_RGB;
const Wnd = zguilite.Wnd;
const Rect = zguilite.Rect;
const BITMAP_INFO = zguilite.BITMAP_INFO;
const Theme = zguilite.Theme;
const Bitmap = zguilite.Bitmap;
const SlideGroup = zguilite.SlideGroup;
const WND_TREE = zguilite.WND_TREE;
// 枚举 WND_ID
const ID_ROOT = 1;
const ID_PAGE1 = 2;
const ID_PAGE2 = 3;
const ID_PAGE3 = 4;
const ID_PAGE4 = 5;
const ID_PAGE5 = 6;

// 定义 BITMAP_CUSTOM 枚举值
const BITMAP_CUSTOM1 = 0;
const BITMAP_CUSTOM2 = 1;
const BITMAP_CUSTOM3 = 2;
const BITMAP_CUSTOM4 = 3;
const BITMAP_CUSTOM5 = 4;

// 定义 Page 结构体
const Page = struct {
    wnd: zguilite.Wnd = .{ .m_class = "Page", .m_vtable = .{
        .on_paint = Page.on_paint,
    } },
    // 这里需要根据 Wnd 的具体实现添加更多成员
    pub fn init(rid: u16) Page {
        var page = Page{};
        page.wnd.m_id = rid;
        return page;
    }
    pub fn on_paint(self: *Wnd) !void {
        var rect = Rect.init();
        std.log.debug("Page on_paint m_id:{d}", .{self.m_id});
        // const self:*Page = @fieldParentPtr("wnd",w);
        self.get_screen_rect(&rect);
        var bmp: ?*BITMAP_INFO = null;
        switch (self.m_id) {
            ID_PAGE1 => bmp = @constCast(try Theme.get_bmp(.BITMAP_CUSTOM1)),
            ID_PAGE2 => bmp = @constCast(try Theme.get_bmp(.BITMAP_CUSTOM2)),
            ID_PAGE3 => bmp = @constCast(try Theme.get_bmp(.BITMAP_CUSTOM3)),
            ID_PAGE4 => bmp = @constCast(try Theme.get_bmp(.BITMAP_CUSTOM4)),
            ID_PAGE5 => bmp = @constCast(try Theme.get_bmp(.BITMAP_CUSTOM5)),
            else => {},
        }
        if (bmp) |bitmap| {
            if (self.m_surface) |surface| {
                std.log.debug("Page on_paint draw_bitmap self.m_z_order:{} rect.m_left:{}, rect.m_top:{}", .{ self.m_z_order, rect.m_left, rect.m_top });
                try Bitmap.draw_bitmap(surface, self.m_z_order, bitmap, rect.m_left, rect.m_top, zguilite.DEFAULT_MASK_COLOR);
            } else {
                std.debug.assert(false);
            }
        } else {
            std.debug.assert(false);
        }
    }

    // 以下是一些占位函数，根据实际情况完善
    inline fn get_screen_rect(self: *Page, rect: *Rect) void {
        self.wnd.get_screen_rect(rect);
    }
};

var s_root_children: [1]WND_TREE = [_]WND_TREE{
    WND_TREE{ .ptr = null, .id = 0, .x = 0, .y = 0, .width = 0, .height = 0, .z_order = 0 },
};

const ten_bmp = @import("./ten_bmp.zig").ten_bmp;
const jack_bmp = @import("./jack_bmp.zig").jack_bmp;
const queen_bmp = @import("./queen_bmp.zig").queen_bmp;
const king_bmp = @import("./king_bmp.zig").king_bmp;
const ace_bmp = @import("./ace_bmp.zig").ace_bmp;

// 函数 load_resource
fn load_resource() !void {
    try Theme.add_bmp(.BITMAP_CUSTOM1, &ten_bmp);
    try Theme.add_bmp(.BITMAP_CUSTOM2, &jack_bmp);
    try Theme.add_bmp(.BITMAP_CUSTOM3, &queen_bmp);
    try Theme.add_bmp(.BITMAP_CUSTOM4, &king_bmp);
    try Theme.add_bmp(.BITMAP_CUSTOM5, &ace_bmp);
}
fn subWinMain(idx: u16) !void {
    // 定义全局变量
    var s_page1 = Page.init(ID_PAGE1);
    var s_page2 = Page.init(ID_PAGE2);
    var s_page3 = Page.init(ID_PAGE3);
    var s_page4 = Page.init(ID_PAGE4);
    var s_page5 = Page.init(ID_PAGE5);

    var win = X11{};

    var root: SlideGroup = .{};
    const screen_width: i32 = UI_WIDTH;
    const screen_height: i32 = UI_HEIGHT;
    var color_bytes: u32 = 0;
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    const title = try std.fmt.allocPrintZ(allocator,"{d}",.{idx});
    defer allocator.free(title);
    const frameBuffer = try win.init(allocator,title, screen_width, screen_height, &color_bytes);
    defer win.deinit();

    var _display: zguilite.Display = .{};
    try _display.init2(frameBuffer.ptr, screen_width, screen_height, screen_width, screen_height, color_bytes, (1 + 5), null);
    const surface = try _display.allocSurface(.Z_ORDER_LEVEL_1, zguilite.Rect.init2(0, 0, screen_width, screen_height));
    surface.set_active(true);

    root.init();
    root.wnd.set_surface(surface);

    const ID_DESKTOP = 1;

    var onTouchCallbackObj = X11.onTouchCallback.init(&root, &struct {
        pub fn onTouch(_root: *SlideGroup, x: i32, y: i32, action: zguilite.TOUCH_ACTION) anyerror!void {
            try _root.wnd.on_touch(x, y, action);
        }
    }.onTouch);
    win.setTouchCallback(&onTouchCallbackObj);

    try root.wnd.connect(null, ID_DESKTOP, null, 0, 0, screen_width, screen_height, null);

    try root.add_slide(&s_page1.wnd, ID_PAGE1, 0, 0, UI_WIDTH, UI_HEIGHT, null, .Z_ORDER_LEVEL_0);
    try root.add_slide(&s_page2.wnd, ID_PAGE2, 0, 0, UI_WIDTH, UI_HEIGHT, null, .Z_ORDER_LEVEL_0);
    try root.add_slide(&s_page3.wnd, ID_PAGE3, 0, 0, UI_WIDTH, UI_HEIGHT, null, .Z_ORDER_LEVEL_0);
    try root.add_slide(&s_page4.wnd, ID_PAGE4, 0, 0, UI_WIDTH, UI_HEIGHT, null, .Z_ORDER_LEVEL_0);
    try root.add_slide(&s_page5.wnd, ID_PAGE5, 0, 0, UI_WIDTH, UI_HEIGHT, null, .Z_ORDER_LEVEL_0);
    try root.set_active_slide(idx, true);
    try root.wnd.show_window();

    try win.loop();
}
pub fn main() !void {
    std.log.debug("main begin", .{});
    X11.initThreads();

    try load_resource();

    const thread = try std.Thread.spawn(.{}, subWinMain, .{0});
    defer thread.join();

    try subWinMain(1);
}
