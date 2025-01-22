const std = @import("std");
const zguilite = @import("zguilite");
const x11 = @import("x11");
const UI_WIDTH: i32 = 600; // 示例值，根据实际情况修改
const UI_HEIGHT: i32 = 800; // 示例值，根据实际情况修改

const fWidth:f32 = @floatFromInt(UI_WIDTH);
const fHeight:f32 = @floatFromInt(UI_HEIGHT);
const fWidthHalf:f32 = @floatFromInt(UI_WIDTH / 2 ) ;
const fHeightHalf:f32 = @floatFromInt(UI_HEIGHT / 2 ) ;

const Z_ORDER_LEVEL_0 = zguilite.Z_ORDER_LEVEL_0;
const GL_RGB = zguilite.GL_RGB;

fn rand(range:u32) u32 {
    return std.crypto.random.intRangeAtMostBiased(u32,0,range);
}
var s_surface:?*zguilite.Surface = null;
const Star = struct {
    start_x: u32,
    start_y: u32,
    x: f32,
    y: f32,
    x_factor: f32,
    y_factor: f32,
    size_factor: f32,
    size: f32,

    fn init(self: *Star) void {
        self.start_x = rand(UI_WIDTH);
        self.start_y = rand(UI_HEIGHT);
        self.x = @floatFromInt(self.start_x);
        self.y = @floatFromInt(self.start_y);
        self.size = 1.0;
        self.x_factor = fWidth;
        self.y_factor = fHeight;
        self.size_factor = 1.0;
    }

    fn move(self: *Star) void {
        if (s_surface) |surface| {
            var rect = zguilite.Rect.init2(
                @intFromFloat(self.x),
                @intFromFloat(self.y),
                @intFromFloat(self.size),
                @intFromFloat(self.size)
                );
            surface.fill_rect(
                rect,
                0,
                Z_ORDER_LEVEL_0,
            ); // clear star footprint

            self.x_factor -= 6.0;
            self.y_factor -= 6.0;
            self.size += self.size / 20.0;

            if (self.x_factor < 1.0 or self.y_factor < 1.0) {
                self.init();
                return;
            }
            const istartX:i32 = @intCast(self.start_x);
            const istartY:i32 = @intCast(self.start_y);

            if (self.start_x > (UI_WIDTH / 2) and self.start_y > (UI_HEIGHT / 2)) {
                self.x = fWidthHalf + fWidth * (@as(f32,@floatFromInt(self.start_x - (UI_WIDTH / 2))) / self.x_factor);
                self.y = fHeightHalf + fHeight * (@as(f32,@floatFromInt(istartY - (UI_HEIGHT / 2))) / self.y_factor);
            } else if (self.start_x <= (UI_WIDTH / 2) and istartY > (UI_HEIGHT / 2)) {
                self.x = fWidthHalf - fWidth * (@as(f32,@floatFromInt((UI_WIDTH / 2) - istartX)) / self.x_factor);
                self.y = fHeightHalf + fHeight * (@as(f32,@floatFromInt(istartY - (UI_HEIGHT / 2))) / self.y_factor);
            } else if (istartX > (UI_WIDTH / 2) and istartY <= (UI_HEIGHT / 2)) {
                self.x = fWidthHalf + fWidth * (@as(f32,@floatFromInt(istartX - (UI_WIDTH / 2))) / self.x_factor);
                self.y = fHeightHalf - fHeight * (@as(f32,@floatFromInt((UI_HEIGHT / 2) - istartY)) / self.y_factor);
            } else if (istartX <= (UI_WIDTH / 2) and istartY <= (UI_HEIGHT / 2)) {
                self.x = fWidthHalf - fWidth * (@as(f32,@floatFromInt((UI_WIDTH / 2) - istartX)) / self.x_factor);
                self.y = fHeightHalf - fHeight * (@as(f32,@floatFromInt((UI_HEIGHT / 2) - istartY)) / self.y_factor);
            }

            if (self.x < 0.0 or (self.x + self.size - 1) >= fWidth or
                self.y < 0.0 or (self.y + self.size - 1) >= fHeight) {
                self.init();
                return;
            }
            rect = zguilite.Rect.init2(
                @intFromFloat(self.x),
                @intFromFloat(self.y),
                @intFromFloat(self.size),
                @intFromFloat(self.size)
                );
            surface.fill_rect(
                rect,
                GL_RGB(255, 255, 255),
                Z_ORDER_LEVEL_0,
            ); // draw star
            std.log.debug("start draw size:{d:.2} rect:{}",.{self.size,rect});
        }
    }
};

var stars: [100]Star = undefined;

const Main = struct {
    wnd: zguilite.Wnd = .{ .m_class = "Main", .m_vtable = .{
        .on_paint = Main.on_paint,
    } },

    fn on_paint(w: *zguilite.Wnd) !void {
        if (w.m_surface) |surface| {
            const rect = zguilite.Rect.init2(0,0,UI_WIDTH,UI_HEIGHT);
            surface.fill_rect(rect,0,0);
            for (&stars) |*star| {
                star.init();
            }
        
            while (true) {
                for (&stars) |*star| {
                    star.move();
                }
                try x11.refreshApp();
                std.time.sleep(50 * std.time.ns_per_ms);
            }
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
    const surface = try _display.alloSurface(.Z_ORDER_LEVEL_1, zguilite.Rect.init2(0, 0, screen_width, screen_height));
    surface.set_active(true);
    s_surface = surface;

    var mainWnd = Main{};
    mainWnd.wnd.set_surface(surface);
    const ID_DESKTOP = 1;
    

    try mainWnd.wnd.connect(null, ID_DESKTOP, null, 0, 0, screen_width, screen_height, null);
    try mainWnd.wnd.show_window();
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
