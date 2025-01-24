const std = @import("std");
const zguilite = @import("zguilite");
const player = @import("./player.zig");

const X11 = @import("x11");
const UI_WIDTH: i32 = 640; // 示例值，根据实际情况修改
const UI_HEIGHT: i32 = 360; // 示例值，根据实际情况修改

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
    player:?player.Player = null,
    lastSeconds:f64 = 0,
    isPlayEnd:bool = false,
    fn init(colorBytes:u32)!Main{
        var m = Main{};
        var p = player.Player.init(UI_WIDTH,UI_HEIGHT,colorBytes);
        errdefer {
            p.close();
        }
        try p.open("./1.mp4");
        try p.readFrame(null,player.AV_PIX_FMT_RGB565LE);
        m.player = p;
        return m;
    }
    fn deinit(m:*Main)void{
        if(m.player)|*p|{
            p.close();
            m.player = null;
        }
    }

    fn renderVideoFrame(m:*Main)!void{
        std.log.debug("Main renderVideoFrame",.{});
        if(m.isPlayEnd){
            return error.play_end;
        }
        const start = try std.time.Instant.now();
        const surface = m.wnd.m_surface orelse return error.wnd_surface_null;
        const display = surface.m_display orelse return error.surface_display_null;

        const fb = display.get_updated_fb(null,null,true);
        var p = m.player orelse return error.player_null;
        switch(p.colorBytes){
            2 => {
                try p.readFrame(fb,player.AV_PIX_FMT_RGB565LE);
            },
            4 => {
                std.log.debug("main on_paint readFrame color_bytes:{d}",.{p.colorBytes});
                try p.readFrame(fb,player.AV_PIX_FMT_BGR0);
            },
            else => {
                try p.readFrame(null,player.AV_PIX_FMT_RGB565LE);
            }
        }
        // try p.renderRawData(s);
        std.log.debug("main on_paint app refresh ",.{});
        try app.refresh();
        const curSeconds = try p.currentSeconds();
        if(curSeconds <= m.lastSeconds){
            std.log.debug("main on_paint play end, pts:{d} curSeconds:{d} lastSeconds:{d}",.{p.av_frame.?.pts, curSeconds,m.lastSeconds});
            m.isPlayEnd = true;
            return ;
        }
        const end = try std.time.Instant.now();
        const passTime = end.since(start);
        const wantWaitTime  = @as(u64,@intFromFloat((curSeconds - m.lastSeconds)*std.time.ns_per_s));
        const realWaitTime = wantWaitTime - passTime;
        std.log.info("Main renderVideoFrame wantWaitTime:{d} realWaitTime:{d}",.{wantWaitTime,realWaitTime});
        std.time.sleep(realWaitTime);
        m.lastSeconds = curSeconds;
    }
    fn on_paint(w: *zguilite.Wnd) !void {
        const this:*Main = @fieldParentPtr("wnd",w);
        std.log.debug("main on_paint",.{});
        if (w.m_surface) |surface| {
            const rect = zguilite.Rect.init2(0, 0, UI_WIDTH, UI_HEIGHT);
            surface.fill_rect(rect, 0, 0);
            if(this.player)|*p|{
                _ = p; // autofix
                // while(true){
                    this.renderVideoFrame()  catch |e|{
                        switch(e){
                            error.surface_display_null,error.wnd_surface_null => {
                                return;
                            },
                            else => {
                                return e;
                            }
                        }
                    };
                // }
            }
            
        }
    }
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

    var mainWnd = try Main.init(color_bytes);
    defer mainWnd.deinit();

    mainWnd.wnd.set_surface(surface);
    const ID_DESKTOP = 1;

    try mainWnd.wnd.connect(null, ID_DESKTOP, null, 0, 0, screen_width, screen_height, null);
    try mainWnd.wnd.show_window();
    const idleCallback = zguilite.WND_CALLBACK.init(&mainWnd,struct{
        fn onIdle(m:*Main)!void{
            try m.renderVideoFrame();
        }
    }.onIdle);
    app.setIdleCallback(idleCallback);
    try app.loop();
}

fn loadResource() !void {
    _ = zguilite.Theme.add_font(.FONT_DEFAULT, @ptrCast(@constCast(&zguilite.Consolas_24B.Consolas_24B)));
    _ = zguilite.Theme.add_color(.COLOR_WND_FONT, zguilite.GL_RGB(255, 255, 255));
    _ = zguilite.Theme.add_color(.COLOR_WND_NORMAL, zguilite.GL_RGB(59, 75, 94));
    _ = zguilite.Theme.add_color(.COLOR_WND_PUSHED, zguilite.GL_RGB(33, 42, 53));
    _ = zguilite.Theme.add_color(.COLOR_WND_FOCUS, zguilite.GL_RGB(43, 118, 219));
    _ = zguilite.Theme.add_color(.COLOR_WND_BORDER, zguilite.GL_RGB(46, 59, 73));
}
