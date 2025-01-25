const std = @import("std");
const zguilite = @import("zguilite");
const freetype_operator = @import("./freetype_operator.zig");
const map_bmp = @import("./guilite_map_bmp.zig");

const X11 = @import("x11");
const UI_WIDTH: i32 = 800; // 示例值，根据实际情况修改
const UI_HEIGHT: i32 = 600; // 示例值，根据实际情况修改

const fWidth: f32 = @floatFromInt(UI_WIDTH);
const fHeight: f32 = @floatFromInt(UI_HEIGHT);
const fWidthHalf: f32 = @floatFromInt(UI_WIDTH / 2);
const fHeightHalf: f32 = @floatFromInt(UI_HEIGHT / 2);

const Z_ORDER_LEVEL_0 = zguilite.Z_ORDER_LEVEL_0;
const GL_RGB = zguilite.GL_RGB;


const Main = struct {
    wnd: zguilite.Wnd = .{ .m_class = "Main", .m_vtable = .{
        .on_paint = Main.on_paint,
    } },
    fn init()!Main{
        const m = Main{};
        return m;
    }
    fn deinit(m:*Main)void{
        _ = m; // autofix
    }

    fn on_paint(w: *zguilite.Wnd) !void {
        const this:*Main = @fieldParentPtr("wnd",w);
        _ = this; // autofix
        std.log.debug("main on_paint",.{});
        if (w.m_surface) |surface| {
            const rect = zguilite.Rect.init2(0, 0, UI_WIDTH, UI_HEIGHT);
            surface.fill_rect(rect, 0, 0);
            try zguilite.Bitmap.draw_bitmap(surface,zguilite.Z_ORDER_LEVEL_0,try zguilite.Theme.get_bmp(.BITMAP_CUSTOM1),0,200,zguilite.DEFAULT_MASK_COLOR);
        }
    }
};


const welcome = [_][]const u8{
	"Hello, GuiLite has only 4000+ lines of basic C++ code.\n    But, we have developers all over the world.",
	"GuiLite僅僅只有4千行的基礎C++代碼。\n  但我們的開發者，遍佈全球。",
	"こんにちは、GuiLiteには4000行以上のC ++コードしかありません\n  しかし、世界中に開発者がいます"
};

var app = X11{};
pub fn main() !void {
    std.log.debug("main begin", .{});
    try loadResource();

    const screen_width: i32 = UI_WIDTH;
    const screen_height: i32 = UI_HEIGHT;
    var color_bytes: u32 = 0;
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    const frameBuffer = try app.init(allocator,"main", screen_width, screen_height, &color_bytes);
    defer app.deinit();

    var _display: zguilite.Display = .{};
    try _display.init2(frameBuffer.ptr, screen_width, screen_height, screen_width, screen_height, color_bytes, 3, null);
    const surface = try _display.allocSurface(.Z_ORDER_LEVEL_1, zguilite.Rect.init2(0, 0, screen_width, screen_height));
    surface.set_active(true);

    var mainWnd = try Main.init();
    defer mainWnd.deinit();

    mainWnd.wnd.set_surface(surface);
    const ID_DESKTOP = 1;

    var btn = zguilite.Button{};
    const ID_BTN = 2;

    var children = [_]?*const zguilite.WND_TREE{
        &.{
            .p_wnd = btn.asWnd(), //
            .resource_id = ID_BTN,
            .str = "NEXT",
            .x = 330,
            .y = 540,
            .width = 100,
            .height = 50,
            .p_child_tree = null,
        },
    };
    const ClickData = struct{
        index:u32 = 0,
        m:*Main = undefined,
    };
    var clickData = ClickData{
        .m = &mainWnd,
    };

    var onTouchCallbackObj = X11.onTouchCallback.init(&mainWnd, &struct {
        pub fn onTouch(_mainWnd: *Main, x: usize, y: usize, action: zguilite.TOUCH_ACTION) anyerror!void {
            // std.log.debug("onTouch(x:{},y:{})",.{x,y});
            try _mainWnd.wnd.on_touch(@intCast(x), @intCast(y), action);
        }
    }.onTouch);
    app.setTouchCallback(&onTouchCallbackObj);

    btn.set_on_click(zguilite.WND_CALLBACK.init(&clickData,struct{
        fn onClick(data:*ClickData,id: i32, param: i32) !void{
            _ = id; // autofix
            _ = param; // autofix
            
            if(data.m.wnd.m_surface)|s|{
                const rect = zguilite.Rect.init2(0,60,UI_WIDTH,140);
                s.fill_rect(rect,zguilite.GL_RGB(0,0,0),zguilite.Z_ORDER_LEVEL_0);
                zguilite.Word.draw_string(s,zguilite.Z_ORDER_LEVEL_0,welcome[data.index],80,50,zguilite.Theme.get_font(.FONT_DEFAULT),zguilite.GL_RGB(172, 226, 9), 0);
                data.index +%= 1;
                data.index = @truncate(@mod(data.index,welcome.len));
            }
        }
    }.onClick));
    try mainWnd.wnd.connect(null, ID_DESKTOP, null, 0, 0, screen_width, screen_height, &children);
    try mainWnd.wnd.show_window();

    try btn.on_click.?.on(0,0);

    const idleCallback = zguilite.WND_CALLBACK.init(&mainWnd,struct{
        fn onIdle(m:*Main)!void{
            _ = m; // autofix
        }
    }.onIdle);
    app.setIdleCallback(idleCallback);
    try app.loop();
}

fn loadResource() !void {
    try freetype_operator.FreetypeOperator.init();
    zguilite.fontOperator = freetype_operator.FreetypeOperator.ToFontOperator();

    // _ = zguilite.Theme.add_font(.FONT_DEFAULT, @ptrCast(@constCast(&zguilite.Consolas_24B.Consolas_24B)));
    _ = zguilite.Theme.add_font(.FONT_DEFAULT, @ptrCast(@constCast(try freetype_operator.FreetypeOperator.set_font("./simhei.ttf",32,32))));
    try zguilite.Theme.add_bmp(.BITMAP_CUSTOM1,@ptrCast(@constCast(&map_bmp.guilite_map_bmp)));
    _ = zguilite.Theme.add_color(.COLOR_WND_FONT, zguilite.GL_RGB(255, 255, 255));
    _ = zguilite.Theme.add_color(.COLOR_WND_NORMAL, zguilite.GL_RGB(59, 75, 94));
    _ = zguilite.Theme.add_color(.COLOR_WND_PUSHED, zguilite.GL_RGB(33, 42, 53));
    _ = zguilite.Theme.add_color(.COLOR_WND_FOCUS, zguilite.GL_RGB(43, 118, 219));
    _ = zguilite.Theme.add_color(.COLOR_WND_BORDER, zguilite.GL_RGB(46, 59, 73));
}
