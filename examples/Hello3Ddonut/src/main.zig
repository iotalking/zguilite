const std = @import("std");
const zguilite = @import("zguilite");
const X11 = @import("x11");
const freetype = @import("freetype");
const consolas_13 = @import("./Consolas_13.zig").Consolas_13;

const UI_WIDTH: i32 = 240; // 示例值，根据实际情况修改
const UI_HEIGHT: i32 = 320; // 示例值，根据实际情况修改
const Z_ORDER_LEVEL_0 = zguilite.Z_ORDER_LEVEL_0;

const WIDTH: usize = 50;
const X_OFFSET: i32 = 20;
const X_RADIUS: f32 = 25;
const HEIGHT: usize = 22;
const Y_OFFSET: i32 = 12;
const Y_RADIUS: f32 = 15;

var frame_buffer: [(WIDTH) * (HEIGHT)]u8 = undefined;
var z: [WIDTH * HEIGHT]f32 = undefined;
var A: f32 = 0.0;
var B: f32 = 0.0;
fn build_frame() void {
    @memset(&frame_buffer, ' ');
    @memset(z[0..], 0.0);
 
    var j: f32 = 0.0;
    while (j < 6.28) : (j += 0.07) {
        var i: f32 = 0.0;
        while (i < 6.28) : (i += 0.02) {
            const c = @sin(i);
            const d = @cos(j);
            const e = @sin(A);
            const f = @sin(j);
            const g = @cos(A);
            const h = d + 2;
            const D = 1.0 / (c * h * e + f * g + 5.0);
            const l = @cos(i);
            const m = @cos(B);
            const n = @sin(B);
            const t = c * h * g - f * e;
            const x = X_OFFSET + @as(i32,@intFromFloat(X_RADIUS * D * (l * h * m - t * n)));
            const y = Y_OFFSET + @as(i32,@intFromFloat(Y_RADIUS * D * (l * h * n + t * m)));
            const _o = x + @as(i32,@intCast(WIDTH)) * y;
            const o:u32 = @intCast(_o);
            const N = 8.0 * ((f * e - c * d * g) * m - c * d * e - f * g - l * d * n);
 
            if (y < HEIGHT and y > 0 and x > 0 and x < WIDTH and D > z[o]) {
                z[o] = D;
                const _N:u32 = @bitCast(@as(i32,@intFromFloat(if (N > 0) N else 0)));
                frame_buffer[o] = ".,-~:;=!*#$@"[_N];
            }
        }
    }
    const fWidth:f32 = @floatFromInt(WIDTH);
    const fHeight:f32 = @floatFromInt(HEIGHT);
    A += 0.00004 * fWidth * fHeight;
    B += 0.00002 * fWidth * fHeight;
}

fn render_frame(surface:*zguilite.Surface) void {
    var i: i32 = 0;
    const font = zguilite.Theme.get_font(.FONT_DEFAULT);
    const iw:i32 = @intCast(WIDTH);
    while (i < HEIGHT) : (i += 1) {
        const idx:u32 = @bitCast(i*iw);
        zguilite.Word.draw_string(surface, zguilite.Z_ORDER_LEVEL_0, frame_buffer[idx..][0..WIDTH], 0, i * 13, font, zguilite.GL_RGB(245, 192, 86), zguilite.GL_RGB(0, 0, 0));
    }
}


const Main = struct {
    wnd: zguilite.Wnd = .{ .m_class = "Main", .m_vtable = .{
        .on_paint = Main.on_paint,
    } },
    fn on_paint(w: *zguilite.Wnd) !void {
        _ = w; // autofix
    }
};

var app = X11{};
var exit = false;
fn draw(surface:*zguilite.Surface)!void{
    var t = try std.time.Timer.start();
    while(!exit){
        t.reset();
        build_frame();
        render_frame(surface);
        std.log.err("draw time:{d}",.{t.read()/std.time.ns_per_ms});
    }
}
pub fn main() !void {
    std.log.debug("main begin", .{});
    try loadResource();
    // zguilite.init();

    const screen_width: i32 = UI_WIDTH;
    const screen_height: i32 = UI_HEIGHT;
    var color_bytes: u32 = 0;
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    const frameBuffer = try app.init(allocator,"main", screen_width, screen_height, &color_bytes);
    defer app.deinit();

    var _display: zguilite.Display = .{};
    try _display.init2(frameBuffer.ptr, screen_width, screen_height, screen_width, screen_height, color_bytes, 3, null);
    var surface = try _display.allocSurface(.Z_ORDER_LEVEL_1, zguilite.Rect.init2(0, 0, screen_width, screen_height));
    surface.set_active(true);

    const rect = zguilite.Rect.init2(0, 0, UI_WIDTH, UI_HEIGHT);

    surface.fill_rect(rect, zguilite.COLORS.BLACK, Z_ORDER_LEVEL_0); // clear previous image

    var mainWnd = Main{
    };
    mainWnd.wnd.set_surface(surface);

    const ID_DESKTOP = 1;
    try mainWnd.wnd.connect(null, ID_DESKTOP, null, 0, 0, screen_width, screen_height, null);
    try mainWnd.wnd.show_window();


    const t = try std.Thread.spawn(.{},draw,.{surface});
    defer {
        exit = true;
        t.join();
    }
    try app.loop();
}

fn loadResource() !void {
    _ = zguilite.Theme.add_font(.FONT_DEFAULT,@ptrCast(@constCast(&consolas_13)));
}
